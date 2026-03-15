**Lesson-by-lesson breakdown of Module 15 – Command Syntax Notation**
---

## Module 15 – Command Syntax Notation

---

## Lesson 1: Why Syntax Notation Matters

### Key Concepts

* Every CLI tool has a **synopsis** — a compact description of how to use it
* Man pages, help screens, and documentation all use the **same notation conventions**
* If you can read syntax notation, you can use **any command** without a tutorial
* This is a foundational skill for working with Linux, networking gear, PowerShell, and APIs

### The Man Page Synopsis

When you run `man cp` or `cp --help`, the first thing you see is the **SYNOPSIS**:

```
cp [OPTION]... [-T] SOURCE DEST
cp [OPTION]... SOURCE... DIRECTORY
cp [OPTION]... -t DIRECTORY SOURCE...
```

This tells you **every valid way** to invoke the command — if you can read the notation.

---

## Lesson 2: The Core Notation Symbols

### Square Brackets — `[optional]`

Square brackets mean the enclosed item is **optional**. You can include it or leave it out.

```
ls [OPTION]... [FILE]...
```

* `ls` — valid (no options, no file)
* `ls -l` — valid (one option)
* `ls -la /home` — valid (options + file)

### Angle Brackets — `<required>`

Angle brackets (or ALL CAPS without brackets) mean the item is **required**. You must provide it.

```
ssh <user>@<host>
ping <destination>
```

* `ssh admin@10.0.0.1` — valid
* `ssh` — **invalid** (missing required user and host)

**Note:** Some documentation uses ALL CAPS instead of angle brackets:

```
cp SOURCE DEST
```

Both `SOURCE` and `DEST` are required — they're placeholders you replace with actual values.

### Ellipsis — `...`

Three dots mean the preceding item can be **repeated** one or more times.

```
cp [OPTION]... SOURCE... DIRECTORY
```

* `cp file1.txt /backup/` — valid (one source)
* `cp file1.txt file2.txt file3.txt /backup/` — valid (multiple sources)
* `cp /backup/` — **invalid** (need at least one SOURCE)

### Pipe / Vertical Bar — `|`

The pipe means **choose one** from the given alternatives (mutually exclusive).

```
git {pull|push|fetch} [remote]
```

* `git pull` — valid
* `git push origin` — valid
* `git pull push` — **invalid** (pick one, not both)

### Curly Braces — `{choose|one}`

Curly braces group **mutually exclusive required** choices. You must pick exactly one.

```
ip {addr|link|route} show
```

* `ip addr show` — valid
* `ip link show` — valid
* `ip show` — **invalid** (must choose one from the group)

### Parentheses — `(group)`

Parentheses group items together, often combined with `|` for optional choices.

```
tar (-c|-x|-t) [-v] [-f file]
```

* `tar -cvf archive.tar /data` — valid (create, verbose, file)
* `tar -xf archive.tar` — valid (extract, file)

### Double Dash — `--`

Signals **end of options**. Everything after `--` is treated as an argument, not a flag.

```
rm -- -weird-filename
grep -- -pattern file.txt
```

Without `--`, the shell would try to interpret `-weird-filename` as a flag.

---

## Lesson 3: Placeholders and Metavariables

### What Are Metavariables?

Metavariables are **placeholder names** that you replace with actual values. They appear in UPPER CASE or inside angle brackets.

| Metavariable | What You Replace It With | Example |
|-------------|-------------------------|---------|
| `FILE` | An actual filename | `report.txt` |
| `DIR` or `DIRECTORY` | A directory path | `/home/admin/` |
| `HOST` | Hostname or IP address | `10.0.0.1` |
| `PORT` | A port number | `22` |
| `USER` | A username | `admin` |
| `PATTERN` | A search string or regex | `"error.*fatal"` |
| `COMMAND` | A command to execute | `ls -la` |
| `N` | A number | `5` |

### Real Examples

```
# Man page says:
head [-n N] [FILE]...

# You type:
head -n 20 access.log

# Man page says:
scp [OPTION] SOURCE... TARGET

# You type:
scp -r /local/dir admin@server:/remote/dir
```

---

## Lesson 4: Reading Real Man Page Synopses

### Example 1: `grep`

```
grep [OPTION]... PATTERN [FILE]...
```

Breaking it down:

| Part | Meaning |
|------|---------|
| `grep` | The command name (literal — type exactly this) |
| `[OPTION]...` | Zero or more optional flags (`-i`, `-r`, `-v`, etc.) |
| `PATTERN` | **Required** — the search pattern |
| `[FILE]...` | Zero or more optional files (defaults to stdin) |

Valid invocations:
* `grep "error" log.txt` — pattern + one file
* `grep -i "error" *.log` — option + pattern + multiple files
* `echo "test" | grep "test"` — pattern only (reads stdin)

### Example 2: `find`

```
find [PATH]... [EXPRESSION]
```

| Part | Meaning |
|------|---------|
| `find` | Command name |
| `[PATH]...` | Zero or more starting directories |
| `[EXPRESSION]` | Optional filter/action expressions |

Valid invocations:
* `find` — search current directory, list everything
* `find /var/log -name "*.log"` — path + expression
* `find /home /tmp -type f -size +10M` — multiple paths + expressions

### Example 3: `ip` (Networking)

```
ip [ OPTIONS ] OBJECT { COMMAND | help }
```

| Part | Meaning |
|------|---------|
| `ip` | Command name |
| `[ OPTIONS ]` | Optional global flags |
| `OBJECT` | **Required** — `addr`, `link`, `route`, etc. |
| `{ COMMAND \| help }` | **Required** — choose a subcommand OR `help` |

Valid invocations:
* `ip addr show` — object + command
* `ip -br link show` — option + object + command
* `ip route help` — object + help

### Example 4: Cisco IOS

```
Router(config)# ip route NETWORK MASK {NEXT-HOP | EXIT-INTERFACE} [AD]
```

| Part | Meaning |
|------|---------|
| `ip route` | Literal command |
| `NETWORK` | Required destination network |
| `MASK` | Required subnet mask |
| `{NEXT-HOP \| EXIT-INTERFACE}` | Required — choose one |
| `[AD]` | Optional administrative distance |

Valid:
* `ip route 10.0.0.0 255.0.0.0 192.168.1.1`
* `ip route 10.0.0.0 255.0.0.0 GigabitEthernet0/1 5`

---

## Lesson 5: POSIX vs GNU vs Cisco vs PowerShell Conventions

### Comparison Across Platforms

| Convention | POSIX/Linux | GNU Long Form | Cisco IOS | PowerShell |
|-----------|-------------|---------------|-----------|------------|
| **Short flag** | `-l` | `-l` | N/A | N/A |
| **Long flag** | N/A | `--long` | N/A | `-Verbose` |
| **Required arg** | `FILE` | `FILE` | `NETWORK` | `<Path>` |
| **Optional** | `[FILE]` | `[FILE]` | `[AD]` | `[-Name <String>]` |
| **Repeatable** | `FILE...` | `FILE...` | N/A | `<String[]>` |
| **Choice** | `{a\|b}` | `{a\|b}` | `{a \| b}` | N/A |

### PowerShell Syntax Notation

PowerShell uses its own style in `Get-Help`:

```powershell
Get-ChildItem [[-Path] <String[]>] [-Filter <String>] [-Recurse] [-Force]
```

| Notation | Meaning |
|----------|---------|
| `[-Path]` | Parameter name is optional (positional) |
| `<String[]>` | Accepts one or more strings |
| `[-Recurse]` | Optional switch (no value needed) |
| `[-Filter <String>]` | Optional parameter that takes a string value |

---

## Lesson 6: Common Mistakes and Pitfalls

### Mistakes Beginners Make

| Mistake | Example | Why It's Wrong |
|---------|---------|---------------|
| Typing the brackets literally | `ls [OPTION]` | Brackets are notation — don't type them |
| Typing the angle brackets | `ssh <admin>@<host>` | Replace `<admin>` with the actual username |
| Skipping required arguments | `cp file.txt` | `cp` needs both SOURCE and DEST |
| Treating `\|` as "and" | `git pull push` | It means OR — choose one |
| Ignoring `...` | Only passing one file when multiple needed | `...` means you CAN pass more |
| Typing metavariables literally | `ping HOST` | Replace HOST with `10.0.0.1` |

### Quick Reference Card

```
NOTATION          MEANING                     TYPE IT?
─────────────────────────────────────────────────────
command           Literal — type exactly       YES
[optional]        Can omit                     NO brackets
<required>        Must provide                 NO brackets
UPPERCASE         Placeholder — replace it     REPLACE
...               Repeat previous item         N/A
{a|b}             Choose one                   NO braces
--                End of options               YES
-flag             Short option                 YES
--long-flag       Long option                  YES
```

---

## Summary

| Symbol | Name | Meaning | Required? |
|--------|------|---------|-----------|
| `[ ]` | Square brackets | Optional item | No |
| `< >` | Angle brackets | Required placeholder | Yes |
| `UPPER` | Metavariable | Replace with real value | Yes |
| `...` | Ellipsis | Repeatable | Depends |
| `{ \| }` | Braces + pipe | Choose exactly one | Yes |
| `( )` | Parentheses | Grouping | Depends |
| `--` | Double dash | End of options | Literal |

---

## Module 15 Objectives Covered

| Objective | Met By |
|-----------|--------|
| Read man page synopses | Symbol breakdown + real examples |
| Distinguish optional from required | `[ ]` vs `< >` vs UPPER CASE |
| Understand repeatable arguments | Ellipsis `...` notation |
| Parse mutually exclusive choices | `{ a \| b }` notation |
| Apply across platforms | POSIX, GNU, Cisco, PowerShell comparison |
| Avoid common syntax mistakes | Pitfall table + quick reference card |
