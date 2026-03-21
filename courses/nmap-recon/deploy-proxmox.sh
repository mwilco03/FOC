#!/bin/bash
# =============================================================================
# deploy-proxmox.sh — Deploy nmap training lab in an Alpine LXC container
#
# Re-deployable: run this on ANY Proxmox host to stand up the full lab.
# NEVER installs anything on the Proxmox host itself.
#
# This is ONE deployment path. The core app is Docker Compose.
# See DEPLOYMENT.md for all deployment options.
# =============================================================================
set -euo pipefail

# =============================================================================
# Constants — all tunable via environment variables
# =============================================================================

# LXC container settings
readonly CT_VMID="${VMID:-9002}"
readonly CT_HOSTNAME="${CT_HOSTNAME:-nmap-lab}"
readonly CT_CORES="${CT_CORES:-4}"
readonly CT_MEMORY="${CT_MEMORY:-8192}"
readonly CT_SWAP="${CT_SWAP:-2048}"
readonly CT_DISK_GB="${CT_DISK_GB:-32}"
readonly CT_BRIDGE="${CT_BRIDGE:-vmbr0}"
readonly CT_STORAGE="${CT_STORAGE:-local-lvm}"
readonly CT_TEMPLATE_STORAGE="${CT_TEMPLATE_STORAGE:-local}"
readonly CT_ALPINE_TEMPLATE="${CT_ALPINE_TEMPLATE:-alpine-3.22-default_20250617_amd64.tar.xz}"

# Source repo
readonly REPO_URL="${REPO_URL:-https://github.com/mwilco03/foc.git}"
readonly REPO_COURSE_PATH="courses/nmap-recon"
readonly LAB_DIR="/root/nmap-lab"

# Retry/timeout tuning
readonly NETWORK_WAIT_ATTEMPTS=30
readonly NETWORK_WAIT_INTERVAL=2
readonly CTFD_WAIT_ATTEMPTS=60
readonly CTFD_WAIT_INTERVAL=3
readonly SERVICE_STABILIZE_SECS=10
readonly VERIFY_RETRY_ATTEMPTS=5
readonly VERIFY_RETRY_INTERVAL=3

# Service ports (must match docker-compose.yml)
readonly PORT_TRAEFIK_WEB=80
readonly PORT_TRAEFIK_DASHBOARD=8080
readonly PORT_CTFD=8000
readonly PORT_LAB_CONTROLLER=8888
readonly PORT_STUDENT_DIRECT_BASE=4201

# Target network (must match docker-compose.yml target_net)
readonly TARGET_WEBSERVER_IP="172.20.1.10"

# Expected container count from docker-compose.yml
readonly EXPECTED_CONTAINERS=28
readonly MIN_HEALTHY_CONTAINERS=25

# Alpine packages needed inside the container
readonly ALPINE_PACKAGES="docker docker-compose docker-cli-compose git bash curl"

# Proxmox template cache path
readonly TEMPLATE_CACHE="/var/lib/vz/template/cache"

# Script location (for local file push)
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
# Verify: check an HTTP endpoint and log pass/fail
# Returns 0 on success, increments FAILURES on failure
# =============================================================================
verify_http() {
    local label=$1 port=$2
    if retry "$VERIFY_RETRY_ATTEMPTS" "$VERIFY_RETRY_INTERVAL" \
        curl -sf "http://${CONTAINER_IP}:${port}"; then
        log "${label} (port ${port}): OK"
    else
        err "${label} (port ${port}): FAIL"
        FAILURES=$((FAILURES + 1))
    fi
}

# =============================================================================
# Pre-flight checks
# =============================================================================
command -v pct >/dev/null 2>&1 || die "pct not found — must run on a Proxmox host"
command -v pvesm >/dev/null 2>&1 || die "pvesm not found — must run on a Proxmox host"

# Verify quorum (single-node clusters often need this)
if ! pvecm status 2>/dev/null | grep -q "Quorate:.*Yes"; then
    warn "Cluster not quorate. Attempting to fix (single node)..."
    pvecm expected 1 2>/dev/null || true
    sleep 2
    pvecm status 2>/dev/null | grep -q "Quorate:.*Yes" || die "Cannot establish quorum"
    log "Quorum restored"
fi

# =============================================================================
# Handle --clean flag
# =============================================================================
if [[ "${1:-}" == "--clean" ]]; then
    if pct status "$CT_VMID" &>/dev/null; then
        warn "Destroying existing container ${CT_VMID}..."
        pct stop "$CT_VMID" 2>/dev/null || true
        sleep 2
        pct destroy "$CT_VMID" --purge 2>/dev/null || true
        log "Container ${CT_VMID} destroyed"
    fi
fi

if pct status "$CT_VMID" &>/dev/null; then
    die "Container ${CT_VMID} already exists. Use --clean to rebuild, or set VMID=<id>"
fi

# =============================================================================
# Download Alpine template if needed
# =============================================================================
if [[ ! -f "${TEMPLATE_CACHE}/${CT_ALPINE_TEMPLATE}" ]]; then
    log "Downloading Alpine template..."
    pveam download "$CT_TEMPLATE_STORAGE" "$CT_ALPINE_TEMPLATE" \
        || die "Failed to download template"
fi

# =============================================================================
# Create and configure LXC container
# =============================================================================
log "Creating LXC container ${CT_VMID} (${CT_HOSTNAME})..."
pct create "$CT_VMID" "${CT_TEMPLATE_STORAGE}:vztmpl/${CT_ALPINE_TEMPLATE}" \
    --hostname "$CT_HOSTNAME" \
    --cores "$CT_CORES" \
    --memory "$CT_MEMORY" \
    --swap "$CT_SWAP" \
    --rootfs "${CT_STORAGE}:${CT_DISK_GB}" \
    --net0 "name=eth0,bridge=${CT_BRIDGE},ip=dhcp" \
    --features nesting=1,keyctl=1 \
    --unprivileged 0 \
    --ostype alpine || die "Failed to create container"

# Docker-in-LXC requires unconfined apparmor and full device access
log "Configuring LXC security for Docker-in-LXC..."
cat >> "/etc/pve/lxc/${CT_VMID}.conf" <<'LXC_CONF'
lxc.apparmor.profile: unconfined
lxc.cap.drop:
lxc.cgroup2.devices.allow: a
lxc.mount.auto: proc:rw sys:rw
LXC_CONF

# =============================================================================
# Start container and wait for network
# =============================================================================
log "Starting container..."
pct start "$CT_VMID" || die "Failed to start container"
sleep 3

retry "$NETWORK_WAIT_ATTEMPTS" "$NETWORK_WAIT_INTERVAL" \
    pct exec "$CT_VMID" -- ping -c1 -W2 8.8.8.8 \
    || die "Container has no internet after $((NETWORK_WAIT_ATTEMPTS * NETWORK_WAIT_INTERVAL))s"
log "Container online with network"

# =============================================================================
# Install Docker inside container
# =============================================================================
log "Installing Docker and dependencies..."
pct exec "$CT_VMID" -- sh -c "apk update && apk add ${ALPINE_PACKAGES}" \
    || die "Package install failed"

pct exec "$CT_VMID" -- sh -c \
    "rc-update add docker default && service docker start" 2>&1 \
    | grep -v "write error" || true
sleep 3

pct exec "$CT_VMID" -- docker info &>/dev/null || die "Docker failed to start"
log "Docker is running"

# =============================================================================
# Transfer lab files into container
# =============================================================================
log "Setting up nmap lab files..."
pct exec "$CT_VMID" -- mkdir -p "$LAB_DIR"

if [[ -f "${SCRIPT_DIR}/docker-compose.yml" ]]; then
    log "Pushing local repo files into container..."
    (cd "$SCRIPT_DIR" && tar cf - --exclude='.git' .) \
        | pct exec "$CT_VMID" -- tar xf - -C "$LAB_DIR"
else
    log "Cloning repo..."
    pct exec "$CT_VMID" -- sh -c \
        "git clone ${REPO_URL} /tmp/foc && cp -r /tmp/foc/${REPO_COURSE_PATH}/* ${LAB_DIR}/ && rm -rf /tmp/foc"
fi

# Create .env from example if not present
if ! pct exec "$CT_VMID" -- test -f "${LAB_DIR}/.env"; then
    log "Creating .env from example..."
    pct exec "$CT_VMID" -- cp "${LAB_DIR}/.env.example" "${LAB_DIR}/.env"
fi

# =============================================================================
# Build and deploy
# =============================================================================
log "Building Docker images (this takes a few minutes)..."
pct exec "$CT_VMID" -- sh -c "cd ${LAB_DIR} && docker compose build 2>&1" \
    || die "Docker build failed"

log "Starting all containers..."
pct exec "$CT_VMID" -- sh -c "cd ${LAB_DIR} && docker compose up -d 2>&1" \
    || die "Docker compose up failed"

log "Waiting for CTFd to come online..."
retry "$CTFD_WAIT_ATTEMPTS" "$CTFD_WAIT_INTERVAL" \
    pct exec "$CT_VMID" -- curl -sf "http://localhost:${PORT_CTFD}" \
    || die "CTFd did not come online after $((CTFD_WAIT_ATTEMPTS * CTFD_WAIT_INTERVAL))s"
log "CTFd is up"

# =============================================================================
# Seed CTFd challenges
# =============================================================================
log "Seeding CTFd challenges and user accounts..."
pct exec "$CT_VMID" -- sh -c \
    "cd ${LAB_DIR} && chmod +x ctfd/setup.sh && bash ctfd/setup.sh 2>&1" \
    || warn "CTFd setup had issues — check manually"

# =============================================================================
# Verify deployment
# Complexity: O(n) where n = number of service checks (constant set of 7)
# =============================================================================
log "Waiting for all services to stabilize..."
sleep "$SERVICE_STABILIZE_SECS"

log "Verifying deployment..."
CONTAINER_IP=$(pct exec "$CT_VMID" -- sh -c \
    "ip addr show eth0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" 2>/dev/null)
FAILURES=0

# Declarative service checks: label → port
declare -A SERVICE_CHECKS=(
    ["Student terminals"]="$PORT_TRAEFIK_WEB"
    ["CTFd scoreboard"]="$PORT_CTFD"
    ["Lab controller"]="$PORT_LAB_CONTROLLER"
    ["Direct student-1"]="$PORT_STUDENT_DIRECT_BASE"
)

for label in "${!SERVICE_CHECKS[@]}"; do
    verify_http "$label" "${SERVICE_CHECKS[$label]}"
done

# Functional check: nmap scanning works from student terminal
if pct exec "$CT_VMID" -- docker exec nmap-lab-student-1-1 \
    nmap -sn "$TARGET_WEBSERVER_IP" 2>&1 | grep -q "Host is up"; then
    log "Nmap scanning from student terminal: OK"
else
    err "Nmap scanning from student terminal: FAIL"
    FAILURES=$((FAILURES + 1))
fi

# Security check: sudo restricted (must not get a root shell)
SUDO_OUT=$(pct exec "$CT_VMID" -- docker exec nmap-lab-student-1-1 \
    su -c "sudo -n /bin/bash -c 'echo pwned' 2>&1" team1 || true)
if echo "$SUDO_OUT" | grep -q "pwned"; then
    err "Sudo shell escape: NOT BLOCKED (got root shell!)"
    FAILURES=$((FAILURES + 1))
else
    log "Sudo shell escape blocked: OK"
fi

# Container count check
RUNNING=$(pct exec "$CT_VMID" -- sh -c \
    "cd ${LAB_DIR} && docker compose ps -q 2>/dev/null | wc -l")
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

  Container IP:      ${CONTAINER_IP}
  Student Terminal:   http://${CONTAINER_IP}:${PORT_TRAEFIK_WEB}
  Direct Terminals:   http://${CONTAINER_IP}:${PORT_STUDENT_DIRECT_BASE} - 4210
  CTFd Scoreboard:    http://${CONTAINER_IP}:${PORT_CTFD}
  Lab Controller:     http://${CONTAINER_IP}:${PORT_LAB_CONTROLLER}
  Traefik Dashboard:  http://${CONTAINER_IP}:${PORT_TRAEFIK_DASHBOARD}

  Credentials — see .env and ctfd/credentials.txt
  LXC Container:      pct exec ${CT_VMID} -- bash

=================================================================
EOF
