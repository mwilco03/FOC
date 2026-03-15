# Piv0t.L4ND

Multi-protocol cybersecurity training labs. Each course is self-contained and independently deployable.

## Repository Structure

```
platform/           Reusable infrastructure (terminal, scoreboard, flag gen, scripts)
courses/            Self-contained courses (each independently deployable)
  pivoting/         Network Traversal Lab v5.0 - 9 hops, 10 networks
```

## Quick Start

```bash
# Run preflight checks
./platform/scripts/preflight.sh

# Start a course
cd courses/pivoting
../../platform/scripts/start.sh

# Access points:
#   Terminal:   http://localhost:4200
#   Scoreboard: http://localhost:8080
```

## Adding a Course

Each course lives in `courses/<name>/` and must be independently deployable.
A course references `../../platform/` for shared infrastructure (terminal, scoreboard, init).
See `courses/README.md` for the course contract.

## Requirements

- Docker + Docker Compose
- 4GB RAM minimum (see preflight output for per-course estimates)
- Linux, macOS, or Windows with WSL2
