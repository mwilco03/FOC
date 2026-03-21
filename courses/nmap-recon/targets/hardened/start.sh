#!/bin/sh
# =============================================================================
# Hardened host startup — ICMP blocking, SSH, Python services
# =============================================================================

# --- Constants ---------------------------------------------------------------
SSHD_PORT=22222
SERVICES_SCRIPT="/app/services.py"

# --- ICMP blocking (requires NET_ADMIN capability) --------------------------
if iptables -A INPUT -p icmp --icmp-type echo-request -j DROP 2>&1; then
    echo "[+] ICMP echo-request blocked (students need -Pn)"
else
    echo "[!] WARNING: iptables failed — container may lack NET_ADMIN capability"
    echo "[!] Host will respond to ping (students won't need -Pn for this host)"
fi
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP 2>/dev/null || true

# --- SSH on non-standard port -----------------------------------------------
/usr/sbin/sshd
if netstat -tlnp 2>/dev/null | grep -q ":${SSHD_PORT}"; then
    echo "[+] sshd listening on port ${SSHD_PORT}"
else
    echo "[-] WARNING: sshd may not have started on port ${SSHD_PORT}"
fi

# --- Python TCP/UDP services -------------------------------------------------
python3 "$SERVICES_SCRIPT" &
SERVICES_PID=$!
sleep 1

if kill -0 "$SERVICES_PID" 2>/dev/null; then
    echo "[+] Python services started (PID ${SERVICES_PID})"
else
    echo "[-] ERROR: Python services failed to start"
    echo "[-] Attempting restart..."
    python3 "$SERVICES_SCRIPT" &
    SERVICES_PID=$!
    sleep 1
    if kill -0 "$SERVICES_PID" 2>/dev/null; then
        echo "[+] Python services started on retry (PID ${SERVICES_PID})"
    else
        echo "[-] FATAL: Python services could not start"
    fi
fi

# --- Keep container alive (PID 1) -------------------------------------------
exec sleep infinity
