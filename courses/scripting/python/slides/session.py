"""Session content for the Python course: the fundamentals half of the ladder.

The 20 fundamentals challenges are the ones the Python Terminal already ships.
build.py writes them into PythonTerminal.html in the order given here (grouped
by concept, easiest first), followed by the Codewars kata from kata.py.

Each test is (call, expected_repr). The terminal compares repr(result) to the
expected string, allowing either quote style.
"""

DEBRIEF = [
    ("Battle", "Does it pass?", "Run test(). Every line green, or which one is red and why?"),
    ("Flawless", "What input breaks it?", "Empty list, empty string, negative number, one element. Try one."),
    ("Daybreak", "Which version reads best?", "Compare two pairs' solutions. Which would you rather maintain?"),
]

# One row per block of the day. Minutes are a plan, not a measurement.
AGENDA = [
    ("0:00", "Open", "Everyone opens the Terminal link and gets Python running"),
    ("0:15", "Fundamentals", "Six blocks: concept, pair exercise, debrief, quick check"),
    ("2:15", "Break", ""),
    ("2:30", "Codewars kata, 7 kyu", "Problem first, then the walkthrough step by step"),
    ("3:15", "Stretch", "Pairs pick a 6 kyu kata, then swap and try to break each other's"),
    ("3:45", "Close", "Where to keep practicing; homework"),
]

# ---------------------------------------------------------------- challenges
FUNDAMENTALS = {
    "add": dict(sig="def add(a, b):", desc="Return the sum of a and b",
        tests=[("add(2, 3)", "5"), ("add(-1, 1)", "0"), ("add(100, 250)", "350"), ("add(0, 0)", "0")]),
    "celsius_to_fahrenheit": dict(sig="def celsius_to_fahrenheit(c):", desc="Convert Celsius to Fahrenheit (F = C * 9/5 + 32)",
        tests=[("celsius_to_fahrenheit(0)", "32.0"), ("celsius_to_fahrenheit(100)", "212.0"), ("celsius_to_fahrenheit(-40)", "-40.0")]),
    "max_of_three": dict(sig="def max_of_three(a, b, c):", desc="Return the largest of three numbers",
        tests=[("max_of_three(1,2,3)", "3"), ("max_of_three(3,2,1)", "3"), ("max_of_three(-1,0,-5)", "0"), ("max_of_three(5,5,5)", "5")]),
    "count_evens": dict(sig="def count_evens(numbers):", desc="Count how many even numbers are in the list",
        tests=[("count_evens([1,2,3,4])", "2"), ("count_evens([2,4,6,8])", "4"), ("count_evens([1,3,5])", "0"), ("count_evens([])", "0")]),
    "multiply_all": dict(sig="def multiply_all(numbers):", desc="Return the product of all numbers in the list (1 for empty)",
        tests=[("multiply_all([1,2,3,4])", "24"), ("multiply_all([5])", "5"), ("multiply_all([2,0,5])", "0"), ("multiply_all([])", "1")]),
    "sum_digits": dict(sig="def sum_digits(n):", desc="Return the sum of all digits in n",
        tests=[("sum_digits(123)", "6"), ("sum_digits(0)", "0"), ("sum_digits(999)", "27"), ("sum_digits(1001)", "2")]),
    "average": dict(sig="def average(lst):", desc="Return the average of numbers (0.0 for empty list)",
        tests=[("average([2,4,6])", "4.0"), ("average([1])", "1.0"), ("average([1,2,3,4])", "2.5"), ("average([])", "0.0")]),
    "reverse_string": dict(sig="def reverse_string(s):", desc="Return the reversed string",
        tests=[('reverse_string("hello")', "'olleh'"), ('reverse_string("a")', "'a'"), ('reverse_string("")', "''"), ('reverse_string("Python")', "'nohtyP'")]),
    "is_palindrome": dict(sig="def is_palindrome(s):", desc="Return True if string is a palindrome",
        tests=[('is_palindrome("radar")', "True"), ('is_palindrome("hello")', "False"), ('is_palindrome("")', "True"), ('is_palindrome("level")', "True")]),
    "count_vowels": dict(sig="def count_vowels(s):", desc="Count vowels (a,e,i,o,u) case-insensitive",
        tests=[('count_vowels("hello")', "2"), ('count_vowels("sky")', "0"), ('count_vowels("aeiou")', "5"), ('count_vowels("AEiOu")', "5")]),
    "capitalize_words": dict(sig="def capitalize_words(sentence):", desc="Capitalize the first letter of each word",
        tests=[('capitalize_words("hello world")', "'Hello World'"), ('capitalize_words("hi there")', "'Hi There'"), ('capitalize_words("")', "''")]),
    "sort_numbers": dict(sig="def sort_numbers(lst):", desc="Return a new sorted list (ascending)",
        tests=[("sort_numbers([3,1,2])", "[1, 2, 3]"), ("sort_numbers([5])", "[5]"), ("sort_numbers([])", "[]"), ("sort_numbers([10,-1])", "[-1, 10]")]),
    "filter_evens": dict(sig="def filter_evens(lst):", desc="Return a list with only the even numbers",
        tests=[("filter_evens([1,2,3,4])", "[2, 4]"), ("filter_evens([])", "[]"), ("filter_evens([1,3,5])", "[]"), ("filter_evens([0,2,8])", "[0, 2, 8]")]),
    "flatten": dict(sig="def flatten(matrix):", desc="Flatten a 2D list into a 1D list",
        tests=[("flatten([[1,2],[3,4]])", "[1, 2, 3, 4]"), ("flatten([[5]])", "[5]"), ("flatten([[]])", "[]"), ("flatten([[1],[2,3]])", "[1, 2, 3]")]),
    "common_elements": dict(sig="def common_elements(a, b):", desc="Return a sorted list of the items found in both lists",
        tests=[("common_elements([1,2,3],[2,3,4])", "[2, 3]"), ("common_elements([],[1])", "[]"), ("common_elements([1,2],[1,2,3])", "[1, 2]"), ("common_elements([3,1],[1,3])", "[1, 3]")]),
    "word_count": dict(sig="def word_count(text):", desc="Return a dict with word frequencies",
        tests=[('word_count("hello world hello")', '{"hello": 2, "world": 1}'), ('word_count("a a a")', '{"a": 3}'), ('word_count("")', "{}")]),
    "get_keys": dict(sig="def get_keys(d):", desc="Return a list of the dictionary's keys",
        tests=[('get_keys({"a":1,"b":2})', "['a', 'b']"), ("get_keys({})", "[]")]),
    "invert_dict": dict(sig="def invert_dict(d):", desc="Return a dictionary with keys and values swapped",
        tests=[('invert_dict({"a":1,"b":2})', "{1: 'a', 2: 'b'}"), ("invert_dict({})", "{}"), ('invert_dict({"x":10})', "{10: 'x'}")]),
    "square_dict": dict(sig="def square_dict(nums):", desc="Return a dict mapping each number to its square",
        tests=[("square_dict([1,2,3])", "{1: 1, 2: 4, 3: 9}"), ("square_dict([])", "{}"), ("square_dict([0])", "{0: 0}")]),
    "find_primes": dict(sig="def find_primes(n):", desc="Return a list of all prime numbers up to and including n",
        tests=[("find_primes(10)", "[2, 3, 5, 7]"), ("find_primes(1)", "[]"), ("find_primes(2)", "[2]"), ("find_primes(20)", "[2, 3, 5, 7, 11, 13, 17, 19]")]),
}

# ---------------------------------------------------------------- blocks
# Each block: a concept slide, an activity slide (the challenges, in pairs),
# and a two-question check. Quiz answers are 0-based indexes into opts.
BLOCKS = [
    dict(
        key="functions", title="Functions and numbers",
        keyline="A function takes inputs, does one job, and hands back one value with return.",
        read=[
            "def names the function and its inputs. The indented lines underneath are its body.",
            "return sends a value back to whoever called the function. Without it, the caller gets None.",
            "Numbers: + - * / work as you expect. / always gives a decimal, so 9 / 3 is 3.0.",
        ],
        code='''def add(a, b):
    return a + b

add(2, 3)        # 5
add(2, 3) * 10   # 50''',
        challenges=["add", "celsius_to_fahrenheit", "max_of_three"],
        talk="What does the terminal show if you forget the word return?",
        quiz=[
            ("Which keyword defines a function?", ["function", "func", "def", "fn"], 2),
            ("Which operator checks equality?", ["=", "==", "===", "!="], 1),
        ],
        prepare="Everyone has the Terminal open and challenge 1 showing in the panel.",
        direct="Type the def line, press Enter, type the indented return line, press Enter twice. Then type test(). Read the three red or green lines aloud.",
        consider="Indentation is the first wall. Four spaces, or Tab in this terminal. A pair that gets IndentationError is normal; have them retype the body line.",
    ),
    dict(
        key="loops", title="Loops and accumulators",
        keyline="A for loop visits each item in turn. An accumulator is a variable you update every pass.",
        read=[
            "Start the accumulator before the loop: 0 for a sum or count, 1 for a product, an empty list to collect.",
            "Inside the loop, update it. After the loop, return it.",
            "% gives the remainder. n % 2 == 0 means n is even.",
        ],
        code='''def count_evens(numbers):
    count = 0
    for n in numbers:
        if n % 2 == 0:
            count += 1
    return count''',
        challenges=["count_evens", "multiply_all", "sum_digits", "average"],
        talk="Why does multiply_all start at 1 and not 0?",
        quiz=[
            ("What is the output of 10 % 3?", ["3", "1", "0", "10"], 1),
            ("What does range(3) produce?", ["0, 1, 2, 3", "0, 1, 2", "1, 2, 3", "3"], 1),
        ],
        prepare="Have the empty-list cases ready to point at: count_evens([]) is 0, multiply_all([]) is 1, average([]) is 0.0.",
        direct="Pairs swap who types. Write the accumulator pattern once together on screen, then let them adapt it four times.",
        consider="average([]) divides by zero. That is the first time the Flawless question has teeth: what input breaks it? Let a pair hit ZeroDivisionError before showing the if.",
    ),
    dict(
        key="strings", title="Strings",
        keyline="A string is a sequence of characters. You can loop over it, slice it, and call methods on it.",
        read=[
            "Slicing: s[::-1] walks the string backwards. s[0] is the first character.",
            "Methods return a new string; the original never changes. s.lower(), s.upper(), s.capitalize().",
            "split() breaks a sentence into a list of words. ' '.join(words) puts it back together.",
        ],
        code='''s = "Hello World"
s[::-1]              # 'dlroW olleH'
s.lower()            # 'hello world'
words = s.split()    # ['Hello', 'World']
" ".join(words)      # 'Hello World'
"e" in s             # True''',
        challenges=["reverse_string", "is_palindrome", "count_vowels", "capitalize_words"],
        talk="is_palindrome('Radar') is False. Should it be? What one call fixes it?",
        quiz=[
            ('What does "hello"[::-1] produce?', ['"olleh"', '"hello"', '"h"', "an error"], 0),
            ("What does str.split() do by default?", ["Split on whitespace", "Split on commas", "Split on newlines", "Return the characters"], 0),
        ],
        prepare="Nothing extra. The reference tab in the Python Lab lists every method used here.",
        direct="Show s[::-1] live in the terminal before they start. Then let them discover that is_palindrome is one line once reverse_string exists.",
        consider="count_vowels is where in shows up: c in 'aeiou'. A pair that writes five == comparisons has a working answer; the Daybreak question is which version reads best.",
    ),
    dict(
        key="lists", title="Lists",
        keyline="A list holds items in order. You can sort it, filter it, and build a new one from an old one.",
        read=[
            "sorted(lst) returns a new sorted list and leaves lst alone. lst.sort() sorts in place and returns None.",
            "A list comprehension builds a list in one line: [x for x in lst if x % 2 == 0].",
            "Nested lists are lists of lists. Two loops, or a comprehension with two for clauses, walk them.",
        ],
        code='''nums = [3, 1, 2]
sorted(nums)                      # [1, 2, 3]
[n for n in nums if n % 2 == 0]   # [2]

grid = [[1, 2], [3, 4]]
[x for row in grid for x in row]  # [1, 2, 3, 4]''',
        challenges=["sort_numbers", "filter_evens", "flatten", "common_elements"],
        talk="What does the terminal print if you return lst.sort()?",
        quiz=[
            ("What does sorted() return?", ["A new sorted list", "None, it sorts in place", "A tuple", "A set"], 0),
            ("What is a list comprehension?", ["[expr for x in iterable]", "list(x)", "for x in list: append", "def list(x):"], 0),
        ],
        prepare="Have sorted versus .sort() typed and ready to run.",
        direct="Write filter_evens as a for loop first, then as a comprehension. Same result, two shapes. Let pairs pick either for the rest.",
        consider="common_elements asks for a sorted result on purpose. Sets have no order; sorted() gives one. A pair returning list(set(a) & set(b)) passes by luck on small ints and fails on [3,1],[1,3].",
    ),
    dict(
        key="dicts", title="Dictionaries",
        keyline="A dictionary maps keys to values. Look up by key instead of by position.",
        read=[
            "d[key] reads a value and raises KeyError if the key is missing. d.get(key, 0) returns 0 instead.",
            "Counting things: d[word] = d.get(word, 0) + 1 inside a loop.",
            "d.keys(), d.values(), d.items() give you the parts. Wrap in list() when the test wants a list.",
        ],
        code='''counts = {}
for word in "a b a".split():
    counts[word] = counts.get(word, 0) + 1
counts                 # {'a': 2, 'b': 1}

{k: v * v for k, v in [(1, 1), (2, 2)]}
                       # {1: 1, 2: 4}''',
        challenges=["word_count", "get_keys", "invert_dict", "square_dict"],
        talk="get_keys returned dict_keys([...]) and failed. Why, and what one call fixes it?",
        quiz=[
            ('What does dict.get("key", 0) do?', ["Returns the value, or 0 if missing", "Always returns 0", "Raises an error if missing", "Deletes the key"], 0),
            ("Which data type is immutable?", ["list", "dict", "tuple", "set"], 2),
        ],
        prepare="Have word_count('') ready as the Flawless case: it must return {} without error.",
        direct="Build the counting loop together, line by line, in the terminal. Then pairs do get_keys and invert_dict on their own.",
        consider="The terminal compares printed form. dict_keys and Counter both hold the right data and both fail the test. That is the moment to talk about returning the type the caller asked for.",
    ),
    dict(
        key="together", title="Putting it together",
        keyline="Bigger problems are small problems stacked: a loop inside a loop, a check inside a loop.",
        read=[
            "find_primes needs two ideas you already have: a loop over candidates, and an inner check for divisors.",
            "Write the inner check as its own helper function first. Test it alone. Then use it in the loop.",
            "This is the shape of every Codewars kata that follows: break it down, test each piece.",
        ],
        code='''def is_prime(n):
    if n < 2:
        return False
    for d in range(2, n):
        if n % d == 0:
            return False
    return True

def find_primes(n):
    return [p for p in range(2, n + 1) if is_prime(p)]''',
        challenges=["find_primes"],
        talk="Where would you stop the inner loop early, and why does it still give the right answer?",
        quiz=[
            ('bool("") evaluates to?', ["True", "False", "None", "an error"], 1),
            ("How do you handle errors in Python?", ["try / except", "catch / throw", "if / error", "handle / when"], 0),
        ],
        prepare="This is the last fundamentals block before the break. Pairs that finish early start the first 7 kyu kata.",
        direct="Do not show the code first. Give pairs ten minutes with only the tests. Then walk the helper-function version on screen.",
        consider="A pair whose find_primes(1) returns [2] has an off-by-one in range. Ask them to read range(2, n + 1) aloud.",
    ),
]

# Challenges the terminal ships, in ladder order.
FUNDAMENTALS_ORDER = [name for b in BLOCKS for name in b["challenges"]]
assert sorted(FUNDAMENTALS_ORDER) == sorted(FUNDAMENTALS), "every challenge must be in exactly one block"
assert len(FUNDAMENTALS_ORDER) == 20
