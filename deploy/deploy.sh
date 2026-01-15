#!/bin/bash
set -e

# Iranians.Vote Production Deployment Script
# Server: 173.212.214.147 (api.iranians.vote)
# Usage: ./deploy.sh [pull|start|stop|restart|logs|status]

DEPLOY_DIR="/opt/iranians-vote"
REPO_URL="https://github.com/ArmaniranEmpire/IV.git"
BRANCH="main"

cd $DEPLOY_DIR

case "$1" in
  pull)
    echo "📥 Pulling latest changes..."
    if [ -d "repo" ]; then
      cd repo && git fetch origin && git reset --hard origin/$BRANCH
    else
      git clone --branch $BRANCH $REPO_URL repo
    fi
    echo "✅ Pull complete"
    ;;
    
  start)
    echo "🚀 Starting services..."
    cd repo/platform/deploy
    
    # Check for .env
    if [ ! -f .env ]; then
      echo "⚠️  No .env file found. Copying from .env.example..."
      cp .env.example .env
      echo "⚠️  Please edit .env and set RELAYER_PRIVATE_KEY, then run again"
      exit 1
    fi
    
    docker compose -f docker-compose.production.yaml up -d
    echo "✅ Services started"
    docker compose -f docker-compose.production.yaml ps
    ;;
    
  stop)
    echo "🛑 Stopping services..."
    cd repo/platform/deploy
    docker compose -f docker-compose.production.yaml down
    echo "✅ Services stopped"
    ;;
    
  restart)
    echo "🔄 Restarting services..."
    $0 stop
    $0 start
    ;;
    
  logs)
    cd repo/platform/deploy
    docker compose -f docker-compose.production.yaml logs -f ${2:-}
    ;;
    
  status)
    cd repo/platform/deploy
    docker compose -f docker-compose.production.yaml ps
    ;;
    
  update)
    echo "📦 Full update: pull + restart..."
    $0 pull
    $0 restart
    ;;
    
  *)
    echo "Iranians.Vote Deployment"
    echo ""
    echo "Usage: $0 {pull|start|stop|restart|logs|status|update}"
    echo ""
    echo "Commands:"
    echo "  pull     - Pull latest code from GitHub"
    echo "  start    - Start all services"
    echo "  stop     - Stop all services"
    echo "  restart  - Restart all services"
    echo "  logs     - Show logs (optionally: logs <service>)"
    echo "  status   - Show service status"
    echo "  update   - Pull + restart (full deployment)"
    exit 1
    ;;
esac
