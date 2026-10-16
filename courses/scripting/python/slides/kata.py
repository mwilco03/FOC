"""Deck content: 20 Codewars kata, 5 per rank.

Each kata's `code` is exactly what the slide shows and exactly what
test_kata.py executes, so the slides cannot drift from a working solution.
Each step names the code lines it covers (1-based), the operation, and why.
"""

RANKS = {
    7: ("Basic syntax", "Strings, loops, conversions, and the built-in functions you reach for every day."),
    6: ("Data structures", "Dictionaries, counters, tuples, and lists used to model a problem."),
    5: ("Idioms", "Stacks, decorators, regular expressions, and sort keys."),
    4: ("Putting it together", "Multi-step problems that combine everything before them."),
}

KATA = [
    # ------------------------------------------------------------------ 7 kyu
    dict(
        rank=7, name="Disemvowel Trolls", id="52fba66badcd10859f00097e",
        skill="Iterating a string, the in operator, str.join",
        task="Remove every vowel (a, e, i, o, u, either case) from a comment.",
        example=('disemvowel("This website is for losers LOL!")', '"Ths wbst s fr lsrs LL!"'),
        code='''def disemvowel(string_):
    kept = (ch for ch in string_
            if ch.lower() not in "aeiou")
    return "".join(kept)''',
        steps=[
            ([2], "for ch in string_", "A string is a sequence. A for loop hands you one character at a time, with no index to manage."),
            ([3], 'ch.lower() not in "aeiou"', "Lowercase once so one check covers A and a. The in operator on a string tests membership."),
            ([2, 3], "( ... for ... if ... )", "Parentheses make a generator: it produces kept characters on demand instead of building a list first."),
            ([4], '"".join(kept)', "Strings are immutable, so += in a loop copies the string every time. join builds the result once."),
        ],
        tests=[
            ('disemvowel("This website is for losers LOL!")', "Ths wbst s fr lsrs LL!"),
            ('disemvowel("No offense but,\\nYour writing is among the worst I\'ve ever read")',
             "N ffns bt,\nYr wrtng s mng th wrst \'v vr rd"),
            ('disemvowel("AEIOUaeiou")', ""),
        ],
        notes="Ask the room: why not <code>string_.replace()</code> five times? It works, but makes ten passes over the string (five vowels, two cases) where one pass will do.",
    ),
    dict(
        rank=7, name="Square Every Digit", id="546e2562b03326a88e000020",
        skill="Converting between int and str",
        task="Square each digit of a number and glue the results together.",
        example=("square_digits(9119)", "811181"),
        code='''def square_digits(num):
    digits = str(num)
    squares = [str(int(d) ** 2) for d in digits]
    return int("".join(squares))''',
        steps=[
            ([2], "str(num)", "An int has no digits to loop over. Its text form does, one character per digit."),
            ([3], "int(d) ** 2", "Each character is text. Convert it back to a number before doing math, then ** squares it."),
            ([3], "str( ... )", "Wrap each square back in str so the pieces can be glued: 81, 1, 1, 81."),
            ([4], 'int("".join(squares))', "join gives \"811181\". The kata wants a number back, so int() finishes the round trip."),
        ],
        tests=[("square_digits(9119)", 811181), ("square_digits(765)", 493625), ("square_digits(0)", 0)],
        notes="The lesson is the round trip <code>int → str → int → str → int</code>. Each conversion has a reason: text to iterate, numbers to calculate, text to concatenate.",
    ),
    dict(
        rank=7, name="Highest and Lowest", id="554b4ac871d6813a03000035",
        skill="split, int conversion, min and max, f-strings",
        task='Given a string of space-separated numbers, return "highest lowest".',
        example=('high_and_low("1 9 3 4 -5")', '"9 -5"'),
        code='''def high_and_low(numbers):
    values = [int(n) for n in numbers.split()]
    return f"{max(values)} {min(values)}"''',
        steps=[
            ([2], "numbers.split()", "With no argument, split breaks on any run of whitespace and returns a list of strings."),
            ([2], "int(n) for n in ...", "Strings compare letter by letter, so \"9\" > \"10\". Convert to int to compare as numbers."),
            ([2], "[ ... ] not map()", "A list can be read twice. map() is a one-shot iterator: max would use it up and min would get nothing."),
            ([3], 'f"{max(values)} {min(values)}"', "An f-string evaluates each expression in braces and formats the result into the text."),
        ],
        tests=[
            ('high_and_low("1 2 3 4 5")', "5 1"),
            ('high_and_low("1 2 -3 4 5")', "5 -3"),
            ('high_and_low("1 9 3 4 -5")', "9 -5"),
            ('high_and_low("8 3 -5 42 -1 0 0 -9 4 7 4 -4")', "42 -9"),
        ],
        notes='Demonstrate the trap live: <code>max("9 10".split())</code> returns <code>"9"</code>. Then <code>m = map(int, "1 2".split()); max(m); min(m)</code> raises <code>ValueError</code> because <code>m</code> is empty.',
    ),
    dict(
        rank=7, name="Complementary DNA", id="554e4a2f232cdd87d9000038",
        skill="Translation tables: str.maketrans and str.translate",
        task="Swap each DNA base for its partner: A with T, C with G.",
        example=('DNA_strand("ATTGC")', '"TAACG"'),
        code='''def DNA_strand(dna):
    pairs = str.maketrans("ATCG", "TAGC")
    return dna.translate(pairs)''',
        steps=[
            ([2], 'str.maketrans("ATCG", "TAGC")', "Builds a lookup table: the first string's letters map, position by position, to the second's."),
            ([3], "dna.translate(pairs)", "Replaces every character in one pass, all swaps at the same time."),
            ([2, 3], "why not .replace()", "Chained replace undoes itself: A→T, then T→A turns the new T's back. translate never re-reads its own output."),
        ],
        tests=[('DNA_strand("ATTGC")', "TAACG"), ('DNA_strand("GTAT")', "CATA"), ('DNA_strand("AAAA")', "TTTT")],
        notes='Show the broken version: <code>"AT".replace("A","T").replace("T","A")</code> gives <code>"AA"</code>, not <code>"TA"</code>. A dictionary plus join also works; translate is the built-in for exactly this.',
    ),
    dict(
        rank=7, name="Two to One", id="5656b6906de340bd1b0000ac",
        skill="set for uniqueness, sorted for order",
        task="Combine two strings of letters, keep each letter once, return them in alphabetical order.",
        example=('longest("xyaabbbccccdefww", "xxxxyyyyabklmopq")', '"abcdefklmopqwxy"'),
        code='''def longest(a1, a2):
    letters = set(a1 + a2)
    return "".join(sorted(letters))''',
        steps=[
            ([2], "a1 + a2", "+ on strings concatenates. One combined string means one place to remove duplicates."),
            ([2], "set( ... )", "A set holds each value once. Passing a string adds each character, so duplicates vanish."),
            ([3], "sorted(letters)", "A set has no order. sorted accepts any iterable and returns a new sorted list."),
            ([3], '"".join( ... )', "sorted returns a list of single characters. join turns it back into one string."),
        ],
        tests=[
            ('longest("aretheyhere", "yestheyarehere")', "aehrsty"),
            ('longest("loopingisfunbutdangerous", "lessdangerousthancoding")', "abcdefghilnoprstu"),
            ('longest("inmanylanguages", "theresapairoffunctions")', "acefghilmnoprstuy"),
        ],
        notes="Common slip: <code>set(a1, a2)</code> raises <code>TypeError</code>, because set takes one iterable. Union of two sets also works: <code>set(a1) | set(a2)</code>.",
    ),
    # ------------------------------------------------------------------ 6 kyu
    dict(
        rank=6, name="Counting Duplicates", id="54bf1c2cd5b56cc47f0007a1",
        skill="collections.Counter",
        task="Count how many distinct characters (ignoring case) appear more than once.",
        example=('duplicate_count("aabBcde")', "2"),
        code='''from collections import Counter

def duplicate_count(text):
    counts = Counter(text.lower())
    return sum(1 for n in counts.values() if n > 1)''',
        steps=[
            ([1], "from collections import Counter", "Counter is in the standard library. It is a dictionary subclass built for counting."),
            ([4], "text.lower()", "The kata ignores case, so B and b must land on the same key."),
            ([4], "Counter( ... )", "One call walks the string and tallies it: {'a': 2, 'b': 2, 'c': 1, ...}."),
            ([5], "sum(1 for n in counts.values() if n > 1)", "Add 1 for each tally above 1. This counts how many characters repeat, not how many repeats there are."),
        ],
        tests=[
            ('duplicate_count("abcde")', 0), ('duplicate_count("aabBcde")', 2),
            ('duplicate_count("indivisibility")', 1), ('duplicate_count("Indivisibilities")', 2),
            ('duplicate_count("aA11")', 2),
        ],
        notes="Write the hand-rolled version first: <code>counts = {}</code>, then <code>counts[c] = counts.get(c, 0) + 1</code>. Then show that Counter is that loop, already written.",
    ),
    dict(
        rank=6, name="Unique In Order", id="54e6533c92449cc251001667",
        skill="itertools.groupby",
        task="Collapse runs of the same item to one, keeping the original order.",
        example=('unique_in_order("AAAABBBCCDAABBB")', "['A', 'B', 'C', 'D', 'A', 'B']"),
        code='''from itertools import groupby

def unique_in_order(sequence):
    runs = groupby(sequence)
    return [key for key, _run in runs]''',
        steps=[
            ([4], "groupby(sequence)", "groupby gathers consecutive equal items. AAAA becomes one group, and a later AA starts a new one."),
            ([5], "for key, _run in runs", "Each group is a pair: the value and an iterator over its run. Tuple unpacking names both."),
            ([5], "_run", "A leading underscore says \"not used.\" Only the key matters here."),
            ([4, 5], "why not set()", "A set would drop the second A and B and forget the order. The kata keeps both."),
        ],
        tests=[
            ('unique_in_order("AAAABBBCCDAABBB")', ["A", "B", "C", "D", "A", "B"]),
            ('unique_in_order("ABBCcAD")', ["A", "B", "C", "c", "A", "D"]),
            ("unique_in_order([1, 2, 2, 3, 3])", [1, 2, 3]),
            ('unique_in_order("")', []),
        ],
        notes="groupby works on strings and lists alike, because it only needs an iterable. The loop version compares each item to the last one appended: <code>if not out or out[-1] != x</code>.",
    ),
    dict(
        rank=6, name="Take a Ten Minutes Walk", id="54da539698b8a2ad76000228",
        skill="Dictionaries as lookup tables, tuple unpacking",
        task="A walk is a list of one-minute moves (n, s, e, w). Is it exactly ten minutes and back at the start?",
        example=("is_valid_walk(['n','s','n','s','n','s','n','s','n','s'])", "True"),
        code='''def is_valid_walk(walk):
    if len(walk) != 10:
        return False
    moves = {"n": (0, 1), "s": (0, -1),
             "e": (1, 0), "w": (-1, 0)}
    x = y = 0
    for step in walk:
        dx, dy = moves[step]
        x, y = x + dx, y + dy
    return (x, y) == (0, 0)''',
        steps=[
            ([2, 3], "if len(walk) != 10: return False", "Do the cheap check first. A wrong length fails without walking a single step."),
            ([4, 5], "moves = {...}", "Data instead of an if/elif chain: each letter maps to how it changes x and y."),
            ([8], "dx, dy = moves[step]", "Look up the move, then unpack the pair into two names in one line."),
            ([9], "x, y = x + dx, y + dy", "The right side is evaluated in full before either name is assigned."),
            ([10], "(x, y) == (0, 0)", "Tuples compare item by item. One comparison asks whether we are home."),
        ],
        tests=[
            ("is_valid_walk(['n','s','n','s','n','s','n','s','n','s'])", True),
            ("is_valid_walk(['w','e','w','e','w','e','w','e','w','e','w','e'])", False),
            ("is_valid_walk(['w'])", False),
            ("is_valid_walk(['n','n','n','s','n','s','n','s','n','s'])", False),
        ],
        notes="Shorter alternative: <code>walk.count('n') == walk.count('s')</code> and the same for e and w. The dictionary version scales to any set of directions.",
    ),
    dict(
        rank=6, name="Mexican Wave", id="58f5c63f1e26ecda7e000029",
        skill="enumerate, slicing, list comprehensions",
        task="Return every version of the string with exactly one letter capitalized, left to right, skipping spaces.",
        example=('wave("hello")', "['Hello', 'hEllo', 'heLlo', 'helLo', 'hellO']"),
        code='''def wave(people):
    return [
        people[:i] + ch.upper() + people[i + 1:]
        for i, ch in enumerate(people)
        if not ch.isspace()
    ]''',
        steps=[
            ([4], "enumerate(people)", "Gives the position and the character together, so no range(len(...)) is needed."),
            ([5], "if not ch.isspace()", "A space cannot be capitalized, so it gets no wave of its own."),
            ([3], "people[:i] + ch.upper() + people[i+1:]", "Strings cannot be changed in place. Build a new one: everything before, the capital, everything after."),
            ([2, 6], "[ ... for ... if ... ]", "A list comprehension reads as one sentence: this expression, for each item, when the condition holds."),
        ],
        tests=[
            ('wave("hello")', ["Hello", "hEllo", "heLlo", "helLo", "hellO"]),
            ('wave(" gap ")', [" Gap ", " gAp ", " gaP "]),
            ('wave("two words")', ["Two words", "tWo words", "twO words", "two Words", "two wOrds", "two woRds", "two worDs", "two wordS"]),
            ('wave("")', []),
        ],
        notes="Slicing never fails out of range: <code>\"abc\"[3:]</code> is <code>\"\"</code>, so the last letter needs no special case.",
    ),
    dict(
        rank=6, name="The Supermarket Queue", id="57b06f90e298a7b53d000a86",
        skill="Modeling a process with a list",
        task="Customers (each a checkout time) queue for n tills. When does the last one finish?",
        example=("queue_time([10, 2, 3, 3], 2)", "10"),
        code='''def queue_time(customers, n):
    tills = [0] * n
    for t in customers:
        i = tills.index(min(tills))
        tills[i] += t
    return max(tills)''',
        steps=[
            ([2], "[0] * n", "One running total per till, all starting free. Safe for ints; [[]] * n would share one list n times."),
            ([3], "for t in customers", "The queue is first come, first served, so walk it in order."),
            ([4], "tills.index(min(tills))", "The next customer goes to whichever till frees up first: the smallest total."),
            ([5], "tills[i] += t", "That till is now busy until its total plus this customer's time."),
            ([6], "max(tills)", "Everyone is done when the busiest till is done."),
        ],
        tests=[
            ("queue_time([], 1)", 0), ("queue_time([5, 3, 4], 1)", 12),
            ("queue_time([10, 2, 3, 3], 2)", 10), ("queue_time([2, 3, 10], 2)", 12),
            ("queue_time([1, 2, 3, 4, 5], 100)", 5),
        ],
        notes="Trace [10, 2, 3, 3] with 2 tills on the board: [10, 0] → [10, 2] → [10, 5] → [10, 8] → max is 10. A heap (<code>heapq</code>) makes the min step faster for large n.",
    ),
    # ------------------------------------------------------------------ 5 kyu
    dict(
        rank=5, name="Valid Parentheses", id="52774a314c2333f0a7000688",
        skill="A list used as a stack, truthiness of empty containers",
        task="Is every ( closed by a matching ) in the right order?",
        example=('valid_parentheses("(())((()())())")', "True"),
        code='''def valid_parentheses(string):
    stack = []
    for ch in string:
        if ch == "(":
            stack.append(ch)
        elif ch == ")":
            if not stack:
                return False
            stack.pop()
    return not stack''',
        steps=[
            ([2], "stack = []", "A list works as a stack: append adds to the end, pop removes from the end. Last in, first out."),
            ([4, 5], "stack.append(ch)", "Every opener waits on the stack for its closer."),
            ([7, 8], "if not stack: return False", "An empty list is falsy. A ) with nothing open can never be fixed later, so fail now."),
            ([9], "stack.pop()", "A closer cancels the most recent opener."),
            ([10], "return not stack", "Anything left on the stack was opened and never closed."),
        ],
        tests=[
            ('valid_parentheses("()")', True), ('valid_parentheses(")(()))")', False),
            ('valid_parentheses("(")', False), ('valid_parentheses("(())((()())())")', True),
            ('valid_parentheses("hi(hi)()")', True), ('valid_parentheses("")', True),
        ],
        notes="With one bracket type, a counter does the same job. The stack earns its place when there are several types: push the opener, and on a closer check that <code>stack.pop()</code> is its partner.",
    ),
    dict(
        rank=5, name="Memoized Fibonacci", id="529adbf7533b761c560004e5",
        skill="Decorators and functools.cache",
        task="The plain recursive Fibonacci is too slow for n = 70. Make it fast without changing its logic.",
        example=("fibonacci(70)", "190392490709135"),
        code='''from functools import cache

@cache
def fibonacci(n):
    if n in [0, 1]:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)''',
        steps=[
            ([5, 6, 7], "the original recursion", "fib(n) calls fib(n-1) and fib(n-2), which call the same values again. The calls double with every n."),
            ([1], "from functools import cache", "cache stores each result keyed by the arguments it was called with."),
            ([3], "@cache", "A decorator wraps the function below it. Now every call checks the store before doing any work."),
            ([7], "fibonacci(n - 1) + ...", "Each n is computed once. 70 takes 71 real calls instead of hundreds of trillions."),
        ],
        tests=[("fibonacci(0)", 0), ("fibonacci(1)", 1), ("fibonacci(50)", 12586269025), ("fibonacci(70)", 190392490709135)],
        notes="Show the decorator is just sugar: <code>fibonacci = cache(fibonacci)</code>. Then write the hand-rolled version with a dictionary to show what cache does inside.",
    ),
    dict(
        rank=5, name="Extract the domain name from a URL", id="514a024011ea4fb54200004b",
        skill="The re module: optional groups and capture groups",
        task="Pull the bare domain name out of a URL.",
        example=('domain_name("http://www.zombie-bites.com")', '"zombie-bites"'),
        code='''import re

def domain_name(url):
    match = re.match(r"(?:https?://)?(?:www\\.)?([^./]+)", url)
    return match.group(1)''',
        steps=[
            ([4], 'r"..."', "A raw string keeps backslashes as typed, so \\. reaches the regex engine as \"a literal dot.\""),
            ([4], "(?:https?://)?", "s? makes the s optional. (?: ) groups without capturing. The trailing ? makes the whole scheme optional."),
            ([4], "(?:www\\.)?", "Same pattern: skip www. if it is there."),
            ([4], "([^./]+)", "Capture one or more characters that are not a dot or slash. It stops at the end of the name."),
            ([5], "match.group(1)", "Group 1 is the first capturing group: the name alone."),
        ],
        tests=[
            ('domain_name("http://google.com")', "google"), ('domain_name("http://google.co.jp")', "google"),
            ('domain_name("www.xakep.ru")', "xakep"), ('domain_name("https://youtube.com")', "youtube"),
            ('domain_name("http://github.com/carbonfive/raygun")', "github"),
            ('domain_name("http://www.zombie-bites.com")', "zombie-bites"),
        ],
        notes="Without regex: <code>url.replace('http://','').replace('https://','').replace('www.','').split('.')[0]</code>. Compare the two for readability; both pass.",
    ),
    dict(
        rank=5, name="Moving Zeros To The End", id="52597aa56021e91c93000cb0",
        skill="sorted with a key function, stable sorting, bool as int",
        task="Move every zero to the end of the list, keeping the order of everything else.",
        example=("move_zeros([1, 0, 1, 2, 0, 1, 3])", "[1, 1, 2, 1, 3, 0, 0]"),
        code='''def move_zeros(lst):
    return sorted(lst, key=lambda x: x == 0)''',
        steps=[
            ([2], "key=lambda x: x == 0", "sorted compares key values, not the items. Each item's key is True (a zero) or False (anything else)."),
            ([2], "False < True", "bool is a subclass of int: False is 0 and True is 1. All False keys sort before all True keys."),
            ([2], "stable sort", "Python's sort is stable: items with equal keys keep their original order. That keeps 1, 1, 2, 1, 3 in place."),
        ],
        tests=[
            ("move_zeros([1, 2, 0, 1, 0, 1, 0, 3, 0, 1])", [1, 2, 1, 1, 3, 1, 0, 0, 0, 0]),
            ("move_zeros([9, 0, 0, 9, 1, 2, 0, 1, 0, 1, 0, 3, 0, 1, 9, 0, 0, 0, 0, 9])",
             [9, 9, 1, 2, 1, 1, 3, 1, 9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            ("move_zeros([0, 0])", [0, 0]), ("move_zeros([])", []),
        ],
        notes="Ask: what is <code>True + True</code>? (2.) The two-comprehension version is just as good: <code>[x for x in lst if x != 0] + [0] * lst.count(0)</code>.",
    ),
    dict(
        rank=5, name="Directions Reduction", id="550f22f4d758534c1100025a",
        skill="A stack applied to a puzzle",
        task="Remove pairs of opposite directions that sit next to each other, repeating until none are left.",
        example=('dir_reduc(["NORTH", "SOUTH", "SOUTH", "EAST", "WEST", "NORTH", "WEST"])', '["WEST"]'),
        code='''OPPOSITE = {"NORTH": "SOUTH", "SOUTH": "NORTH",
            "EAST": "WEST", "WEST": "EAST"}

def dir_reduc(arr):
    stack = []
    for d in arr:
        if stack and stack[-1] == OPPOSITE[d]:
            stack.pop()
        else:
            stack.append(d)
    return stack''',
        steps=[
            ([1, 2], "OPPOSITE = {...}", "A module-level constant, in capitals by convention. It answers \"what cancels this?\""),
            ([7], "stack and stack[-1] == ...", "and short-circuits: if the stack is empty, Python never reads stack[-1], so no IndexError."),
            ([8], "stack.pop()", "The new direction cancels the last one we kept. Both disappear."),
            ([10], "stack.append(d)", "Nothing to cancel, so keep it. A cancel can expose an older pair, and the stack catches that too."),
        ],
        tests=[
            ('dir_reduc(["NORTH", "SOUTH", "SOUTH", "EAST", "WEST", "NORTH", "WEST"])', ["WEST"]),
            ('dir_reduc(["NORTH", "WEST", "SOUTH", "EAST"])', ["NORTH", "WEST", "SOUTH", "EAST"]),
            ('dir_reduc(["NORTH", "SOUTH", "EAST", "WEST"])', []),
            ('dir_reduc(["NORTH", "SOUTH", "SOUTH", "EAST", "WEST", "NORTH", "NORTH"])', ["NORTH"]),
        ],
        notes="Same shape as Valid Parentheses, one slide back. The stack makes this one pass; the naive \"remove pairs and start over\" loop rescans the list after every removal.",
    ),
    # ------------------------------------------------------------------ 4 kyu
    dict(
        rank=4, name="Human readable duration format", id="52742f58faf5485cae000b9a",
        skill="divmod, building a list of parts, joining with grammar",
        task='Turn a number of seconds into text like "1 hour, 1 minute and 2 seconds".',
        example=("format_duration(3662)", '"1 hour, 1 minute and 2 seconds"'),
        code='''UNITS = [("year", 31536000), ("day", 86400),
         ("hour", 3600), ("minute", 60), ("second", 1)]

def format_duration(seconds):
    if seconds == 0:
        return "now"
    parts = []
    for name, size in UNITS:
        count, seconds = divmod(seconds, size)
        if count:
            parts.append(f"{count} {name}" + "s" * (count > 1))
    if len(parts) == 1:
        return parts[0]
    return ", ".join(parts[:-1]) + " and " + parts[-1]''',
        steps=[
            ([1, 2], "UNITS = [...]", "Largest unit first. A list of tuples keeps the order and pairs each name with its size in seconds."),
            ([9], "count, seconds = divmod(seconds, size)", "divmod returns the quotient and the remainder at once. The remainder moves on to the next unit."),
            ([10, 11], '"s" * (count > 1)', "Skip zero units. A bool times a string gives \"s\" or \"\", so plurals need no if."),
            ([12, 13], "len(parts) == 1", "One part needs no joining words."),
            ([14], 'parts[:-1] ... " and " ... parts[-1]', "Commas between all but the last, then \"and\" before the last."),
        ],
        tests=[
            ("format_duration(0)", "now"), ("format_duration(1)", "1 second"),
            ("format_duration(62)", "1 minute and 2 seconds"), ("format_duration(120)", "2 minutes"),
            ("format_duration(3600)", "1 hour"), ("format_duration(3662)", "1 hour, 1 minute and 2 seconds"),
            ("format_duration(132030240)", "4 years, 68 days, 3 hours and 4 minutes"),
        ],
        notes="The kata defines a year as 365 days. Trace 3662 on the board: divmod by 3600 → (1, 62), by 60 → (1, 2), by 1 → (2, 0).",
    ),
    dict(
        rank=4, name="Snail", id="521c2db8ddc89b9b7a0000c1",
        skill="Nested lists, zip(*m) to transpose, slicing to reverse",
        task="Walk an n × n grid clockwise from the outside in and return the values in order.",
        example=("snail([[1,2,3],[4,5,6],[7,8,9]])", "[1, 2, 3, 6, 9, 8, 7, 4, 5]"),
        code='''def snail(snail_map):
    grid = [row[:] for row in snail_map]
    result = []
    while grid:
        result += grid.pop(0)
        grid = [list(r) for r in zip(*grid)][::-1]
    return result''',
        steps=[
            ([2], "[row[:] for row in snail_map]", "Copy each row first. The loop destroys its grid, and the caller's list should survive."),
            ([5], "result += grid.pop(0)", "Take the top row, left to right. pop(0) removes it from the grid."),
            ([6], "zip(*grid)", "* spreads the rows as separate arguments. zip pairs their columns: that is a transpose."),
            ([6], "[::-1]", "Reversing the transposed rows rotates the grid a quarter turn counterclockwise, so the next edge is on top."),
            ([4], "while grid", "Repeat until the grid is an empty list, which is falsy."),
        ],
        tests=[
            ("snail([[1,2,3],[4,5,6],[7,8,9]])", [1, 2, 3, 6, 9, 8, 7, 4, 5]),
            ("snail([[1,2,3],[8,9,4],[7,6,5]])", [1, 2, 3, 4, 5, 6, 7, 8, 9]),
            ("snail([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]])",
             [1, 2, 3, 4, 8, 12, 16, 15, 14, 13, 9, 5, 6, 7, 11, 10]),
            ("snail([[]])", []),
        ],
        notes="Draw it: take the top row off, rotate what is left so the right edge is on top, repeat. The kata's 0 × 0 case is <code>[[]]</code>, and the loop handles it: the empty row adds nothing and zip of nothing is empty.",
    ),
    dict(
        rank=4, name="Range Extraction", id="51ba717bb08c1cd60f00002f",
        skill="Two-pointer loops and edge cases",
        task="Compress a sorted list of integers: runs of 3 or more become start-end, everything else stays.",
        example=("solution([-6, -3, -2, -1, 0, 1, 3, 4, 5, 7, 8, 9, 10, 11, 14, 15, 17, 18, 19, 20])",
                 '"-6,-3-1,3-5,7-11,14,15,17-20"'),
        code='''def solution(args):
    out = []
    i = 0
    while i < len(args):
        j = i
        while j + 1 < len(args) and args[j + 1] == args[j] + 1:
            j += 1
        if j - i >= 2:
            out.append(f"{args[i]}-{args[j]}")
        else:
            out.extend(str(n) for n in args[i:j + 1])
        i = j + 1
    return ",".join(out)''',
        steps=[
            ([3, 5], "i and j", "i marks where a run starts. j walks forward to where it ends."),
            ([6, 7], "args[j + 1] == args[j] + 1", "Check the bound first: and short-circuits, so args[j + 1] is never read past the end."),
            ([8, 9], "j - i >= 2", "Three numbers span two steps. Only those become a range."),
            ([10, 11], "out.extend( ... )", "A run of one or two is written out number by number. extend adds each item, not a list."),
            ([12], "i = j + 1", "Jump past the run just handled. Every number is visited once."),
        ],
        tests=[
            ("solution([-10, -9, -8, -6, -3, -2, -1, 0, 1, 3, 4, 5, 7, 8, 9, 10, 11, 14, 15, 17, 18, 19, 20])",
             "-10--8,-6,-3-1,3-5,7-11,14,15,17-20"),
            ("solution([-3, -2, -1, 2, 10, 15, 16, 18, 19, 20])", "-3--1,2,10,15,16,18-20"),
            ("solution([1, 2])", "1,2"), ("solution([1, 2, 3])", "1-3"),
        ],
        notes="Point out <code>-10--8</code>: the dash between numbers and the minus sign look the same, and the kata wants exactly that. Edge cases to try: two in a row (14,15) and a run at the very end.",
    ),
    dict(
        rank=4, name="Sum of Intervals", id="52b7ed099cdc285c300001cd",
        skill="Sorting tuples, sweeping overlapping ranges",
        task="Given intervals that may overlap, return the total length they cover.",
        example=("sum_of_intervals([(1, 4), (7, 10), (3, 5)])", "7"),
        code='''def sum_of_intervals(intervals):
    total, reach = 0, float("-inf")
    for lo, hi in sorted(intervals):
        lo = max(lo, reach)
        if hi > lo:
            total += hi - lo
            reach = hi
    return total''',
        steps=[
            ([3], "sorted(intervals)", "Tuples sort by first item, then second. Sorted by start, overlaps sit next to each other."),
            ([2], 'reach = float("-inf")', "reach is the furthest point covered so far. Negative infinity means nothing is covered yet."),
            ([4], "lo = max(lo, reach)", "Skip the part already counted: start counting from wherever coverage ends."),
            ([5, 6, 7], "if hi > lo", "Count only new ground. An interval inside an earlier one adds nothing and leaves reach alone."),
        ],
        tests=[
            ("sum_of_intervals([(1, 5)])", 4), ("sum_of_intervals([(1, 5), (6, 10)])", 8),
            ("sum_of_intervals([(1, 5), (1, 5)])", 4), ("sum_of_intervals([(1, 4), (7, 10), (3, 5)])", 7),
            ("sum_of_intervals([(1, 20), (2, 3), (5, 30)])", 29),
            ("sum_of_intervals([(-1_000_000_000, 1_000_000_000)])", 2_000_000_000),
        ],
        notes="The kata's large tests make <code>set(range(lo, hi))</code> too slow and too large. Sorting then sweeping is O(n log n) in the number of intervals, no matter how long each one is.",
    ),
    dict(
        rank=4, name="So Many Permutations!", id="5254ca2719453dcc0b00027d",
        skill="Recursion, sets for uniqueness, and the itertools shortcut",
        task="Return every unique ordering of the letters in a string.",
        example=('permutations("aabb")', "['aabb', 'abab', 'abba', 'baab', 'baba', 'bbaa']"),
        code='''def permutations(s):
    if len(s) <= 1:
        return [s]
    result = set()
    for i, ch in enumerate(s):
        rest = s[:i] + s[i + 1:]
        for tail in permutations(rest):
            result.add(ch + tail)
    return sorted(result)''',
        steps=[
            ([2, 3], "if len(s) <= 1: return [s]", "The base case. A recursive function needs a size small enough to answer directly."),
            ([5, 6], "rest = s[:i] + s[i+1:]", "Pick each letter in turn to go first. Slicing removes it from what is left."),
            ([7], "permutations(rest)", "Trust the function to order the shorter string. Each call is one letter smaller, so it ends."),
            ([4, 8], "result = set()", "\"aabb\" has two a's, so some orderings repeat. A set keeps each once."),
            ([9], "sorted(result)", "Return a list in a predictable order."),
        ],
        tests=[
            ('permutations("a")', ["a"]), ('permutations("ab")', ["ab", "ba"]),
            ('permutations("aabb")', ["aabb", "abab", "abba", "baab", "baba", "bbaa"]),
            ('len(permutations("abcd"))', 24),
        ],
        notes='The one-line version: <code>sorted({"".join(p) for p in itertools.permutations(s)})</code>. Teach the recursion first, then show the library. Knowing both is the point.',
    ),
]
