# Platform

Reusable infrastructure components shared across all courses.

## Components

| Directory | Purpose |
|-----------|---------|
| `terminal/` | Shell-in-a-Box web terminal (student attack platform) |
| `scoreboard/` | Flask-based progress tracker with tiered hint system |
| `init/` | Flag generation container (PIVOT{container_randomhex} format) |
| `seccomp/` | Security profiles for container hardening |
| `scripts/` | Deployment, preflight, reset, and install scripts |

## Usage

Courses reference platform components via relative paths in their `compose.yml`:

```yaml
services:
  launchpad:
    build: ../../platform/terminal
  scoreboard:
    build: ../../platform/scoreboard
  init:
    build: ../../platform/init
```

## Contract

- Platform does not know about courses
- Courses opt in to platform components, they are never forced
- Changes to platform are platform PRs, not course PRs
- Platform images are versioned/pinned here, not in courses
