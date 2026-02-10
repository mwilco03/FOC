# Pivot Lab Installation Guide

## Prerequisites

- **Docker** (20.10+)
- **Docker Compose** (v2.0+ or docker-compose v1.29+)
- **4GB RAM** minimum (8GB recommended)
- **2GB free disk space**
- **Ports 4200 and 8080** available on host

## Installation Methods

### Method 1: One-Line Bootstrap Installer (Easiest)

```bash
curl -fsSL https://raw.githubusercontent.com/mwilco03/Piv0t.L4ND/main/install.sh | bash
```

This will:
1. Check for Docker and Docker Compose
2. Verify Docker daemon is running
3. Clone the repository to `~/Piv0t.L4ND`
4. Set executable permissions on scripts
5. Display next steps

**After installation:**
```bash
cd ~/Piv0t.L4ND
./start.sh
```

### Method 2: Manual Git Clone

```bash
# Clone the repository
git clone https://github.com/mwilco03/Piv0t.L4ND.git
cd Piv0t.L4ND

# Run preflight checks (recommended)
./preflight.sh

# Start the lab
./start.sh
```

### Method 3: Download ZIP

```bash
# Download and extract
wget https://github.com/mwilco03/Piv0t.L4ND/archive/refs/heads/main.zip
unzip main.zip
cd Piv0t.L4ND-main

# Make scripts executable
chmod +x *.sh

# Run preflight and start
./preflight.sh
./start.sh
```

## Docker Installation (If Needed)

### Linux (Ubuntu/Debian)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (avoid sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Linux (Fedora/RHEL/CentOS)

```bash
# Install Docker
sudo dnf install docker

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### macOS

Download and install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)

Docker Compose is included with Docker Desktop.

### Windows (WSL2)

1. Install WSL2: https://docs.microsoft.com/en-us/windows/wsl/install
2. Install Docker Desktop: https://www.docker.com/products/docker-desktop
3. Enable WSL2 integration in Docker Desktop settings
4. Run commands from WSL2 terminal

## Preflight Check

The `preflight.sh` script verifies:

✓ Docker installation and version
✓ Docker Compose availability
✓ Docker daemon status
✓ Port 4200 availability (LAUNCHPAD)
✓ Port 8080 availability (SCOREBOARD)
✓ Disk space (2GB+ recommended)
✓ Available memory (4GB+ recommended)

**Run preflight check manually:**
```bash
./preflight.sh
```

**Preflight is automatically run** when you execute `./start.sh`

## Troubleshooting Installation

### Port Conflicts

If ports 4200 or 8080 are in use:

**Option 1: Stop conflicting services**
```bash
# Find what's using the port
sudo lsof -i :4200
sudo lsof -i :8080

# Stop the service (example)
sudo systemctl stop <service-name>
```

**Option 2: Change exposed ports**

Edit `docker-compose.yml`:
```yaml
launchpad:
  ports:
    - "4201:4200"  # Change 4200 to 4201 (or any free port)

scoreboard:
  ports:
    - "8081:8080"  # Change 8080 to 8081 (or any free port)
```

Then access via the new ports:
- Terminal: http://localhost:4201
- Scoreboard: http://localhost:8081

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Reload group membership (or logout/login)
newgrp docker

# Verify
docker ps
```

### Docker Daemon Not Running

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**macOS/Windows:**
- Start Docker Desktop application

### Disk Space Issues

```bash
# Check available space
df -h .

# Clean up Docker (removes unused containers/images)
docker system prune -a
```

### Low Memory Warnings

If you have less than 4GB available:
- Close unnecessary applications
- Consider increasing Docker memory limit (Docker Desktop settings)
- Lab may run slower but should still function

## Verifying Installation

After running `./start.sh`, verify the lab is running:

```bash
# Check container status
docker compose ps

# Should see 11 containers running:
# - init (may be exited - this is normal)
# - launchpad
# - scoreboard
# - gate, tunnel, fileserv, webshell, dropzone, depot, resolver, cache, vault
```

**Access the lab:**
- Terminal: http://localhost:4200
- Scoreboard: http://localhost:8080

You should see the shellinabox terminal interface and scoreboard UI.

## Uninstallation

```bash
# Stop and remove all containers
cd ~/Piv0t.L4ND
docker compose down -v

# Remove repository
cd ..
rm -rf Piv0t.L4ND

# (Optional) Remove Docker images
docker images | grep pivot | awk '{print $3}' | xargs docker rmi
```

## Advanced: Air-Gapped Installation

For environments without internet access:

1. **Download on internet-connected machine:**
   ```bash
   git clone https://github.com/mwilco03/Piv0t.L4ND.git
   cd Piv0t.L4ND
   docker compose pull  # Pre-pull base images
   docker save alpine:3.19 > alpine.tar
   ```

2. **Transfer to air-gapped machine:**
   - Copy entire `Piv0t.L4ND` directory
   - Copy `alpine.tar`

3. **On air-gapped machine:**
   ```bash
   docker load < alpine.tar
   cd Piv0t.L4ND
   ./start.sh
   ```

4. **For linpeas.sh (used in LAUNCHPAD):**
   - Pre-download: `wget https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh`
   - Place in `launchpad/` directory
   - Update Dockerfile to `COPY linpeas.sh /home/player/` instead of `wget`

## Getting Help

- **Documentation:** See `Design.md` for complete lab details
- **Issues:** https://github.com/mwilco03/Piv0t.L4ND/issues
- **Preflight:** Run `./preflight.sh` for diagnostics

---

**Ready to Start?**

```bash
cd ~/Piv0t.L4ND
./start.sh
```

Then open http://localhost:4200 in your browser and begin hacking! 🎯
