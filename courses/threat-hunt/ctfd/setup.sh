#!/bin/bash
# =============================================================================
# Threat Hunt Lab — CTFd Challenge Seeder
# Usage: bash ctfd/setup.sh http://localhost:8000
# =============================================================================

set -e

CTFD_URL="${1:-http://localhost:8000}"
ADMIN_USER="admin"
ADMIN_EMAIL="admin@threathunt.lab"
ADMIN_PASS="ThreatHuntLab2024!"
EVENT_NAME="Threat Hunt Lab"

# Load .env
CTFD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "${CTFD_DIR}/.env" ]; then
    set -a; source "${CTFD_DIR}/.env"; set +a
fi

API="${CTFD_URL}/api/v1"
CT="Content-Type: application/json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[X]${NC} $1"; }

# ---------------------------------------------------------------------------
# Step 1: Initial Setup Wizard
# ---------------------------------------------------------------------------
info "Checking CTFd setup state..."
SETUP_PAGE=$(curl -s -c /tmp/ctfd_cookies.txt "${CTFD_URL}/setup" -L)
if echo "$SETUP_PAGE" | grep -q "nonce"; then
    info "Running initial setup wizard..."
    NONCE=$(echo "$SETUP_PAGE" | grep -o 'name="nonce"[^>]*value="[^"]*"' | grep -o 'value="[^"]*"' | sed 's/value="//;s/"$//')
    curl -s -b /tmp/ctfd_cookies.txt -c /tmp/ctfd_cookies.txt \
        -X POST "${CTFD_URL}/setup" \
        -d "ctf_name=${EVENT_NAME}&ctf_description=Threat+Hunt+Training+Lab&user_mode=users&name=${ADMIN_USER}&email=${ADMIN_EMAIL}&password=${ADMIN_PASS}&nonce=${NONCE}" \
        -o /dev/null
    info "Setup wizard complete"
else
    info "CTFd already configured"
fi

# ---------------------------------------------------------------------------
# Step 2: Login and get API token
# ---------------------------------------------------------------------------
info "Authenticating..."
LOGIN_PAGE=$(curl -s -c /tmp/ctfd_cookies.txt "${CTFD_URL}/login")
NONCE=$(echo "$LOGIN_PAGE" | grep -o 'name="nonce"[^>]*value="[^"]*"' | grep -o 'value="[^"]*"' | sed 's/value="//;s/"$//')
curl -s -b /tmp/ctfd_cookies.txt -c /tmp/ctfd_cookies.txt \
    -X POST "${CTFD_URL}/login" \
    -d "name=${ADMIN_USER}&password=${ADMIN_PASS}&nonce=${NONCE}" \
    -o /dev/null

ADMIN_PAGE=$(curl -s -b /tmp/ctfd_cookies.txt -L "${CTFD_URL}/admin/statistics")
CSRF_NONCE=$(echo "$ADMIN_PAGE" | grep -o "csrfNonce.*:.*\"[a-f0-9]*\"" | grep -o '"[a-f0-9]*"' | sed 's/"//g')

TOKEN_RESP=$(curl -s -b /tmp/ctfd_cookies.txt \
    -X POST "${API}/tokens" \
    -H "$CT" -H "CSRF-Token: ${CSRF_NONCE}" \
    -d '{"description":"threat-hunt-setup"}')
ADMIN_TOKEN=$(echo "$TOKEN_RESP" | grep -o '"value" *: *"[^"]*"' | sed 's/"value" *: *"//;s/"$//' || echo "")

if [ -z "$ADMIN_TOKEN" ]; then
    error "Failed to get API token"
    exit 1
fi
info "Got API token"

AUTH="Authorization: Token ${ADMIN_TOKEN}"

# ---------------------------------------------------------------------------
# Step 3: Create team accounts
# ---------------------------------------------------------------------------
info "Creating team accounts..."

declare -A TEAM_PASSWORDS
for i in $(seq 1 ${STUDENT_COUNT:-5}); do
    TEAM_NAME="team${i}"
    PASS_VAR="TEAM${i}_PASS"
    TEAM_PASS="${!PASS_VAR:-hunt4threats${i}}"

    curl -s -X POST "${API}/users" \
        -H "$AUTH" -H "$CT" \
        -d "{
            \"name\": \"${TEAM_NAME}\",
            \"email\": \"${TEAM_NAME}@threathunt.lab\",
            \"password\": \"${TEAM_PASS}\",
            \"type\": \"user\",
            \"verified\": true,
            \"hidden\": false
        }" > /dev/null
    TEAM_PASSWORDS["${TEAM_NAME}"]="${TEAM_PASS}"
    info "Created ${TEAM_NAME}"
done

# ---------------------------------------------------------------------------
# Step 4: Create challenges
# ---------------------------------------------------------------------------
info "Seeding challenges..."

create_challenge() {
    local name="$1" category="$2" description="$3" value=$4 flag="$5"

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

# ╔═══════════════════════════════════════════════════════════════╗
# ║ ORIENTATION — During lecture (trivial)                       ║
# ║ 8 challenges, need 4 to unlock next                         ║
# ╚═══════════════════════════════════════════════════════════════╝

create_challenge "Process Create" "Orientation" \
    "What Sysmon Event ID represents a process being created?\n\nA) 3\nB) 1\nC) 10\nD) 22" 25 "B"

create_challenge "DNS Log" "Orientation" \
    "Which Zeek log file records DNS queries and responses?\n\nA) conn.log\nB) http.log\nC) dns.log\nD) ssl.log" 25 "C"

create_challenge "MITRE Persistence" "Orientation" \
    "In MITRE ATT&CK, what tactic does 'Scheduled Task/Job' fall under?\n\nA) Execution\nB) Persistence\nC) Privilege Escalation\nD) Both B and C" 25 "D"

create_challenge "TTL Fingerprint" "Orientation" \
    "A packet arrives with TTL=128. What OS family most likely sent it?\n\nA) Linux\nB) Windows\nC) macOS\nD) Cisco IOS" 25 "B"

create_challenge "Parent Process" "Orientation" \
    "In Sysmon Event 1, what field shows which process spawned the new process?\n\nA) SourceImage\nB) CallerImage\nC) ParentImage\nD) OriginProcess" 25 "C"

create_challenge "lsass Alert" "Orientation" \
    "Sysmon Event 10 (ProcessAccess) targeting lsass.exe is a high-fidelity indicator of what technique?\n\nA) Lateral Movement\nB) Credential Dumping\nC) Privilege Escalation\nD) Defense Evasion" 25 "B"

create_challenge "KQL Basics" "Orientation" \
    "In Kibana (KQL), how do you search for all Sysmon process creation events?\n\nA) sysmon.event_id: 1\nB) event.code: 1\nC) EventID = 1\nD) winlog.event_id: \"1\"" 25 "D"

create_challenge "Conn Log Fields" "Orientation" \
    "In Zeek's conn.log, what field shows the total bytes sent by the originator?\n\nA) resp_bytes\nB) orig_bytes\nC) src_bytes\nD) tx_bytes\n\nHint: Zeek uses orig/resp, not src/dst." 25 "B"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ INITIAL TRIAGE — First hands-on (easy)                      ║
# ║ 8 challenges, need 4 to unlock next                         ║
# ╚═══════════════════════════════════════════════════════════════╝

create_challenge "Find the Victim" "Initial Triage" \
    "Query Kibana for Sysmon events. What is the hostname of the compromised workstation?\n\nSubmit as FLAG{HOSTNAME}\n\nHint: Look at the host.name field in any Sysmon event." 50 "FLAG{KIOSK-PUB-04}"

create_challenge "USB Insertion" "Initial Triage" \
    "A USB device was plugged into the victim. Find the Sysmon event that shows the USB driver loading.\n\nWhat time (UTC) was the device connected? Submit as FLAG{HH:MM}\n\nHint: Sysmon Event 6 (DriverLoaded) — look for USB-related drivers." 75 "FLAG{14:23}"

create_challenge "AppLocker Block" "Initial Triage" \
    "AppLocker blocked an initial execution attempt. What file was blocked?\n\nSubmit as FLAG{filename.ext}\n\nHint: Search the applocker index for Event ID 8004." 75 "FLAG{invoice.exe}"

create_challenge "Event Volume" "Initial Triage" \
    "How many total Sysmon events were generated on the victim in the 2-hour attack window?\n\nSubmit as FLAG{X} (round to nearest thousand)\n\nHint: Use Kibana's date histogram. The noise is the point." 50 "FLAG{47000}"

create_challenge "First and Last" "Initial Triage" \
    "What is the timestamp of the FIRST suspicious event (non-noise) and the LAST?\n\nSubmit the duration in minutes as FLAG{X}\n\nHint: The attack runs from initial LNK execution to final DNS exfil query." 100 "FLAG{94}"

create_challenge "Source of Truth" "Initial Triage" \
    "How many unique source IPs generated Sysmon events? Submit as FLAG{X}\n\nHint: Use Kibana aggregation on source.ip or host.ip." 50 "FLAG{1}"

create_challenge "The Attacker's Seat" "Initial Triage" \
    "Based on the USB insertion event and the public terminal naming convention (KIOSK-PUB-XX), what seat number was the attacker at?\n\nSubmit as FLAG{X}" 50 "FLAG{4}"

create_challenge "Log Gap" "Initial Triage" \
    "There's a 3-minute gap in Sysmon logging during the attack. Why?\n\nA) The attacker stopped Sysmon temporarily\nB) The system rebooted\nC) Network connectivity was lost\nD) The attacker cleared the log\n\nHint: Look for Sysmon Event 4 (Service State Change)." 75 "A"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ SYSMON TUNING — Noise reduction (easy-medium)               ║
# ║ 8 challenges, need 4 to unlock next                         ║
# ╚═══════════════════════════════════════════════════════════════╝

create_challenge "The Firehose" "Sysmon Tuning" \
    "Your sysmon index has ~47,000 events from the victim in 2 hours. What percentage are Event ID 1 (ProcessCreate)?\n\nA) 15%\nB) 40%\nC) 65%\nD) 85%\n\nHint: Use Kibana's visualization to break down by event.code." 50 "C"

create_challenge "Noise Floor" "Sysmon Tuning" \
    "Build a Kibana query that EXCLUDES events where ParentImage ends with svchost.exe. How many events remain?\n\nSubmit as FLAG{X} (round to nearest thousand)\n\nHint: NOT winlog.event_data.ParentImage: *svchost.exe" 75 "FLAG{28000}"

create_challenge "Browser Spawn" "Sysmon Tuning" \
    "Build this query: ParentImage contains 'chrome.exe' AND Image does NOT contain 'chrome.exe'. How many hits?\n\nSubmit as FLAG{X}\n\nThis is the single most valuable detection for a kiosk." 100 "FLAG{3}"

create_challenge "Top Talkers" "Sysmon Tuning" \
    "Create a Kibana aggregation: top 10 Image paths by event count for Event ID 1. What is the #1 most frequent process?\n\nSubmit as FLAG{process.exe}" 50 "FLAG{svchost.exe}"

create_challenge "Signal Extraction" "Sysmon Tuning" \
    "After excluding svchost.exe, chrome.exe, MsMpEng.exe (Defender), and RuntimeBroker.exe from ParentImage, how many Event ID 1 entries remain?\n\nSubmit as FLAG{X}\n\nThese are your signal." 100 "FLAG{127}"

create_challenge "DNS Noise" "Sysmon Tuning" \
    "In Sysmon Event 22 (DNS), how many queries go to *.microsoft.com or *.windowsupdate.com?\n\nA) <100\nB) 500-1000\nC) 2000-5000\nD) >10000\n\nThese should be in your Sysmon config exclusions." 50 "C"

create_challenge "Config Assessment" "Sysmon Tuning" \
    "The victim's Sysmon config uses onmatch='exclude' for ProcessCreate. What does this mean?\n\nA) Only excluded processes are logged\nB) Everything is logged EXCEPT the excluded processes\nC) Nothing is logged\nD) Only included processes are logged" 50 "B"

create_challenge "Core Strength Assessment" "Sysmon Tuning" \
    "Demonstrate a passing Air Force plank (1:30 minimum). The instructor will observe and provide the flag.\n\nYou must leave your terminal to complete this challenge." 200 "${PT_PLANK_FLAG:-FLAG{1:30}}"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ KILL CHAIN ANALYSIS — Trace the attack (medium)             ║
# ║ 10 challenges, need 5 to unlock next                        ║
# ╚═══════════════════════════════════════════════════════════════╝

create_challenge "Process Tree" "Kill Chain Analysis" \
    "Find the suspicious parent-child chain. What is the full process tree?\n\nSubmit as FLAG{grandparent>parent>child} using just exe names.\n\nHint: Look for cmd.exe spawning powershell.exe. What spawned cmd.exe?" 150 "FLAG{explorer.exe>cmd.exe>powershell.exe}"

create_challenge "Decode the Payload" "Kill Chain Analysis" \
    "The attacker used powershell.exe -enc with a base64-encoded command. Decode it.\n\nWhat domain does it reach out to? Submit as FLAG{domain}\n\nHint: Copy the -enc value, base64 -d it, or use CyberChef." 150 "FLAG{update-service.xyz}"

create_challenge "Persistence: Scheduled Task" "Kill Chain Analysis" \
    "Find the scheduled task the attacker created. What is the task name?\n\nSubmit as FLAG{TaskName}\n\nHint: Windows Security Event 4698 or Get-ScheduledTask on the victim." 125 "FLAG{WindowsUpdateService}"

create_challenge "Persistence: Registry" "Kill Chain Analysis" \
    "The attacker added a Registry Run key for persistence. What value name did they use?\n\nSubmit as FLAG{ValueName}\n\nHint: Sysmon Event 13 (RegistryValueSet) targeting CurrentVersion\\Run." 125 "FLAG{WindowsUpdateSvc}"

create_challenge "Defense Evasion: Masquerade" "Kill Chain Analysis" \
    "The attacker placed a binary named svchost.exe in an unusual location. Where?\n\nSubmit as FLAG{full\\path}\n\nHint: Real svchost.exe lives in C:\\Windows\\System32. This one doesn't." 125 "FLAG{C:\\Windows\\Temp\\svchost.exe}"

create_challenge "Credential Access" "Kill Chain Analysis" \
    "Find the Sysmon Event 10 where a process accessed lsass.exe. What process accessed it?\n\nSubmit as FLAG{process.exe}\n\nHint: TargetImage: *lsass.exe in the ProcessAccess events." 150 "FLAG{svchost.exe}"

create_challenge "C2 Beacon Interval" "Kill Chain Analysis" \
    "In Zeek dns.log, the attacker's C2 domain (update-service.xyz) is queried at a regular interval. What is the interval in seconds?\n\nSubmit as FLAG{X}\n\nHint: Sort DNS queries to that domain by timestamp, calculate the delta." 150 "FLAG{30}"

create_challenge "Lateral Movement" "Kill Chain Analysis" \
    "The attacker moved laterally via SMB. What internal IP did they connect to from the victim?\n\nSubmit as FLAG{IP}\n\nHint: Zeek conn.log or smb.log — look for 445/tcp connections to non-public IPs." 150 "FLAG{10.10.30.5}"

create_challenge "PowerShell History" "Kill Chain Analysis" \
    "PS Remote into your victim box and read the attacker's PowerShell history. What filename did they exfiltrate?\n\nSubmit as FLAG{filename}\n\nHint: C:\\Users\\Public\\...\\PSReadLine\\ConsoleHost_history.txt" 125 "FLAG{relief-ops.xlsx}"

create_challenge "Port Profile" "Kill Chain Analysis" \
    "The attacker ran discovery commands. Based on their 'net view' and 'arp -a' output in PS history, what were they looking for?\n\nA) Domain controllers\nB) Network shares on the relief ops VLAN\nC) Other public terminals\nD) DNS servers" 100 "B"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ ACTIVE RESPONSE — Live containment + Kansa + Arkime (m-hard) ║
# ║ 8 challenges, need 4 to unlock next                         ║
# ╚═══════════════════════════════════════════════════════════════╝

create_challenge "Contain the Host" "Active Response" \
    "PS Remote into your victim. Execute Invoke-Contain.ps1 with JumpBoxIP=10.10.1.1. Verify containment in Kibana.\n\nSubmit the Windows Event ID logged by the containment script as FLAG{X}\n\nHint: Check Application event log for ContainmentScript source." 200 "FLAG{9001}"

create_challenge "Verify Isolation" "Active Response" \
    "After containment: from the victim, can you still ping 8.8.8.8? Can you still reach 10.10.1.1?\n\nSubmit as FLAG{external_result,internal_result} where result is PASS or FAIL\n\nHint: ping 8.8.8.8 should fail. ping 10.10.1.1 should succeed." 150 "FLAG{FAIL,PASS}"

create_challenge "Logs Still Flowing" "Active Response" \
    "After containment, verify that Winlogbeat is still shipping events to ELK. Check Kibana for new events from the victim AFTER the containment timestamp.\n\nAre events still flowing? Submit FLAG{YES} or FLAG{NO}" 100 "FLAG{YES}"

create_challenge "Decontain" "Active Response" \
    "Run Invoke-Decontain.ps1. Verify in Kibana that the decontainment event (Event 9002) appears.\n\nWhat Windows Event ID is logged? Submit as FLAG{X}" 100 "FLAG{9002}"

create_challenge "Kansa: Autoruns" "Active Response" \
    "On your victim, examine the output of Get-ScheduledTask. How many tasks have 'powershell' in their command?\n\nSubmit as FLAG{X}\n\nHint: Get-ScheduledTask | Where-Object { \\$_.Actions.Execute -like '*powershell*' }" 125 "FLAG{1}"

create_challenge "Arkime: SMB Session" "Active Response" \
    "In Arkime (port 8005), search for SMB sessions involving the victim IP. What share name was accessed during lateral movement?\n\nSubmit as FLAG{sharename}\n\nHint: Filter by protocol=smb and look at the session details." 175 "FLAG{share}"

create_challenge "Arkime: DNS Exfil" "Active Response" \
    "In Arkime, filter for DNS sessions to update-service.xyz. How many unique DNS queries contain base64-encoded data in the subdomain?\n\nSubmit as FLAG{X}\n\nHint: Look for unusually long query names (>50 chars)." 175 "FLAG{12}"

create_challenge "Sit-Rep (Literally)" "Active Response" \
    "Complete the Air Force minimum sit-ups (42 in 1 minute). The instructor will count and provide the flag.\n\nYou must leave your terminal to complete this challenge." 200 "${PT_SITUP_FLAG:-FLAG{42}}"

# ╔═══════════════════════════════════════════════════════════════╗
# ║ DETECTION ENGINEERING — Hard + time sinks                    ║
# ║ 10 challenges, last category                                 ║
# ╚═══════════════════════════════════════════════════════════════╝

create_challenge "YARA: Fake svchost" "Detection Engineering" \
    "Write a YARA rule that detects the attacker's fake svchost.exe based on: it has an MZ header but is NOT in C:\\Windows\\System32\\.\n\nRun it against C:\\Windows\\Temp\\ on the victim.\n\nSubmit the flag found in the rule match output: FLAG{yara_detection_works}" 250 "FLAG{yara_detection_works}"

create_challenge "Kibana Alert: Browser Spawn" "Detection Engineering" \
    "Create a Kibana alert rule that fires when a browser process (chrome.exe, msedge.exe) spawns cmd.exe or powershell.exe.\n\nWhat is the minimum field combination needed?\n\nA) ParentImage + Image\nB) ParentImage + Image + CommandLine\nC) Image + CommandLine\nD) ParentImage only" 100 "A"

create_challenge "DNS Tunnel Decode" "Detection Engineering" \
    "The attacker exfiltrated data via DNS tunneling. The subdomain labels of queries to update-service.xyz contain base64-encoded data.\n\nExtract and decode all the subdomain labels. What is the first line of the decoded data?\n\nSubmit as FLAG{first_line}\n\nHint: tshark + base64 -d, or Zeek dns.log + jq + base64" 300 "FLAG{BEGIN_CERTIFICATE}"

create_challenge "Full Timeline" "Detection Engineering" \
    "Build a complete incident timeline from first artifact to last. Minimum 8 entries.\n\nSubmit the timestamp of the exfiltration completion (last DNS tunnel query) as FLAG{HH:MM:SS}\n\nHint: Correlate Sysmon + Zeek + Windows Security events." 250 "FLAG{15:57:23}"

create_challenge "Firewall Gap" "Detection Engineering" \
    "The attacker moved from VLAN 20 (public) to VLAN 30 (relief ops) via SMB. This should have been blocked.\n\nWhat firewall rule was missing?\n\nA) Block VLAN 20 → VLAN 30 TCP/445\nB) Block VLAN 20 → VLAN 10 TCP/445\nC) Block all inter-VLAN traffic\nD) Block VLAN 20 outbound entirely" 150 "A"

create_challenge "Sysmon Config Fix" "Detection Engineering" \
    "The current Sysmon config excluded svchost.exe parent processes. The attacker's renamed binary was called svchost.exe.\n\nWhat's the correct fix?\n\nA) Remove the svchost exclusion entirely\nB) Exclude by full path C:\\Windows\\System32\\svchost.exe, not just filename\nC) Add an include rule for svchost.exe in unusual paths\nD) Both B and C" 100 "D"

create_challenge "IOC Extraction" "Detection Engineering" \
    "Extract all Indicators of Compromise from this incident. How many unique IOCs (IPs, domains, file hashes, file paths) can you identify?\n\nSubmit as FLAG{X}\n\nHint: C2 domain, lateral movement IP, malicious binary hash, LNK paths, registry keys, scheduled task name..." 200 "FLAG{8}"

create_challenge "Brief the Commander" "Detection Engineering" \
    "Give a 5-minute verbal briefing to the instructor covering:\n1. What happened (kill chain summary)\n2. What the attacker got (impact)\n3. What failed in our defenses\n4. What we fix first\n\nWhiteboard allowed. Instructor provides the flag." 300 "FLAG{briefing_complete}"

create_challenge "Incident Report" "Detection Engineering" \
    "Based on the cafe's playbook PB-01, what is the FIRST action after detecting a compromised terminal?\n\nA) Reboot the machine\nB) Pull network at the managed switch port\nC) Run antivirus scan\nD) Call law enforcement" 100 "B"

create_challenge "WMI Persistence" "Detection Engineering" \
    "Advanced: The attacker ALSO set up a WMI event subscription for persistence. Can you find it?\n\nPS Remote to victim and run: Get-CimInstance -Namespace root/subscription -ClassName __EventConsumer\n\nSubmit the consumer name as FLAG{name}\n\nThis is the hardest persistence to find. Most analysts miss it." 300 "FLAG{WindowsUpdateConsumer}"

# ---------------------------------------------------------------------------
# Step 5: Apply Theme
# ---------------------------------------------------------------------------
info "Applying custom theme..."

THEME_CSS=""
if [ -f "${CTFD_DIR}/ctfd/theme.css" ]; then
    THEME_CSS=$(cat "${CTFD_DIR}/ctfd/theme.css")
fi

read -r -d '' CUSTOM_HEAD << 'HEADEOF' || true
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
HEADEOF

if [ -n "$THEME_CSS" ]; then
    CUSTOM_HEAD="${CUSTOM_HEAD}<style>${THEME_CSS}</style>"
fi

ESCAPED_HEAD=$(echo "$CUSTOM_HEAD" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo "\"\"")
curl -s -X PATCH "${API}/configs/theme_header" \
    -H "$AUTH" -H "$CT" \
    -d "{\"value\": ${ESCAPED_HEAD}}" > /dev/null && \
    info "Theme applied" || warn "Theme application failed"

# Scoreboard enhancements
if [ -f "${CTFD_DIR}/ctfd/scoreboard-enhancements.js" ]; then
    JS=$(cat "${CTFD_DIR}/ctfd/scoreboard-enhancements.js")
    FOOTER="<script>${JS}</script>"
    ESCAPED_FOOTER=$(echo "$FOOTER" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo "\"\"")
    curl -s -X PATCH "${API}/configs/theme_footer" \
        -H "$AUTH" -H "$CT" \
        -d "{\"value\": ${ESCAPED_FOOTER}}" > /dev/null && \
        info "Scoreboard enhancements applied" || warn "Scoreboard enhancements failed"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
info "50 challenges created across 6 progressive categories"
echo ""
echo "  Categories (unlock order):"
echo "    1. Orientation:           8 challenges  (trivial, during lecture)"
echo "    2. Initial Triage:        8 challenges  (easy)"
echo "    3. Sysmon Tuning:         8 challenges  (easy-medium)"
echo "    4. Kill Chain Analysis:   10 challenges (medium)"
echo "    5. Active Response:       8 challenges  (medium-hard)"
echo "    6. Detection Engineering: 10 challenges (hard, time sinks)"
echo ""
echo "  50% of a category must be solved to unlock the next."
echo ""
echo "  CREDENTIALS"
echo "  Admin: ${ADMIN_USER} / ${ADMIN_PASS}"
for i in $(seq 1 ${STUDENT_COUNT:-5}); do
    echo "  team${i} / ${TEAM_PASSWORDS[team${i}]}"
done
echo ""

# Save credentials
CREDS_FILE="${CTFD_DIR}/ctfd/credentials.txt"
echo "Admin: ${ADMIN_USER} / ${ADMIN_PASS}" > "$CREDS_FILE"
for i in $(seq 1 ${STUDENT_COUNT:-5}); do
    echo "team${i} / ${TEAM_PASSWORDS[team${i}]}" >> "$CREDS_FILE"
done
info "Credentials saved to ctfd/credentials.txt"

rm -f /tmp/ctfd_cookies.txt
