#!/usr/bin/env bash
# Generate an RSA-2048 keypair for sso-svc JWT signing (Phase 1.1).
#
# Usage:
#   scripts/generate-jwt-keypair.sh <kid>
#
# Example:
#   scripts/generate-jwt-keypair.sh k1
#
# Prints export lines for SSO_JWT_CURRENT_KID and SSO_JWT_CURRENT_PRIVATE_KEY
# ready to paste into your .env file. The private key is single-line
# base64-encoded PEM so it survives env-var storage (Docker, systemd,
# secret managers) without newline mangling.
#
# Public key material is NOT stored separately — sso-svc derives it from the
# private key at startup and serves it at /.well-known/jwks.json.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <kid>" >&2
  echo "  kid is a stable identifier for this keypair, e.g. 'k1', 'k2026q2'." >&2
  exit 1
fi

KID="$1"

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required" >&2
  exit 1
fi

# RSA-2048 is the OIDC default and what every JWKS consumer supports.
# PKCS#1 ("RSA PRIVATE KEY") — what older tooling expects; we accept both.
PEM="$(openssl genrsa 2048 2>/dev/null)"

# Base64-encode for safe single-line env storage. The Go-side loader auto-
# detects base64 vs PEM, so either form works.
if base64 --help 2>&1 | grep -q -- '-w'; then
  ENCODED="$(printf '%s' "$PEM" | base64 -w0)"
else
  # macOS / BSD base64 emits a single line by default.
  ENCODED="$(printf '%s' "$PEM" | base64)"
fi

cat <<EOF
# --- Paste into .env ---
SSO_JWT_CURRENT_KID=$KID
SSO_JWT_CURRENT_PRIVATE_KEY=$ENCODED
# -----------------------
EOF
