#!/bin/bash
# deploy-matrix-nginx.sh
# Deploys matrix.jomhoor.org, mas.jomhoor.org, element.jomhoor.org nginx vhosts
# and issues TLS certs via certbot.
# Run as root on the VPS: bash /tmp/deploy-matrix-nginx.sh
set -euo pipefail

CONF_DIR=/opt/civic-compass/nginx/conf.d
CERTBOT_CONF=/opt/civic-compass/certbot/conf
CERTBOT_WWW=/opt/civic-compass/certbot/www
CIVIC_NETWORK=civic-compass_civic

echo "=== Step 1: Write HTTP-only confs (for ACME challenge) ==="

cat > "$CONF_DIR/matrix.conf" << 'NGINX_EOF'
# matrix.jomhoor.org — Synapse Matrix homeserver (HTTP-only, pending cert)
server {
    listen 80;
    server_name matrix.jomhoor.org;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 301 https://$host$request_uri;
    }
}
NGINX_EOF

cat > "$CONF_DIR/mas.conf" << 'NGINX_EOF'
# mas.jomhoor.org — Matrix Authentication Service (HTTP-only, pending cert)
server {
    listen 80;
    server_name mas.jomhoor.org;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 301 https://$host$request_uri;
    }
}
NGINX_EOF

cat > "$CONF_DIR/element.conf" << 'NGINX_EOF'
# element.jomhoor.org — Element Web (HTTP-only, pending cert)
server {
    listen 80;
    server_name element.jomhoor.org;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 301 https://$host$request_uri;
    }
}
NGINX_EOF

echo "=== Step 2: Test nginx config and reload ==="
docker exec civic-nginx nginx -t
docker exec civic-nginx nginx -s reload
echo "nginx reloaded with HTTP-only confs"

echo "=== Step 3: Issue TLS certs via certbot (webroot) ==="
docker run --rm \
  --dns 8.8.8.8 --dns 8.8.4.4 \
  --network "$CIVIC_NETWORK" \
  -v "$CERTBOT_CONF:/etc/letsencrypt" \
  -v "$CERTBOT_WWW:/var/www/certbot" \
  certbot/certbot certonly \
    --webroot -w /var/www/certbot \
    -d matrix.jomhoor.org \
    -d mas.jomhoor.org \
    -d element.jomhoor.org \
    --agree-tos --no-eff-email --non-interactive \
    --cert-name matrix.jomhoor.org

echo "Certs issued. Verifying..."
ls -la "$CERTBOT_CONF/live/matrix.jomhoor.org/"

echo "=== Step 4: Write full HTTPS confs ==="

# ── 00-maps.conf ─────────────────────────────────────────────────────────────
cat > "$CONF_DIR/00-maps.conf" << 'NGINX_EOF'
# 00-maps.conf — Shared nginx map directives (loaded first alphabetically)
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
NGINX_EOF

# ── matrix.conf ──────────────────────────────────────────────────────────────
cat > "$CONF_DIR/matrix.conf" << 'NGINX_EOF'
# matrix.jomhoor.org — Synapse Matrix homeserver
# civic-nginx is on iranians-vote_default network → container name resolves

server {
    listen 80;
    server_name matrix.jomhoor.org;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    http2 on;
    server_name matrix.jomhoor.org;

    ssl_certificate     /etc/letsencrypt/live/matrix.jomhoor.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/matrix.jomhoor.org/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:MATRIX_SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;

    resolver 127.0.0.11 valid=10s;
    client_max_body_size 50M;

    location /.well-known/matrix/client {
        default_type application/json;
        add_header Access-Control-Allow-Origin * always;
        return 200 '{"m.homeserver":{"base_url":"https://matrix.jomhoor.org"},"m.authentication":{"issuer":"https://mas.jomhoor.org/"}}';
    }

    location /.well-known/matrix/server {
        default_type application/json;
        add_header Access-Control-Allow-Origin * always;
        return 200 '{"m.server":"matrix.jomhoor.org:443"}';
    }

    location /_matrix/ {
        set $synapse_upstream http://synapse:8008;
        proxy_pass $synapse_upstream$request_uri;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
        proxy_buffering off;
    }

    location /_synapse/ {
        set $synapse_upstream http://synapse:8008;
        proxy_pass $synapse_upstream$request_uri;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }

    location /health {
        return 200 "ok";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

# ── mas.conf ─────────────────────────────────────────────────────────────────
cat > "$CONF_DIR/mas.conf" << 'NGINX_EOF'
# mas.jomhoor.org — Matrix Authentication Service
server {
    listen 80;
    server_name mas.jomhoor.org;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    http2 on;
    server_name mas.jomhoor.org;

    ssl_certificate     /etc/letsencrypt/live/matrix.jomhoor.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/matrix.jomhoor.org/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:MAS_SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;

    resolver 127.0.0.11 valid=10s;

    location / {
        set $mas_upstream http://mas:8080;
        proxy_pass $mas_upstream$request_uri;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }

    location /health {
        return 200 "ok";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

# ── element.conf ─────────────────────────────────────────────────────────────
cat > "$CONF_DIR/element.conf" << 'NGINX_EOF'
# element.jomhoor.org — Element Web Matrix client
server {
    listen 80;
    server_name element.jomhoor.org;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    http2 on;
    server_name element.jomhoor.org;

    ssl_certificate     /etc/letsencrypt/live/matrix.jomhoor.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/matrix.jomhoor.org/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:ELEMENT_SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;

    resolver 127.0.0.11 valid=10s;

    location / {
        set $element_upstream http://element-web:80;
        proxy_pass $element_upstream$request_uri;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }

    location /health {
        return 200 "ok";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

echo "=== Step 5: Test full HTTPS nginx config and reload ==="
docker exec civic-nginx nginx -t
docker exec civic-nginx nginx -s reload
echo "nginx reloaded with full HTTPS confs"

echo "=== Step 6: Verify endpoints ==="
sleep 2
curl -s -o /dev/null -w "matrix.jomhoor.org: %{http_code}\n" https://matrix.jomhoor.org/.well-known/matrix/client
curl -s -o /dev/null -w "mas.jomhoor.org: %{http_code}\n" https://mas.jomhoor.org/health
curl -s -o /dev/null -w "element.jomhoor.org: %{http_code}\n" https://element.jomhoor.org/health

echo "=== DONE ==="
