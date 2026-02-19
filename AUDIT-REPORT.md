# FOC Code Audit Report

**Date:** 2026-02-19
**Scope:** Full front-to-back audit — dead ends, broken workflows, user-disrupting issues, and game overlap

---

## Executive Summary

FOC is a vanilla HTML/JS/CSS educational platform with 5 networking games, 1 multi-module study tool (NetDrill), 4 scripting challenge labs, and supplementary reference pages. The audit found **1 game-breaking bug**, **7 incorrect reference data values**, **3 quizzes with trivially gameable answers**, and several navigation dead ends and missing completion states. Overall the codebase is well-structured, but there are issues that would frustrate or mislead students.

---

## Table of Contents

1. [Critical / Game-Breaking Bugs](#1-critical--game-breaking-bugs)
2. [Navigation Dead Ends](#2-navigation-dead-ends)
3. [Broken Workflows & Logic Bugs](#3-broken-workflows--logic-bugs)
4. [Content Accuracy Errors](#4-content-accuracy-errors)
5. [Game Overlap Analysis](#5-game-overlap-analysis)
6. [Missing Completion States](#6-missing-completion-states)
7. [Input Validation Gaps](#7-input-validation-gaps)
8. [Consistency Issues Across Labs](#8-consistency-issues-across-labs)
9. [Mobile / Touch Support Gaps](#9-mobile--touch-support-gaps)
10. [Low-Priority / Polish Items](#10-low-priority--polish-items)
11. [What's Working Well](#11-whats-working-well)

---

## 1. Critical / Game-Breaking Bugs

### 1.1 OSI Tower — Stage 2 is impossible to complete
**File:** `Networking/tower.html`
**Severity:** CRITICAL — blocks all progress past Stage 1

Layers 7, 6, and 5 all have `addr: 'Data'`. The drop handler removes any previous placement with the same value, so placing "Data" in Layer 6 removes it from Layer 7. You can never have "Data" in more than one slot simultaneously. Since Stage 2 requires all 7 slots correct, it can never be completed, which also blocks Stage 3 and the victory screen.

### 1.2 Hex Trainer — TypeError crash after "I KNOW IT"
**File:** `Networking/hex.html`
**Severity:** HIGH — JavaScript crash halts functionality

In guided mode, clicking "I KNOW IT" replaces the step-by-step inputs with a single answer field. But the "CHECK" button still calls `checkGuided()`, which tries to access the removed DOM elements (`#gq-0`, `#gr-0`, etc.), throwing a `TypeError: Cannot read properties of null`.

### 1.3 Quiz answers always at index 0 — PowerShell, Batch, Bash
**Files:** `Challenges2.html`, `Challenges3.html`, `Challenges4.html`
**Severity:** HIGH — defeats the purpose of the quiz

Every single quiz question in these three labs has `c:0` (correct answer is always the first option). A student can score 100% by always clicking the first choice. Only the Python lab (`Challenges1.html`) distributes answers across positions.

---

## 2. Navigation Dead Ends

| Page | Issue |
|------|-------|
| `Networking/subnetting.html` (NetDrill) | **No back/home link.** This is the main tool — the most prominent link on the landing page — and users have no way to return except the browser back button. |
| `Networking/SubnettingSheet.html` | **No back/home link** and **not linked from `index.html` at all.** The page is orphaned — users can't discover it through site navigation. |
| `404.html` | Has a "Back to Home" link. Working correctly. |
| All other pages | Have working `← Home` / `← Back` links. No issues. |

---

## 3. Broken Workflows & Logic Bugs

### 3.1 Subnet Invaders — life-drain cascade
**File:** `Networking/invaders.html`, lines 629-641

Once enemies cross the danger line (`canvas.height - 20`), `enemyBaseY` is never reset. Every subsequent wrong answer triggers the danger-line check again, costing an additional life. This creates a rapid-death spiral from just 2-3 wrong answers after enemies cross the threshold.

### 3.2 Bit Flip — speed mode dead end after timer expires
**File:** `Networking/bitflip.html`, lines 284-293

When the 60-second timer hits 0, the game shows "TIME UP!" but leaves the user stranded. There's no restart button, no "play again" prompt. The CHECK button silently stops working but NEXT still generates new problems, creating a confusing hybrid state. The user must manually click the PRACTICE tab to recover.

### 3.3 Subnet Quest — no overall game completion
**File:** `Networking/quest.html`

Clearing all 6 zones updates the counter to `ZONES: 6/6` but nothing else happens. No victory screen, no congratulations, no acknowledgment. Individual zone victories work fine, but the overall game just... ends without fanfare.

### 3.4 Subnet Quest — infinite XP farming
**File:** `Networking/quest.html`, lines 536-538

Cleared zones remain clickable and award XP on re-completion. A student can grind zone 1 repeatedly to inflate their level, which undermines the progression system.

### 3.5 NetDrill Protocol Quiz — "Both" is never correct
**File:** `Networking/subnetting.html`, lines 1536-1542

The TCP/UDP quiz type filters to only protocols where `transport` is exactly `'TCP'` or `'UDP'`, excluding dual-stack protocols like DNS (`'TCP/UDP'`). The "Both" option appears as a choice but can never be the correct answer.

### 3.6 NetDrill — all drill sections allow double-scoring
**File:** `Networking/subnetting.html` (lines 1962, 2031, 2091, 2154, 2201)

Clicking "Check" multiple times on the same problem increments the score each time. There's no guard flag to prevent re-evaluation. Affects: Number Drill, CIDR Drill, Host Count Drill, Wildcard Drill, AND Drill.

### 3.7 Challenge Labs — drill check button not disabled after submission
**Files:** `Challenges1.html`, `Challenges2.html`, `Challenges3.html`, `Challenges4.html`

The "Check" button remains active after grading a drill answer. Rapid clicking inflates the score by +10 per click. The input field is disabled but the button is not.

### 3.8 Batch Lab — Drill #4 answer doesn't match template
**File:** `Challenges3.html`, line 260

The template shows `____ %fname%.txt echo %text%` with the blank at the beginning. The accepted answer `>` would produce `> %fname%.txt echo %text%` which is invalid Batch syntax. The alternative accepted answer is a complete command that doesn't fit the blank-fill pattern.

### 3.9 Batch Lab — Drill #6 two blanks, one answer field
**File:** `Challenges3.html`, line 262

The template has `if "____"=="____"` (two blanks) but expects a single answer string `%password%"=="secret123` that spans across both blanks and the operator. Confusing interaction model.

---

## 4. Content Accuracy Errors

### SubnettingSheet.html — 7 data errors

| Line | Error | Correct Value |
|------|-------|---------------|
| 103 | IPv4 first octet shows `162` | Should be `192` (binary `11000000` = 192) |
| 165 | Hex solution shows `3BF3` | Should be `3BF2` (matches the worked example) |
| 203 | Subnet range starts at `10.200.20.32` | Should start at `10.200.20.64` (for /27 network `10.200.20.64`) |
| 277, 294 | Network ID shows `118.26.x.x` | Should be `188.26.x.x` (typo: 1 vs 8) |
| 292 | IP `188.x.x.x` called "class A" | Should be "class B" (128-191 range) |
| 303 | Binary of `100` shown as `01100110` (=102) | Should be `01100100` |
| 222-223 | Broadcast derivation shows subnet mask bits | Should show flipped host bits |

### Bash Lab — answer/test mismatches

| Line | Issue |
|------|-------|
| 307 | `print_banner` answer pads with spaces but test shows `=` padding |
| 292 | `count_words` answer with `wc -w` may include leading whitespace not shown in test |
| 303 | `sort_unique` answer produces trailing space in output |

### Python Lab — minor accuracy issues

| Line | Issue |
|------|-------|
| 227 | `common_elements` accepts `list(set(a) & set(b))` which doesn't guarantee order |

### NetDrill Reference Table — debatable layer assignments

| Protocol | Listed Layer | Common Alternative |
|----------|-------------|-------------------|
| ARP | Layer 3 | Often considered Layer 2 or L2/L3 boundary |
| BGP | Layer 3 | Runs over TCP port 179, technically L7 in OSI |
| Bluetooth | Layer 1 only | Spans L1-L2 |

---

## 5. Game Overlap Analysis

There is **significant topic overlap** across the networking games, but each uses a different pedagogical approach. Here's the overlap matrix:

| Topic | NetDrill | Invaders | Quest | Tower | Bit Flip | Hex Trainer |
|-------|----------|----------|-------|-------|----------|-------------|
| OSI Layer Names | Tab 1 (drag-drop) | — | — | Stage 1 (drag-drop) | — | — |
| OSI Addressing | Tab 1 (drag-drop) | — | — | Stage 2 (drag-drop) | — | — |
| OSI PDUs | Tab 1 (drag-drop) | — | — | Stage 3 (drag-drop) | — | — |
| Protocol → Layer | Tab 2 (quiz) | Waves 5-6 | — | — | — | — |
| Protocol → Port | Tab 2 (quiz) | Waves 5-6 | — | — | — | — |
| TCP vs UDP | Tab 2 (quiz) | — | — | — | — | — |
| Binary ↔ Decimal | Tab 3 (converter) | Waves 1-2 | Zone 1-2 | — | — | — |
| Hex ↔ Decimal | Tab 3 (converter) | Waves 3-4 | — | — | — | All modes |
| CIDR → Subnet Mask | Tab 4 (drill) | Waves 5-8 | Zone 3-4 | — | All modes | — |
| Network/Broadcast calc | Tab 5-6 (calc/practice) | Waves 7-8 | Zone 5-6 (boss) | — | — | — |
| Wildcard Masks | Tab 4 (drill) | — | — | — | — | — |
| AND Operations | Tab 4 (drill) | — | — | — | — | — |

### Key Overlaps

1. **OSI Layer drag-and-drop exists in both NetDrill (Tab 1) and OSI Tower** — identical mechanic (drag layer names to slots), identical content. OSI Tower adds Stages 2-3 (addressing/PDUs), which NetDrill also covers in its OSI tab. These two are nearly redundant. The difference: Tower is a standalone progressive game; NetDrill's is an embedded practice tool.

2. **Binary/decimal conversion is covered in 3 places** — NetDrill Tab 3, Invaders Waves 1-2, and Quest Zones 1-2. Each uses a different format (converter tool vs. shooting game vs. RPG battle). Low concern since repetition aids learning, and the delivery mechanisms differ.

3. **CIDR/subnet mask practice is covered in 3 places** — NetDrill Tab 4, Invaders Waves 5-8, and Bit Flip. Again, different formats: drill, arcade, and toggle-bits. Low concern.

4. **Hex conversion is covered in 2 places** — NetDrill Tab 3 and Hex Trainer. The Hex Trainer adds guided long-division steps, which is unique content not in NetDrill. Low concern.

### Assessment

The overlap is **intentional and pedagogically sound** — the same concepts are reinforced through different game mechanics (drill, arcade, RPG, drag-drop, timed challenge). The only concerning duplicate is **OSI Tower Stage 1 vs. NetDrill OSI Tab**, which are nearly identical in both mechanic and content. One of them could link to the other instead of duplicating the exercise.

---

## 6. Missing Completion States

| Tool/Game | What Happens at "End" | Issue |
|-----------|-----------------------|-------|
| All 4 Challenge Lab Quizzes | `qIdx = (qIdx+1) % QUIZ.length` — wraps to question 1 silently | No completion screen, score keeps accumulating infinitely |
| All 4 Challenge Lab Drills | `dIdx = (dIdx+1) % DRILLS.length` — wraps silently | Same as above |
| Subnet Quest (all zones cleared) | Counter shows `ZONES: 6/6`, nothing else | No final victory screen |
| Bit Flip Speed Mode | Shows "TIME UP! Score: X", then stuck | No restart prompt or summary |
| NetDrill drills (all 5 types) | Infinite — "Next" always generates a new problem | No endpoint, but this is acceptable for practice tools |

---

## 7. Input Validation Gaps

### NetDrill Subnet Calculator — accepts invalid IPs
**File:** `Networking/subnetting.html`, lines 2272-2276

The regex `^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$` accepts IPs like `999.999.999.999`. No per-octet range check (0-255). The calculator silently produces garbage output for invalid IPs.

Same issue in the AND Visualizer (line 2238).

### Challenge Lab Drills — no input sanitization
**Files:** `Challenges1.html`, `Challenges2.html`, `Challenges3.html`

When showing the expected answer on wrong submission, the answer string is injected via `innerHTML` without HTML escaping. Only `Challenges4.html` (Bash) escapes `<` and `>`. The others are vulnerable to rendering issues if answers contain HTML characters.

---

## 8. Consistency Issues Across Labs

| Aspect | Python | PowerShell | Batch | Bash |
|--------|--------|------------|-------|------|
| Drill count | 20 | 20 | **15** | 20 |
| Quiz count | 20 | 20 | **15** | 20 |
| Quiz answer distribution | Varied (0,1,2) | **All index 0** | **All index 0** | **All index 0** |
| Drill format | Type full line | Type full line | **Fill-in-blank** | Type full line |
| Case sensitivity | Case-sensitive | **Case-sensitive** (should be insensitive) | Case-insensitive | Case-sensitive |
| HTML escaping in feedback | No | No | No | **Yes** |
| `# TODO` regex | Non-global | Non-global | Global (`/g`) | Global (`/g`) |

Notable: **PowerShell is a case-insensitive language** but the drill requires exact case matching. Typing `Get-childitem` instead of `Get-ChildItem` would be marked wrong even though PowerShell treats them identically.

---

## 9. Mobile / Touch Support Gaps

| Feature | Mobile Support |
|---------|---------------|
| OSI Tower (drag-and-drop) | **Non-functional** — HTML5 drag-and-drop doesn't work on touch devices |
| NetDrill OSI Tab (drag-and-drop) | **Non-functional** — same issue |
| Subnet Invaders (keyboard controls) | **Non-functional** — requires keyboard for movement/shooting |
| All other tools | Functional with responsive CSS breakpoints |

---

## 10. Low-Priority / Polish Items

- **404.html** uses `Courier New` font while the rest of the site uses `JetBrains Mono`
- **index.html** `<title>` says "Networking Fundamentals" but site also covers scripting labs
- No `<meta name="description">` on any page
- No semantic HTML landmarks (`<main>`, `<nav>`, `<header>`) on index.html
- Card icons in index.html missing `aria-hidden="true"` for screen readers
- No `:focus-visible` styles on card links for keyboard navigation
- SubnettingSheet.html has no `@media print` styles (theme button prints, dark backgrounds waste ink)
- SubnettingSheet.html editable cells have no persistence (lost on reload)
- README repo structure tree omits `SubnettingSheet.html`
- README doesn't mention `NetConfig.md`, `NetConfigLab.md`, or data files

---

## 11. What's Working Well

- **All 10 internal links from index.html resolve correctly** — no broken links
- **Card descriptions accurately match their target pages**
- **Core subnet math is correct** — `ipToInt`, `intToIp`, `cidrToMask`, `calcSubnet` all produce accurate results
- **Question banks in Invaders and Quest are factually correct** (80+ questions verified)
- **Responsive CSS** is present on most pages with sensible breakpoints
- **Tab systems** work reliably across all pages
- **Python lab** is the gold standard — varied quiz positions, accurate content, good drill design
- **Hex Trainer guided mode** is unique and pedagogically strong (long-division visualization)
- **Consistent dark theme** with CSS custom properties across all pages
- **Zero external dependencies** — no build step, no framework, everything loads fast

---

## Summary Counts

| Category | Count |
|----------|-------|
| Critical / game-breaking bugs | 3 |
| Navigation dead ends | 2 |
| Broken workflows / logic bugs | 9 |
| Content accuracy errors | 11 |
| Missing completion states | 5 |
| Input validation gaps | 2 |
| Consistency issues | 7 |
| Mobile/touch gaps | 3 |
| Low-priority polish items | 10 |
| **Total findings** | **52** |
