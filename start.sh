#!/bin/bash
# Pivot Lab startup script
# Generates randomized IPs and starts the lab

set -e

# Run preflight checks first
if [ -f ./preflight.sh ]; then
    ./preflight.sh
    if [ $? -ne 0 ]; then
        echo "Preflight checks failed. Aborting startup."
        exit 1
    fi
else
    echo "Warning: preflight.sh not found. Skipping system checks."
fi

echo "═══════════════════════════════════════════════════════"
echo "  Pivot Lab v5.0 - Startup"
echo "═══════════════════════════════════════════════════════"
echo ""

# Generate random last octets (.50-.200)
generate_octet() {
    echo $((50 + RANDOM % 151))
}

echo "Generating randomized IP addresses..."

# Create .env file
cat > .env << EOF
# Pivot Lab Environment Configuration
# Generated: $(date)

GATE_IP=172.20.1.$(generate_octet)
TUNNEL_IP=172.20.2.$(generate_octet)
FILESERV_IP=172.20.3.$(generate_octet)
WEBSHELL_IP=172.20.4.$(generate_octet)
DROPZONE_IP=172.20.5.$(generate_octet)
DEPOT_IP=172.20.6.$(generate_octet)
RESOLVER_IP=172.20.7.$(generate_octet)
CACHE_IP=172.20.8.$(generate_octet)
VAULT_IP=172.20.9.$(generate_octet)
EOF

echo "IP addresses generated:"
cat .env | grep _IP=
echo ""

# Start docker compose
echo "Starting containers..."
docker compose up -d

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Pivot Lab Started Successfully!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Access points:"
echo "  - Terminal:   http://localhost:4200"
echo "  - Scoreboard: http://localhost:8080"
echo ""
echo "Waiting for services to initialize..."
sleep 5
echo ""
echo "Ready! Open your browser and begin."
echo ""
