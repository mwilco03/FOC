# FOC - Foundations of Computing

Interactive study tools for **Networking Fundamentals** and scripting, built as a GitHub Pages site.

## Quick Start

> **Live Site:** [mwilco03.github.io/FOC](https://mwilco03.github.io/FOC/)

| Tool | Link | Description |
|------|------|-------------|
| **NetDrill** | [Open](https://mwilco03.github.io/FOC/Networking/subnetting.html) | Main interactive study platform |
| Python Cheat Sheet | [Open](https://mwilco03.github.io/FOC/Challenges1.html) | Python scripting quick reference |
| PowerShell Cheat Sheet | [Open](https://mwilco03.github.io/FOC/Challenges2.html) | PowerShell commands and patterns |
| Batch Cheat Sheet | [Open](https://mwilco03.github.io/FOC/Challenges3.html) | Windows command line reference |
| Bash Cheat Sheet | [Open](https://mwilco03.github.io/FOC/Challenges4.html) | Linux shell scripting reference |

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
│   ├── FOC - Subnetting.md     # Subnetting reference notes
│   └── PacketTracerFiles/      # Cisco Packet Tracer labs
├── CDA-B/                      # Cisco network admin modules
├── Challenges[1-4].html        # Scripting cheat sheets
├── Challenges[1-4].*           # Script source files
└── README.md
```
