#!/bin/sh
# =============================================================================
# Database server startup — SSH, MariaDB, PostgreSQL, Redis
# =============================================================================

# --- Constants ---------------------------------------------------------------
PG_DATA="/var/lib/postgresql/data"
PG_LOG="/tmp/pg.log"
PG_READY_TIMEOUT=30
PG_READY_INTERVAL=1

SSHD_PORT=22
MYSQL_PORT=3306
PG_PORT=5432
REDIS_PORT=6379

# --- SSH (port 22) -----------------------------------------------------------
/usr/sbin/sshd
if netstat -tlnp 2>/dev/null | grep -q ":${SSHD_PORT}"; then
    echo "[+] sshd listening on port ${SSHD_PORT}"
else
    echo "[-] WARNING: sshd may not have started"
fi

# --- MariaDB (port 3306) -----------------------------------------------------
mysqld_safe --skip-grant-tables &
sleep 3
if netstat -tlnp 2>/dev/null | grep -q ":${MYSQL_PORT}"; then
    echo "[+] MariaDB listening on port ${MYSQL_PORT}"
else
    echo "[-] WARNING: MariaDB may not be ready on port ${MYSQL_PORT}"
fi

# --- PostgreSQL (port 5432) — wait until ready --------------------------------
su postgres -c "pg_ctl start -D ${PG_DATA} -l ${PG_LOG}" 2>/dev/null

elapsed=0
while [ "$elapsed" -lt "$PG_READY_TIMEOUT" ]; do
    if su postgres -c "pg_isready -q" 2>/dev/null; then
        echo "[+] PostgreSQL ready on port ${PG_PORT} (after ${elapsed}s)"
        break
    fi
    sleep "$PG_READY_INTERVAL"
    elapsed=$((elapsed + PG_READY_INTERVAL))
done

if [ "$elapsed" -ge "$PG_READY_TIMEOUT" ]; then
    echo "[-] WARNING: PostgreSQL not ready after ${PG_READY_TIMEOUT}s — check ${PG_LOG}"
fi

# --- Redis (port 6379) -------------------------------------------------------
redis-server --protected-mode no --daemonize yes
if netstat -tlnp 2>/dev/null | grep -q ":${REDIS_PORT}"; then
    echo "[+] Redis listening on port ${REDIS_PORT}"
else
    echo "[-] WARNING: Redis may not have started on port ${REDIS_PORT}"
fi

# --- Keep container alive (PID 1) --------------------------------------------
exec sleep infinity
