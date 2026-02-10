#!/bin/bash
# Pivot Lab Preflight Check
# Verifies system requirements and port availability before starting

set -e

echo "═══════════════════════════════════════════════════════"
echo "  Pivot Lab v5.0 - Preflight Check"
echo "═══════════════════════════════════════════════════════"
echo ""

PREFLIGHT_PASS=true

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Docker installation
echo -n "Checking Docker installation... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
    echo -e "${GREEN}✓${NC} Docker ${DOCKER_VERSION}"
else
    echo -e "${RED}✗${NC} Docker not found"
    echo "  Install: https://docs.docker.com/get-docker/"
    PREFLIGHT_PASS=false
fi

# Check 2: Docker Compose installation
echo -n "Checking Docker Compose... "
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "installed")
    echo -e "${GREEN}✓${NC} Docker Compose ${COMPOSE_VERSION}"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d ' ' -f3 | cut -d ',' -f1)
    echo -e "${GREEN}✓${NC} docker-compose ${COMPOSE_VERSION}"
else
    echo -e "${RED}✗${NC} Docker Compose not found"
    echo "  Install: https://docs.docker.com/compose/install/"
    PREFLIGHT_PASS=false
fi

# Check 3: Docker daemon running
echo -n "Checking Docker daemon... "
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓${NC} Running"
else
    echo -e "${RED}✗${NC} Docker daemon not running or permission denied"
    echo "  Start Docker or add user to docker group: sudo usermod -aG docker \$USER"
    PREFLIGHT_PASS=false
fi

# Check 4: Port availability
echo ""
echo "Checking port availability:"

REQUIRED_PORTS=(4200 8080)
PORT_CONFLICTS=()

for port in "${REQUIRED_PORTS[@]}"; do
    echo -n "  Port ${port}... "

    # Check if port is in use (works on Linux and macOS)
    if command -v ss &> /dev/null; then
        # Use ss (modern Linux)
        if ss -tuln | grep -q ":${port} "; then
            echo -e "${RED}✗${NC} In use"
            PORT_CONFLICTS+=($port)
            # Try to identify what's using it
            PROCESS=$(ss -tlnp 2>/dev/null | grep ":${port} " | awk '{print $6}' | cut -d'"' -f2 || echo "unknown")
            echo "    Process: ${PROCESS}"
        else
            echo -e "${GREEN}✓${NC} Available"
        fi
    elif command -v netstat &> /dev/null; then
        # Use netstat (macOS and older Linux)
        if netstat -an | grep -q "[:.]${port} .*LISTEN"; then
            echo -e "${RED}✗${NC} In use"
            PORT_CONFLICTS+=($port)
        else
            echo -e "${GREEN}✓${NC} Available"
        fi
    elif command -v lsof &> /dev/null; then
        # Use lsof as fallback
        if lsof -i :${port} &> /dev/null; then
            echo -e "${RED}✗${NC} In use"
            PORT_CONFLICTS+=($port)
            PROCESS=$(lsof -i :${port} -t | xargs ps -p 2>/dev/null | tail -1 || echo "unknown")
            echo "    Process: ${PROCESS}"
        else
            echo -e "${GREEN}✓${NC} Available"
        fi
    else
        echo -e "${YELLOW}?${NC} Cannot check (no ss/netstat/lsof)"
    fi
done

# Check 5: Available disk space
echo ""
echo -n "Checking disk space... "
AVAILABLE_KB=$(df . | tail -1 | awk '{print $4}')
AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))

if [ $AVAILABLE_GB -lt 2 ]; then
    echo -e "${YELLOW}⚠${NC} Low disk space (${AVAILABLE_GB}GB available, 2GB+ recommended)"
else
    echo -e "${GREEN}✓${NC} ${AVAILABLE_GB}GB available"
fi

# Check 6: Available memory
echo -n "Checking available memory... "
if command -v free &> /dev/null; then
    AVAILABLE_MB=$(free -m | awk '/^Mem:/{print $7}')
    if [ $AVAILABLE_MB -lt 2048 ]; then
        echo -e "${YELLOW}⚠${NC} Low memory (${AVAILABLE_MB}MB available, 4GB+ recommended)"
    else
        echo -e "${GREEN}✓${NC} ${AVAILABLE_MB}MB available"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS memory check
    FREE_PAGES=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
    FREE_MB=$((FREE_PAGES * 4096 / 1024 / 1024))
    echo -e "${GREEN}✓${NC} ${FREE_MB}MB available"
else
    echo -e "${YELLOW}?${NC} Cannot determine (not a blocker)"
fi

echo ""
echo "═══════════════════════════════════════════════════════"

# Final verdict
if [ "$PREFLIGHT_PASS" = false ]; then
    echo -e "${RED}✗ PREFLIGHT FAILED${NC}"
    echo ""
    echo "Please resolve the issues above before starting the lab."
    exit 1
fi

if [ ${#PORT_CONFLICTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠ WARNING: Port conflicts detected${NC}"
    echo ""
    echo "The following ports are in use: ${PORT_CONFLICTS[*]}"
    echo ""
    echo "Options:"
    echo "  1. Stop services using these ports"
    echo "  2. Modify docker-compose.yml to use different host ports"
    echo "  3. Continue anyway (may cause startup failures)"
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Startup cancelled."
        exit 1
    fi
fi

echo -e "${GREEN}✓ PREFLIGHT PASSED${NC}"
echo ""
echo "All checks passed. Ready to start Pivot Lab!"
echo ""
