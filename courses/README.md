# Courses

Each subdirectory is a self-contained, independently deployable course.

## Course Contract

A course directory **must**:
1. Be deployable with no dependency on sibling course directories
2. Include a `README.md` explaining what it covers and how to run it
3. Either work by opening `.html` files directly (static) or contain its own `compose.yml` (Docker)

A course directory **may** include:
- `compose.yml` - Docker Compose referencing `../../platform/` for shared infra
- `targets/` - Course-specific Docker containers
- `hints/` - Tiered hint files
- `tools/` - Static binaries or course-specific tools
- `slides/` - Instructor presentation content
- `instructor/` - Solution guides, pace guides
- `.env.template` - Environment variable template

## Available Courses

| Course | Type | Content | Status |
|--------|------|---------|--------|
| [networking-fundamentals/](networking-fundamentals/) | Static HTML/JS | 8 tools/games, Packet Tracer labs | ~90% |
| [scripting/](scripting/) | Static HTML/JS | 5 language labs (Python, PowerShell, Bash, Batch, Data/APIs) | ~90% |
| [cda-b/](cda-b/) | Markdown reference | CDA-B modules M10-M15 | Complete |
| [pivoting/](pivoting/) | Docker CTF lab | 9 hops, 10 networks, scoreboard + hints | ~65% |
