#!/bin/bash
# Initialize Arkime DB schema and import PCAP
set -e

ES_HOST="${ARKIME_ELASTICSEARCH:-http://elasticsearch:9200}"
PCAP="/pcap/attack.pcap"

echo "[arkime] Waiting for Elasticsearch..."
until wget -qO- "$ES_HOST/_cluster/health" > /dev/null 2>&1; do
    sleep 5
done
echo "[arkime] Elasticsearch ready"

# Initialize DB (idempotent)
echo "[arkime] Initializing database..."
/opt/arkime/db/db.pl --insecure "$ES_HOST" init --ifneeded 2>/dev/null || true

# Create admin user for viewer
/opt/arkime/bin/arkime_add_user.sh admin "Lab Admin" changeme --admin --insecure "$ES_HOST" 2>/dev/null || true

# Import PCAP if present
if [ -f "$PCAP" ]; then
    echo "[arkime] Importing $PCAP..."
    /opt/arkime/bin/capture --insecure -c /opt/arkime/etc/config.ini -r "$PCAP" 2>/dev/null || echo "[arkime] Capture import may have had issues"
    echo "[arkime] PCAP imported"
else
    echo "[arkime] No PCAP at $PCAP"
fi

# Start viewer
echo "[arkime] Starting viewer on port 8005..."
cd /opt/arkime/viewer
exec /opt/arkime/bin/node viewer.js --insecure -c /opt/arkime/etc/config.ini
