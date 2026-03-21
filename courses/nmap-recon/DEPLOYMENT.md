# Nmap Training Lab — Deployment Guide

The nmap training lab is a **Docker Compose application**. It runs on any system with Docker. Each deployment path below ends with the same result: 28 containers running, 52 CTF challenges seeded, 10 student terminals ready.

## Prerequisites (All Platforms)

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Docker Engine | 24.0+ | 28.0+ |
| Docker Compose | v2.11+ (plugin) | v2.36+ |
| RAM | 4 GB free | 8 GB free |
| Disk | 10 GB free | 20 GB free |
| CPU cores | 2 | 4+ |
| Ports available | 80, 4201-4210, 8000, 8080, 8888 | — |

## Quick Start (Any Docker Host)

```bash
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

**Access points** (replace `<HOST_IP>` with your machine's IP):

| Service | URL | Purpose |
|---------|-----|---------|
| Student Terminal | `http://<HOST_IP>:80` | Load-balanced shellinabox (sticky sessions) |
| Direct Terminal N | `http://<HOST_IP>:420N` | Per-student terminal (1-10) |
| CTFd Scoreboard | `http://<HOST_IP>:8000` | Challenge submission and scoring |
| Lab Controller | `http://<HOST_IP>:8888` | Instructor slides, solutions, timer |
| Traefik Dashboard | `http://<HOST_IP>:8080` | Load balancer admin |

**Default credentials** (from `.env`):

| Account | Username | Password |
|---------|----------|----------|
| CTFd Admin | `admin` | `NmapLab2024!` |
| Students | `team1`–`team10` | `scan4flags1`–`scan4flags10` |
| Solution Guide | — | `instructor2024` |

---

## Deployment Path 1: Generic Linux (Primary)

Works on Ubuntu, Debian, Fedora, Arch, or any Linux distribution.

### Automated Deploy

```bash
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
chmod +x deploy-linux.sh
./deploy-linux.sh            # Build, deploy, seed CTFd, verify
./deploy-linux.sh --clean    # Tear down first, then fresh deploy
```

The script checks for Docker, creates `.env`, builds images, starts containers, seeds CTFd challenges, and runs verification checks. It is idempotent — safe to run multiple times.

### Manual Deploy

```bash
# Install Docker if needed
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

# Deploy
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

### macOS

macOS uses Docker Desktop, which runs Linux containers natively. Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/), then follow the manual deploy steps above from Terminal.

### Verify

```bash
docker compose ps                        # All 28 containers running
curl -s http://localhost:80 | head -5     # Student terminal HTML
curl -s http://localhost:8000 | head -5   # CTFd HTML
```

### Teardown

```bash
docker compose down -v    # Stop all containers, remove volumes
```

---

## Deployment Path 2: Windows (Docker Desktop)

Docker Desktop for Windows runs Linux containers natively. No WSL knowledge required.

### Prerequisites

1. **Docker Desktop** — download and install from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
2. **Git for Windows** — download from [git-scm.com](https://git-scm.com/download/win) (provides `git` and `bash` for the setup script)

### Automated Deploy

Open **PowerShell** and run:

```powershell
git clone https://github.com/mwilco03/foc.git
cd foc\courses\nmap-recon
.\deploy-windows.ps1            # Build, deploy, seed CTFd, verify
.\deploy-windows.ps1 --clean    # Tear down first, then fresh deploy
```

The script checks for Docker Desktop (starts it if needed), builds images, starts containers, seeds CTFd via Git Bash, and runs verification. It is idempotent — safe to run multiple times.

### Manual Deploy

Open **PowerShell** or **Command Prompt**:

```powershell
# Ensure Docker Desktop is running (check system tray)
git clone https://github.com/mwilco03/foc.git
cd foc\courses\nmap-recon
copy .env.example .env
docker compose up -d --build
```

Then open **Git Bash** (installed with Git for Windows) and run:

```bash
cd /c/path/to/foc/courses/nmap-recon
bash ctfd/setup.sh
```

### Known Limitation: UDP Scanning

Docker Desktop uses a user-space network stack that does not fully support raw UDP sockets. This is a Docker Desktop networking limitation, not a Windows limitation.

**Impact:**
- `nmap -sU` (UDP scans) may show all ports as `open|filtered`
- SYN scans (`nmap -sS`) work correctly
- TCP connect scans (`nmap -sT`) work correctly
- The **UDP Hunt** and related Deep Dive challenges may not work as intended

**Workaround:** For full UDP support, deploy on native Linux (Path 1) or a cloud VM (Path 4).

### Teardown

```powershell
docker compose down -v
```

---

## Deployment Path 3: Proxmox LXC

For Proxmox environments, deploy inside an Alpine LXC container. **Never install Docker on the Proxmox host.**

### Option A: Community Script (Recommended)

Use the [Proxmox VE Helper Scripts](https://community-scripts.github.io/ProxmoxVE/) to create a Docker-ready Alpine LXC:

```bash
# From the Proxmox host shell
bash -c "$(curl -fsSL https://community-scripts.github.io/ProxmoxVE/scripts/alpine-docker.sh)"
```

Then `pct exec` or SSH into the container and follow the **Quick Start** above.

### Option B: Automated Script

The included `deploy-proxmox.sh` handles everything: LXC creation, Docker install, build, deploy, seed, and verify. It is idempotent — running it again updates the lab in place.

```bash
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
bash deploy-proxmox.sh              # Creates CT 9002, builds, deploys, verifies
bash deploy-proxmox.sh              # Safe to re-run — updates in place
bash deploy-proxmox.sh --clean      # Destroy existing CT and rebuild from scratch
VMID=9050 bash deploy-proxmox.sh    # Use a different container ID
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

# 4. Inside the container
apk update && apk add docker docker-cli-compose git bash curl
rc-update add docker default && service docker start
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
cp .env.example .env
docker compose up -d --build
bash ctfd/setup.sh
```

### Teardown

```bash
# Inside container
docker compose down -v

# From Proxmox host (destroys entire container)
pct stop 9002 && pct destroy 9002 --purge
```

---

## Deployment Path 4: Cloud VM (AWS / GCP / Azure)

Any Ubuntu or Debian VM with Docker installed.

### Automated Deploy

```bash
# SSH into your cloud VM, then:
git clone https://github.com/mwilco03/foc.git
cd foc/courses/nmap-recon
chmod +x deploy-cloud.sh
./deploy-cloud.sh            # Auto-detects cloud, installs Docker, deploys
./deploy-cloud.sh --clean    # Tear down first
```

The script auto-detects your cloud provider (AWS/GCP/Azure), installs Docker if missing, prints firewall reminders with provider-specific CLI examples, then delegates to `deploy-linux.sh`.

### Instance Sizing

| Provider | Minimum | Recommended |
|----------|---------|-------------|
| AWS EC2 | `t3.large` (2 vCPU, 8 GB) | `t3.xlarge` (4 vCPU, 16 GB) |
| GCP CE | `e2-standard-2` | `e2-standard-4` |
| Azure | `Standard_D2s_v3` | `Standard_D4s_v3` |

Use Ubuntu 22.04+ or Debian 12+ as the base image. 30 GB disk minimum.

### Firewall Rules

Open these TCP ports to your classroom IP range:

```
80, 4201-4210, 8000, 8080, 8888
```

**AWS:**
```bash
aws ec2 authorize-security-group-ingress --group-id <sg-id> \
    --protocol tcp --port 80 --cidr <classroom-cidr>
# Repeat for 4201-4210, 8000, 8080, 8888
```

**GCP:**
```bash
gcloud compute firewall-rules create nmap-lab \
    --allow tcp:80,tcp:4201-4210,tcp:8000,tcp:8080,tcp:8888 \
    --source-ranges <classroom-cidr>
```

**Azure:**
```bash
az network nsg rule create -g <rg> --nsg-name <nsg> -n nmap-lab \
    --priority 100 --access Allow --protocol Tcp \
    --destination-port-ranges 80 4201-4210 8000 8080 8888
```

### Cost

A 4-core/8GB VM runs approximately $0.15-0.20/hr. Tear down after class to avoid charges.

### Teardown

```bash
docker compose down -v    # Remove lab
# Then terminate the VM through your cloud console
```

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

## Deploy Scripts Summary

| Script | Platform | What it does |
|--------|----------|-------------|
| `deploy-linux.sh` | Any Linux / macOS | Checks Docker, builds, deploys, seeds CTFd, verifies |
| `deploy-windows.ps1` | Windows (Docker Desktop) | Checks/starts Docker Desktop, builds, deploys, seeds via Git Bash |
| `deploy-proxmox.sh` | Proxmox VE | Creates Alpine LXC, installs Docker, builds, deploys, verifies |
| `deploy-cloud.sh` | AWS / GCP / Azure | Installs Docker, prints firewall hints, delegates to `deploy-linux.sh` |
| `deploy.sh` | Any (legacy) | Original upstream deploy script |
| `deploy.ps1` | Windows (legacy) | Original upstream PowerShell script |

All scripts support `--clean` for a fresh start and are idempotent (safe to run twice).

---

## Troubleshooting

### Port Conflicts

```bash
# Linux/macOS
sudo lsof -i :80
sudo lsof -i :8000
```

```powershell
# Windows
netstat -ano | findstr :80
netstat -ano | findstr :8000
```

### Containers Restarting

```bash
docker compose logs <service-name>
docker compose restart <service-name>
```

### CTFd Setup Fails

```bash
# Re-run (idempotent for user creation, additive for challenges)
bash ctfd/setup.sh
```

### Student Can't Scan Targets

```bash
docker exec nmap-lab-student-1-1 nmap -sn 172.20.1.0/24
```

### Docker Build Fails in LXC

Ensure the LXC container has nesting, unconfined apparmor, and full device access. See Deployment Path 3 for the full config.
