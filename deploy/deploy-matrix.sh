#!/usr/bin/env bash
# deploy-matrix.sh — run as root on iranians-vote-vps
# Usage: bash deploy-matrix.sh
set -euo pipefail

REPO_DIR="/opt/iranians-vote/repo"
DEPLOY_DIR="/opt/iranians-vote"
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
VHOSTS_SRC="$REPO_DIR/deploy/nginx-vhosts"

echo "=== 1/7  git pull ==="
cd "$REPO_DIR"
git pull origin feat/sso

echo "=== 2/7  Generate MATRIX_POSTGRES_PASSWORD (skip if .env already has it) ==="
ENV_FILE="$DEPLOY_DIR/.env"
if grep -q "^MATRIX_POSTGRES_PASSWORD=" "$ENV_FILE" 2>/dev/null; then
  echo "  → already set in $ENV_FILE"
else
  PG_PASS="$(openssl rand -hex 24)"
  echo "MATRIX_POSTGRES_PASSWORD=$PG_PASS" >> "$ENV_FILE"
  echo "  → wrote MATRIX_POSTGRES_PASSWORD to $ENV_FILE"
  echo "  ⚠  Copy this value into configs/synapse/homeserver.yaml and configs/mas/config.yaml"
  grep "^MATRIX_POSTGRES_PASSWORD=" "$ENV_FILE"
fi

echo "=== 3/7  Symlink nginx vhosts ==="
for conf in matrix-jomhoor-org.conf mas-jomhoor-org.conf element-jomhoor-org.conf; do
  src="$VHOSTS_SRC/$conf"
  avail="$NGINX_AVAILABLE/$conf"
  enabled="$NGINX_ENABLED/$conf"
  if [ ! -f "$src" ]; then
    echo "  ✗ $src not found — did git pull succeed?"
    exit 1
  fi
  ln -sf "$src" "$avail"
  ln -sf "$avail" "$enabled"
  echo "  → $conf linked"
done

echo "=== 4/7  Certbot TLS ==="
echo "  Checking DNS resolution…"
for domain in matrix.jomhoor.org mas.jomhoor.org element.jomhoor.org; do
  ip="$(dig +short "$domain" | tail -1)"
  echo "  $domain → ${ip:-'NOT RESOLVING — stop and fix DNS first!'}"
  if [ -z "$ip" ]; then
    echo "ERROR: $domain does not resolve. Fix DNS before continuing."
    exit 1
  fi
done

# Temporarily serve HTTP only so certbot can do ACME challenge
# Our vhosts already have the ACME location block; nginx must be running first
nginx -t
systemctl reload nginx

# Issue/expand cert
certbot certonly --nginx \
  -d matrix.jomhoor.org \
  -d mas.jomhoor.org \
  -d element.jomhoor.org \
  --non-interactive --agree-tos --email admin@jomhoor.org

echo "=== 5/7  Enable HTTPS blocks in vhosts (uncomment ssl_certificate lines) ==="
# The conf files already have the correct ssl_certificate paths for Let's Encrypt.
# Certbot --nginx rewrites them automatically, so this step is a no-op if you
# used --nginx above.  Just reload to apply.
nginx -t && systemctl reload nginx
echo "  → nginx reloaded with TLS"

echo "=== 6/7  Build config files from examples (if not already present) ==="
cd "$REPO_DIR"
if [ ! -f configs/synapse/homeserver.yaml ]; then
  cp configs/synapse/homeserver.yaml.example configs/synapse/homeserver.yaml
  echo "  → created configs/synapse/homeserver.yaml  ⚠  Fill in FILL_IN_* placeholders!"
fi
if [ ! -f configs/mas/config.yaml ]; then
  cp configs/mas/config.yaml.example configs/mas/config.yaml
  echo "  → created configs/mas/config.yaml  ⚠  Fill in FILL_IN_* placeholders!"
fi
echo ""
echo "  Placeholders to fill in configs/synapse/homeserver.yaml:"
echo "    FILL_IN_MATRIX_POSTGRES_PASSWORD"
echo "    FILL_IN_SYNAPSE_CLIENT_ID_FROM_MAS_CONFIG"
echo "    FILL_IN_SYNAPSE_CLIENT_SECRET_FROM_MAS_CONFIG"
echo "    FILL_IN_MAS_ADMIN_TOKEN"
echo ""
echo "  Placeholders to fill in configs/mas/config.yaml:"
echo "    FILL_IN_MATRIX_POSTGRES_PASSWORD"
echo "    FILL_IN_32_BYTE_HEX_SECRET    (run: openssl rand -hex 32)"
echo "    FILL_IN_RSA_PRIVATE_KEY_PEM   (run: openssl genrsa 2048)"
echo "    FILL_IN_SYNAPSE_CLIENT_SECRET (choose any strong secret)"
echo "    FILL_IN_SSO_CLIENT_SECRET     (bcrypt hash of sso_clients.client_secret for MAS)"
echo ""
echo "  Edit both files, then continue with step 7."
echo ""
read -rp "  Press Enter once you have filled in all placeholders… "

echo "=== 7/7  Start Matrix services ==="
cd "$DEPLOY_DIR"

# Ensure .env is sourced for MATRIX_POSTGRES_PASSWORD
set -a; source "$ENV_FILE"; set +a

# Start matrix-postgres first
docker compose --env-file "$ENV_FILE" up -d matrix-postgres
echo "  → Waiting 10s for postgres to initialise…"
sleep 10

# Generate Synapse config (produces homeserver.yaml + signing key) if no signing key yet
if [ ! -f "$REPO_DIR/configs/synapse/homeserver.signing.key" ]; then
  echo "  → Running Synapse config generator (merges into your homeserver.yaml)…"
  docker compose --env-file "$ENV_FILE" run --rm synapse generate
  echo "  ⚠  A new signing key was generated in configs/synapse/.  Back it up!"
else
  echo "  → Signing key already exists, skipping generate."
fi

# Start remaining services
docker compose --env-file "$ENV_FILE" up -d synapse mas element-web

echo ""
echo "=== Done! ==="
echo "  Check logs:"
echo "    docker compose logs -f synapse"
echo "    docker compose logs -f mas"
echo "    docker compose logs -f element-web"
echo ""
echo "  Verify:"
echo "    curl -s https://matrix.jomhoor.org/.well-known/matrix/client | python3 -m json.tool"
echo "    curl -s https://mas.jomhoor.org/health"
echo "    curl -s https://element.jomhoor.org/ | grep -o '<title>[^<]*'"
