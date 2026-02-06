# FOC - Foundations of Computing

Interactive study tools for **Networking Fundamentals** and scripting, built as a GitHub Pages site.

## Quick Start

> **Live Site:** [mwilco03.github.io/FOC](https://mwilco03.github.io/FOC/)

| Tool | Link | Description |
|------|------|-------------|
| **NetDrill** | [Open](https://mwilco03.github.io/FOC/Networking/subnetting.html) | Main interactive study platform |
| **Subnet Invaders** | [Open](https://mwilco03.github.io/FOC/Networking/invaders.html) | Space Invaders quiz game — 8 waves of networking questions |
| **Subnet Quest** | [Open](https://mwilco03.github.io/FOC/Networking/quest.html) | Turn-based RPG with boss-fight subnet tables |
| **OSI Tower** | [Open](https://mwilco03.github.io/FOC/Networking/tower.html) | Progressive 3-stage OSI model builder |
| **Bit Flip** | [Open](https://mwilco03.github.io/FOC/Networking/bitflip.html) | Toggle 32 bits to build CIDR subnet masks |
| **Hex Trainer** | [Open](https://mwilco03.github.io/FOC/Networking/hex.html) | Guided long-division hex conversion trainer |
| **Subnetting Sheet** | [Open](https://mwilco03.github.io/FOC/Networking/SubnettingSheet.html) | Interactive subnetting notes & homework with editable cells |
| Python Cheat Sheet | [Open](https://mwilco03.github.io/FOC/Challenges1.html) | Python scripting quick reference |
| PowerShell Cheat Sheet | [Open](https://mwilco03.github.io/FOC/Challenges2.html) | PowerShell commands and patterns |
| Batch Cheat Sheet | [Open](https://mwilco03.github.io/FOC/Challenges3.html) | Windows command line reference |
| Bash Cheat Sheet | [Open](https://mwilco03.github.io/FOC/Challenges4.html) | Linux shell scripting reference |

## Interactive Games

| Game | What It Drills |
|------|---------------|
| **Subnet Invaders** | Space Invaders with networking questions. 8 waves from binary basics through VLSM. Correct answer destroys an enemy, wrong answer adds a row. Pixel-art animated spaceships. |
| **Subnet Quest** | Turn-based RPG across 6 zones (Binary Caverns → Final Fortress). Multiple-choice battles, fill-in-the-blank boss fights with full subnet tables. XP/leveling system. |
| **OSI Tower** | 3 progressive stages: drag layer names, then addressing types, then PDUs. Green/red per-slot feedback. Each stage unlocks after passing the previous one. |
| **Bit Flip** | 32 clickable bits in 4 octet groups. Given a CIDR prefix, toggle bits to build the correct subnet mask. Practice mode + 60-second speed run. Shortcuts for filling octets. |
| **Hex Trainer** | Guided long-division for dec-to-hex. Reverse mode for hex-to-dec with place values. Speed drill with random direction. Hex 0–15 reference always visible. |

## NetDrill Modules

The main study tool has 7 interactive tabs:

| Tab | What It Drills |
|-----|---------------|
| **OSI Layers** | Drag-and-drop layer names to positions. Shows addressing (MAC/IP/Port) and PDU (Frames/Packets/Segments) per layer. Click to remove placed items. |
| **Protocol Quiz** | Which layer? Which port? TCP or UDP? What addressing type? Randomized questions with explanations. |
| **Number Systems** | Live bin/hex/dec converter, clickable bit toggle chart, timed conversion drills, hex reference (0-15), powers of 2 chart, subnet magic numbers. |
| **Subnet Math** | CIDR-to-mask, host count & block size, wildcard masks, AND operations. Each drill has streak tracking. Includes a bitwise AND visualizer. |
| **Subnet Calc** | Enter any IP + CIDR prefix to see network/broadcast/mask/wildcard/hosts with full binary breakdown. CIDR cheat sheet included. |
| **Subnet Practice** | Random subnetting problems — calculate network, broadcast, mask, hosts, first/last usable by hand, then check your work. |
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
open FOC/Networking/subnetting.html
```

## Repo Structure

```
FOC/
├── index.html                  # Landing page
├── 404.html                    # Custom 404 page
├── .nojekyll                   # Bypass Jekyll processing
├── Networking/
│   ├── subnetting.html         # NetDrill interactive tool
│   ├── invaders.html           # Subnet Invaders game
│   ├── quest.html              # Subnet Quest RPG
│   ├── tower.html              # OSI Tower builder
│   ├── bitflip.html            # Bit Flip CIDR trainer
│   ├── hex.html                # Hex Trainer
│   ├── FOC - Subnetting.md     # Subnetting reference notes
│   └── PacketTracerFiles/      # Cisco Packet Tracer labs
├── CDA-B/                      # Cisco network admin modules
├── Challenges[1-4].html        # Scripting cheat sheets
├── Challenges[1-4].*           # Script source files
└── README.md
```
