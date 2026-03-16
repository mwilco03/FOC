#!/bin/bash
# Import Kibana saved objects (dashboards, visualizations, index patterns)
# Run after Kibana is healthy

KIBANA_URL="${1:-http://localhost:5601}"
DASH_DIR="$(dirname "$0")/dashboards"

echo "[*] Waiting for Kibana..."
until curl -sf "${KIBANA_URL}/api/status" > /dev/null 2>&1; do
    sleep 5
done
echo "[+] Kibana ready"

# Create index patterns
echo "[+] Creating index patterns..."
for idx in sysmon zeek winsec applocker winlogbeat; do
    curl -sf -X POST "${KIBANA_URL}/api/saved_objects/index-pattern/${idx}" \
        -H "kbn-xsrf: true" \
        -H "Content-Type: application/json" \
        -d "{
            \"attributes\": {
                \"title\": \"${idx}-*\",
                \"timeFieldName\": \"@timestamp\"
            }
        }" > /dev/null 2>&1
    echo "  Created: ${idx}-*"
done

# Set sysmon as default
curl -sf -X POST "${KIBANA_URL}/api/kibana/settings" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -d '{"changes":{"defaultIndex":"sysmon"}}' > /dev/null 2>&1

# Import NDJSON dashboards if they exist
for f in "${DASH_DIR}"/*.ndjson; do
    [ -f "$f" ] || continue
    echo "[+] Importing $(basename "$f")..."
    curl -sf -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
        -H "kbn-xsrf: true" \
        --form file=@"$f" > /dev/null 2>&1
done

echo "[+] Dashboard import complete"
