# FOC Code Audit Report

**Date:** 2026-02-19
**Last Updated:** 2026-03-05
**Scope:** Full front-to-back audit — dead ends, broken workflows, user-disrupting issues, and game overlap

---

## Executive Summary

FOC is a vanilla HTML/JS/CSS educational platform with 7 networking games/tools, 1 multi-module study tool (NetDrill), 5 scripting/data challenge labs, and supplementary reference pages. Previous audit found 52 issues. Many have been resolved. This report tracks remaining open items.

---

## Table of Contents

1. [Resolved Issues](#1-resolved-issues)
2. [Remaining Broken Workflows & Logic Bugs](#2-remaining-broken-workflows--logic-bugs)
3. [Remaining Content Accuracy Notes](#3-remaining-content-accuracy-notes)
4. [Game Overlap Analysis](#4-game-overlap-analysis)
5. [Remaining Low-Priority Items](#5-remaining-low-priority-items)
6. [What's Working Well](#6-whats-working-well)

---

## 1. Resolved Issues

The following issues from the original audit have been fixed:

| # | Issue | Resolution |
|---|-------|-----------|
| 1.1 | OSI Tower Stage 2/3 impossible (duplicate "Data" values) | Fixed — each chip now tracked by unique ID, not value |
| 1.2 | Hex Trainer TypeError crash after "I KNOW IT" | Fixed — `skippedGuided` flag prevents `checkGuided()` from accessing removed DOM |
| 1.3 | Quiz answers always at index 0 (PowerShell, Batch, Bash) | Fixed — correct answer positions now distributed (c:0-3) and shuffled at runtime |
| 2.1 | NetDrill no back/home link | Fixed — prominent Home link added to top of page |
| 2.2 | SubnettingSheet orphaned (no navigation) | Fixed — Home link added, page linked from index.html |
| 4.x | SubnettingSheet 7 data errors | Fixed — binary values, hex calculations, IP classes all corrected |
| 6.x | Challenge lab quizzes/drills wrap silently | Fixed — completion screens added with final score and restart buttons |
| 8.x | PowerShell case sensitivity | Drills now use case-insensitive comparison via `.toLowerCase()` |

---

## 2. Remaining Broken Workflows & Logic Bugs

### 2.1 Subnet Invaders — life-drain cascade
**File:** `Networking/invaders.html`, lines 629-641

Once enemies cross the danger line, `enemyBaseY` is never reset. Every subsequent wrong answer costs an additional life, creating a rapid-death spiral.

### 2.2 Bit Flip — speed mode dead end after timer expires
**File:** `Networking/bitflip.html`, lines 284-293

When the 60-second timer hits 0, the game shows "TIME UP!" but leaves the user stranded with no restart prompt.

### 2.3 Subnet Quest — no overall game completion
**File:** `Networking/quest.html`

Clearing all 6 zones updates the counter to `ZONES: 6/6` but shows no victory screen.

### 2.4 Subnet Quest — infinite XP farming
**File:** `Networking/quest.html`, lines 536-538

Cleared zones remain clickable and award XP on re-completion.

### 2.5 NetDrill Protocol Quiz — "Both" is never correct
**File:** `Networking/subnetting.html`, lines 1536-1542

TCP/UDP quiz filters exclude dual-stack protocols like DNS. The "Both" option appears but can never be correct.

### 2.6 NetDrill — all drill sections allow double-scoring
**File:** `Networking/subnetting.html` (lines 1962, 2031, 2091, 2154, 2201)

Clicking "Check" multiple times increments score each time. No guard flag.

### 2.7 Challenge Labs — drill check button not disabled after submission
**Files:** `Challenges1.html`, `Challenges2.html`, `Challenges3.html`, `Challenges4.html`

The "Check" button remains active after grading. Rapid clicking inflates score.

### 2.8 Batch Lab — Drill #4 and #6 confusing format
**File:** `Challenges3.html`

Drill #4's blank-fill template doesn't match the expected answer format. Drill #6 has two blanks but expects a single answer spanning both.

---

## 3. Remaining Content Accuracy Notes

### Bash Lab — answer/test mismatches

| Drill | Issue |
|-------|-------|
| `print_banner` | Answer pads with spaces but test description shows `=` padding |
| `count_words` | `wc -w` may include leading whitespace not shown in test |
| `sort_unique` | Answer produces trailing space in output |

### NetDrill Reference Table — debatable layer assignments

| Protocol | Listed Layer | Common Alternative |
|----------|-------------|-------------------|
| ARP | Layer 3 | Often considered Layer 2 or L2/L3 boundary |
| Bluetooth | Layer 1 only | Spans L1-L2 |

---

## 4. Game Overlap Analysis

The overlap across networking games is **intentional and pedagogically sound** — the same concepts are reinforced through different game mechanics (drill, arcade, RPG, drag-drop, timed challenge). See the original audit for the full overlap matrix.

---

## 5. Remaining Low-Priority Items

- `404.html` uses `Courier New` font while the rest uses `JetBrains Mono`
- No `<meta name="description">` on any page
- No semantic HTML landmarks (`<main>`, `<nav>`, `<header>`) on index.html
- Card icons in index.html missing `aria-hidden="true"` for screen readers
- No `:focus-visible` styles on card links for keyboard navigation
- SubnettingSheet.html has no `@media print` styles
- SubnettingSheet.html editable cells have no persistence (lost on reload)

---

## 6. What's Working Well

- **All internal links from index.html resolve correctly** — no broken links
- **Card descriptions accurately match their target pages**
- **Core subnet math is correct** across all tools
- **Question banks verified** (80+ questions in Invaders and Quest)
- **Responsive CSS** with sensible breakpoints on all pages
- **Tab systems** work reliably
- **Python lab** is the gold standard for drill/quiz design
- **Hex Trainer guided mode** is unique and pedagogically strong
- **Consistent dark theme** with CSS custom properties
- **Zero external dependencies** — no build step, no framework
- **Quiz answer shuffling** prevents pattern-guessing
- **Progress persistence** via localStorage on all challenge labs
- **Navigation links** on all pages back to index

---

## Summary Counts

| Category | Original | Resolved | Remaining |
|----------|---------|----------|-----------|
| Critical / game-breaking bugs | 3 | 3 | 0 |
| Navigation dead ends | 2 | 2 | 0 |
| Broken workflows / logic bugs | 9 | 1 | 8 |
| Content accuracy errors | 11 | 7 | 4 |
| Missing completion states | 5 | 4 | 1 |
| Input validation gaps | 2 | 0 | 2 |
| Consistency issues | 7 | 2 | 5 |
| Mobile/touch gaps | 3 | 0 | 3 |
| Low-priority polish items | 10 | 3 | 7 |
| **Total findings** | **52** | **22** | **30** |
