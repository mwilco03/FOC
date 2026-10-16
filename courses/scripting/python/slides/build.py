"""Build the Python course deck and the Terminal's challenge list from one content set.

    python build.py            # writes index.html, updates ../PythonTerminal.html
    python build.py --check    # only run the content self-tests

Content lives in session.py (fundamentals blocks, agenda, debrief) and
kata.py (20 Codewars kata with tested solutions). The deck follows the
lesson-template structure: title bar with step icon, stage, footer with a
discussion prompt and a badge that points at the learner's material, and
leader notes headed by step number.
"""
import builtins
import html
import io
import json
import keyword
import re
import sys
import tokenize
from pathlib import Path

from kata import KATA, RANKS
from session import AGENDA, BLOCKS, DEBRIEF, FUNDAMENTALS, FUNDAMENTALS_ORDER

HERE = Path(__file__).parent
TERMINAL = HERE.parent / "PythonTerminal.html"
TERMINAL_URL = "../PythonTerminal.html"
BUILTINS = set(dir(builtins))
STR_TOKENS = {tokenize.STRING}
for _n in ("FSTRING_START", "FSTRING_MIDDLE", "FSTRING_END"):
    if hasattr(tokenize, _n):
        STR_TOKENS.add(getattr(tokenize, _n))

esc = html.escape

# ---------------------------------------------------------------- icons
ICON = {
    "terminal": '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 9l3 3-3 3M12 15h5"/>',
    "code":     '<path d="M8 7l-5 5 5 5M16 7l5 5-5 5M14 4l-4 16"/>',
    "activity": '<path d="M12 3v4M12 17v4M3 12h4M17 12h4"/><circle cx="12" cy="12" r="3.3"/>',
    "quiz":     '<path d="M9 11l2.5 2.5L16 9"/><rect x="4" y="4" width="16" height="16" rx="3"/>',
    "talk":     '<path d="M20 12a7 7 0 0 1-9.8 6.4L4 20l1.6-4.2A7 7 0 1 1 20 12Z"/>',
    "book":     '<path d="M3 5a2 2 0 0 1 2-2h5v16H5a2 2 0 0 0-2 2V5Z"/><path d="M21 5a2 2 0 0 0-2-2h-5v16h5a2 2 0 0 1 2 2V5Z"/>',
    "star":     '<path d="M12 3l2.5 5.4 5.9.7-4.4 4 1.2 5.8L12 16.9 6.8 19l1.2-5.8-4.4-4 5.9-.7L12 3Z"/>',
    "clock":    '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    "flag":     '<path d="M5 21V4M5 4h11l-2 4 2 4H5"/>',
    "coffee":   '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V9Z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M7 4v2M11 4v2"/>',
}


def svg(name):
    return (f'<svg viewBox="0 0 24 24" fill="none" stroke-width="1.9" stroke-linecap="round" '
            f'stroke-linejoin="round">{ICON[name]}</svg>')


# ---------------------------------------------------------------- code
def highlight(code):
    """Return one HTML string per source line, with token spans."""
    lines = code.splitlines()
    marks = {i: [] for i in range(len(lines))}
    prev = None
    for tok in tokenize.generate_tokens(io.StringIO(code + "\n").readline):
        (r0, c0), (r1, c1) = tok.start, tok.end
        if r0 != r1 or r0 - 1 not in marks:
            continue
        cls = None
        if tok.type in STR_TOKENS:
            cls = "s"
        elif tok.type == tokenize.NUMBER:
            cls = "n"
        elif tok.type == tokenize.COMMENT:
            cls = "c"
        elif tok.type == tokenize.NAME:
            if prev is not None and prev.string in ("def", "@"):
                cls = "f"
            elif keyword.iskeyword(tok.string) or tok.string in ("True", "False", "None"):
                cls = "k"
            elif tok.string in BUILTINS:
                cls = "b"
            elif tok.string.isupper():
                cls = "u"
        elif tok.type == tokenize.OP and tok.string == "@":
            cls = "f"
        if cls:
            marks[r0 - 1].append((c0, c1, cls))
        if tok.type not in (tokenize.NL, tokenize.NEWLINE, tokenize.INDENT, tokenize.DEDENT):
            prev = tok
    out = []
    for i, line in enumerate(lines):
        pos, buf = 0, []
        for c0, c1, cls in sorted(marks[i]):
            if c0 < pos:
                continue
            buf.append(esc(line[pos:c0]))
            buf.append(f'<span class="t{cls}">{esc(line[c0:c1])}</span>')
            pos = c1
        buf.append(esc(line[pos:]))
        out.append("".join(buf) or " ")
    return out


def code_block(code):
    rows = highlight(code)
    body = "".join(
        f'<div class="ln" data-n="{i}"><span class="gut">{i}</span><span class="src">{r}</span></div>'
        for i, r in enumerate(rows, 1)
    )
    return f'<div class="code"><pre>{body}</pre></div>'


# ---------------------------------------------------------------- pieces
def kyu(rank):
    return f'<span class="kyu k{rank}"><span class="hex"></span>{rank} kyu</span>'


def bar(icon, title, kick=None, rank=None):
    k = f'<span class="kick">{esc(kick)}</span>' if kick else ""
    r = kyu(rank) if rank else ""
    return (f'<div class="bar"><span class="ico">{svg(icon)}</span>'
            f'<span class="ttl">{k}{esc(title)}</span>{r}</div>')


def foot(talk=None, badge=None):
    t = (f'<span class="talk"><span class="ico">{svg("talk")}</span><span><b>Talk about it:</b>{esc(talk)}</span></span>'
         if talk else "<span></span>")
    b = f'<span class="badge">{esc(badge)}</span>' if badge else ""
    return f'<div class="foot">{t}{b}</div>'


def details(summary, body, open_=True, cls=None):
    o = " open" if open_ else ""
    c = f' class="{cls}"' if cls else ""
    body = body if body.lstrip().startswith("<") else f"<p>{body}</p>"
    return f"<details{c}{o}><summary>{summary}</summary>{body}</details>"


def notes(step, lead=None, items=(), src=None, verbatim=(), anskey=None, bridge=None, tip=None):
    """Leader notes. items: (summary, body, open). verbatim: paragraphs read aloud."""
    p = ['<aside class="notes"><div class="notes-body">']
    if anskey:
        p.append('<div class="anskey"><h4>✓ Answer key</h4><ol>' +
                 "".join(f"<li>{a}</li>" for a in anskey) + "</ol></div>")
    if bridge:
        p.append(f'<div class="bridge"><h4>Bridge</h4><p>{bridge}</p></div>')
    p.append(f'<h4><span class="dot"></span>{esc(step)}</h4>')
    if src:
        p.append(f'<div class="srcbar">{src}</div>')
    if lead:
        p.append(f'<p class="lead">{lead}</p>')
    for it in items:
        summ, body = it[0], it[1]
        p.append(details(summ, body, it[2] if len(it) > 2 else True))
    if tip:
        p.append(details("Teaching tip", tip, True, "tip"))
    if verbatim:
        p.append(details("Read-aloud: learner-facing text (verbatim)",
                         "".join(f"<p>{esc(v)}</p>" for v in verbatim), False, "verbatim"))
    p.append("</div></aside>")
    return "".join(p)


def debrief_html():
    return "".join(f"<li><b>{esc(f)}:</b> {esc(q)} <span class=\"mute\">{esc(h)}</span></li>" for f, q, h in DEBRIEF)


def kata_url(k):
    return f"https://www.codewars.com/kata/{k['id']}"


def func_name(code):
    m = re.search(r"^def (\w+)\(", code, re.M)
    return m.group(1)


def sig_line(code):
    return next(l for l in code.splitlines() if l.startswith("def "))


# ---------------------------------------------------------------- ladder
def ladder():
    """[(level_label, [challenge dicts with name, sig, desc, tests, rank])] in terminal order."""
    rungs = [("Fundamentals", [dict(name=n, rank=None, **FUNDAMENTALS[n]) for n in FUNDAMENTALS_ORDER])]
    for r in (7, 6, 5, 4):
        rungs.append((f"{r} kyu", [
            dict(name=func_name(k["code"]), sig=sig_line(k["code"]), rank=r,
                 desc=f"{k['task']} (Codewars, {r} kyu: {k['name']})",
                 tests=[(c, repr(e)) for c, e in k["tests"]], kata=k)
            for k in KATA if k["rank"] == r]))
    return rungs


def terminal_index():
    """name -> 1-based position in the terminal."""
    idx, n = {}, 0
    for _, items in ladder():
        for it in items:
            n += 1
            idx[it["name"]] = n
    return idx


# ---------------------------------------------------------------- slides
def cover():
    return f"""<section class="dark" data-background-color="#0a0e17">
<div class="cover">
  <div class="mark">&gt;&gt;&gt;</div>
  <div class="kick">FOC · Scripting · Python</div>
  <h1>Python from zero to kata</h1>
  <div class="rule"></div>
  <p class="verse">One browser tab, no installs. Twenty fundamentals in pairs, then Codewars kata from 7 kyu to 4 kyu, each one solved step by step.</p>
  <div class="ranks">{''.join(kyu(r) for r in (7, 6, 5, 4))}</div>
</div>
{notes("Before the session",
       "Four hours, remote, beginners on their own laptops. The only link learners need is the Python Terminal.",
       [("Prepare", "Send the Terminal link the day before and ask everyone to open it and type 2 + 2. It downloads about 30 MB from a CDN on first load, and locked-down laptops or ad blockers can stop it. Better to find out the day before."),
        ("Prepare", "Open this deck and press Presenter to get these notes on your second screen. Have the Terminal open in another tab for live typing."),
        ("Consider", "Progress is saved in the learner's browser. A private window or cleared site data loses it. Say so at the open.")])}
</section>"""


def open_slide():
    return f"""<section>
{bar("terminal", "Open the Python Terminal", "Step 1 · Open")}
<div class="stage withfoot">
  <div class="keyline">Open the Terminal link, wait for “Python ready”, type <code>2 + 2</code>.</div>
  <p class="read">The terminal is real Python running in your browser. Nothing to install, nothing to sign up for.</p>
  <p class="read">The panel at the top shows one challenge at a time. You write the function in the terminal, then type <code>test()</code> to check it.</p>
  <ul class="blist">
    <li><code>test()</code> runs the checks for the current challenge</li>
    <li><code>next()</code> and <code>prev()</code> move along the ladder, <code>challenge(7)</code> jumps</li>
    <li><code>help()</code> lists everything, <code>reset()</code> clears your attempt</li>
  </ul>
</div>
{foot("What did 2 + 2 print, and what did 7 / 2 print?", "Terminal · challenge 1")}
{notes("Step 1 · Open",
       "Goal: every laptop shows the prompt and has run one line of Python. Nothing else happens until this is true.",
       [("Direct", "Share the link in chat. Ask everyone to type 2 + 2 and then 7 / 2 and report both answers in chat. The second one makes the point that / gives decimals."),
        ("Direct", "Pair people up now and put them in breakout rooms of two. One types, one reads the tests aloud. They swap every challenge."),
        ("Consider", "If a laptop shows “Failed to Load”, the CDN is blocked. Pair that person with someone whose terminal works and move on; do not debug networks on the clock.")],
       verbatim=["Open the Terminal link, wait for Python ready, type 2 + 2.",
                 "The terminal is real Python running in your browser. Nothing to install, nothing to sign up for.",
                 "The panel at the top shows one challenge at a time. You write the function in the terminal, then type test() to check it."])}
</section>"""


def how_slide():
    rungs = [("Fundamentals", "1–20", None, "Functions, loops, strings, lists, dicts")]
    idx = terminal_index()
    for r in (7, 6, 5, 4):
        names = [func_name(k["code"]) for k in KATA if k["rank"] == r]
        rungs.append((RANKS[r][0], f"{idx[names[0]]}–{idx[names[-1]]}", r, f"{r} kyu Codewars kata"))
    rows = "".join(
        f'<div class="rung">{kyu(r) if r else "<span></span>"}<span class="lvl">{esc(t)}<small>{esc(d)}</small></span><span class="tn">{n}</span></div>'
        for t, n, r, d in rungs)
    deb = "".join(
        f'<div class="howcard"><div class="hnum">{i}</div><h3>{esc(f)}: {esc(q)}</h3><p>{esc(h)}</p></div>'
        for i, (f, q, h) in enumerate(DEBRIEF, 1))
    return f"""<section>
{bar("flag", "How the day works", "Read me first")}
<div class="stage">
  <div class="how">
    <div class="howcol">
      <div class="howcard"><div class="hnum">★</div><h3>Pairs. Swap who types every challenge.</h3><p>One types, the other reads the tests aloud and watches for the red line.</p></div>
      {deb}
    </div>
    <div class="ladder"><h3>The ladder, easiest first</h3>{rows}</div>
  </div>
</div>
{notes("Step 1 · Open",
       "Say the three debrief questions once, then use them after every exercise without re-explaining.",
       [("Direct", "After each exercise, bring the rooms back and ask the three questions in order. Battle is a show of hands. Flawless wants one concrete input. Daybreak needs two solutions on screen; ask a pair to paste theirs in chat."),
        ("Consider", "No scores, no rankings during the session. The terminal keeps a score for the learner only; do not read it out.")])}
</section>"""


def agenda_slide():
    rows = "".join(f'<tr><td class="n">{esc(t)}</td><td><b>{esc(b)}</b></td><td>{esc(d)}</td></tr>' for t, b, d in AGENDA)
    return f"""<section>
{bar("clock", "Four hours", "Agenda")}
<div class="stage">
  <table class="acttable"><tr><th>Time</th><th>Block</th><th>What happens</th></tr>{rows}</table>
</div>
{notes("Step 1 · Open",
       "The minutes are a plan, not a measurement. Fundamentals blocks run about twenty minutes each: five for the concept, ten in pairs, five to debrief.",
       [("Consider", "If the room is slow, drop the stretch block, not the debriefs. The debrief is where the learning is said out loud."),
        ("Consider", "If the room is fast, the 6 kyu kata are in the terminal already. Point pairs at them and keep the debrief rhythm.")])}
</section>"""


def concept_slide(b, step):
    reads = "".join(f'<p class="read">{esc(t)}</p>' for t in b["read"])
    return f"""<section>
{bar("code", b["title"], f"Step {step} · Concept")}
<div class="stage withfoot">
  <div class="concept">
    <div class="txt"><div class="keyline">{esc(b["keyline"])}</div>{reads}</div>
    {code_block(b["code"])}
  </div>
</div>
{foot(None, "Python Lab · Reference tab")}
{notes(f"Step {step} · {b['title']}",
       "Five minutes. Read the key line, run the code on the right live in the terminal, then send pairs to the activity.",
       [("Prepare", b["prepare"]),
        ("Direct", "Type the example on the right into the terminal yourself while they watch. Typing, not pasting: they need to see where Enter goes.")],
       verbatim=[b["keyline"], *b["read"]])}
</section>"""


def activity_slide(b, step):
    idx = terminal_index()
    nums = [idx[n] for n in b["challenges"]]
    cards = "".join(
        f'<div class="acard fragment rise" data-fragment-index="{i}"><span class="tn">{idx[n]}</span>'
        f'<div><div class="stem">{esc(FUNDAMENTALS[n]["desc"])}</div>'
        f'<div class="sig"><b>{esc(FUNDAMENTALS[n]["sig"])}</b> &nbsp; {esc(FUNDAMENTALS[n]["tests"][0][0])} → {esc(FUNDAMENTALS[n]["tests"][0][1])}</div></div></div>'
        for i, n in enumerate(b["challenges"], 1))
    rng = f"{nums[0]}–{nums[-1]}" if len(nums) > 1 else f"{nums[0]}"
    tests = [f"{n}: " + "  ".join(f"{c} == {e}" for c, e in FUNDAMENTALS[n]["tests"]) for n in b["challenges"]]
    return f"""<section>
{bar("activity", f"In pairs: challenges {rng}", f"Step {step} · Activity")}
<div class="stage withfoot">
  <p class="act-intro">Type <code>challenge({nums[0]})</code>. Write the function, run <code>test()</code>, swap, <code>next()</code>.</p>
  {cards}
</div>
{foot(b["talk"], f"Terminal · {rng}")}
{notes(f"Step {step} · {b['title']}",
       f"Ten minutes in breakout rooms. Then the three debrief questions.",
       [("Direct", b["direct"]),
        ("Consider", b["consider"]),
        ("All tests the terminal runs", "<ul>" + "".join(f"<li><code>{esc(t)}</code></li>" for t in tests) + "</ul>", False)],
       verbatim=[f"Type challenge({nums[0]}). Write the function, run test(), swap, next().",
                 *[FUNDAMENTALS[n]["desc"] for n in b["challenges"]]])}
</section>"""


def quiz_slide(b, step):
    cards = []
    key = []
    for i, (q, opts, c) in enumerate(b["quiz"], 1):
        o = "".join(f'<div class="opt"><span class="lt">{"abcd"[j]}.</span>{esc(t)}</div>' for j, t in enumerate(opts))
        cards.append(f'<div class="qcard fragment rise" data-fragment-index="{i}"><div class="stem"><span class="qn">{i}.</span>{esc(q)}</div><div class="opts">{o}</div></div>')
        key.append(f"<b>{i}.</b> {'abcd'[c]}. {esc(opts[c])}")
    return f"""<section>
{bar("quiz", "Quick check", f"Step {step} · Check your understanding")}
<div class="stage withfoot">{''.join(cards)}</div>
{foot(None, "Python Lab · Quiz tab")}
{notes(f"Step {step} · {b['title']}",
       "Two minutes. Answers in chat as a single letter, then reveal. Wrong answers are the useful ones: ask what made the wrong option look right.",
       [("Direct", "Reveal one question at a time with Next. Give ten seconds, read the room, move on.")],
       anskey=key)}
</section>"""


def break_slide():
    return f"""<section class="dark" data-background-color="#0a0e17">
<div class="cover">
  <div class="mark">{svg("coffee").replace('viewBox', 'style="width:1em;height:1em;stroke:#06b6d4" viewBox')}</div>
  <h1>Break</h1>
  <div class="rule"></div>
  <p class="verse">Fifteen minutes. Leave the terminal tab open: your progress is saved in this browser, but a closed private window is gone.</p>
</div>
{notes("Break", "Fifteen minutes. Say the time you will restart, in their time zone if the room spans several.",
       [("Prepare", "Use the break to open the first 7 kyu kata in your own terminal so the walkthrough starts with the problem already on screen.")])}
</section>"""


def divider(rank, step):
    name, blurb = RANKS[rank]
    idx = terminal_index()
    items = [k for k in KATA if k["rank"] == rank]
    li = "".join(
        f'<li><span class="dn">{esc(k["name"])}<span class="tn">#{idx[func_name(k["code"])]}</span></span><span class="ds">{esc(k["skill"])}</span></li>'
        for k in items)
    bridge = {
        7: "You have written twenty functions today. A kata is the same thing with a story around it: here is what comes in, here is what must come out, and the tests are hidden. Same three questions after each one.",
        6: "7 kyu was about knowing the built-ins. 6 kyu is about choosing a data structure before you write the loop.",
        5: "The 5 kyu kata each hinge on one idiom: a stack, a decorator, a regex, a sort key. Learn the idiom, the kata falls.",
        4: "4 kyu problems are several small problems in a trench coat. The skill is splitting them.",
    }[rank]
    return f"""<section class="dark" data-background-color="#0a0e17">
<div class="dv">
  <div class="dv-head">{kyu(rank)}<h2>{esc(name)}</h2></div>
  <p class="dv-blurb">{esc(blurb)}</p>
  <ol class="dv-list">{li}</ol>
</div>
{notes(f"Step {step} · {rank} kyu kata",
       f"{rank} kyu: {esc(name.lower())}. {esc(blurb)} The numbers are the terminal challenge numbers.",
       [(esc(k["name"]), esc(k["skill"]), False) for k in items],
       bridge=esc(bridge))}
</section>"""


def problem_slide(k, step, n):
    call, result = k["example"]
    fname = func_name(k["code"])
    return f"""<section>
{bar("book", k["name"], f"Step {step} · Kata · The problem", k["rank"])}
<div class="stage withfoot">
  <div class="prob">
    <p class="task">{esc(k["task"])}</p>
    <div class="ex">
      <div class="exl">Example</div><div class="excall"><code>{esc(call)}</code></div>
      <div class="exarrow">returns</div><div class="exres"><code>{esc(result)}</code></div>
    </div>
    <div class="skill"><span class="sl">Python skill</span>{esc(k["skill"])}</div>
  </div>
</div>
{foot("What type comes in, what type goes out, and which built-in does half the job?", f"Terminal · {n}")}
{notes(f"Step {step} · {k['rank']} kyu kata",
       esc(k["task"]),
       [("Direct", f"Pairs type <code>challenge({n})</code> and get five minutes with only the tests. Then the walkthrough on the next slide, one step per Next."),
        ("Debrief", "<ul>" + debrief_html() + "</ul>")],
       src=f'Source • Codewars kata » <a href="{kata_url(k)}">{kata_url(k)}</a>',
       verbatim=[k["task"], f"Example: {call} returns {result}"])}
</section>"""


def walk_slide(k, step, n):
    steps = "".join(
        f'<li class="fragment" data-lines="{",".join(map(str, lines))}">'
        f'<span class="sn">{i}</span><div><code class="op">{esc(op)}</code><p class="why">{esc(why)}</p></div></li>'
        for i, (lines, op, why) in enumerate(k["steps"], 1))
    items = [(f"Step {i}: <code>{esc(op)}</code>", esc(why), True) for i, (_, op, why) in enumerate(k["steps"], 1)]
    return f"""<section class="walk">
{bar("code", k["name"], f"Step {step} · Kata · Step by step", k["rank"])}
<div class="stage withfoot">
  <div class="wk">{code_block(k["code"])}<ol class="steps">{steps}</ol></div>
</div>
{foot("Which version in the room reads best, this one or yours?", f"Terminal · {n}")}
{notes(f"Step {step} · {k['rank']} kyu kata",
       f"{len(k['steps'])} steps. Press Next for each one; the lines it covers light up.",
       items, tip=k["notes"])}
</section>"""


def close_slide():
    return f"""<section>
{bar("star", "Where to keep practicing", "Step 8 · Close")}
<div class="stage withfoot">
  <div class="keyline">Your progress is saved in this browser. Come back to the same link on the same laptop and carry on up the ladder.</div>
  <ul class="blist">
    <li><b>Homework:</b> three Codewars kata at 8 kyu. Make a free account at codewars.com and pick Python.</li>
    <li><b>After you pass a kata,</b> read three other people's solutions. That is the fastest way to pick up idioms.</li>
    <li><b>The Python Lab</b> has the reference tab and a twenty-question quiz for review.</li>
    <li><b>The terminal</b> keeps going: 6 kyu, 5 kyu, 4 kyu are already in it.</li>
  </ul>
</div>
{foot("One thing you can do now that you could not this morning?", "Terminal · 1–40")}
{notes("Step 8 · Close",
       "Go round the room, or the chat, with the one question in the footer. Everyone answers, one sentence each.",
       [("Direct", "Paste the Terminal link and the Codewars link in chat before people leave."),
        ("Consider", "Ask for one piece of feedback in chat: which block was too fast.")])}
</section>"""


def recap_slide():
    idx = terminal_index()
    rows = "".join(
        f'<tr><td>{kyu(k["rank"])}</td><td class="rn">{esc(k["name"])}</td><td class="n">#{idx[func_name(k["code"])]}</td><td>{esc(k["skill"])}</td></tr>'
        for k in KATA)
    return f"""<section>
{bar("book", "The 20 kata and the skill each one teaches", "Reference")}
<div class="stage recap"><table>{rows}</table></div>
{notes("Reference", "One line per kata. The number is its position in the terminal.")}
</section>"""


# ---------------------------------------------------------------- page
NAV = """<nav id="navbar" aria-label="Slide navigation">
  <button data-act="prev" title="Previous (&larr;)"><svg viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7"/></svg></button>
  <span class="count"><span id="cur">1</span>/<span id="tot">1</span></span>
  <button data-act="next" title="Next (&rarr; / Space)"><svg viewBox="0 0 24 24"><path d="M9 5l7 7-7 7"/></svg></button>
  <span class="sep"></span>
  <button data-act="present" title="Presenter view (notes on another screen)"><svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="13" rx="2"/><path d="M8 20h8M12 17.5v2.5"/></svg><span class="lbl">Presenter</span></button>
  <button data-act="full" title="Fullscreen (F)"><svg viewBox="0 0 24 24"><path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/></svg></button>
</nav>"""


def build_deck():
    slides = [cover(), open_slide(), how_slide(), agenda_slide()]
    step = 2
    for b in BLOCKS:
        slides += [concept_slide(b, step), activity_slide(b, step), quiz_slide(b, step)]
        step += 1
    slides.append(break_slide())
    idx = terminal_index()
    kstep = step  # one step number for all kata, as the lesson template does for one phase
    for rank in (7, 6, 5, 4):
        slides.append(divider(rank, kstep))
        for k in (k for k in KATA if k["rank"] == rank):
            n = idx[func_name(k["code"])]
            slides += [problem_slide(k, kstep, n), walk_slide(k, kstep, n)]
    slides += [close_slide(), recap_slide()]
    js = (HERE / "deck.js").read_text(encoding="utf-8")
    page = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FOC · Python from zero to kata</title>
<link rel="stylesheet" href="vendor/reveal/reveal.css">
<link rel="stylesheet" href="vendor/foc-deck.css">
</head><body>
<div class="reveal"><div class="slides">
{chr(10).join(slides)}
</div></div>
{NAV}
<script src="vendor/reveal/reveal.js"></script>
<script>
{js}
</script>
</body></html>
"""
    (HERE / "index.html").write_text(page, encoding="utf-8", newline="\n")
    return len(slides), len(page)


# ---------------------------------------------------------------- terminal
BEGIN = "// BEGIN GENERATED"
END = "// END GENERATED"


def js_str(s):
    return json.dumps(s, ensure_ascii=False)


def build_terminal():
    src = TERMINAL.read_text(encoding="utf-8")
    i = src.index(BEGIN)
    i = src.index("\n", i) + 1
    j = src.index(END)
    lines = ["const CHALLENGES = ["]
    for level, items in ladder():
        lines.append(f"  // ---- {level}")
        for it in items:
            tests = ",".join(f"[{js_str(c)},{js_str(e)}]" for c, e in it["tests"])
            lines.append(f"  {{ name:{js_str(it['name'])}, level:{js_str(level)}, sig:{js_str(it['sig'])}, desc:{js_str(it['desc'])},")
            lines.append(f"    tests:[{tests}] }},")
    lines.append("];")
    out = src[:i] + "\n".join(lines) + "\n" + src[j:]
    TERMINAL.write_text(out, encoding="utf-8", newline="\n")
    return sum(len(items) for _, items in ladder())


# ---------------------------------------------------------------- checks
def harness_pass(actual, expected):
    """The terminal's comparison rule, kept identical to _test_challenge."""
    return actual == expected or actual.replace("'", '"') == expected.replace("'", '"')


def check():
    """Every kata solution must pass its own tests under the terminal's rule,
    and no two challenges may share a function name."""
    bad = 0
    names = []
    for level, items in ladder():
        for it in items:
            names.append(it["name"])
            if "kata" not in it:
                continue
            ns = {}
            exec(it["kata"]["code"], ns)
            for call, expected in it["tests"]:
                try:
                    actual = repr(eval(call, ns))
                except Exception as e:  # noqa: BLE001
                    actual = f"RAISED {e}"
                if not harness_pass(actual, expected):
                    bad += 1
                    print(f"FAIL {level} {call}: expected {expected!r}, got {actual!r}")
    dup = {n for n in names if names.count(n) > 1}
    if dup:
        bad += 1
        print("DUPLICATE names:", dup)
    print(f"check: {len(names)} challenges, {bad} problems")
    return bad == 0


if __name__ == "__main__":
    ok = check()
    if "--check" in sys.argv:
        sys.exit(0 if ok else 1)
    if not ok:
        sys.exit(1)
    n, size = build_deck()
    print(f"index.html: {n} slides, {size:,} bytes")
    print(f"PythonTerminal.html: {build_terminal()} challenges written")
