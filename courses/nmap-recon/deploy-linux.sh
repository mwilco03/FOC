#!/bin/bash
# =============================================================================
# deploy-linux.sh — Deploy nmap training lab on any Linux host with Docker
#
# Idempotent: safe to run multiple times. Existing containers are updated
# in place; use --clean for a fresh start.
#
# Usage:
#   ./deploy-linux.sh            # Build and deploy (or update existing)
#   ./deploy-linux.sh --clean    # Tear down first, then deploy fresh
# =============================================================================
set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

# Docker requirements
readonly DOCKER_MIN_VERSION="24.0"
readonly COMPOSE_MIN_VERSION="2.11"

# Service ports (must match docker-compose.yml)
readonly PORT_TRAEFIK_WEB=80
readonly PORT_TRAEFIK_DASHBOARD=8080
readonly PORT_CTFD=8000
readonly PORT_LAB_CONTROLLER=8888
readonly PORT_STUDENT_DIRECT_BASE=4201
readonly PORT_STUDENT_DIRECT_END=4210

# Target network (must match docker-compose.yml target_net)
readonly TARGET_WEBSERVER_IP="172.20.1.10"

# Expected container count from docker-compose.yml
readonly EXPECTED_CONTAINERS=28
readonly MIN_HEALTHY_CONTAINERS=25

# Retry/timeout tuning
readonly CTFD_WAIT_ATTEMPTS=60
readonly CTFD_WAIT_INTERVAL=2
readonly SERVICE_STABILIZE_SECS=10
readonly VERIFY_RETRY_ATTEMPTS=5
readonly VERIFY_RETRY_INTERVAL=3

# Derived
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# =============================================================================
# Output helpers
# =============================================================================
declare -A COLORS=( [red]='\033[0;31m' [grn]='\033[0;32m' [yel]='\033[1;33m' [cyn]='\033[0;36m' [rst]='\033[0m' )

log()  { echo -e "${COLORS[grn]}[+]${COLORS[rst]} $*"; }
warn() { echo -e "${COLORS[yel]}[!]${COLORS[rst]} $*"; }
err()  { echo -e "${COLORS[red]}[-]${COLORS[rst]} $*" >&2; }
die()  { err "$@"; exit 1; }

# =============================================================================
# Utility: retry a command up to N times with interval
# Complexity: O(attempts) — linear retry with early exit on success
# =============================================================================
retry() {
    local max_attempts=$1 interval=$2; shift 2
    for attempt in $(seq 1 "$max_attempts"); do
        if "$@" &>/dev/null; then return 0; fi
        sleep "$interval"
    done
    return 1
}

# =============================================================================
# Utility: verify an HTTP endpoint
# =============================================================================
verify_http() {
    local label=$1 url=$2
    if retry "$VERIFY_RETRY_ATTEMPTS" "$VERIFY_RETRY_INTERVAL" curl -sf "$url"; then
        log "${label}: OK"
    else
        err "${label}: FAIL"
        FAILURES=$((FAILURES + 1))
    fi
}

# =============================================================================
# Pre-flight: check Docker installation
# =============================================================================
cd "$SCRIPT_DIR"

command -v docker >/dev/null 2>&1 \
    || die "Docker not found. Install: curl -fsSL https://get.docker.com | sh"

docker info &>/dev/null \
    || die "Docker daemon is not running. Start it: sudo systemctl start docker"

docker compose version &>/dev/null \
    || die "Docker Compose plugin not found. Update Docker to ${DOCKER_MIN_VERSION}+"

log "Docker is ready"

# =============================================================================
# Handle --clean flag (idempotent teardown)
# =============================================================================
if [[ "${1:-}" == "--clean" ]]; then
    warn "Clean deploy — tearing down existing lab..."
    docker compose down -v 2>/dev/null || true
fi

# =============================================================================
# Create .env if missing
# =============================================================================
if [[ ! -f .env ]]; then
    log "Creating .env from .env.example..."
    cp .env.example .env
fi

# =============================================================================
# Build and start
# =============================================================================
log "Building and starting all containers..."
docker compose up -d --build 2>&1 | grep -E "Built|Created|Started|Pulled" || true

# =============================================================================
# Wait for CTFd
# =============================================================================
log "Waiting for CTFd..."
retry "$CTFD_WAIT_ATTEMPTS" "$CTFD_WAIT_INTERVAL" \
    curl -sf "http://localhost:${PORT_CTFD}" \
    || die "CTFd did not come online after $((CTFD_WAIT_ATTEMPTS * CTFD_WAIT_INTERVAL))s"
log "CTFd is up"

# =============================================================================
# Seed CTFd challenges (idempotent — setup.sh handles existing state)
# =============================================================================
log "Seeding CTFd challenges and user accounts..."
bash ctfd/setup.sh "http://localhost:${PORT_CTFD}" \
    || warn "CTFd setup had issues — check manually"

# =============================================================================
# Verify deployment
# Complexity: O(n) where n = number of service checks (constant set)
# =============================================================================
log "Waiting for services to stabilize..."
sleep "$SERVICE_STABILIZE_SECS"

log "Verifying deployment..."
FAILURES=0

# Detect host IP
HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}' \
    || ip route get 1 2>/dev/null | awk '{print $7; exit}' \
    || echo "localhost")

# Declarative HTTP checks
# Note: direct student ports (4201-4210) are optional — port 80 with sticky
# sessions is the primary student access path.
declare -A SERVICE_CHECKS=(
    ["Student terminals (port ${PORT_TRAEFIK_WEB})"]="http://localhost:${PORT_TRAEFIK_WEB}"
    ["CTFd scoreboard (port ${PORT_CTFD})"]="http://localhost:${PORT_CTFD}"
    ["Lab controller (port ${PORT_LAB_CONTROLLER})"]="http://localhost:${PORT_LAB_CONTROLLER}"
)

for label in "${!SERVICE_CHECKS[@]}"; do
    verify_http "$label" "${SERVICE_CHECKS[$label]}"
done

# Functional check: nmap scanning
if docker exec nmap-lab-student-1-1 nmap -sn "$TARGET_WEBSERVER_IP" 2>&1 | grep -q "Host is up"; then
    log "Nmap scanning from student terminal: OK"
else
    err "Nmap scanning from student terminal: FAIL"
    FAILURES=$((FAILURES + 1))
fi

# Container count
RUNNING=$(docker compose ps -q 2>/dev/null | wc -l)
if [[ "$RUNNING" -ge "$MIN_HEALTHY_CONTAINERS" ]]; then
    log "Running containers: ${RUNNING}/${EXPECTED_CONTAINERS}"
else
    err "Only ${RUNNING}/${EXPECTED_CONTAINERS} containers running"
    FAILURES=$((FAILURES + 1))
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "================================================================="
if [[ "$FAILURES" -eq 0 ]]; then
    echo -e "${COLORS[grn]}  DEPLOYMENT SUCCESSFUL — all checks passed${COLORS[rst]}"
else
    echo -e "${COLORS[yel]}  DEPLOYMENT COMPLETE — ${FAILURES} check(s) failed${COLORS[rst]}"
fi
cat <<EOF

  Student Terminal:   http://${HOST_IP}:${PORT_TRAEFIK_WEB}
  Direct Terminals:   http://${HOST_IP}:${PORT_STUDENT_DIRECT_BASE} - ${PORT_STUDENT_DIRECT_END}
  CTFd Scoreboard:    http://${HOST_IP}:${PORT_CTFD}
  Lab Controller:     http://${HOST_IP}:${PORT_LAB_CONTROLLER}
  Traefik Dashboard:  http://${HOST_IP}:${PORT_TRAEFIK_DASHBOARD}

  Credentials:        see .env and ctfd/credentials.txt
  Teardown:           docker compose down -v

=================================================================
EOF
