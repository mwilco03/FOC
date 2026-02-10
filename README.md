# Pivot Lab v5.0

Multi-Protocol Network Traversal Training Environment

## Overview

Pivot Lab is a containerized cybersecurity training environment that teaches penetration testing, lateral movement, and network pivoting techniques. Players progress through 9 isolated network segments, exploiting services and chaining tunnels to collect flags.

## Features

- **Zero Prerequisites**: Access via web browser only (shellinabox web terminal)
- **9 Challenge Containers**: Progressive difficulty from Easy to Hard
- **Multi-Protocol**: SSH, HTTP, FTP, TFTP, DNS, Redis, SMB, and more
- **Live Off the Land**: Minimal tools on targets, improvisation required
- **Randomized**: Flags and IPs partially randomized per session
- **Scoreboard**: Real-time progress tracking with sequential hint system
- **Alpine Linux**: All containers run Alpine 3.19 with maintained APK packages

## Quick Start

### One-Line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/mwilco03/Piv0t.L4ND/main/install.sh | bash
```

This will:
- Check for Docker and Docker Compose
- Clone the repository to `~/Piv0t.L4ND`
- Make all scripts executable
- Provide next steps

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/mwilco03/Piv0t.L4ND.git
cd Piv0t.L4ND

# Run preflight checks
./preflight.sh

# Start the lab
./start.sh

# Access points:
# - Terminal: http://localhost:4200
# - Scoreboard: http://localhost:8080
```

## Architecture

10 containers across 10 isolated network segments:
- LAUNCHPAD: Web terminal (your attack platform)
- SCOREBOARD: Progress tracking and hints
- 9 Challenge containers (GATE → TUNNEL → FILESERV → WEBSHELL → DROPZONE → DEPOT → RESOLVER → CACHE → VAULT)

Each container bridges two networks, forming a chain requiring lateral movement and tunneling.

## Scoring

- Total possible: 4,050 points
- Points per hop range from 100 (Hop 1) to 1,000 (Hop 9)
- Hints available in 3 tiers (Nudge, Guide, Walkthrough)
- Hint costs: 10%, 25%, 50% of hop points (cumulative 85%)

## Requirements

- Docker + Docker Compose
- 4GB RAM minimum
- Linux, macOS, or Windows with WSL2

## Operations

```bash
./start.sh           # Start the lab with randomized IPs
./reset.sh           # Full reset (tears down and regenerates)
docker compose down  # Soft reset (preserves flags)
```

## Skills Learned

- Network reconnaissance (TCP/UDP scanning)
- SSH tunneling (-L/-R/-D, SOCKS proxy)
- Service enumeration and exploitation
- Privilege escalation (SUID binaries, LinPEAS)
- Protocol abuse (FTP, TFTP, DNS AXFR, Redis RCE, SMB)
- Living off the land techniques
- File transfer methods
- Credential discovery and password cracking

## Documentation

- `Design.md` - Complete design document with technical details
- `containers/` - Dockerfiles and configurations for all containers
- `hints/` - Hint JSON files for each hop
- `tools/` - Static binaries for network operations

## License

Educational use only. See LICENSE for details.

## Support

For issues and feedback: https://github.com/mwilco03/Piv0t.L4ND/issues

---

**Start Date**: 2024
**Version**: 5.0
**Base OS**: Alpine Linux 3.19
