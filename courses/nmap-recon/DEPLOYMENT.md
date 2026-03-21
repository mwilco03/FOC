# Nmap Training Lab — Deployment Guide

The nmap training lab is a **Docker Compose application**. It runs on any system with Docker installed. This guide covers all supported deployment paths.

## Prerequisites (All Platforms)

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Docker Engine | 24.0+ | 28.0+ |
| Docker Compose | v2.11+ (plugin) | v2.36+ |
| RAM | 4 GB free | 8 GB free |
| Disk | 10 GB free | 20 GB free |
| CPU cores | 2 | 4+ |
| Ports available | 80, 4201-4210, 8000, 8080, 8888 | — |

**Verify Docker:**

```bash
docker --version          # Must be 24.0+
docker compose version    # Must be v2.11+
```

## Quick Start (Any Docker Host)

```bash
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env         # Review and customize if needed
docker compose build
docker compose up -d
bash ctfd/setup.sh           # Seed challenges and student accounts
```

**Access points (replace `<HOST_IP>` with your machine's IP):**

| Service | URL | Purpose |
|---------|-----|---------|
| Student Terminal | `http://<HOST_IP>:80` | Load-balanced shellinabox (sticky sessions) |
| Direct Terminal N | `http://<HOST_IP>:420N` | Per-student terminal (1-10) |
| CTFd Scoreboard | `http://<HOST_IP>:8000` | Challenge submission and scoring |
| Lab Controller | `http://<HOST_IP>:8888` | Instructor slides, solutions, timer |
| Traefik Dashboard | `http://<HOST_IP>:8080` | Load balancer admin |

**Default credentials (from `.env`):**

| Account | Username | Password |
|---------|----------|----------|
| CTFd Admin | `admin` | `NmapLab2024!` |
| Students | `team1`–`team10` | `scan4flags1`–`scan4flags10` |
| Solution Guide | — | `instructor2024` |

---

## Deployment Path 1: Generic Linux (Primary)

This is the primary and simplest deployment path. Works on Ubuntu, Debian, Fedora, Arch, or any Linux distribution with Docker installed.

### Install Docker (if needed)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

### Deploy

```bash
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

### Verify

```bash
docker compose ps                        # All 28 containers running
curl -s http://localhost:80 | head -5     # Student terminal HTML
curl -s http://localhost:8000 | head -5   # CTFd HTML
```

### Teardown

```bash
docker compose down -v    # Stops containers, removes volumes
```

---

## Deployment Path 2: Proxmox LXC

For Proxmox environments, deploy inside an Alpine LXC container. **Never install Docker on the Proxmox host.**

### Option A: Community Script (Recommended)

Use the [Proxmox VE Helper Scripts](https://community-scripts.github.io/ProxmoxVE/) to create a Docker-ready Alpine LXC:

```bash
# From the Proxmox host shell — creates an Alpine Docker LXC
bash -c "$(curl -fsSL https://community-scripts.github.io/ProxmoxVE/scripts/alpine-docker.sh)"
```

Then SSH or `pct exec` into the container and follow the **Quick Start** above.

### Option B: Automated Script

The included `deploy-proxmox.sh` handles everything: LXC creation, Docker install, build, deploy, seed, and verify.

```bash
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
bash deploy-proxmox.sh          # Creates CT 9002, builds, deploys, verifies
```

**Options:**

```bash
bash deploy-proxmox.sh --clean           # Destroy existing CT and rebuild
VMID=9050 bash deploy-proxmox.sh         # Use a different container ID
CT_CORES=8 CT_MEMORY=16384 bash deploy-proxmox.sh  # More resources
```

All settings are configurable via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `VMID` | `9002` | LXC container ID |
| `CT_HOSTNAME` | `nmap-lab` | Container hostname |
| `CT_CORES` | `4` | CPU cores |
| `CT_MEMORY` | `8192` | RAM in MB |
| `CT_DISK_GB` | `32` | Root disk size in GB |
| `CT_BRIDGE` | `vmbr0` | Network bridge |
| `CT_STORAGE` | `local-lvm` | Storage backend |

### Option C: Manual LXC Setup

```bash
# 1. Create privileged Alpine container with nesting
pct create 9002 local:vztmpl/alpine-3.22-default_20250617_amd64.tar.xz \
    --hostname nmap-lab --cores 4 --memory 8192 \
    --rootfs local-lvm:32 --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --features nesting=1,keyctl=1 --unprivileged 0 --ostype alpine

# 2. Add Docker-in-LXC config
cat >> /etc/pve/lxc/9002.conf <<'EOF'
lxc.apparmor.profile: unconfined
lxc.cap.drop:
lxc.cgroup2.devices.allow: a
lxc.mount.auto: proc:rw sys:rw
EOF

# 3. Start and enter
pct start 9002
pct exec 9002 -- bash

# 4. Inside the container: install Docker, clone, deploy
apk update && apk add docker docker-cli-compose git bash curl
rc-update add docker default && service docker start
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

---

## Deployment Path 3: Docker Desktop (Windows / macOS)

Works on Docker Desktop for Windows (WSL2 backend) and Docker Desktop for Mac.

### Known Limitation: UDP Scanning

Docker Desktop uses a user-space network stack that does not support raw UDP sockets in the same way as native Linux. This means:

- `nmap -sU` (UDP scans) may produce unreliable results or show all ports as `open|filtered`
- SYN scans (`nmap -sS`) work correctly
- Connect scans (`nmap -sT`) work correctly
- The **UDP Hunt** and related Deep Dive challenges may not work as intended

**Workaround:** For full UDP support, deploy on native Linux or in a Linux VM.

### Deploy on Windows (WSL2)

```powershell
# Ensure Docker Desktop is running with WSL2 backend
wsl
```

Then from the WSL2 terminal:

```bash
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

Or use the included PowerShell script:

```powershell
cd foc\courses\nmap-recon
.\deploy.ps1
```

### Deploy on macOS

```bash
# Ensure Docker Desktop is running
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

---

## Deployment Path 4: Cloud VM (AWS / GCP / Azure)

Any Ubuntu or Debian VM with Docker installed. Minimum `t3.large` / `e2-standard-2` / `Standard_D2s_v3`.

### AWS EC2

```bash
# Launch Ubuntu 22.04+ instance (t3.xlarge recommended)
# Security group: allow TCP 80, 4201-4210, 8000, 8080, 8888

# SSH in, then:
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu && newgrp docker
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

### GCP Compute Engine

```bash
# Create VM: e2-standard-4, Ubuntu 22.04, 30GB disk
# Firewall rule: allow tcp:80,4201-4210,8000,8080,8888

gcloud compute ssh <instance>
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

### Azure

```bash
# Create VM: Standard_D4s_v3, Ubuntu 22.04
# NSG: allow TCP 80, 4201-4210, 8000, 8080, 8888

ssh <vm-ip>
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

### Cloud-Specific Notes

- **Firewall/Security Groups:** Open TCP ports 80, 4201-4210, 8000, 8080, 8888. Restrict to your classroom IP range.
- **DNS:** Point a domain at the VM's public IP for easier student access.
- **Cost:** A 4-core/8GB VM runs ~$0.15-0.20/hr. Tear down after class.
- **Persistent storage:** The `ctfd-db-data` Docker volume survives `docker compose down` (without `-v`). Use `-v` flag for clean teardown.

---

## Architecture Overview

```
                    ┌─────────────────────────────────┐
                    │       Docker Compose App         │
                    │                                  │
 :80 ──────► Traefik LB ──► student-1..10 (shellinabox)
 :4201-4210 ─────────────┘        │
                                   ▼
                           target_net (172.20.1.0/24)
                           ├── webserver   (.10)
                           ├── mailserver  (.20)
                           ├── fileserver  (.30)
                           ├── database    (.40)
                           ├── devbox      (.50)
                           ├── hardened    (.60)
                           └── distractors (.100-.106)

 :8000 ────► CTFd ──► MariaDB + Redis
 :8888 ────► Lab Controller (slides, solutions, timer)
```

**28 containers total:**
- 10 student terminals (Debian + nmap + shellinabox)
- 6 target hosts (multi-service, realistic configs)
- 7 distractors (no flags — network noise)
- 5 infrastructure (Traefik, CTFd, MariaDB, Redis, Lab Controller)

---

## Security Model

| Control | Implementation |
|---------|---------------|
| User isolation | Home directories `chmod 700`; users cannot read each other's files |
| Sudo restriction | Sudo limited to `nmap`, `tcpdump`, `traceroute` only |
| No shell escape | `sudo /bin/bash` and `sudo su` are denied; nmap 7.93 has no `--interactive` mode |
| Network isolation | Students on `student_net` + `target_net`; CTFd on separate `ctfd_net` |
| Container isolation | Each student terminal is a separate container |

---

## Configuration

All configuration is in `.env` (copy from `.env.example`):

| Variable | Purpose | Default |
|----------|---------|---------|
| `CTFD_SECRET_KEY` | CTFd session encryption | `nmap-training-...-change-me` |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password | `ctfd_root_pass_2024` |
| `MYSQL_USER` / `MYSQL_PASSWORD` | CTFd database credentials | `ctfd` / `ctfd_db_pass_2024` |
| `SOLUTION_PASSWORD` | Lab controller solution guide | `instructor2024` |
| `CTF_DURATION_MINUTES` | CTF timer length | `120` |
| `CTF_EXTEND_MINUTES` | Extension per instructor action | `60` |
| `TEAM1_PASS`–`TEAM10_PASS` | Student login passwords | `scan4flags1`–`scan4flags10` |

---

## Troubleshooting

### Port Conflicts

```bash
# Find what's using a port
sudo lsof -i :80
sudo lsof -i :8000

# Change exposed ports in docker-compose.yml if needed
```

### Containers Restarting

```bash
docker compose logs <service-name>    # Check logs for crash reason
docker compose restart <service-name> # Restart a specific service
```

### CTFd Setup Fails

```bash
# Re-run setup (idempotent for user creation, additive for challenges)
bash ctfd/setup.sh
```

### Student Can't Scan Targets

```bash
# Verify target network connectivity from inside student container
docker exec nmap-lab-student-1-1 nmap -sn 172.20.1.0/24
```

### Docker Build Fails in LXC

Ensure the LXC container has:
- Nesting enabled (`features: nesting=1`)
- AppArmor unconfined (`lxc.apparmor.profile: unconfined`)
- Full device access (`lxc.cgroup2.devices.allow: a`)

See "Deployment Path 2: Proxmox LXC" above for the full config.

---

## Teardown

```bash
docker compose down -v    # Stop all containers, remove volumes (clean slate)
docker compose down       # Stop containers, keep volumes (preserve CTFd data)
```

For Proxmox LXC:
```bash
pct stop 9002 && pct destroy 9002 --purge
```
