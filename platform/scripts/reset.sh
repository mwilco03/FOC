#!/bin/bash
# Pivot Lab reset script
# Tears down everything and brings it back up fresh

set -e

echo "═══════════════════════════════════════════════════════"
echo "  Pivot Lab v5.0 - Full Reset"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Stopping and removing all containers..."
docker compose down -v

echo ""
echo "Cleaning up..."
rm -f .env

echo ""
echo "Regenerating environment..."
./start.sh

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Reset Complete!"
echo "═══════════════════════════════════════════════════════"
