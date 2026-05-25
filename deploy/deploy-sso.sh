#!/usr/bin/env bash
# Deploy sso-svc to production.
#
# Workflow:
#   1. Push code to git (triggers GitHub Actions to build + push image to GHCR)
#   2. SSH to server: pull new image, restart container
#
# Usage:
#   ./scripts/deploy-sso.sh              # deploy current branch
#   ./scripts/deploy-sso.sh --skip-push  # skip git push (image already built)

set -euo pipefail

SKIP_PUSH=false
for arg in "$@"; do
  [[ "$arg" == "--skip-push" ]] && SKIP_PUSH=true
done

IMAGE="ghcr.io/jomhoor/sso-svc:feat-sso"
SERVER="iranians-vote-vps"
COMPOSE_DIR="/opt/iranians-vote"

if [[ "$SKIP_PUSH" == "false" ]]; then
  echo ">>> Pushing to git..."
  git push origin "$(git rev-parse --abbrev-ref HEAD)"

  echo ">>> Waiting for GitHub Actions to build image (press Ctrl+C to skip wait and deploy manually)..."
  echo "    Track build at: https://github.com/jomhoor/Platform/actions"
  read -r -p "    Press Enter when the Actions build is green: "
fi

echo ">>> Deploying to $SERVER..."
ssh "$SERVER" "
  set -e
  echo 'Pulling image...'
  docker pull $IMAGE
  echo 'Restarting sso-svc...'
  cd $COMPOSE_DIR
  docker compose up -d --no-build sso-svc
  echo 'Done. Logs:'
  docker logs sso-svc --tail 20
"
