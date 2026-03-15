# FOC - Future Operators Course

Interactive study tools for **networking**, **scripting**, **data analysis**, and **security forensics**, built as a GitHub Pages site.

> **Live Site:** [mwilco03.github.io/FOC](https://mwilco03.github.io/FOC/)

## Repository Structure

```
hub/                            Landing page (GitHub Pages root)
courses/
  networking-fundamentals/      NetDrill, Subnet Invaders, Quest, OSI Tower, PCAP Forensics, Packet Tracer
  scripting/                    Challenge labs by language
    python/                     Interactive reference + 20 drills + quiz
    powershell/                 Cmdlet reference + 20 drills + quiz
    bash/                       Text processing + 20 drills + quiz + terminal
    batch/                      Variable/loop reference + 15 drills + quiz
    data-apis/                  JSON, YAML, REST, curl, jq, regex + 20 drills
  cda-b/                        CDA-B course modules (M10-M15)
```

## Quick Start

No build step. Open any `.html` file directly in a browser:

```bash
git clone https://github.com/mwilco03/FOC.git
open FOC/hub/index.html
```

## Courses

Each course is self-contained. See [courses/README.md](courses/README.md) for the full index.

### Networking Fundamentals
NetDrill (7-tab study platform), Subnet Invaders, Subnet Quest RPG, OSI Tower, Bit Flip, Hex Trainer, PCAP Forensics, Packet Tracer labs.

### Scripting
Python, PowerShell, Bash, Batch, Data & APIs — each with interactive reference, challenge drills, and quizzes.

### CDA-B Modules
Switching (M10), Protocol Basics (M11), Wireless (M12), Infrastructure Services (M13), Security & AD (M14-15).

## Enabling GitHub Pages

1. Go to **Settings** > **Pages**
2. Source: **Deploy from a branch**
3. Branch: **main**, folder: **/ (root)**
4. Update paths in `hub/index.html` to point to `courses/` subdirectories

## Local Usage

```bash
git clone https://github.com/mwilco03/FOC.git
open FOC/hub/index.html
```
