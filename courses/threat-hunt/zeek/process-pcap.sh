#!/bin/bash
# Process attack PCAP with Zeek, output JSON logs to shared volume
set -e

PCAP="/pcap/attack.pcap"
OUTDIR="/zeek-logs"

if [ ! -f "$PCAP" ]; then
    echo "[zeek] No PCAP found at $PCAP — waiting for it..."
    # Poll every 10s in case PCAP is being downloaded/generated
    for i in $(seq 1 60); do
        sleep 10
        [ -f "$PCAP" ] && break
    done
fi

if [ ! -f "$PCAP" ]; then
    echo "[zeek] No PCAP after 10 minutes. Sleeping."
    sleep infinity
fi

echo "[zeek] Processing $PCAP..."
cd "$OUTDIR"
zeek -r "$PCAP" LogAscii::use_json=T

echo "[zeek] Logs generated:"
ls -la "$OUTDIR"/*.log 2>/dev/null || echo "  (none)"
echo "[zeek] Done. Sleeping to keep container alive for Logstash file input."
sleep infinity
