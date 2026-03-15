# Courses

Each subdirectory is a self-contained, independently deployable course.

## Course Contract

A course directory **must**:
1. Be deployable with no dependency on sibling course directories
2. Contain its own `compose.yml` (or be pure static content with no Docker)
3. Reference `../../platform/` for shared infrastructure
4. Include a `README.md` explaining what it is and how to run it

A course directory **may**:
- `targets/` - Course-specific Docker containers
- `hints/` - Tiered hint files
- `tools/` - Static binaries or course-specific tools
- `slides/` - Instructor presentation content
- `instructor/` - Solution guides, pace guides
- `.env.template` - Environment variable template

## Available Courses

| Course | Type | Status |
|--------|------|--------|
| [pivoting/](pivoting/) | Docker CTF lab (9 hops, 10 networks) | ~65% |
