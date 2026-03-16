#!/bin/bash
# =============================================================================
# CTFd Auto-Provisioner
# Automatically sets up CTFd: admin account, team accounts, and challenges
# Usage: ./setup.sh [CTFD_URL]
# =============================================================================

set -euo pipefail

CTFD_URL="${1:-http://localhost:8000}"
ADMIN_USER="admin"
ADMIN_PASS="NmapLab2024!"
ADMIN_EMAIL="admin@training.lab"
EVENT_NAME="Nmap Training Lab"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; exit 1; }

# ---------------------------------------------------------------------------
# Wait for CTFd to be ready
# ---------------------------------------------------------------------------
info "Waiting for CTFd at ${CTFD_URL}..."
for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" "${CTFD_URL}" 2>/dev/null | grep -qE "200|302"; then
        info "CTFd is up!"
        break
    fi
    sleep 2
done

# ---------------------------------------------------------------------------
# Step 1: Complete initial setup wizard
# ---------------------------------------------------------------------------
info "Running initial setup wizard..."

# Get CSRF nonce from setup page
SETUP_PAGE=$(curl -s -c /tmp/ctfd_cookies.txt "${CTFD_URL}/setup")
NONCE=$(echo "$SETUP_PAGE" | grep -o 'name="nonce"[^>]*value="[^"]*"' | grep -o 'value="[^"]*"' | sed 's/value="//;s/"$//' || echo "")

if [ -n "$NONCE" ]; then
    # Submit setup form
    curl -s -b /tmp/ctfd_cookies.txt -c /tmp/ctfd_cookies.txt \
        -X POST "${CTFD_URL}/setup" \
        -d "ctf_name=${EVENT_NAME}&ctf_description=Nmap+Training+Lab&user_mode=users&name=${ADMIN_USER}&email=${ADMIN_EMAIL}&password=${ADMIN_PASS}&nonce=${NONCE}" \
        -o /dev/null
    info "Initial setup complete"
else
    warn "Setup already completed or nonce not found, skipping wizard"
fi

# ---------------------------------------------------------------------------
# Step 2: Login and get session
# ---------------------------------------------------------------------------
info "Logging in as admin..."

LOGIN_PAGE=$(curl -s -c /tmp/ctfd_cookies.txt "${CTFD_URL}/login")
NONCE=$(echo "$LOGIN_PAGE" | grep -o 'name="nonce"[^>]*value="[^"]*"' | grep -o 'value="[^"]*"' | sed 's/value="//;s/"$//' || echo "")

curl -s -b /tmp/ctfd_cookies.txt -c /tmp/ctfd_cookies.txt \
    -X POST "${CTFD_URL}/login" \
    -d "name=${ADMIN_USER}&password=${ADMIN_PASS}&nonce=${NONCE}" \
    -o /dev/null

# Get CSRF nonce from admin page
ADMIN_PAGE=$(curl -s -b /tmp/ctfd_cookies.txt -L "${CTFD_URL}/admin")
CSRF_NONCE=$(echo "$ADMIN_PAGE" | grep -o "csrfNonce.*:.*\"[a-f0-9]*\"" | grep -o '"[a-f0-9]*"' | sed 's/"//g' || echo "")

# Generate API token
TOKEN_RESP=$(curl -s -b /tmp/ctfd_cookies.txt \
    -X POST "${CTFD_URL}/api/v1/tokens" \
    -H "Content-Type: application/json" \
    -H "CSRF-Token: ${CSRF_NONCE}" \
    -d '{"description":"setup-script"}')

ADMIN_TOKEN=$(echo "$TOKEN_RESP" | grep -o '"value" *: *"[^"]*"' | sed 's/"value" *: *"//;s/"$//' || echo "")

if [ -z "$ADMIN_TOKEN" ]; then
    error "Failed to get API token. Check CTFd manually at ${CTFD_URL}"
fi

info "Got API token"

API="${CTFD_URL}/api/v1"
AUTH="Authorization: Token ${ADMIN_TOKEN}"
CT="Content-Type: application/json"

# ---------------------------------------------------------------------------
# Step 3: Create team accounts (team1 - team10)
# ---------------------------------------------------------------------------
info "Creating student accounts..."
echo ""

# Load passwords from .env file
ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

declare -A TEAM_PASSWORDS

for i in $(seq 1 10); do
    # Read password from env var TEAM{N}_PASS, fallback to default
    PASS_VAR="TEAM${i}_PASS"
    TEAM_PASS="${!PASS_VAR:-scan4flags${i}}"
    TEAM_NAME="team${i}"
    TEAM_EMAIL="team${i}@training.lab"

    USER_RESP=$(curl -s -X POST "${API}/users" \
        -H "$AUTH" -H "$CT" \
        -d "{
            \"name\": \"${TEAM_NAME}\",
            \"email\": \"${TEAM_EMAIL}\",
            \"password\": \"${TEAM_PASS}\",
            \"type\": \"user\",
            \"verified\": true,
            \"hidden\": false
        }")

    TEAM_PASSWORDS["${TEAM_NAME}"]="${TEAM_PASS}"
    info "Created ${TEAM_NAME} / ${TEAM_PASS}"
done

# ---------------------------------------------------------------------------
# Step 4: Seed Challenges
# ---------------------------------------------------------------------------
echo ""
info "Seeding challenges..."
echo ""

create_challenge() {
    local name="$1" category="$2" description="$3" value="$4" flag="$5"

    local resp
    resp=$(curl -s -X POST "${API}/challenges" \
        -H "$AUTH" -H "$CT" \
        -d "{
            \"name\": \"${name}\",
            \"category\": \"${category}\",
            \"description\": \"${description}\",
            \"value\": ${value},
            \"type\": \"standard\",
            \"state\": \"hidden\"
        }")

    local cid
    cid=$(echo "$resp" | grep -o '"id" *: *[0-9]*' | sed 's/"id" *: *//' | head -1 || echo "")

    if [ -z "$cid" ]; then
        warn "Failed to create challenge: ${name} (may already exist)"
        return
    fi

    curl -s -X POST "${API}/flags" \
        -H "$AUTH" -H "$CT" \
        -d "{
            \"challenge_id\": ${cid},
            \"content\": \"${flag}\",
            \"type\": \"static\"
        }" > /dev/null

    info "Created: ${name} (${value} pts) [${category}]"
}

# ==========================================================================
# TARGET MAP:
#   .10  webserver  SSH(22) HTTP(80) MySQL(3306) Dev(8888)
#   .20  mailserver SSH(22) SMTP(25) POP3(110) IMAP(143) Webmail(443)
#   .30  fileserver FTP(21) SSH(22) SMB(139,445)
#   .40  database   SSH(22) MySQL(3306) PostgreSQL(5432) Redis(6379)
#   .50  devbox     SSH(2222) DNS(5353) Apps(4444,5555,6666,9999)
#   .60  hardened   Port2, SSH(22222) Elite(31337) Slow(65000) [ICMP blocked]
#   .100-.106  distractors (printer, camera, monitoring, iot, test, vpn, voip)
# ==========================================================================

# ╔═══════════════════════════════════════════════════════════════╗
# ║ KNOWLEDGE CHECK - Available during lecture (trivial)         ║
# ║ 8 challenges, need 4 to unlock next                         ║
# ╚═══════════════════════════════════════════════════════════════╝
create_challenge "SYN Scan" "Knowledge Check" \
    "Which nmap flag performs a SYN (stealth) scan?\n\nA) -sT\nB) -sS\nC) -sU\nD) -sP\n\nSubmit just the letter." 25 "B"

create_challenge "Default Scan Scope" "Knowledge Check" \
    "By default, how many ports does nmap scan?\n\nA) 100\nB) 65535\nC) 1000\nD) 1024\n\nSubmit just the letter." 25 "C"

create_challenge "UDP Flag" "Knowledge Check" \
    "Which flag performs a UDP scan?\n\nA) -sU\nB) -sV\nC) -sN\nD) -sD\n\nSubmit just the letter." 25 "A"

create_challenge "OS Detection Flag" "Knowledge Check" \
    "Which flag enables OS detection?\n\nA) -sV\nB) -A\nC) -O\nD) -D\n\nSubmit the most specific one." 25 "C"

create_challenge "Well-Known Ports" "Knowledge Check" \
    "What is the well-known port range?\n\nA) 0-255\nB) 0-1023\nC) 1-1024\nD) 0-65535" 25 "B"

create_challenge "Three-Way Handshake" "Knowledge Check" \
    "Correct order of a TCP three-way handshake?\n\nA) SYN, ACK, SYN-ACK\nB) ACK, SYN, SYN-ACK\nC) SYN, SYN-ACK, ACK\nD) SYN-ACK, SYN, ACK" 25 "C"

create_challenge "TTL Analysis" "Knowledge Check" \
    "You run nmap and see TTL=128 in the response. What OS family is this most likely?\n\nA) Linux\nB) Windows\nC) Cisco IOS\nD) FreeBSD\n\n(Linux=64, Windows=128, Cisco=255)" 25 "B"

create_challenge "Scr1pt K1dd13" "Knowledge Check" \
    "What does the nmap output flag -oS do?\n\nA) Saves output to an SQLite database\nB) Outputs in 'script kiddie' format (l33t sp34k)\nC) Saves only open ports to a summary file\nD) Outputs in structured SNMP format\n\nHint: man nmap. Search for -oS. You might laugh." 25 "B"

create_challenge "Hidden in Plain Sight" "Knowledge Check" \
    "It's right in front of your eyes, you just need to see it.<!-- FLAG{inspect_element_is_your_friend} -->" 50 "FLAG{inspect_element_is_your_friend}"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ HOST DISCOVERY - First hands-on (easy)                       ║
# ║ 6 challenges, need 3 to unlock next                          ║
# ╚═══════════════════════════════════════════════════════════════╝
create_challenge "Ping Sweep" "Host Discovery" \
    "How many hosts respond to a ping sweep on 172.20.1.0/24? Submit as FLAG{X}.\n\nHint: nmap -sn 172.20.1.0/24\nNote: not every host responds..." 50 "FLAG{12}"

create_challenge "Find the Mail Server" "Host Discovery" \
    "What is the IP of the host running SMTP? Submit as FLAG{IP}.\n\nHint: nmap -p 25 172.20.1.0/24" 50 "FLAG{172.20.1.20}"

create_challenge "Ghost Host" "Host Discovery" \
    "One host doesn't respond to ping. What is its IP? Submit as FLAG{IP}.\n\nHint: Try nmap -Pn on IPs that don't appear in your ping sweep." 100 "FLAG{172.20.1.60}"

create_challenge "Port Profile: Windows or Linux?" "Host Discovery" \
    "172.20.1.104 has ports 22, 80, 3000, 8080 open. What OS is this most likely?\n\nA) Windows Server\nB) Linux\nC) macOS\nD) Network Appliance\n\n(Think: which OS typically runs SSH on 22 + web services?)" 50 "B"

create_challenge "Port Profile: Identify the Printer" "Host Discovery" \
    "One host has ports 80, 443, 515, and 9100 open. What is it?\n\nA) Web server\nB) Database server\nC) Network printer\nD) VPN gateway\n\n(Port 9100 = RAW/JetDirect, 515 = LPD)" 50 "C"

create_challenge "Count the Infrastructure" "Host Discovery" \
    "How many TOTAL hosts exist on 172.20.1.0/24 (including ones that don't ping back)? Submit as FLAG{X}.\n\nHint: You may need -Pn and to check a range of IPs systematically." 150 "FLAG{13}"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ PORT SCANNING - Enumeration skills (easy-medium)             ║
# ║ 8 challenges, need 4 to unlock next                          ║
# ╚═══════════════════════════════════════════════════════════════╝
create_challenge "Web Server Ports" "Port Scanning" \
    "How many TCP ports are open on 172.20.1.10? Submit as FLAG{X}.\n\nHint: nmap -p- 172.20.1.10" 75 "FLAG{5}"

create_challenge "Non-Standard Web Port" "Port Scanning" \
    "The web server has a dev portal on a non-standard port. What port? Submit as FLAG{PORT}." 75 "FLAG{8888}"

create_challenge "Mail Server Enumerate" "Port Scanning" \
    "How many ports are open on the mail server (172.20.1.20)? Submit as FLAG{X}." 75 "FLAG{6}"

create_challenge "File Server Protocols" "Port Scanning" \
    "The file server at 172.20.1.30 runs multiple file sharing protocols. Name them.\n\nA) FTP and NFS\nB) FTP and SMB\nC) SMB and NFS\nD) FTP, SMB, and NFS" 75 "B"

create_challenge "Database Host" "Port Scanning" \
    "How many different database services run on 172.20.1.40? Submit as FLAG{X}.\n\nHint: MySQL, PostgreSQL, Redis are all database services." 100 "FLAG{3}"

create_challenge "Dev Box Mess" "Port Scanning" \
    "How many TCP ports are open on the dev box (172.20.1.50)? Submit as FLAG{X}." 100 "FLAG{6}"

create_challenge "Hardened Full Scan" "Port Scanning" \
    "Scan ALL 65535 ports on 172.20.1.60 (the ghost host). How many TCP ports? Submit as FLAG{X}.\n\nRemember: -Pn required. This will take time." 200 "FLAG{8}"

create_challenge "What's the VoIP Box?" "Port Scanning" \
    "172.20.1.106 has ports 80, 5060, 5061, and 8088 open. What is this device?\n\nA) Web server\nB) Mail server\nC) VoIP PBX\nD) Monitoring system\n\n(Port 5060/5061 = SIP)" 75 "C"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ SERVICE DETECTION - Version analysis (medium)                ║
# ║ 8 challenges, need 4 to unlock next                          ║
# ╚═══════════════════════════════════════════════════════════════╝
create_challenge "SMTP Banner" "Service Detection" \
    "Grab the SMTP banner from the mail server. The flag is in the banner.\n\nnmap -sV -p 25 172.20.1.20" 100 "FLAG{smtp_banner_captured}"

create_challenge "FTP Banner" "Service Detection" \
    "Grab the FTP banner from the file server.\n\nnc 172.20.1.30 21" 100 "FLAG{ftp_anonymous_access}"

create_challenge "SSH on Wrong Port" "Service Detection" \
    "The dev box has SSH on a non-standard port. Find it and grab the banner flag.\n\nHint: It's above port 2000." 150 "FLAG{ssh_version_detected}"

create_challenge "Webmail Portal" "Service Detection" \
    "The mail server has a web interface. Find it and read the HTML source.\n\nHint: Not on port 80. Try other web ports." 150 "FLAG{webmail_portal_found}"

create_challenge "Identify the Camera" "Service Detection" \
    "Run version detection on 172.20.1.101. What brand of camera is it?\n\nA) Hikvision\nB) Axis\nC) Dahua\nD) Ring\n\nnmap -sV 172.20.1.101" 100 "B"

create_challenge "Version Fingerprint" "Service Detection" \
    "What web server software and version is the monitoring host (172.20.1.102) advertising on port 443?\n\nA) Apache 2.4\nB) Nginx 1.24\nC) Grafana v10.2.1\nD) IIS 10.0\n\nnmap -sV -p 443 172.20.1.102 or nc" 100 "C"

create_challenge "Cleartext Protocol Hunt" "Service Detection" \
    "The mail server runs both secure and insecure mail protocols. Which port gives you POP3 in cleartext?\n\nA) 110\nB) 143\nC) 993\nD) 995" 100 "A"

create_challenge "Service Behind the Port" "Service Detection" \
    "Port 9100 on the printer (172.20.1.100) is open. What protocol/service does this port typically indicate?\n\nA) HTTP\nB) JetDirect (RAW printing)\nC) MySQL\nD) SNMP\n\nHint: Think about what a printer does." 75 "B"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ ADVANCED RECON - Real analysis (medium-hard)                 ║
# ║ 8 challenges, need 4 to unlock next                          ║
# ║ Includes time sinks for advanced students                    ║
# ╚═══════════════════════════════════════════════════════════════╝
create_challenge "HTTP Headers" "Advanced Recon" \
    "The web server has a flag hidden in the HTTP headers (not the page body).\n\ncurl -I http://172.20.1.10 or nmap --script=http-headers" 150 "FLAG{http_header_hidden}"

create_challenge "Admin Panel" "Advanced Recon" \
    "The web server has an admin panel with credentials in the HTML source. Find it.\n\nHint: Try common paths like /admin/" 150 "FLAG{admin_panel_exposed}"

create_challenge "OS Detection" "Advanced Recon" \
    "What OS family is the web server running? Submit as FLAG{Linux}.\n\nsudo nmap -O 172.20.1.10" 150 "FLAG{Linux}"

create_challenge "SMB Guest Share" "Advanced Recon" \
    "The file server has an open SMB share. Find the flag.\n\nnmap --script=smb-enum-shares -p 445 172.20.1.30" 200 "FLAG{smb_guest_share_open}"

create_challenge "Dev Portal Leaked Creds" "Advanced Recon" \
    "The web server's dev portal on port 8888 has leaked database credentials in the source. What's the DB password?\n\nSubmit as FLAG{password}" 200 "FLAG{dev_password_123}"

create_challenge "Identify the IoT" "Advanced Recon" \
    "172.20.1.103 has port 1883 open. What protocol runs on this port?\n\nA) MQTT\nB) CoAP\nC) AMQP\nD) ZigBee\n\n(Common in IoT/smart building systems)" 100 "A"

create_challenge "Printer Deep Dive" "Advanced Recon" \
    "You found the network printer at 172.20.1.100. In a real pentest, why is an HP LaserJet interesting?\n\nA) It stores print job history with document contents\nB) Default admin credentials are common and rarely changed\nC) LDAP credentials for scan-to-email are often stored in cleartext\nD) All of the above" 100 "D"

create_challenge "TTL from the Field" "Advanced Recon" \
    "You scan 172.20.1.40 and see TTL=64 in responses. Combined with ports 22, 3306, 5432, and 6379, what OS?\n\nA) Windows Server 2022\nB) Linux\nC) Cisco IOS\nD) macOS\n\n(TTL=64 is Linux default. Windows=128, Cisco=255)" 100 "B"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ DEEP DIVE - Hard challenges + time sinks                     ║
# ║ 8 challenges, last category. Go nuts.                        ║
# ║ Mix of flags that take real work + analytical questions       ║
# ╚═══════════════════════════════════════════════════════════════╝
create_challenge "Outside the Top 1000" "Deep Dive" \
    "The hardened host has a service on a port below 10 that nmap's DEFAULT scan misses entirely. Find the flag.\n\nThis is the kind of thing you miss if you never use -p-." 300 "FLAG{port2_not_in_top1000}"

create_challenge "Elite Port" "Deep Dive" \
    "There's a service on a well-known 'elite' port on the hardened host (172.20.1.60). Find it.\n\nHint: This port number is legendary in hacker culture." 200 "FLAG{elite_port_31337}"

create_challenge "UDP Hunt" "Deep Dive" \
    "One service on the hardened host is only accessible via UDP. Discover it.\n\nnmap -sU -Pn 172.20.1.60 (UDP scanning is slow — be patient or target specific ports)" 250 "FLAG{udp_service_discovered}"

create_challenge "Patience Rewarded" "Deep Dive" \
    "A service on the hardened host is deliberately slow (3+ second delay before responding). Capture its banner.\n\nnc -w 10 172.20.1.60 65000 (wait for it...)" 250 "FLAG{patience_rewarded_65000}"

create_challenge "DNS Secrets" "Deep Dive" \
    "The dev box runs a DNS server on a non-standard port. Query flag.corp.local for a TXT record.\n\nFirst: find the DNS port. Then: dig @172.20.1.50 -p PORT flag.corp.local TXT" 250 "FLAG{dns_txt_record_found}"

create_challenge "Debug Console" "Deep Dive" \
    "A developer left a debug console exposed on the dev box. Find it and grab the flag.\n\nHint: nc to each open port on 172.20.1.50" 200 "FLAG{debug_console_exposed}"

create_challenge "The Forgotten Test Server" "Deep Dive" \
    "172.20.1.104 looks like a forgotten test server. What CI/CD tool is exposed on port 8080?\n\nA) GitLab CI\nB) Jenkins\nC) GitHub Actions\nD) CircleCI\n\nIn a real environment, this would be a critical finding. Exposed Jenkins = code execution." 150 "B"

create_challenge "Redis Without Auth" "Deep Dive" \
    "The database server's Redis instance has no authentication. Use nmap to prove it and think about why this matters.\n\nnmap --script=redis-info -p 6379 172.20.1.40\n\nWhat can an attacker do with unauthenticated Redis?\n\nA) Read/write arbitrary data\nB) Write SSH keys to gain shell access\nC) Execute Lua scripts on the server\nD) All of the above" 200 "D"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ BONUS ROUND - Creative challenges that reward curiosity      ║
# ╚═══════════════════════════════════════════════════════════════╝
create_challenge "What the Bots Know" "Advanced Recon" \
    "Good scanners read what crawlers can't. The web server at 172.20.1.10 has a file that tells search engines where NOT to look. Maybe you should look there.\n\nHint: What file do well-behaved robots read before exploring?" 200 "FLAG{robots_txt_reveals_all}"

create_challenge "Keyring Left in the Open" "Advanced Recon" \
    "The web server's robots.txt points to several directories. One of them has API keys that should never be public.\n\nHint: /robots.txt told you where the bodies are buried. Follow the breadcrumbs." 200 "FLAG{api_keys_in_robots}"

create_challenge "Token Trouble" "Deep Dive" \
    "The web server has an app on port 3000. It gives you a guest token. The admin panel wants more.\n\nThe token is a JWT. The 'secret' to cracking it isn't very secret at all.\n\nHint: Decode the JWT (it's just base64). Change what needs changing. Re-sign it. The key is... elementary." 350 "FLAG{jwt_admin_bypass}"

create_challenge "Speak the Protocol" "Deep Dive" \
    "The mail server has a service on port 2525 that wants a conversation, not just a connection. You can't just grab a banner — you have to TALK to it.\n\nHint: It speaks SMTP. Be polite — say HELO. Introduce yourself (MAIL FROM). Then ask for what you want (RCPT TO). Use nc." 300 "FLAG{smtp_conversation_complete}"

create_challenge "Knock Knock" "Deep Dive" \
    "Port 1337 on the hardened host is locked. But the door has a combination lock — you just have to knock in the right order.\n\nHint: Three knocks. Ascending. Round numbers. Think thousands. You have 15 seconds between knocks.\n\nnc -zv 172.20.1.60 <port1> && nc -zv 172.20.1.60 <port2> && nc -zv 172.20.1.60 <port3> && nc 172.20.1.60 1337" 400 "FLAG{port_knock_master}"

create_challenge "Core Strength Assessment" "Advanced Recon" \
    "Demonstrate a passing Air Force plank (1:30 minimum). The instructor will observe and provide the flag.\n\nYou must leave your terminal to complete this challenge.\n\nHint: The flag is your time. Can you hold it together under pressure?" 200 "${PT_PLANK_FLAG:-FLAG{1:30}}"

create_challenge "Sit-Rep (Literally)" "Port Scanning" \
    "Complete the Air Force minimum sit-ups (42 in 1 minute). The instructor will count and provide the flag.\n\nYou must leave your terminal to complete this challenge.\n\nHint: Sometimes the hardest ports to crack aren't on a network." 200 "${PT_SITUP_FLAG:-FLAG{42}}"

create_challenge "Dev Portal Creds" "Advanced Recon" \
    "The web server's dev portal is leaking like a sieve. Someone left database credentials right in the HTML.\n\nHint: Port 8888 has secrets hiding in plain sight. View source." 150 "FLAG{dev_password_123}"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ NMAP MASTERY - Gotcha questions from the man page            ║
# ║ Tests whether you've actually READ the manual                ║
# ╚═══════════════════════════════════════════════════════════════╝
create_challenge "Ghost File" "Deep Dive" \
    "You run: nmap -iL .hidden_hosts\n\nThe file .hidden_hosts does not exist. How many hosts does nmap scan?\n\nA) 0 — nmap errors out\nB) 1 — it scans localhost as fallback\nC) 256 — it defaults to the local /24\nD) It hangs waiting for stdin\n\nHint: Try it. What actually happens?" 150 "A"

create_challenge "List Scan Gotcha" "Deep Dive" \
    "You run: nmap -sL 10.0.0.0/8\n\nHow many hosts are actually SCANNED (probed with packets)?\n\nA) 16,777,216\nB) 16,777,214\nC) 254\nD) 0\n\nHint: Read what -sL actually does. Very carefully. List. Scan." 200 "D"

create_challenge "Top Ports Deep Cut" "Deep Dive" \
    "Run: nmap --top-ports 10 -v -oG - 127.0.0.1\n\nLook at the 'Ports scanned' line in the output. What is the LAST port in the top 10 list? Submit as FLAG{PORT}.\n\nHint: Don't guess. Run it. Read the output." 150 "FLAG{3389}"

create_challenge "The Verbose Trick" "Service Detection" \
    "While an nmap scan is running, you can press a key to increase verbosity and see results as they come in. What key?\n\nA) v\nB) i\nC) +\nD) Enter\n\nHint: man nmap, search for 'runtime interaction'" 50 "A"

create_challenge "Reason Code" "Port Scanning" \
    "You scan a host and see a port marked as 'open' with reason 'syn-ack'. What scan type produced this?\n\nA) -sT (TCP connect)\nB) -sS (SYN stealth)\nC) -sU (UDP)\nD) -sN (TCP NULL)\n\nHint: SYN scan sends SYN, gets SYN-ACK back = open. The --reason flag shows this." 75 "B"

create_challenge "Output Archaeology" "Service Detection" \
    "You find an old scan file. The first line says:\n\n# Nmap 7.93 scan initiated Fri Mar 14 12:00:00 2026\n\nWhat output format is this?\n\nA) Normal (-oN)\nB) XML (-oX)\nC) Grepable (-oG)\nD) Script kiddie (-oS)\n\nHint: The # comment prefix is the giveaway." 50 "C"

create_challenge "CIDR Math" "Host Discovery" \
    "Your commander says 'scan the 172.16.0.0/20 subnet.' How many IP addresses does that include?\n\nA) 256\nB) 1,024\nC) 4,096\nD) 8,192\n\nHint: /20 means 32-20 = 12 host bits. 2^12 = ?" 50 "C"

# ---------------------------------------------------------------------------
# Step 5: Apply Custom CSS Theme
# ---------------------------------------------------------------------------
info "Applying custom theme..."

read -r -d '' CUSTOM_HEAD << 'HEADEOF' || true
<script src="https://cdn.tailwindcss.com"></script>
<script>tailwind.config={prefix:'tw-',corePlugins:{preflight:false},theme:{extend:{colors:{cyber:'#00ff41',cyberdark:'#00cc33',accent:'#ff6b35',card:'#1a1a2e',deep:'#0f0f23'}}}}</script>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
@keyframes scanline{0%{transform:translateY(-100%)}100%{transform:translateY(100vh)}}
@keyframes glow-pulse{0%,100%{opacity:.6}50%{opacity:1}}
@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}
@keyframes gradient-shift{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
@keyframes fade-up{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
</style>
HEADEOF

# Build combined theme_header (fonts + animations + CSS all in one <style> block)
# Write to file then use Python in Docker for proper JSON escaping
THEME_CSS_FILE="$(dirname "$0")/theme.css"

read -r -d '' CUSTOM_CSS << 'CSSEOF' || true
:root {
  --primary: #00ff41;
  --primary-dim: rgba(0,255,65,.15);
  --primary-glow: rgba(0,255,65,.4);
  --accent: #ff6b35;
  --accent-glow: rgba(255,107,53,.4);
  --bg: #0a0a14;
  --bg-elevated: #0f0f23;
  --card: #141428;
  --card-hover: #1a1a3a;
  --border: rgba(0,255,65,.12);
  --border-hover: rgba(0,255,65,.35);
  --text: #e8e8f0;
  --text-dim: #8888aa;
  --success: #00ff41;
  --danger: #ff4757;
  --radius-sm: 8px;
  --radius-md: 14px;
  --radius-lg: 20px;
  --radius-xl: 28px;
}

* { transition: all .2s ease !important; }

body {
  background: var(--bg) !important;
  color: var(--text) !important;
  font-family: 'Inter', -apple-system, sans-serif !important;
  overflow-x: hidden !important;
}

body::before {
  content: '';
  position: fixed;
  top: 0; left: 0; right: 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, var(--primary), transparent);
  animation: glow-pulse 3s ease-in-out infinite;
  z-index: 9999;
}

/* ═══════════════ NAVBAR ═══════════════ */
.navbar {
  background: rgba(15,15,35,.85) !important;
  backdrop-filter: blur(20px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(180%) !important;
  border: none !important;
  border-bottom: 1px solid var(--border) !important;
  box-shadow: 0 4px 30px rgba(0,0,0,.4) !important;
  padding: 12px 0 !important;
}
.navbar-brand {
  color: var(--primary) !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-weight: 700 !important;
  font-size: 1.3em !important;
  letter-spacing: 2px !important;
  text-shadow: 0 0 20px var(--primary-glow) !important;
}
.nav-link {
  color: var(--text-dim) !important;
  font-weight: 500 !important;
  font-size: .95em !important;
  padding: 8px 16px !important;
  border-radius: var(--radius-sm) !important;
  letter-spacing: .5px !important;
}
.nav-link:hover, .nav-link.active {
  color: var(--primary) !important;
  background: var(--primary-dim) !important;
  text-shadow: 0 0 8px var(--primary-glow) !important;
}

/* ═══════════════ HERO / JUMBOTRON ═══════════════ */
.jumbotron {
  background: linear-gradient(135deg, var(--card) 0%, var(--bg-elevated) 100%) !important;
  border: 1px solid var(--border) !important;
  border-radius: var(--radius-xl) !important;
  padding: 48px !important;
  box-shadow: 0 8px 40px rgba(0,0,0,.5), inset 0 1px 0 rgba(255,255,255,.03) !important;
  position: relative !important;
  overflow: hidden !important;
}
.jumbotron::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: radial-gradient(ellipse at 20% 50%, var(--primary-dim) 0%, transparent 60%);
  pointer-events: none;
}

/* ═══════════════ CARDS ═══════════════ */
.card {
  background: var(--card) !important;
  border: 1px solid var(--border) !important;
  border-radius: var(--radius-lg) !important;
  box-shadow: 0 4px 24px rgba(0,0,0,.3), inset 0 1px 0 rgba(255,255,255,.02) !important;
  color: var(--text) !important;
  overflow: hidden !important;
}
.card:hover {
  border-color: var(--border-hover) !important;
  box-shadow: 0 8px 40px rgba(0,0,0,.4), 0 0 20px var(--primary-dim) !important;
  transform: translateY(-2px) !important;
}

/* ═══════════════ CHALLENGE BUTTONS ═══════════════ */
.challenge-button {
  background: linear-gradient(145deg, var(--card), var(--bg-elevated)) !important;
  border: 1px solid var(--border) !important;
  border-radius: var(--radius-md) !important;
  color: var(--text) !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-weight: 600 !important;
  padding: 16px !important;
  position: relative !important;
  overflow: hidden !important;
  animation: fade-up .5s ease both !important;
}
.challenge-button::before {
  content: '';
  position: absolute;
  top: 0; left: -100%;
  width: 100%; height: 100%;
  background: linear-gradient(90deg, transparent, rgba(0,255,65,.06), transparent);
  transition: left .6s ease !important;
}
.challenge-button:hover::before { left: 100%; }
.challenge-button:hover {
  border-color: var(--primary) !important;
  box-shadow: 0 0 30px var(--primary-dim), 0 8px 32px rgba(0,0,0,.4), inset 0 0 40px rgba(0,255,65,.03) !important;
  transform: translateY(-3px) scale(1.01) !important;
  color: var(--primary) !important;
}
.challenge-button .challenge-name {
  font-size: 1.05em !important;
}
.challenge-button .challenge-points {
  color: var(--primary) !important;
  font-weight: 700 !important;
  text-shadow: 0 0 8px var(--primary-glow) !important;
}
.challenge-button.solved {
  background: linear-gradient(145deg, #0d2818, #163d28) !important;
  border-color: #2d6a4f !important;
}
.challenge-button.solved::after {
  content: '\2713';
  position: absolute;
  top: 10px; right: 14px;
  color: var(--success);
  font-size: 1.4em;
  text-shadow: 0 0 10px var(--primary-glow);
}

/* ═══════════════ BUTTONS ═══════════════ */
.btn-primary, .btn-outline-primary {
  background: linear-gradient(135deg, #00ff41 0%, #00cc33 50%, #00ff41 100%) !important;
  background-size: 200% 200% !important;
  animation: gradient-shift 3s ease infinite !important;
  border: none !important;
  color: #000 !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-weight: 700 !important;
  font-size: .85em !important;
  letter-spacing: 1.5px !important;
  text-transform: uppercase !important;
  border-radius: var(--radius-sm) !important;
  padding: 10px 24px !important;
  box-shadow: 0 2px 12px var(--primary-dim) !important;
}
.btn-primary:hover, .btn-outline-primary:hover {
  transform: translateY(-2px) !important;
  box-shadow: 0 6px 24px var(--primary-glow) !important;
}
.btn-primary:active { transform: translateY(0) scale(.98) !important; }

.btn-outline-secondary, .btn-secondary {
  background: transparent !important;
  border: 1px solid var(--border-hover) !important;
  color: var(--text-dim) !important;
  border-radius: var(--radius-sm) !important;
}
.btn-outline-secondary:hover { border-color: var(--primary) !important; color: var(--primary) !important; }

/* ═══════════════ HEADINGS ═══════════════ */
h1, h2, h3 {
  font-family: 'JetBrains Mono', monospace !important;
  color: var(--primary) !important;
  text-shadow: 0 0 20px rgba(0,255,65,.2) !important;
  letter-spacing: 1px !important;
}
h4, h5, h6 { color: var(--text) !important; font-weight: 600 !important; }

/* ═══════════════ MODALS ═══════════════ */
.modal-content {
  background: var(--card) !important;
  border: 1px solid var(--border-hover) !important;
  border-radius: var(--radius-xl) !important;
  box-shadow: 0 25px 80px rgba(0,0,0,.7), 0 0 40px var(--primary-dim) !important;
  color: var(--text) !important;
  overflow: hidden !important;
}
.modal-header {
  background: linear-gradient(135deg, var(--bg-elevated), var(--card)) !important;
  border-bottom: 1px solid var(--border) !important;
  padding: 20px 28px !important;
}
.modal-title {
  font-family: 'JetBrains Mono', monospace !important;
  color: var(--primary) !important;
  font-weight: 700 !important;
  text-shadow: 0 0 15px var(--primary-glow) !important;
}
.modal-body { padding: 28px !important; line-height: 1.7 !important; }
.modal-footer {
  border-top: 1px solid var(--border) !important;
  padding: 16px 28px !important;
  background: rgba(0,0,0,.15) !important;
}
.modal-backdrop.show { opacity: .75 !important; backdrop-filter: blur(4px) !important; }
.close, .btn-close { color: var(--text-dim) !important; text-shadow: none !important; }

/* ═══════════════ FORMS ═══════════════ */
.form-control, input[type="text"], input[type="password"], textarea, select {
  background: var(--bg) !important;
  border: 1px solid var(--border) !important;
  color: var(--text) !important;
  border-radius: var(--radius-sm) !important;
  padding: 10px 16px !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-size: .9em !important;
}
.form-control:focus, input:focus, textarea:focus {
  border-color: var(--primary) !important;
  box-shadow: 0 0 0 3px var(--primary-dim), 0 0 20px var(--primary-dim) !important;
  outline: none !important;
}
::placeholder { color: var(--text-dim) !important; opacity: .5 !important; }

/* ═══════════════ TABLES / SCOREBOARD ═══════════════ */
.table {
  background: var(--card) !important;
  color: var(--text) !important;
  border-radius: var(--radius-md) !important;
  overflow: hidden !important;
  border-collapse: separate !important;
  border-spacing: 0 !important;
}
.table thead th {
  background: linear-gradient(180deg, #16213e, var(--bg-elevated)) !important;
  color: var(--primary) !important;
  border: none !important;
  border-bottom: 2px solid var(--border) !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-size: .78em !important;
  font-weight: 600 !important;
  letter-spacing: 1.5px !important;
  text-transform: uppercase !important;
  padding: 14px 16px !important;
}
.table td {
  border: none !important;
  border-bottom: 1px solid rgba(255,255,255,.03) !important;
  padding: 12px 16px !important;
  font-size: .93em !important;
}
.table tbody tr { transition: all .15s ease !important; }
.table tbody tr:hover { background: rgba(0,255,65,.04) !important; }
.table tbody tr:first-child td { font-weight: 600 !important; color: var(--primary) !important; }

/* ═══════════════ ALERTS ═══════════════ */
.alert {
  border-radius: var(--radius-md) !important;
  border: 1px solid !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-size: .9em !important;
  padding: 14px 20px !important;
}
.alert-success {
  background: rgba(0,255,65,.08) !important;
  border-color: rgba(0,255,65,.25) !important;
  color: var(--success) !important;
}
.alert-danger {
  background: rgba(255,71,87,.08) !important;
  border-color: rgba(255,71,87,.25) !important;
  color: var(--danger) !important;
}

/* ═══════════════ BADGES / CATEGORY PILLS ═══════════════ */
.badge {
  border-radius: 20px !important;
  padding: 5px 14px !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-size: .75em !important;
  font-weight: 600 !important;
  letter-spacing: .5px !important;
  border: 1px solid rgba(255,255,255,.1) !important;
}
.badge-primary, .badge-success {
  background: var(--primary-dim) !important;
  color: var(--primary) !important;
  border-color: rgba(0,255,65,.25) !important;
}

/* ═══════════════ PAGINATION ═══════════════ */
.page-link {
  background: var(--card) !important;
  border: 1px solid var(--border) !important;
  color: var(--text-dim) !important;
  border-radius: var(--radius-sm) !important;
  margin: 0 3px !important;
}
.page-link:hover { background: var(--primary-dim) !important; color: var(--primary) !important; }
.page-item.active .page-link {
  background: var(--primary) !important;
  color: #000 !important;
  border-color: var(--primary) !important;
}

/* ═══════════════ FOOTER ═══════════════ */
footer {
  background: rgba(15,15,35,.9) !important;
  backdrop-filter: blur(10px) !important;
  border-top: 1px solid var(--border) !important;
  padding: 20px 0 !important;
}
footer a { color: var(--text-dim) !important; }
footer a:hover { color: var(--primary) !important; }

/* ═══════════════ SCROLLBAR ═══════════════ */
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: var(--bg); }
::-webkit-scrollbar-thumb { background: rgba(0,255,65,.2); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: rgba(0,255,65,.4); }

/* ═══════════════ SELECTION ═══════════════ */
::selection { background: var(--primary); color: #000; }

/* ═══════════════ LINKS ═══════════════ */
a { color: var(--primary) !important; text-decoration: none !important; }
a:hover { color: #33ff66 !important; text-shadow: 0 0 8px var(--primary-dim) !important; }

/* ═══════════════ CATEGORY TABS ═══════════════ */
.nav-tabs { border-bottom: 2px solid var(--border) !important; }
.nav-tabs .nav-link {
  border: none !important;
  border-bottom: 2px solid transparent !important;
  color: var(--text-dim) !important;
  font-family: 'JetBrains Mono', monospace !important;
  font-size: .85em !important;
  padding: 10px 20px !important;
  margin-bottom: -2px !important;
}
.nav-tabs .nav-link:hover { border-bottom-color: var(--primary-dim) !important; color: var(--primary) !important; }
.nav-tabs .nav-link.active {
  background: transparent !important;
  border-bottom-color: var(--primary) !important;
  color: var(--primary) !important;
  text-shadow: 0 0 10px var(--primary-dim) !important;
}

/* ═══════════════ CONTAINER WIDTHS ═══════════════ */
.container { max-width: 1200px !important; }

/* ═══════════════ SMOOTH ENTRY ═══════════════ */
.challenge-button:nth-child(1){animation-delay:.05s!important}
.challenge-button:nth-child(2){animation-delay:.1s!important}
.challenge-button:nth-child(3){animation-delay:.15s!important}
.challenge-button:nth-child(4){animation-delay:.2s!important}
.challenge-button:nth-child(5){animation-delay:.25s!important}
.challenge-button:nth-child(6){animation-delay:.3s!important}
.challenge-button:nth-child(7){animation-delay:.35s!important}
.challenge-button:nth-child(8){animation-delay:.4s!important}
.challenge-button:nth-child(9){animation-delay:.45s!important}
.challenge-button:nth-child(10){animation-delay:.5s!important}
CSSEOF

# Write CSS to file
echo "$CUSTOM_CSS" > "$THEME_CSS_FILE"

# Use Docker Python to create properly escaped JSON payload
CTFD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
docker run --rm -v "${CTFD_DIR}/ctfd:/data" python:3.11-alpine python3 -c "
import json
css = open('/data/theme.css').read()
header = '<script src=\"https://cdn.tailwindcss.com\"></script>' + \
'<script>tailwind.config={prefix:\"tw-\",corePlugins:{preflight:false}}</script>' + \
'<link href=\"https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Inter:wght@400;500;600;700&display=swap\" rel=\"stylesheet\">' + \
'<style>' + \
'@keyframes glow-pulse{0%,100%{opacity:.6}50%{opacity:1}}' + \
'@keyframes gradient-shift{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}' + \
'@keyframes fade-up{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}' + \
css + '</style>'
with open('/data/theme_header_payload.json','w') as f:
    json.dump({'value': header}, f)
print('Payload ready')
" 2>/dev/null

# Apply via theme_header (the correct config key for CTFd 3.x core theme)
curl -s -o /dev/null -w "" -X PATCH "${API}/configs/theme_header" \
    -H "$AUTH" -H "$CT" \
    -d @"$(dirname "$0")/theme_header_payload.json" && \
    info "Theme applied (fonts + animations + CSS)" || \
    warn "Could not apply theme - set manually in Admin > Config > Theme Header"

# ---------------------------------------------------------------------------
# Step 6: Print Summary
# Apply scoreboard enhancements via theme_footer
SCOREBOARD_JS="$(dirname "$0")/scoreboard-enhancements.js"
if [ -f "$SCOREBOARD_JS" ]; then
    docker run --rm -v "${CTFD_DIR}/ctfd:/data" python:3.11-alpine python3 -c "
import json
js = open('/data/scoreboard-enhancements.js').read()
footer = '<script>' + js + '</script>'
with open('/data/footer_payload.json','w') as f:
    json.dump({'value': footer}, f)
print('Payload ready')
" 2>/dev/null
    curl -s -o /dev/null -w "" -X PATCH "${API}/configs/theme_footer" \
        -H "$AUTH" -H "$CT" \
        -d @"$(dirname "$0")/footer_payload.json" && \
        info "Scoreboard enhancements applied (live ticker, confetti)" || \
        warn "Could not apply scoreboard enhancements"
    rm -f "$(dirname "$0")/footer_payload.json"
fi

# ---------------------------------------------------------------------------
echo ""
echo "================================================================="
echo ""
info "CTFd setup complete!"
echo ""
echo -e "${CYAN}  ADMIN ACCOUNT${NC}"
echo "  URL:      ${CTFD_URL}"
echo "  Username: ${ADMIN_USER}"
echo "  Password: ${ADMIN_PASS}"
echo ""
echo -e "${CYAN}  TEAM CREDENTIALS (hand these out to students)${NC}"
echo "  ┌──────────┬──────────┐"
echo "  │ Username │ Password │"
echo "  ├──────────┼──────────┤"
for i in $(seq 1 10); do
    printf "  │ %-8s │ %-8s │\n" "team${i}" "${TEAM_PASSWORDS[team${i}]}"
done
echo "  └──────────┴──────────┘"
echo ""
info "52 challenges created across 6 progressive categories"
echo ""
echo "  Categories (unlock order):"
echo "    1. Knowledge Check:    9 challenges   (trivial, during lecture)"
echo "    2. Host Discovery:     7 challenges   (easy)"
echo "    3. Port Scanning:      9 challenges   (easy-medium)"
echo "    4. Service Detection:  10 challenges  (medium)"
echo "    5. Advanced Recon:     10 challenges  (medium-hard)"
echo "    6. Deep Dive:          15 challenges  (hard, time sinks)"
echo ""
echo "  50% of a category must be solved to unlock the next."
echo "  Hard challenges in each category keep advanced students busy"
echo "  while others progress."
echo ""

# Save credentials to file
CREDS_FILE="$(dirname "$0")/credentials.txt"
{
    echo "=== Nmap Training Lab - Credentials ==="
    echo "Generated: $(date)"
    echo ""
    echo "ADMIN"
    echo "  URL:      ${CTFD_URL}"
    echo "  Username: ${ADMIN_USER}"
    echo "  Password: ${ADMIN_PASS}"
    echo ""
    echo "TEAM CREDENTIALS"
    for i in $(seq 1 10); do
        echo "  team${i} / ${TEAM_PASSWORDS[team${i}]}"
    done
} > "${CREDS_FILE}"

info "Credentials saved to ${CREDS_FILE}"

# Cleanup
rm -f /tmp/ctfd_cookies.txt
