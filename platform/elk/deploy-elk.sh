#!/usr/bin/env bash
# deploy-elk.sh — Two-phase ELK stack deployment
# Phase 1: pull   — Download all container images
# Phase 2: up     — Deploy the stack
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
export COMPOSE_FILE

ELK_VERSION="${ELK_VERSION:-8.13.4}"
export ELK_VERSION

# Images used by the stack
IMAGES=(
  "docker.elastic.co/elasticsearch/elasticsearch:${ELK_VERSION}"
  "docker.elastic.co/logstash/logstash:${ELK_VERSION}"
  "docker.elastic.co/kibana/kibana:${ELK_VERSION}"
)

# ---------- colours ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------- preflight ----------
preflight() {
    local ok=true
    for cmd in docker docker-compose; do
        if ! command -v "$cmd" &>/dev/null; then
            # try "docker compose" (v2 plugin) as fallback
            if [[ "$cmd" == "docker-compose" ]] && docker compose version &>/dev/null; then
                COMPOSE_CMD="docker compose"
                continue
            fi
            error "$cmd is not installed"; ok=false
        fi
    done
    [[ -z "${COMPOSE_CMD:-}" ]] && COMPOSE_CMD="docker-compose"
    $ok || { error "Missing prerequisites — aborting."; exit 1; }

    # Ensure vm.max_map_count for Elasticsearch
    local mmc
    mmc=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
    if (( mmc < 262144 )); then
        warn "vm.max_map_count=$mmc (need >=262144)"
        warn "Run:  sudo sysctl -w vm.max_map_count=262144"
    fi
}

# ---------- phase 1: pull ----------
phase_pull() {
    info "=== Phase 1: Downloading images (ELK ${ELK_VERSION}) ==="
    $COMPOSE_CMD -f "$COMPOSE_FILE" pull
    info "All images downloaded."
}

# ---------- save: export images to a directory (e.g. thumb drive) ----------
phase_save() {
    local dest="${1:?Usage: deploy-elk.sh save /mnt/usb}"
    dest="${dest%/}"  # strip trailing slash

    if [[ ! -d "$dest" ]]; then
        error "Directory does not exist: $dest"
        exit 1
    fi

    local img_dir="${dest}/elk-images-${ELK_VERSION}"
    mkdir -p "$img_dir"

    info "=== Saving images to ${img_dir} ==="
    for img in "${IMAGES[@]}"; do
        local filename
        # elasticsearch:8.13.4 -> elasticsearch_8.13.4.tar
        filename="$(echo "$img" | sed 's|.*/||; s/:/_/g').tar"
        info "Saving ${img} -> ${filename}"
        docker save "$img" -o "${img_dir}/${filename}"
    done

    # Copy the deployment files alongside the images
    info "Copying deployment configs..."
    cp -r "$SCRIPT_DIR"/docker-compose.yml "$img_dir/"
    cp -r "$SCRIPT_DIR"/elasticsearch      "$img_dir/"
    cp -r "$SCRIPT_DIR"/kibana             "$img_dir/"
    cp -r "$SCRIPT_DIR"/logstash           "$img_dir/"
    cp    "$SCRIPT_DIR"/deploy-elk.sh         "$img_dir/"
    cp -f "$SCRIPT_DIR"/deploy-vmware.sh     "$img_dir/" 2>/dev/null || true
    cp -f "$SCRIPT_DIR"/vmware-env.example   "$img_dir/" 2>/dev/null || true
    chmod +x "$img_dir"/deploy-*.sh

    local total
    total=$(du -sh "$img_dir" | cut -f1)
    info "Done. Total size: ${total}"
    info "Contents of ${img_dir}:"
    ls -lh "$img_dir"
    echo ""
    info "To deploy on the air-gapped host:"
    info "  cd ${img_dir}"
    info "  ./deploy-elk.sh load ."
    info "  ./deploy-elk.sh up"
}

# ---------- load: import images from a directory ----------
phase_load() {
    local src="${1:?Usage: deploy-elk.sh load /mnt/usb/elk-images-8.13.4}"
    src="${src%/}"

    if [[ ! -d "$src" ]]; then
        error "Directory does not exist: $src"
        exit 1
    fi

    info "=== Loading images from ${src} ==="
    local count=0
    for tarball in "$src"/*.tar; do
        [[ -f "$tarball" ]] || continue
        info "Loading $(basename "$tarball")..."
        docker load -i "$tarball"
        count=$((count + 1))
    done

    if (( count == 0 )); then
        error "No .tar files found in $src"
        exit 1
    fi
    info "Loaded ${count} image(s). Ready to deploy."
}

# ---------- phase 2: deploy ----------
phase_up() {
    info "=== Phase 2: Deploying ELK stack ==="
    $COMPOSE_CMD -f "$COMPOSE_FILE" up -d
    info "Waiting for Elasticsearch to become ready..."
    local retries=30
    until curl -s -o /dev/null -w '%{http_code}' http://localhost:9200 | grep -q 200; do
        retries=$((retries - 1))
        if (( retries == 0 )); then
            error "Elasticsearch did not become ready in time."
            exit 1
        fi
        sleep 2
    done
    info "Elasticsearch is ready."
    info "Kibana:         http://localhost:5601"
    info "Elasticsearch:  http://localhost:9200"
    echo ""
    info "Logstash input ports:"
    info "  TCP/514  — Syslog"
    info "  UDP/514  — Syslog"
    info "  TCP/5044 — Beats (Sysmon, EVTX, generic)"
    info "  TCP/5045 — Zeek (JSON)"
    info "  TCP/5046 — Suricata (JSON)"
    info "  TCP/5047 — McAfee (JSON)"
    info "  TCP/5048 — Proxy logs"
    info "  TCP/5049 — WSUS logs"
    info "  TCP/5050 — Tenable (JSON)"
}

# ---------- teardown ----------
phase_down() {
    info "Stopping ELK stack..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" down
    info "Stack stopped."
}

phase_destroy() {
    warn "Stopping stack and removing volumes..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" down -v
    info "Stack and volumes removed."
}

# ---------- status ----------
phase_status() {
    $COMPOSE_CMD -f "$COMPOSE_FILE" ps
}

# ---------- main ----------
usage() {
    cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  pull              Download all container images  (Phase 1)
  save <path>       Save images + configs to a directory (e.g. thumb drive)
  load <path>       Load images from a directory into Docker
  up                Deploy the ELK stack           (Phase 2)
  deploy            Run pull + up sequentially
  down              Stop the stack
  destroy           Stop the stack and delete volumes
  status            Show container status

Air-gapped workflow:
  1. On internet-connected host:
       ./deploy-elk.sh pull
       ./deploy-elk.sh save /mnt/usb
  2. Move thumb drive to target host
  3. On air-gapped host:
       ./deploy-elk.sh load /mnt/usb/elk-images-${ELK_VERSION}
       ./deploy-elk.sh up
EOF
}

preflight

case "${1:-}" in
    pull)    phase_pull ;;
    save)    phase_save "${2:-}" ;;
    load)    phase_load "${2:-}" ;;
    up)      phase_up ;;
    deploy)  phase_pull; phase_up ;;
    down)    phase_down ;;
    destroy) phase_destroy ;;
    status)  phase_status ;;
    *)       usage; exit 1 ;;
esac
