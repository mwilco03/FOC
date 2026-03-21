#!/bin/bash
# =============================================================================
# deploy-cloud.sh — Deploy nmap training lab on a cloud VM
#
# Wraps deploy-linux.sh with cloud-specific pre-flight: installs Docker if
# missing, prints firewall reminders for the detected cloud provider.
#
# Idempotent: safe to run multiple times. Use --clean for a fresh start.
#
# Usage:
#   ./deploy-cloud.sh              # Auto-detect, install Docker, deploy
#   ./deploy-cloud.sh --clean      # Tear down first, then deploy fresh
# =============================================================================
set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

# Required TCP ports (must match docker-compose.yml)
readonly -a REQUIRED_PORTS=(80 4201 4202 4203 4204 4205 4206 4207 4208 4209 4210 8000 8080 8888)

# Firewall port spec (compact form for cloud CLI examples)
readonly FIREWALL_PORT_SPEC="80,4201-4210,8000,8080,8888"

# Cloud provider metadata endpoints
readonly -A CLOUD_METADATA_URLS=(
    [aws]="http://169.254.169.254/latest/meta-data/instance-id"
    [gcp]="http://metadata.google.internal/computeMetadata/v1/instance/id"
    [azure]="http://169.254.169.254/metadata/instance?api-version=2021-02-01"
)

# Cloud-specific firewall commands
readonly -A CLOUD_FIREWALL_HINTS=(
    [aws]="aws ec2 authorize-security-group-ingress --group-id <sg-id> --protocol tcp --port ${FIREWALL_PORT_SPEC} --cidr <classroom-cidr>"
    [gcp]="gcloud compute firewall-rules create nmap-lab --allow tcp:${FIREWALL_PORT_SPEC} --source-ranges <classroom-cidr>"
    [azure]="az network nsg rule create -g <rg> --nsg-name <nsg> -n nmap-lab --priority 100 --access Allow --protocol Tcp --destination-port-ranges ${FIREWALL_PORT_SPEC}"
    [unknown]="Open TCP ports ${FIREWALL_PORT_SPEC} in your cloud provider's firewall/security group."
)

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
# Detect cloud provider
# Complexity: O(n) where n = number of known providers (3)
# =============================================================================
detect_cloud() {
    for provider in aws gcp azure; do
        local url="${CLOUD_METADATA_URLS[$provider]}"
        local extra_header=""
        [[ "$provider" == "gcp" ]] && extra_header="-H Metadata-Flavor:Google"
        [[ "$provider" == "azure" ]] && extra_header="-H Metadata:true"
        if curl -sf --connect-timeout 2 --max-time 3 $extra_header "$url" &>/dev/null; then
            echo "$provider"
            return
        fi
    done
    echo "unknown"
}

# =============================================================================
# Install Docker if not present
# =============================================================================
install_docker_if_missing() {
    if command -v docker &>/dev/null && docker info &>/dev/null; then
        log "Docker is already installed and running"
        return
    fi

    if command -v docker &>/dev/null; then
        warn "Docker is installed but not running. Starting..."
        sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
        sleep 3
        docker info &>/dev/null && return
    fi

    log "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo systemctl enable docker 2>/dev/null || true
    sudo systemctl start docker 2>/dev/null || true

    # Add current user to docker group if not root
    if [[ "$(id -u)" -ne 0 ]]; then
        sudo usermod -aG docker "$USER"
        warn "Added $USER to docker group. You may need to log out and back in."
        warn "For now, running with sudo..."
    fi

    docker info &>/dev/null || die "Docker installation failed"
    log "Docker installed and running"
}

# =============================================================================
# Main
# =============================================================================
cd "$SCRIPT_DIR"

log "Detecting cloud provider..."
CLOUD_PROVIDER=$(detect_cloud)
if [[ "$CLOUD_PROVIDER" != "unknown" ]]; then
    log "Detected: ${CLOUD_PROVIDER^^}"
else
    log "No cloud provider detected (bare metal or unrecognized cloud)"
fi

# Print firewall reminder
echo ""
warn "FIREWALL REMINDER: Ensure these TCP ports are open to your classroom:"
echo "  ${FIREWALL_PORT_SPEC}"
echo ""
if [[ -n "${CLOUD_FIREWALL_HINTS[$CLOUD_PROVIDER]:-}" ]]; then
    echo "  Example command:"
    echo "  ${CLOUD_FIREWALL_HINTS[$CLOUD_PROVIDER]}"
    echo ""
fi

# Install Docker if needed
install_docker_if_missing

# Delegate to deploy-linux.sh (which handles build, deploy, seed, verify)
log "Handing off to deploy-linux.sh..."
exec bash "${SCRIPT_DIR}/deploy-linux.sh" "$@"
