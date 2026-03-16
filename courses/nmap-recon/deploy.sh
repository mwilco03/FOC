#!/bin/bash
# =============================================================================
# Nmap Training Lab - One-Shot Deploy
# Brings up the entire lab from scratch on any Docker host.
# Usage: ./deploy.sh
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; exit 1; }

cd "$(dirname "$0")"

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
info "Checking Docker..."
docker info > /dev/null 2>&1 || error "Docker is not running. Start Docker Desktop and try again."
docker compose version > /dev/null 2>&1 || error "Docker Compose not found."
info "Docker is ready"

# ---------------------------------------------------------------------------
# Clean slate (optional)
# ---------------------------------------------------------------------------
if [ "${1:-}" = "--clean" ]; then
    warn "Clean deploy requested - tearing down existing lab..."
    docker compose down -v 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Build and start everything
# ---------------------------------------------------------------------------
info "Building and starting all containers (this may take a few minutes on first run)..."
docker compose up -d --build 2>&1 | while IFS= read -r line; do
    case "$line" in
        *Started*|*Running*|*Healthy*|*Built*) echo -e "  ${GREEN}${line}${NC}" ;;
        *Error*|*error*|*failed*) echo -e "  ${RED}${line}${NC}" ;;
        *) ;;
    esac
done

# ---------------------------------------------------------------------------
# Wait for CTFd
# ---------------------------------------------------------------------------
info "Waiting for CTFd to be ready..."
for i in $(seq 1 60); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null || echo "000")
    if echo "$STATUS" | grep -qE "200|302"; then
        info "CTFd is up!"
        break
    fi
    if [ "$i" = "60" ]; then
        error "CTFd failed to start after 120 seconds"
    fi
    sleep 2
done

# ---------------------------------------------------------------------------
# Run CTFd setup (creates admin, teams, challenges, theme)
# ---------------------------------------------------------------------------
info "Configuring CTFd (admin, teams, challenges, theme)..."
bash ctfd/setup.sh http://localhost:8000

# ---------------------------------------------------------------------------
# Final status
# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
docker compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null
echo ""

# Detect host IP
HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || \
    ip route get 1 2>/dev/null | awk '{print $7; exit}' || \
    echo "localhost")

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Lab is ready!${NC}"
echo ""
echo -e "  ${CYAN}Student Terminal:${NC}  http://${HOST_IP}"
echo -e "  ${CYAN}Direct Access:${NC}    http://${HOST_IP}:4201 through :4210"
echo -e "  ${CYAN}CTFd Scoreboard:${NC}  http://${HOST_IP}:8000"
echo -e "  ${CYAN}Traefik Dashboard:${NC} http://${HOST_IP}:8080"
echo ""
echo -e "  Credentials saved to: ctfd/credentials.txt"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
