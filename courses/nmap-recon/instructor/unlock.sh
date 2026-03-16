#!/bin/bash
# =============================================================================
# Unlock/Lock a CTFd challenge category
# Usage: ./unlock.sh "Host Discovery"           # unlock (make visible)
#        ./unlock.sh "Host Discovery" hide       # lock (make hidden)
# =============================================================================

CTFD_URL="${CTFD_URL:-http://localhost:8000}"
CATEGORY="${1:-}"
ACTION="${2:-visible}"  # visible or hidden

if [ -z "$CATEGORY" ]; then
    echo "Usage: $0 <category> [visible|hidden]"
    echo ""
    echo "Categories:"
    echo "  Host Discovery"
    echo "  Port Scanning"
    echo "  Service Detection"
    echo "  Advanced Scanning"
    echo "  NSE Scripts"
    echo "  Knowledge Check"
    exit 1
fi

# Login
NONCE=$(curl -s -c /tmp/ctfd_unlock.txt "${CTFD_URL}/login" \
    | grep -o 'name="nonce"[^>]*value="[^"]*"' \
    | grep -o 'value="[^"]*"' \
    | sed 's/value="//;s/"$//')
curl -s -b /tmp/ctfd_unlock.txt -c /tmp/ctfd_unlock.txt \
    -X POST "${CTFD_URL}/login" \
    -d "name=admin&password=NmapLab2024%21&nonce=${NONCE}" -o /dev/null

CSRF=$(curl -s -b /tmp/ctfd_unlock.txt -L "${CTFD_URL}/admin" \
    | grep -o "csrfNonce.*:.*\"[a-f0-9]*\"" \
    | grep -o '"[a-f0-9]*"' \
    | sed 's/"//g')

TOKEN=$(curl -s -b /tmp/ctfd_unlock.txt \
    -X POST "${CTFD_URL}/api/v1/tokens" \
    -H "Content-Type: application/json" \
    -H "CSRF-Token: ${CSRF}" \
    -d '{"description":"unlock"}' \
    | grep -o '"value" *: *"[^"]*"' \
    | sed 's/"value" *: *"//;s/"$//')

# Get all challenges
CHALLENGES=$(curl -s "${CTFD_URL}/api/v1/challenges?view=admin" \
    -H "Authorization: Token ${TOKEN}")

# Filter by category and update state
echo "$CHALLENGES" | docker run --rm -i python:3.11-alpine python3 -c "
import sys, json
data = json.load(sys.stdin)
category = '${CATEGORY}'
state = '${ACTION}'
for c in data.get('data', []):
    if c['category'] == category:
        print(f'{c[\"id\"]}|{c[\"name\"]}')
" | while IFS='|' read -r cid cname; do
    curl -s -X PATCH "${CTFD_URL}/api/v1/challenges/${cid}" \
        -H "Authorization: Token ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"state\": \"${ACTION}\"}" > /dev/null
    echo "[+] ${cname} -> ${ACTION}"
done

rm -f /tmp/ctfd_unlock.txt
echo ""
echo "Done. Category '${CATEGORY}' is now ${ACTION}."
