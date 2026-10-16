# Python

A four-hour, no-install Python course for beginners, plus self-study tools. Everything runs in the browser.

| File | For | What it is |
|---|---|---|
| `PythonTerminal.html` | Learners | Real Python (Pyodide) in a terminal. A 40-rung ladder: 20 fundamentals, then 20 Codewars kata from 7 kyu down to 4 kyu. `test()` checks your function. Progress is saved in the browser. |
| `slides/index.html` | Instructor | The session deck. Press **Presenter** for leader notes on a second screen. |
| `Challenges1.html` | Learners | Reference tab, 20 fill-in drills, 20-question quiz. |
| `Challenges1.py` | Learners | 50 TODO functions with expected outputs, for offline practice in any editor. |

## Running the session

1. Send learners the Terminal link the day before. Ask them to open it and type `2 + 2`. It downloads about 30 MB from a CDN the first time; locked-down laptops and ad blockers can block it.
2. Open `slides/index.html`, click **Presenter**. The notes are headed by step and include what to prepare, what to say, and what to watch for.
3. Pairs in breakout rooms, swapping who types every challenge. After each exercise, three debrief questions: does it pass, what input breaks it, which version reads best.

The agenda and all learner-facing text are in the deck. Nothing needs installing on any machine.

## Editing the content

The deck and the terminal's challenge list are generated from two files in `slides/`:

- `session.py`: the fundamentals blocks (concept text, which challenges, the discussion prompt, quiz questions, leader notes), the agenda, the debrief questions.
- `kata.py`: the 20 Codewars kata. Each one's `code` is the solution the deck shows and the tests the terminal runs are derived from the same entry.

Rebuild with:

```
cd slides
python build.py
```

The build refuses to write if any kata solution fails its own tests under the terminal's comparison rule, or if two challenges share a function name. `python build.py --check` runs only the checks.

Do not edit the `CHALLENGES` array in `PythonTerminal.html` by hand; it sits between `BEGIN GENERATED` and `END GENERATED` markers and is overwritten by the build.

## How the terminal checks an answer

It calls your function and compares `repr(result)` to the expected text, allowing either quote style. Returning `32` where `32.0` is expected fails. Returning a `Counter` or `dict_keys` where a `dict` or `list` is expected fails, and the message shows both values. That is deliberate: return the type the caller asked for.

## Offline

The slides are fully offline (reveal.js and fonts are vendored). The terminal needs internet for Pyodide and xterm from jsdelivr.
