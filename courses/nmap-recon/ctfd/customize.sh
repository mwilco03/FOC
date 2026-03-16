#!/bin/bash
# =============================================================================
# CTFd Customization Script
# Applies branding, custom CSS, and logo to CTFd
# Run AFTER setup.sh
# Usage: ./customize.sh [CTFD_URL] [LOGO_PATH]
# =============================================================================

set -euo pipefail

CTFD_URL="${1:-http://localhost:8000}"
LOGO_PATH="${2:-}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

# Load .env
ENV_FILE="$(dirname "$0")/../.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

ADMIN_USER="admin"
ADMIN_PASS="NmapLab2024!"

# ---------------------------------------------------------------------------
# Login and get CSRF token
# ---------------------------------------------------------------------------
info "Logging in to CTFd..."

NONCE=$(curl -s -c /tmp/ctfd_cust.txt "${CTFD_URL}/login" \
    | grep -o 'name="nonce"[^>]*value="[^"]*"' \
    | grep -o 'value="[^"]*"' \
    | sed 's/value="//;s/"$//')

curl -s -b /tmp/ctfd_cust.txt -c /tmp/ctfd_cust.txt \
    -X POST "${CTFD_URL}/login" \
    -d "name=${ADMIN_USER}&password=${ADMIN_PASS}&nonce=${NONCE}" \
    -o /dev/null

CSRF=$(curl -s -b /tmp/ctfd_cust.txt -L "${CTFD_URL}/admin" \
    | grep -o "csrfNonce.*:.*\"[a-f0-9]*\"" \
    | grep -o '"[a-f0-9]*"' \
    | sed 's/"//g')

API="${CTFD_URL}/api/v1"
CT="Content-Type: application/json"

# Get API token
TOKEN_RESP=$(curl -s -b /tmp/ctfd_cust.txt \
    -X POST "${API}/tokens" \
    -H "$CT" -H "CSRF-Token: ${CSRF}" \
    -d '{"description":"customize-script"}')

ADMIN_TOKEN=$(echo "$TOKEN_RESP" | grep -o '"value" *: *"[^"]*"' | sed 's/"value" *: *"//;s/"$//')
AUTH="Authorization: Token ${ADMIN_TOKEN}"

info "Authenticated"

# ---------------------------------------------------------------------------
# Upload logo if provided
# ---------------------------------------------------------------------------
if [ -n "$LOGO_PATH" ] && [ -f "$LOGO_PATH" ]; then
    info "Uploading logo from ${LOGO_PATH}..."
    curl -s -X POST "${API}/files" \
        -H "$AUTH" \
        -F "file=@${LOGO_PATH}" \
        -F "type=logo" \
        -F "nonce=${CSRF}" > /dev/null
    info "Logo uploaded"
else
    warn "No logo path provided, skipping logo upload"
fi

# ---------------------------------------------------------------------------
# Apply custom CSS theme
# ---------------------------------------------------------------------------
info "Applying custom CSS theme..."

CUSTOM_CSS=$(cat <<'CSSEOF'
/* Nmap Training Lab - Custom CTFd Theme */

/* Dark cyber theme */
:root {
    --theme-primary: #00ff41;
    --theme-bg: #0a0a0a;
    --theme-card: #1a1a2e;
    --theme-text: #e0e0e0;
    --theme-accent: #ff6b35;
}

body {
    background-color: var(--theme-bg) !important;
    color: var(--theme-text) !important;
    font-family: 'Courier New', monospace !important;
}

.navbar {
    background-color: #16213e !important;
    border-bottom: 2px solid var(--theme-primary) !important;
}

.navbar-brand, .nav-link {
    color: var(--theme-primary) !important;
}

.nav-link:hover {
    color: var(--theme-accent) !important;
}

.jumbotron, .card {
    background-color: var(--theme-card) !important;
    border: 1px solid #333 !important;
    color: var(--theme-text) !important;
}

.btn-primary, .btn-outline-primary {
    background-color: var(--theme-primary) !important;
    border-color: var(--theme-primary) !important;
    color: #000 !important;
    font-weight: bold !important;
}

.btn-primary:hover {
    background-color: #00cc33 !important;
    border-color: #00cc33 !important;
}

h1, h2, h3, h4, h5, h6 {
    color: var(--theme-primary) !important;
}

.challenge-button {
    background-color: var(--theme-card) !important;
    border: 1px solid var(--theme-primary) !important;
    color: var(--theme-primary) !important;
    transition: all 0.3s !important;
}

.challenge-button:hover {
    background-color: var(--theme-primary) !important;
    color: #000 !important;
    box-shadow: 0 0 15px rgba(0, 255, 65, 0.5) !important;
}

.challenge-button.solved {
    background-color: #1b4332 !important;
    border-color: #2d6a4f !important;
}

/* Scoreboard styling */
.table {
    color: var(--theme-text) !important;
    background-color: var(--theme-card) !important;
}

.table thead th {
    background-color: #16213e !important;
    color: var(--theme-primary) !important;
    border-color: #333 !important;
}

.table td {
    border-color: #333 !important;
}

/* Category badges */
.badge {
    font-family: 'Courier New', monospace !important;
}

/* Input fields */
.form-control {
    background-color: #1a1a2e !important;
    border: 1px solid var(--theme-primary) !important;
    color: var(--theme-text) !important;
}

.form-control:focus {
    box-shadow: 0 0 5px rgba(0, 255, 65, 0.5) !important;
}

/* Modal */
.modal-content {
    background-color: var(--theme-card) !important;
    border: 1px solid var(--theme-primary) !important;
    color: var(--theme-text) !important;
}

/* Footer */
footer {
    background-color: #16213e !important;
    border-top: 1px solid #333 !important;
}

/* Glowing effect for header */
.ctf-name {
    text-shadow: 0 0 10px rgba(0, 255, 65, 0.7) !important;
}

/* Alert boxes */
.alert-success {
    background-color: #1b4332 !important;
    border-color: var(--theme-primary) !important;
    color: var(--theme-primary) !important;
}

.alert-danger {
    background-color: #3d0000 !important;
    border-color: #ff4444 !important;
    color: #ff4444 !important;
}
CSSEOF
)

# Escape the CSS for JSON
ESCAPED_CSS=$(echo "$CUSTOM_CSS" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')

# Apply CSS via config endpoint
curl -s -X PATCH "${API}/configs" \
    -H "$AUTH" -H "$CT" \
    -d "{\"css\": \"${ESCAPED_CSS}\"}" > /dev/null 2>&1 || \
curl -s -X PATCH "${API}/configs/css" \
    -H "$AUTH" -H "$CT" \
    -d "{\"value\": \"${ESCAPED_CSS}\"}" > /dev/null 2>&1 || \
warn "Could not apply CSS via API - apply manually in Admin > Config > Theme"

info "Custom CSS applied"

# ---------------------------------------------------------------------------
# Update CTF description
# ---------------------------------------------------------------------------
info "Updating CTF description..."

curl -s -X PATCH "${API}/configs/ctf_description" \
    -H "$AUTH" -H "$CT" \
    -d '{"value": "Network Reconnaissance Training - Discover, Scan, Enumerate"}' > /dev/null 2>&1 || true

info "Done! CTFd has been customized."
echo ""
echo "  Manual customization options:"
echo "    Admin Panel:  ${CTFD_URL}/admin"
echo "    Theme CSS:    Admin > Config > Theme > Custom CSS"
echo "    Logo:         Admin > Config > Theme > Logo"
echo "    Challenges:   Admin > Challenges"
echo ""

rm -f /tmp/ctfd_cust.txt
