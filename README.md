# FOC - Future Operators Course

Interactive study tools for **networking**, **scripting**, **data analysis**, and **security forensics** — plus deployable CTF training labs.

> **Live Site:** [mwilco03.github.io/FOC](https://mwilco03.github.io/FOC/)

## Repository Structure

```
hub/                            Landing page (GitHub Pages root)
platform/                       Reusable infrastructure (terminal, scoreboard, flag gen, scripts)
courses/
  networking-fundamentals/      NetDrill, Subnet Invaders, Quest, OSI Tower, PCAP Forensics, Packet Tracer
  scripting/                    Challenge labs by language
    python/                     Interactive reference + 20 drills + quiz
    powershell/                 Cmdlet reference + 20 drills + quiz
    bash/                       Text processing + 20 drills + quiz + terminal
    batch/                      Variable/loop reference + 15 drills + quiz
    data-apis/                  JSON, YAML, REST, curl, jq, regex + 20 drills
  cda-b/                        CDA-B course modules (M10-M15)
  pivoting/                     Network Traversal Lab v5.0 - 9 hops, 10 networks
```

## Quick Start

### Static Courses (no install)

Open any `.html` file directly in a browser:

```bash
git clone https://github.com/mwilco03/FOC.git
open FOC/hub/index.html
```

### Instructor-Led Labs (Docker)

```bash
# Run preflight checks
./platform/scripts/preflight.sh

# Start a course
cd courses/pivoting
docker compose -f compose.yml up -d

# Access points:
#   Terminal:   http://localhost:4200
#   Scoreboard: http://localhost:8080
```

## Courses

Each course is self-contained. See [courses/README.md](courses/README.md) for the full index.

### Networking Fundamentals
NetDrill (7-tab study platform), Subnet Invaders, Subnet Quest RPG, OSI Tower, Bit Flip, Hex Trainer, PCAP Forensics, Packet Tracer labs.

### Scripting
Python, PowerShell, Bash, Batch, Data & APIs — each with interactive reference, challenge drills, and quizzes.

### CDA-B Modules
Switching (M10), Protocol Basics (M11), Wireless (M12), Infrastructure Services (M13), Security & AD (M14-15).

### Pivoting Lab
9-hop network traversal CTF. SSH tunneling, FTP, DNS zone transfer, Redis RCE, SMB enumeration. Docker-based with scoreboard and hint system.

## Adding a Course

Each course lives in `courses/<name>/` and must be independently deployable.
Docker courses reference `../../platform/` for shared infrastructure.
Static courses need no Docker at all.
See `courses/README.md` for the course contract.

## Requirements

- **Static courses:** Any modern browser
- **Docker courses:** Docker + Docker Compose, 4GB RAM minimum, Linux/macOS/Windows with WSL2

## Enabling GitHub Pages

1. Go to **Settings** > **Pages**
2. Source: **Deploy from a branch**
3. Branch: **main**, folder: **/ (root)**
