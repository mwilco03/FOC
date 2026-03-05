# FOC - Future Operators Course

Interactive study tools for **networking**, **scripting**, **data analysis**, and **security forensics**, built as a GitHub Pages site.

## Quick Start

> **Live Site:** [mwilco03.github.io/FOC](https://mwilco03.github.io/FOC/)

### Networking Tools

| Tool | Link | Description |
|------|------|-------------|
| **NetDrill** | [Open](https://mwilco03.github.io/FOC/Networking/subnetting.html) | Main interactive study platform — OSI layers, protocol quiz, number systems, subnet math, calculator, and practice |
| **Subnet Invaders** | [Open](https://mwilco03.github.io/FOC/Networking/invaders.html) | Space Invaders quiz game — 8 waves of networking questions |
| **Subnet Quest** | [Open](https://mwilco03.github.io/FOC/Networking/quest.html) | Turn-based RPG with boss-fight subnet tables |
| **OSI Tower** | [Open](https://mwilco03.github.io/FOC/Networking/tower.html) | Progressive 3-stage OSI model builder |
| **Bit Flip** | [Open](https://mwilco03.github.io/FOC/Networking/bitflip.html) | Toggle 32 bits to build CIDR subnet masks |
| **Hex Trainer** | [Open](https://mwilco03.github.io/FOC/Networking/hex.html) | Guided long-division hex conversion trainer |
| **PCAP Forensics** | [Open](https://mwilco03.github.io/FOC/Networking/pcap-challenge.html) | Analyze simulated packet captures — find scans, credentials, DNS tunneling |
| **Subnetting Sheet** | [Open](https://mwilco03.github.io/FOC/Networking/SubnettingSheet.html) | Interactive subnetting notes & homework with editable cells |

### Scripting & Data Labs

| Lab | Link | Description |
|-----|------|-------------|
| **Python Lab** | [Open](https://mwilco03.github.io/FOC/Challenges1.html) | Interactive reference, 20 challenge drills, 20-question quiz |
| **PowerShell Lab** | [Open](https://mwilco03.github.io/FOC/Challenges2.html) | Cmdlet reference, 20 admin challenge drills, 20-question quiz |
| **Batch Lab** | [Open](https://mwilco03.github.io/FOC/Challenges3.html) | Variable/loop/file reference, 15 fill-in-the-blank drills, 15-question quiz |
| **Bash Lab** | [Open](https://mwilco03.github.io/FOC/Challenges4.html) | Text processing & scripting reference, 20 challenge drills, 20-question quiz |
| **Data & APIs Lab** | [Open](https://mwilco03.github.io/FOC/Challenges5.html) | JSON, YAML, REST APIs, curl, jq, regex — live explorer, 20 drills, 20-question quiz |

### CDA-B Course Modules

| Module | Topic | File(s) |
|--------|-------|---------|
| **M10** | Switching — Layer 2, MAC addresses, Cisco privilege levels | `CDA-B/M10-*.md` |
| **M11** | Protocol Basics — SMB, RDP, NetBIOS, firewalls, IDS/IPS, network mapping | `CDA-B/M11.md`, `M11-L.md` |
| **M12** | Wireless Networking — 802.11 standards, WLAN architecture, WPA2/WPA3, troubleshooting | `CDA-B/M12-Wireless.md` |
| **M13** | Infrastructure Services — DHCP, DNS, NAT, NTP, SNMP, Syslog | `CDA-B/M13.md` |
| **M14-15** | Security — Kerberos, Active Directory enumeration, Mimikatz | `CDA-B/M14-15L.md` |

## Interactive Games

| Game | What It Drills |
|------|---------------|
| **Subnet Invaders** | Space Invaders with networking questions. 8 waves from binary basics through VLSM. Correct answer destroys an enemy, wrong answer adds a row. |
| **Subnet Quest** | Turn-based RPG across 6 zones (Binary Caverns → Final Fortress). Multiple-choice battles, fill-in-the-blank boss fights. XP/leveling system. |
| **OSI Tower** | 3 progressive stages: drag layer names, then addressing types, then PDUs. Per-slot feedback with touch support. |
| **Bit Flip** | 32 clickable bits in 4 octet groups. Practice mode + 60-second speed run. |
| **Hex Trainer** | Guided long-division for dec-to-hex. Reverse mode for hex-to-dec. Speed drill with random direction. |
| **PCAP Forensics** | Simulated packet capture analysis. Multiple scenarios: find nmap scans, cleartext passwords, DNS tunneling, lateral movement. Wireshark-style filtering. |

## NetDrill Modules

The main study tool has 7 interactive tabs:

| Tab | What It Drills |
|-----|---------------|
| **OSI Layers** | Drag-and-drop layer names to positions. Shows addressing and PDU per layer. |
| **Protocol Quiz** | Which layer? Which port? TCP or UDP? Randomized questions with explanations. |
| **Number Systems** | Bin/hex/dec converter, bit toggle chart, timed drills, hex reference, powers of 2. |
| **Subnet Math** | CIDR-to-mask, host count, wildcard masks, AND operations with streak tracking. |
| **Subnet Calc** | Enter any IP + CIDR to see full breakdown with binary. |
| **Subnet Practice** | Random subnetting problems — calculate by hand, then verify. |
| **Reference** | 34 protocols mapped to OSI layers, ports, and transport protocols. |

## Enabling GitHub Pages

1. Go to **Settings** > **Pages** in this repo
2. Source: **Deploy from a branch**
3. Branch: **main**, folder: **/ (root)**
4. Save — site will be live at `mwilco03.github.io/FOC/`

## Local Usage

No build step needed. Open any `.html` file directly in a browser:

```bash
git clone https://github.com/mwilco03/FOC.git
open FOC/index.html
```

## Repo Structure

```
FOC/
├── index.html                      # Landing page with all tool links
├── 404.html                        # Custom 404 page
├── .nojekyll                       # Bypass Jekyll processing
├── Networking/
│   ├── subnetting.html             # NetDrill interactive tool
│   ├── invaders.html               # Subnet Invaders game
│   ├── quest.html                  # Subnet Quest RPG
│   ├── tower.html                  # OSI Tower builder
│   ├── bitflip.html                # Bit Flip CIDR trainer
│   ├── hex.html                    # Hex Trainer
│   ├── pcap-challenge.html         # PCAP Forensics investigation game
│   ├── SubnettingSheet.html        # Editable subnetting reference
│   ├── FOC - Subnetting.md         # Subnetting reference notes
│   └── PacketTracerFiles/          # 24 Cisco Packet Tracer labs
├── CDA-B/                          # Cisco network admin modules
│   ├── M10-*.md                    # Module 10: Switching
│   ├── M11*.md                     # Module 11: Protocol Basics
│   ├── M12-Wireless.md             # Module 12: Wireless Networking
│   ├── M13.md                      # Module 13: Infrastructure Services
│   └── M14-15L.md                  # Modules 14-15: Security
├── Challenges1.html + .py          # Python Lab
├── Challenges2.html + .ps1         # PowerShell Lab
├── Challenges3.html + .cmd         # Batch Lab
├── Challenges4.html + .sh          # Bash Lab
├── Challenges5.html                # Data & APIs Lab
├── json-dummy-data.json            # Sample JSON dataset (used by Data & APIs Lab)
├── people-100.csv                  # Sample CSV data
├── u_251031.log                    # Sample log file
├── NetConfig.md                    # Packet Tracer troubleshooting cheat sheet
├── NetConfigLab.md                 # Lab troubleshooting checklist
├── Show-BoundParameters.ps1        # PowerShell utility
├── AUDIT-REPORT.md                 # Code audit findings
└── README.md
```
