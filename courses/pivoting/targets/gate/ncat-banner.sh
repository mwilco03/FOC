#!/bin/bash
# GATE ncat banner and restricted shell

echo "═══════════════════════════════════════════════════════"
echo "  GATE ACCESS CONTROL SYSTEM"
echo "  Authorized Personnel Only"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Connection established. Dropping to restricted shell..."
echo ""

# Give user a shell as ctf
exec su - ctf
