#!/bin/bash
# Pivot Lab Bootstrap Installer
# One-line install: curl -fsSL https://raw.githubusercontent.com/mwilco03/Piv0t.L4ND/main/install.sh | bash

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}${BOLD}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║                                                       ║"
echo "║         PIVOT LAB v5.0 - BOOTSTRAP INSTALLER          ║"
echo "║                                                       ║"
echo "║   Multi-Protocol Network Traversal Training Lab      ║"
echo "║                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
fi

echo -e "${BOLD}Detected OS:${NC} $OS"
echo ""

# Check for Docker
echo -e "${BOLD}[1/4] Checking Docker...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
    echo -e "  ${GREEN}✓${NC} Docker $DOCKER_VERSION installed"
else
    echo -e "  ${RED}✗${NC} Docker not found"
    echo ""
    echo -e "${YELLOW}Docker is required to run Pivot Lab.${NC}"
    echo ""
    echo "Installation instructions:"

    if [ "$OS" = "linux" ]; then
        echo ""
        echo "  Ubuntu/Debian:"
        echo "    curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "    sudo sh get-docker.sh"
        echo "    sudo usermod -aG docker \$USER"
        echo "    newgrp docker"
        echo ""
        echo "  Fedora/RHEL/CentOS:"
        echo "    sudo dnf install docker"
        echo "    sudo systemctl start docker"
        echo "    sudo systemctl enable docker"
        echo "    sudo usermod -aG docker \$USER"
        echo ""
    elif [ "$OS" = "macos" ]; then
        echo ""
        echo "  macOS:"
        echo "    Download and install Docker Desktop:"
        echo "    https://www.docker.com/products/docker-desktop"
        echo ""
    elif [ "$OS" = "windows" ]; then
        echo ""
        echo "  Windows (WSL2 required):"
        echo "    1. Install WSL2: https://docs.microsoft.com/en-us/windows/wsl/install"
        echo "    2. Install Docker Desktop: https://www.docker.com/products/docker-desktop"
        echo ""
    fi

    echo "For more details: https://docs.docker.com/get-docker/"
    echo ""
    exit 1
fi

# Check for Docker Compose
echo -e "${BOLD}[2/4] Checking Docker Compose...${NC}"
COMPOSE_CMD=""
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "v2+")
    echo -e "  ${GREEN}✓${NC} Docker Compose $COMPOSE_VERSION (integrated)"
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d ' ' -f3 | cut -d ',' -f1)
    echo -e "  ${GREEN}✓${NC} docker-compose $COMPOSE_VERSION (standalone)"
    COMPOSE_CMD="docker-compose"
else
    echo -e "  ${RED}✗${NC} Docker Compose not found"
    echo ""
    echo -e "${YELLOW}Docker Compose is required to run Pivot Lab.${NC}"
    echo ""
    echo "Installation:"
    echo "  Modern Docker Desktop includes Compose v2 (docker compose)"
    echo "  For standalone installation: https://docs.docker.com/compose/install/"
    echo ""
    exit 1
fi

# Check Docker daemon
echo -e "${BOLD}[3/4] Checking Docker daemon...${NC}"
if docker ps &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Docker daemon running"
else
    echo -e "  ${RED}✗${NC} Docker daemon not running or permission denied"
    echo ""
    echo "Please ensure:"
    echo "  1. Docker daemon is running"
    echo "  2. Your user has permission (add to docker group):"
    echo "     sudo usermod -aG docker \$USER"
    echo "     newgrp docker"
    echo ""
    exit 1
fi

# Clone repository
echo -e "${BOLD}[4/4] Cloning Pivot Lab repository...${NC}"

INSTALL_DIR="${HOME}/Piv0t.L4ND"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "  ${YELLOW}⚠${NC} Directory already exists: $INSTALL_DIR"
    read -p "  Overwrite? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
    else
        echo "  Installation cancelled."
        exit 1
    fi
fi

if command -v git &> /dev/null; then
    echo "  Cloning repository..."
    git clone https://github.com/mwilco03/Piv0t.L4ND.git "$INSTALL_DIR"
    echo -e "  ${GREEN}✓${NC} Repository cloned to $INSTALL_DIR"
else
    echo -e "  ${RED}✗${NC} Git not found"
    echo ""
    echo "Please install git:"
    if [ "$OS" = "linux" ]; then
        echo "  sudo apt install git  # Debian/Ubuntu"
        echo "  sudo dnf install git  # Fedora/RHEL"
    elif [ "$OS" = "macos" ]; then
        echo "  brew install git"
    fi
    echo ""
    exit 1
fi

cd "$INSTALL_DIR"

# Make scripts executable
chmod +x start.sh reset.sh preflight.sh install.sh

echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "${GREEN}${BOLD}✓ INSTALLATION COMPLETE${NC}"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Pivot Lab is installed at: $INSTALL_DIR"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo "  1. Navigate to the directory:"
echo "     cd $INSTALL_DIR"
echo ""
echo "  2. Start the lab:"
echo "     ./start.sh"
echo ""
echo "  3. Access the lab:"
echo "     Terminal:   http://localhost:4200"
echo "     Scoreboard: http://localhost:8080"
echo ""
echo -e "${BOLD}Quick Commands:${NC}"
echo "  ./start.sh     - Start the lab"
echo "  ./reset.sh     - Full reset (regenerate flags and IPs)"
echo "  ./preflight.sh - Run system checks"
echo ""
echo -e "${BOLD}Documentation:${NC}"
echo "  Design.md  - Complete lab design and walkthroughs"
echo "  README.md  - Quick start guide"
echo "  docs/      - Additional references"
echo ""
echo "Happy hacking! 🎯"
echo ""
