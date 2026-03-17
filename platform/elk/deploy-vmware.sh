#!/usr/bin/env bash
# deploy-vmware.sh — Deploy ELK stack as a VM on VMware ESXi / vSphere
#
# Workflow:
#   1. On internet-connected host:
#        ./deploy-elk.sh pull
#        ./deploy-elk.sh save /mnt/usb
#        # also place a base Linux OVA on the thumb drive
#
#   2. On VMware host (or jump box with govc):
#        ./deploy-vmware.sh create        # create VM from OVA
#        ./deploy-vmware.sh bootstrap     # install Docker + load images + deploy ELK
#
#   Or all-in-one:
#        ./deploy-vmware.sh deploy
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- colours ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------- load environment ----------
load_env() {
    local env_file="${SCRIPT_DIR}/vmware-env.sh"
    if [[ ! -f "$env_file" ]]; then
        error "vmware-env.sh not found."
        error "Copy vmware-env.example to vmware-env.sh and fill in your values."
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$env_file"
}

# ---------- preflight ----------
preflight_vmware() {
    local ok=true
    for cmd in govc ssh scp; do
        if ! command -v "$cmd" &>/dev/null; then
            error "$cmd is not installed"
            ok=false
        fi
    done
    $ok || exit 1

    # Verify govc can connect
    if ! govc about &>/dev/null; then
        error "Cannot connect to vSphere. Check GOVC_URL / credentials in vmware-env.sh"
        exit 1
    fi
    info "Connected to $(govc about | head -1)"
}

# ---------- SSH helpers ----------
vm_ssh() {
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        -i "$VM_SSH_KEY" "${VM_SSH_USER}@${VM_IP}" "$@"
}

vm_scp() {
    scp -o StrictHostKeyChecking=no -i "$VM_SSH_KEY" "$@"
}

wait_for_ssh() {
    info "Waiting for SSH on ${VM_IP}..."
    local retries=60
    while ! vm_ssh "true" &>/dev/null; do
        retries=$((retries - 1))
        if (( retries == 0 )); then
            error "SSH not available after 5 minutes."
            exit 1
        fi
        sleep 5
    done
    info "SSH is ready."
}

# =====================================================================
# Phase 1: Create VM
# =====================================================================
phase_create() {
    info "=== Creating VM: ${VM_NAME} ==="

    # Check if VM already exists
    if govc vm.info "$VM_NAME" &>/dev/null; then
        warn "VM '${VM_NAME}' already exists."
        read -rp "Destroy and recreate? [y/N] " yn
        if [[ "$yn" =~ ^[Yy] ]]; then
            info "Powering off and destroying existing VM..."
            govc vm.power -off -force "$VM_NAME" 2>/dev/null || true
            govc vm.destroy "$VM_NAME"
        else
            info "Skipping create — using existing VM."
            return 0
        fi
    fi

    if [[ -n "${OVA_PATH:-}" && -f "${OVA_PATH:-}" ]]; then
        info "Deploying from OVA: ${OVA_PATH}"
        deploy_from_ova
    else
        info "No OVA found — creating empty VM (requires manual OS install)"
        create_empty_vm
    fi

    info "VM '${VM_NAME}' created."
}

deploy_from_ova() {
    local spec_file
    spec_file=$(mktemp /tmp/elk-ova-spec.XXXXXX.json)

    # Generate OVF spec and customize
    govc import.spec "$OVA_PATH" > "$spec_file" 2>/dev/null || true

    # Build property overrides for cloud-init OVA (Ubuntu cloud images)
    cat > "$spec_file" <<SPEC
{
  "DiskProvisioning": "thin",
  "IPAllocationPolicy": "fixedPolicy",
  "IPProtocol": "IPv4",
  "NetworkMapping": [
    { "Name": "VM Network", "Network": "${GOVC_NETWORK}" }
  ],
  "PowerOn": false,
  "WaitForIP": false,
  "Name": "${VM_NAME}"
}
SPEC

    govc import.ova \
        -options="$spec_file" \
        -name="$VM_NAME" \
        -folder="${GOVC_FOLDER:-}" \
        "$OVA_PATH"

    rm -f "$spec_file"

    # Resize CPU / memory / disk
    govc vm.change -vm "$VM_NAME" \
        -c="${VM_CPUS}" \
        -m="${VM_MEMORY_MB}"

    if [[ -n "${VM_DISK_GB:-}" ]]; then
        govc vm.disk.change -vm "$VM_NAME" -size="${VM_DISK_GB}G" 2>/dev/null || \
            warn "Could not resize disk — may need manual expansion."
    fi

    # Attach cloud-init ISO if we have network config
    if [[ -n "${VM_IP:-}" ]]; then
        create_cloud_init_iso
    fi

    # Power on
    govc vm.power -on "$VM_NAME"
    info "VM powered on. Waiting for IP..."
    govc vm.ip -wait=5m "$VM_NAME" || warn "Timed out waiting for IP."
}

create_empty_vm() {
    govc vm.create \
        -m="${VM_MEMORY_MB}" \
        -c="${VM_CPUS}" \
        -g="${VM_GUEST_ID}" \
        -disk="${VM_DISK_GB}GB" \
        -disk.controller=pvscsi \
        -net="${GOVC_NETWORK}" \
        -net.adapter=vmxnet3 \
        -on=false \
        "$VM_NAME"

    info "Empty VM created. Attach an ISO and install the OS, then run:"
    info "  ./deploy-vmware.sh bootstrap"
}

create_cloud_init_iso() {
    if ! command -v genisoimage &>/dev/null && ! command -v mkisofs &>/dev/null; then
        warn "genisoimage/mkisofs not found — skipping cloud-init ISO."
        warn "You will need to configure networking manually."
        return 0
    fi

    local iso_cmd="genisoimage"
    command -v genisoimage &>/dev/null || iso_cmd="mkisofs"

    local tmpdir
    tmpdir=$(mktemp -d /tmp/elk-cloud-init.XXXXXX)

    cat > "$tmpdir/meta-data" <<META
instance-id: ${VM_NAME}
local-hostname: ${VM_HOSTNAME:-foc-elk}
META

    cat > "$tmpdir/user-data" <<USERDATA
#cloud-config
hostname: ${VM_HOSTNAME:-foc-elk}
manage_etc_hosts: true
users:
  - name: ${VM_SSH_USER}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat "${VM_SSH_KEY}.pub" 2>/dev/null || echo "# no public key found")
packages:
  - docker.io
  - docker-compose
runcmd:
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker ${VM_SSH_USER}
  - sysctl -w vm.max_map_count=262144
  - echo "vm.max_map_count=262144" >> /etc/sysctl.conf
USERDATA

    cat > "$tmpdir/network-config" <<NETCFG
version: 2
ethernets:
  ens192:
    addresses:
      - ${VM_IP}/${VM_NETMASK:-24}
    gateway4: ${VM_GATEWAY}
    nameservers:
      addresses:
        - ${VM_DNS}
NETCFG

    local iso_path="/tmp/${VM_NAME}-cloud-init.iso"
    $iso_cmd -output "$iso_path" -volid cidata -joliet -rock \
        "$tmpdir/meta-data" "$tmpdir/user-data" "$tmpdir/network-config" 2>/dev/null

    # Upload ISO to datastore and attach
    govc datastore.upload "$iso_path" "${VM_NAME}/cloud-init.iso"
    govc device.cdrom.add -vm "$VM_NAME"
    govc device.cdrom.insert -vm "$VM_NAME" \
        -device cdrom-3000 \
        "${VM_NAME}/cloud-init.iso" 2>/dev/null || \
        warn "Could not attach cloud-init ISO automatically."

    rm -rf "$tmpdir" "$iso_path"
    info "Cloud-init ISO attached."
}

# =====================================================================
# Phase 2: Bootstrap Docker + ELK on the VM
# =====================================================================
phase_bootstrap() {
    info "=== Bootstrapping ELK on ${VM_NAME} (${VM_IP}) ==="

    wait_for_ssh

    # Install Docker if not present
    info "Ensuring Docker is installed..."
    vm_ssh <<'INSTALL_DOCKER'
if ! command -v docker &>/dev/null; then
    echo "[INFO] Installing Docker..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker.io docker-compose >/dev/null 2>&1
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker "$USER"
    echo "[INFO] Docker installed."
else
    echo "[INFO] Docker already installed."
fi
sudo sysctl -w vm.max_map_count=262144 2>/dev/null
grep -q "vm.max_map_count" /etc/sysctl.conf || \
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf >/dev/null
INSTALL_DOCKER

    # Determine where the ELK bundle lives
    local elk_bundle=""
    local elk_version="${ELK_VERSION:-8.13.4}"

    # Check common thumb drive mount points for the saved bundle
    for candidate in \
        "${SCRIPT_DIR}" \
        "/mnt/usb/elk-images-${elk_version}" \
        "/media/usb/elk-images-${elk_version}" \
        "/media/${USER}/*/elk-images-${elk_version}"; do
        # shellcheck disable=SC2086
        if ls $candidate/elasticsearch_*.tar &>/dev/null 2>&1; then
            elk_bundle="$candidate"
            break
        fi
    done

    if [[ -z "$elk_bundle" ]]; then
        # No pre-saved images — check if we have internet to pull
        warn "No saved image bundle found."
        warn "Will attempt 'docker pull' on the VM (requires internet)."
        vm_ssh "sudo docker compose version" &>/dev/null || \
            vm_ssh "sudo apt-get install -y -qq docker-compose >/dev/null 2>&1"

        # Copy just the configs
        info "Copying ELK configs to VM..."
        vm_ssh "mkdir -p ~/elk"
        vm_scp -r \
            "$SCRIPT_DIR/docker-compose.yml" \
            "$SCRIPT_DIR/deploy-elk.sh" \
            "$SCRIPT_DIR/elasticsearch" \
            "$SCRIPT_DIR/logstash" \
            "$SCRIPT_DIR/kibana" \
            "${VM_SSH_USER}@${VM_IP}:~/elk/"

        info "Pulling images on VM (this may take a while)..."
        vm_ssh "cd ~/elk && chmod +x deploy-elk.sh && ./deploy-elk.sh pull"
    else
        info "Found image bundle at: ${elk_bundle}"
        info "Copying images + configs to VM..."
        vm_ssh "mkdir -p ~/elk"

        # Copy tar images
        for tarball in "$elk_bundle"/*.tar; do
            [[ -f "$tarball" ]] || continue
            info "  Copying $(basename "$tarball")..."
            vm_scp "$tarball" "${VM_SSH_USER}@${VM_IP}:~/elk/"
        done

        # Copy configs
        for item in docker-compose.yml deploy-elk.sh elasticsearch logstash kibana; do
            if [[ -e "$elk_bundle/$item" ]]; then
                vm_scp -r "$elk_bundle/$item" "${VM_SSH_USER}@${VM_IP}:~/elk/"
            elif [[ -e "$SCRIPT_DIR/$item" ]]; then
                vm_scp -r "$SCRIPT_DIR/$item" "${VM_SSH_USER}@${VM_IP}:~/elk/"
            fi
        done

        info "Loading Docker images on VM..."
        vm_ssh "cd ~/elk && chmod +x deploy-elk.sh && ./deploy-elk.sh load ~/elk"
    fi

    # Deploy the stack
    info "Starting ELK stack on VM..."
    vm_ssh "cd ~/elk && ./deploy-elk.sh up"

    echo ""
    info "=== Deployment complete ==="
    info "VM:             ${VM_NAME} (${VM_IP})"
    info "Kibana:         http://${VM_IP}:5601"
    info "Elasticsearch:  http://${VM_IP}:9200"
    info ""
    info "Logstash inputs on ${VM_IP}:"
    info "  TCP/UDP 514  — Syslog"
    info "  TCP 5044     — Beats (Sysmon, EVTX)"
    info "  TCP 5045     — Zeek"
    info "  TCP 5046     — Suricata"
    info "  TCP 5047     — McAfee"
    info "  TCP 5048     — Proxy"
    info "  TCP 5049     — WSUS"
    info "  TCP 5050     — Tenable"
}

# =====================================================================
# Convenience: power on / off / status
# =====================================================================
phase_power_on() {
    govc vm.power -on "$VM_NAME"
    info "VM '${VM_NAME}' powered on."
}

phase_power_off() {
    govc vm.power -s "$VM_NAME" 2>/dev/null || govc vm.power -off "$VM_NAME"
    info "VM '${VM_NAME}' powered off."
}

phase_vm_status() {
    govc vm.info "$VM_NAME"
}

phase_destroy_vm() {
    warn "This will destroy VM '${VM_NAME}' and all its data."
    read -rp "Are you sure? [y/N] " yn
    if [[ "$yn" =~ ^[Yy] ]]; then
        govc vm.power -off -force "$VM_NAME" 2>/dev/null || true
        govc vm.destroy "$VM_NAME"
        info "VM destroyed."
    fi
}

phase_ssh() {
    info "SSH into ${VM_NAME}..."
    vm_ssh
}

# =====================================================================
# Main
# =====================================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") <command>

VM Lifecycle:
  create          Create VM from OVA (or empty VM)
  bootstrap       Install Docker, load images, deploy ELK on the VM
  deploy          create + bootstrap (all-in-one)

VM Power:
  power-on        Power on the VM
  power-off       Graceful shutdown
  ssh             SSH into the VM
  vm-status       Show VM info from vSphere
  destroy-vm      Power off and delete the VM

Prerequisites:
  - govc installed (https://github.com/vmware/govmomi/releases)
  - vmware-env.sh configured (copy vmware-env.example)

Air-gapped workflow:
  1. Internet host:   ./deploy-elk.sh pull && ./deploy-elk.sh save /mnt/usb
  2. Also place a base Linux OVA on the USB drive
  3. VMware host:     ./deploy-vmware.sh deploy
EOF
}

load_env

case "${1:-}" in
    create)      preflight_vmware; phase_create ;;
    bootstrap)   phase_bootstrap ;;
    deploy)      preflight_vmware; phase_create; phase_bootstrap ;;
    power-on)    preflight_vmware; phase_power_on ;;
    power-off)   preflight_vmware; phase_power_off ;;
    ssh)         phase_ssh ;;
    vm-status)   preflight_vmware; phase_vm_status ;;
    destroy-vm)  preflight_vmware; phase_destroy_vm ;;
    *)           usage; exit 1 ;;
esac
