# Skill: CTF Training Lab Generator

## Trigger
User provides a PowerPoint (.pptx) lesson file or topic area and wants a hands-on training lab with CTF challenges.

## What You Build
Given a lesson/presentation, generate a complete Docker Compose training environment:

### Inputs Required
1. **Lesson content** — a .pptx file (extract via python-pptx in Docker) or topic description
2. **Audience size** — default 10 students
3. **Unit branding** — optional logo/patch image, color scheme
4. **Difficulty range** — beginner to advanced mix

### Architecture (Always This Pattern)
```
Browser :80   --> Traefik (sticky sessions) --> Nx Shell-in-a-Box (tools inside)
Browser :8000 --> CTFd (scoreboard + challenges)
Browser :8888 --> Lab Controller (slides + solutions + auto-unlock)

Three Docker networks:
  student_net  (172.20.0.0/24) - Traefik + student terminals
  target_net   (172.20.1.0/24) - Target hosts + distractors (students also attached)
  ctfd_net     (172.20.2.0/24) - CTFd + MariaDB + Redis + Lab Controller
```

### Output File Structure
```
<lab-name>/
├── docker-compose.yml          # All services, networks, IPs
├── .env                        # Passwords, config, PT flags
├── student.env                 # Team passwords (shared across containers)
├── deploy.sh                   # Linux/Mac one-shot deploy
├── deploy.ps1                  # Windows deploy (checks admin, installs Docker/Git if needed)
├── teardown.sh / teardown.ps1  # Clean shutdown
├── README.md
├── student-terminal/
│   ├── Dockerfile              # Debian + shellinabox + topic-specific tools + man pages
│   ├── entrypoint.sh           # Creates all team users, passwordless sudo, LOGIN prompt
│   ├── motd.txt                # Welcome message (no CTFd URL — dynamic in bashrc)
│   ├── bash_notes.txt          # Terminal-formatted reference (NOT markdown)
│   └── shellinabox-dark.css    # Dark theme matching CTFd
├── targets/
│   ├── <realistic-host-1>/     # Multi-service per host (SSH + primary + extras)
│   ├── <realistic-host-2>/     # Each host = Dockerfile + start.sh + app files
│   ├── ...
│   └── distractors/            # 5-7 noise hosts (printer, camera, IoT, etc.)
│       ├── Dockerfile
│       └── distractors.py      # ROLE env var selects personality
├── lab-controller/
│   ├── Dockerfile
│   ├── controller.py           # Auto-unlock daemon + web server
│   └── static/
│       ├── slides.html         # Reveal.js responsive slides (from pptx content)
│       └── solutions.html      # Password-gated instructor solution guide
├── ctfd/
│   ├── setup.sh                # Auto-provisions everything (admin, teams, challenges, theme)
│   ├── theme.css               # Full dark cyber theme
│   ├── scoreboard-enhancements.js  # Live ticker, confetti, first blood
│   └── customize.sh            # Standalone theme script
└── instructor/
    ├── solution-guide.txt      # Every challenge with exact commands + teaching notes
    ├── pace-guide.txt          # Maps slides to categories, timing, stuck points
    ├── unlock.sh               # Manual category unlock script
    └── handout.txt             # Printable one-pager for students
```

### Challenge Design Rules
1. **6 progressive categories** that auto-unlock (50% threshold):
   - Knowledge Check (trivial, during lecture)
   - Discovery/Basics (easy)
   - Intermediate skill (easy-medium)
   - Applied skill (medium)
   - Advanced application (medium-hard)
   - Deep Dive (hard, time sinks)

2. **Challenge types** — mix all of these:
   - Flags captured from services (banners, headers, source)
   - Multiple choice analysis ("this port profile means what OS?")
   - Tool output interpretation ("what does this result mean?")
   - Man page / documentation gotchas
   - Protocol interaction (nc conversations)
   - Creative/lateral thinking (JWT abuse, robots.txt, port knocking)
   - Physical challenges (PT events, whiteboard tasks — instructor-validated)
   - Inspect element / view source web challenges

3. **Each category has**:
   - Easy wins (ensure progression)
   - Time sinks (keep advanced students busy while others catch up)
   - At least one "trick question" that tests understanding vs. memorization

4. **Hints are**:
   - Slightly cryptic
   - Punny or double entendre when possible
   - Nudge toward the method, never give the answer

5. **Target hosts are realistic**:
   - Multiple services per host (SSH + primary function + extras)
   - 5-7 distractor hosts with no flags (printers, cameras, IoT, VPN)
   - Total ~13 hosts on target network
   - Hostnames that tell a story (corp.local domain)

### Student Terminal Requirements
- Shell-in-a-Box with LOGIN prompt (not auto-login)
- All team users (team1-teamN) on every container
- Passwordless sudo
- Same creds for terminal + CTFd
- Dark theme, 16px font
- man pages for primary tool
- Terminal-formatted cheatsheet (not markdown)
- MOTD displays once (PAM, not bashrc)
- Dynamic CTFd URL via host.docker.internal

### CTFd Configuration
- Auto-provisioned via setup.sh (zero manual steps)
- Dark cyber theme (JetBrains Mono, Inter, glassmorphic navbar, rounded cards)
- Animations (fade-up challenges, gradient buttons, glow effects)
- Scoreboard enhancements (live ticker, confetti on first blood)
- All challenges start HIDDEN — lab-controller auto-unlocks
- theme_header for CSS (not the css config key — CTFd 3.x core theme ignores it)
- theme_footer for scoreboard JS

### Lab Controller
- Polls CTFd API every 10 seconds
- Unlocks next category when 50% of current is solved
- Knowledge Check unlocked from start
- Serves reveal.js slides at /slides (responsive, works on phones)
- Serves solution guide at /solutions (HTTP basic auth, password from .env)
- Manual unlock API: /api/unlock/<category> (instructor auth)
- Manual lock API: /api/lockall (instructor auth)

### Deploy Scripts
- **deploy.ps1** (Windows): Checks admin, installs Docker Desktop + Git via winget if missing, starts Docker daemon, waits, builds, runs setup
- **deploy.sh** (Linux/Mac): Checks Docker, builds, runs setup
- Both detect LAN IP and print summary with all URLs
- **teardown** scripts with confirmation prompt

### The Narrative Flow
1. Students get terminals, scan network → hosts visible but challenges locked
2. "Taste of what's to come" — they see the scoreboard but can't play yet
3. Instructor teaches via slides (on everyone's phones)
4. Knowledge Check available during lecture
5. After intro: instructor triggers first category unlock (or auto after lecture)
6. Categories cascade: complete 50% → next unlocks
7. Physical challenges pull students away from terminals at key moments
8. Deep Dive has time sinks that occupy top performers
9. After class: instructor shares solution guide password
10. Students review what they missed

### Adaptation for Different Topics
To generate a lab for a DIFFERENT topic (e.g., PowerShell, web app security, forensics):
1. Extract slide content from pptx
2. Map slide sections to 6 progressive categories
3. Design target hosts that match the topic (e.g., for web security: vulnerable web apps; for forensics: hosts with artifacts)
4. Install topic-specific tools in student terminal (e.g., Burp Suite, Volatility, PowerShell)
5. Write challenges that progress from "use the tool" to "understand the output" to "think like an analyst"
6. Keep the same infrastructure (Traefik, CTFd, Shell-in-a-Box, lab-controller)
7. Keep distractors relevant to the topic domain
