# 🐍 Functional-Style Python Practice for Beginners
# Focus: Pure functions, loops, recursion, immutability — NO lambdas yet
# Each function includes:
# - Clear TODOs
# - References to look up (e.g., "See: Python for loop")
# - 4 test cases with expected outputs

# === Beginner Problems: Arithmetic, Strings, Loops, Lists ===

# 1. Add Two Numbers
def add(a, b):
    # TODO: Return the sum of a and b
    # See: Python return statement
    pass

# Tests
print(add(2, 3))       # Expected: 5
print(add(-1, 1))      # Expected: 0
print(add(0, 0))       # Expected: 0
print(add(100, 250))   # Expected: 350

# 2. Convert Celsius to Fahrenheit
def celsius_to_fahrenheit(celsius):
    # TODO: Apply the formula: Fahrenheit = Celsius * 9/5 + 32
    # See: Python arithmetic operators
    pass

# Tests
print(celsius_to_fahrenheit(0))    # Expected: 32.0
print(celsius_to_fahrenheit(100))  # Expected: 212.0
print(celsius_to_fahrenheit(-40))  # Expected: -40.0
print(celsius_to_fahrenheit(37))   # Expected: 98.6

# 3. Count Even Numbers in List
def count_evens(numbers):
    # TODO: Use a for loop to count how many numbers are even
    # See: Python for loop, modulo operator
    pass

# Tests
print(count_evens([1, 2, 3, 4]))          # Expected: 2
print(count_evens([2, 4, 6, 8]))          # Expected: 4
print(count_evens([1, 3, 5]))             # Expected: 0
print(count_evens([]))                   # Expected: 0

# 4. Replace Index in List (immutably)
def replace_index(lst, idx, value):
    # TODO: Return a new list with value at index idx replaced
    # See: Python list slicing
    pass

# Tests
print(replace_index([1, 2, 3], 1, 9))     # Expected: [1, 9, 3]
print(replace_index([5, 6, 7], 0, 10))    # Expected: [10, 6, 7]
print(replace_index([0, 1], 1, 5))        # Expected: [0, 5]
print(replace_index([9], 0, 3))           # Expected: [3]

# 5. Multiply All Elements (using loop)
def multiply_all(numbers):
    # TODO: Use a for loop to multiply all elements
    # See: Python for loop, accumulator pattern
    pass

# Tests
print(multiply_all([1, 2, 3, 4]))   # Expected: 24
print(multiply_all([5]))           # Expected: 5
print(multiply_all([]))            # Expected: 1
print(multiply_all([2, 0, 5]))     # Expected: 0

# More problems will follow in full version...

# 6. Uppercase and Join Strings
def format_names(names):
    # TODO: Use a for loop to:
    #   - remove empty strings
    #   - convert names to uppercase
    #   - join with commas
    # See: Python string.upper(), list.append(), str.join()
    pass

# Tests
print(format_names(['alice', 'bob']))           # Expected: 'ALICE,BOB'
print(format_names(['', 'charlie', 'david']))   # Expected: 'CHARLIE,DAVID'
print(format_names(['eve']))                    # Expected: 'EVE'
print(format_names(['']))                       # Expected: ''

# 7. Reverse a String
def reverse_string(s):
    # TODO: Use a while loop or slicing to reverse the string
    # See: Python string slicing or while loops
    pass

# Tests
print(reverse_string('hello'))      # Expected: 'olleh'
print(reverse_string('a'))          # Expected: 'a'
print(reverse_string(''))           # Expected: ''
print(reverse_string('Python'))     # Expected: 'nohtyP'

# 8. Check for Palindrome
def is_palindrome(s):
    # TODO: Compare string with its reverse
    # See: Python string slicing
    pass

# Tests
print(is_palindrome('radar'))       # Expected: True
print(is_palindrome('hello'))       # Expected: False
print(is_palindrome(''))            # Expected: True
print(is_palindrome('level'))       # Expected: True

# 9. Count Vowels in String
def count_vowels(s):
    # TODO: Use a for loop to count vowels (a, e, i, o, u)
    # See: Python membership test: `in`
    pass

# Tests
print(count_vowels('hello'))        # Expected: 2
print(count_vowels('sky'))          # Expected: 0
print(count_vowels('aeiou'))        # Expected: 5
print(count_vowels('AEiOu'))        # Expected: 5

# 10. Recursive Sum of List (Functional Recursion)
def recursive_sum(lst):
    # TODO: Use recursion:
    # - Base case: empty list → return 0
    # - Recursive case: return first element + recursive_sum(rest)
    # See: Python recursion, slicing
    pass

# Tests
print(recursive_sum([1, 2, 3, 4]))   # Expected: 10
print(recursive_sum([]))            # Expected: 0
print(recursive_sum([5]))           # Expected: 5
print(recursive_sum([10, -10, 5]))  # Expected: 5

# (Problems 11–60 will be appended in full as a continuation)

# 11. Absolute Difference
def absolute_diff(a, b):
    # TODO: Return the absolute difference between a and b
    # See: abs() function
    pass

# Tests
print(absolute_diff(5, 3))     # Expected: 2
print(absolute_diff(3, 5))     # Expected: 2
print(absolute_diff(-5, -2))   # Expected: 3
print(absolute_diff(0, 0))     # Expected: 0

# 12. Print Centered Banner
def print_banner(text):
    # TODO: Return text centered in 20 characters with '*'
    # See: Python string.center()
    pass

# Tests
print(print_banner("Hi"))        # Expected: '********Hi*********'
print(print_banner("Welcome"))   # Expected: '******Welcome******'
print(print_banner(""))          # Expected: '********************'
print(print_banner("Python"))    # Expected: '*******Python*******'

# 13. Repeat Characters
def repeat_chars(s):
    # TODO: Return string where each char is repeated twice
    # See: String concatenation, loops
    pass

# Tests
print(repeat_chars("hi"))     # Expected: 'hhii'
print(repeat_chars(""))       # Expected: ''
print(repeat_chars("abc"))    # Expected: 'aabbcc'
print(repeat_chars("A1"))     # Expected: 'AA11'

# 14. Sum of Digits
def sum_digits(n):
    # TODO: Return the sum of digits in a number
    # See: str(), int(), for loop
    pass

# Tests
print(sum_digits(123))        # Expected: 6
print(sum_digits(0))          # Expected: 0
print(sum_digits(999))        # Expected: 27
print(sum_digits(1001))       # Expected: 2

# 15. Max of Three Numbers
def max_of_three(a, b, c):
    # TODO: Return the largest of three numbers
    # See: max() function or conditionals
    pass

# Tests
print(max_of_three(1, 2, 3))   # Expected: 3
print(max_of_three(3, 2, 1))   # Expected: 3
print(max_of_three(-1, 0, -5)) # Expected: 0
print(max_of_three(5, 5, 5))   # Expected: 5

# (... continuing to 60 problems ...)

# 16. Find Smallest Number in List
def min_value(lst):
    # TODO: Loop through and find smallest value
    # See: Python for loop, comparison
    pass

# Tests
print(min_value([1, 4, 2]))     # Expected: 1
print(min_value([99]))          # Expected: 99
print(min_value([-1, 0, -5]))   # Expected: -5
print(min_value([10, 10]))      # Expected: 10

# 17. Average of Numbers
def average(lst):
    # TODO: Return average of numbers in list
    # See: sum(), len()
    pass

# Tests
print(average([2, 4, 6]))        # Expected: 4.0
print(average([1]))              # Expected: 1.0
print(average([1, 2, 3, 4]))     # Expected: 2.5
print(average([]))               # Expected: 0.0

# 18. List All Odd Numbers
def list_odds(n):
    # TODO: Return list of odd numbers from 1 to n (inclusive)
    # See: range(), modulo operator
    pass

# Tests
print(list_odds(5))      # Expected: [1, 3, 5]
print(list_odds(10))     # Expected: [1, 3, 5, 7, 9]
print(list_odds(1))      # Expected: [1]
print(list_odds(0))      # Expected: []

# 19. Capitalize Words
def capitalize_words(sentence):
    # TODO: Return sentence with each word capitalized
    # See: str.split(), str.capitalize(), str.join()
    pass

# Tests
print(capitalize_words("hello world"))        # Expected: "Hello World"
print(capitalize_words("hi there"))           # Expected: "Hi There"
print(capitalize_words(""))                   # Expected: ""
print(capitalize_words("capitalize this!"))   # Expected: "Capitalize This!"

# 20. String Contains Vowel
def contains_vowel(s):
    # TODO: Return True if any vowel is in string
    # See: Python any(), membership test
    pass

# Tests
print(contains_vowel("hello"))   # Expected: True
print(contains_vowel("sky"))     # Expected: False
print(contains_vowel("a"))       # Expected: True
print(contains_vowel(""))        # Expected: False

# More problems (21–60) will continue with similar structure...

# === Intermediate Problems: Sorting, Filtering, Dictionaries, JSON, 2D Arrays ===

# 21. Sort Numbers Ascending
def sort_numbers(lst):
    # TODO: Return a sorted list (ascending order)
    # See: sorted()
    pass

# Tests
print(sort_numbers([3, 1, 2]))   # Expected: [1, 2, 3]
print(sort_numbers([5]))         # Expected: [5]
print(sort_numbers([]))          # Expected: []
print(sort_numbers([10, -1]))    # Expected: [-1, 10]

# 22. Count Word Frequencies
def word_count(text):
    # TODO: Count how often each word appears
    # See: str.split(), dictionary
    pass

# Tests
print(word_count("hello world hello"))     # Expected: {'hello': 2, 'world': 1}
print(word_count(""))                      # Expected: {}
print(word_count("a a a"))                 # Expected: {'a': 3}
print(word_count("one two one"))           # Expected: {'one': 2, 'two': 1}

# 23. Convert JSON to Dict
def json_to_dict(json_string):
    # TODO: Convert JSON string to dictionary
    # See: json.loads
    pass

# Tests
print(json_to_dict('{"a": 1, "b": 2}'))           # Expected: {'a': 1, 'b': 2}
print(json_to_dict('{}'))                        # Expected: {}
print(json_to_dict('{"name": "Bob"}'))           # Expected: {'name': 'Bob'}
print(json_to_dict('{"flag": true}'))            # Expected: {'flag': True}

# 24. Convert Dict to JSON
def dict_to_json(d):
    # TODO: Convert dictionary to JSON string
    # See: json.dumps
    pass

# Tests
print(dict_to_json({'a': 1}))              # Expected: '{"a": 1}'
print(dict_to_json({}))                   # Expected: '{}'
print(dict_to_json({'x': 10}))            # Expected: '{"x": 10}'
print(dict_to_json({'flag': False}))      # Expected: '{"flag": false}'

# 25. Sum Diagonal of 2D Matrix
def sum_diagonal(matrix):
    # TODO: Return sum of matrix[i][i]
    # See: nested lists, range()
    pass

# Tests
print(sum_diagonal([[1, 2], [3, 4]]))             # Expected: 5
print(sum_diagonal([[5]]))                       # Expected: 5
print(sum_diagonal([[1,0,0],[0,2,0],[0,0,3]]))    # Expected: 6
print(sum_diagonal([[1,2,3],[4,5,6],[7,8,9]]))    # Expected: 15

# 26. Row Sums in 2D List
def row_sums(matrix):
    # TODO: Return list of row totals
    # See: list comprehension, sum()
    pass

# Tests
print(row_sums([[1, 2], [3, 4]]))        # Expected: [3, 7]
print(row_sums([[5]]))                  # Expected: [5]
print(row_sums([[1,1,1],[2,2,2]]))      # Expected: [3, 6]
print(row_sums([[]]))                   # Expected: [0]

# 27. Second Largest Number
def second_largest(lst):
    # TODO: Return second largest unique number
    # See: set(), sorted()
    pass

# Tests
print(second_largest([5, 3, 1, 2]))   # Expected: 3
print(second_largest([1, 1, 1]))      # Expected: None
print(second_largest([1, 2]))         # Expected: 1
print(second_largest([10, 20, 30]))   # Expected: 20

# 28. Reverse Words in Sentence
def reverse_words(sentence):
    # TODO: Reverse each word in sentence, keep order
    # See: str.split(), slicing
    pass

# Tests
print(reverse_words("hello world"))    # Expected: "olleh dlrow"
print(reverse_words("hi"))             # Expected: "ih"
print(reverse_words(""))               # Expected: ""
print(reverse_words("abc def ghi"))    # Expected: "cba fed ihg"

# 29. Find Common Elements
def common_elements(a, b):
    # TODO: Return items found in both lists
    # See: set intersection
    pass

# Tests
print(common_elements([1, 2, 3], [2, 3, 4]))   # Expected: [2, 3]
print(common_elements([], [1]))               # Expected: []
print(common_elements(['a'], ['b']))          # Expected: []
print(common_elements([1,2], [1,2,3]))         # Expected: [1, 2]

# 30. Get Keys from Dictionary
def get_keys(d):
    # TODO: Return list of keys
    # See: dict.keys()
    pass

# Tests
print(get_keys({'a': 1, 'b': 2}))        # Expected: ['a', 'b']
print(get_keys({}))                     # Expected: []
print(get_keys({'x': 10}))              # Expected: ['x']
print(get_keys({'a': 1, 'c': 2}))       # Expected: ['a', 'c']

# === Advanced Problems: Comprehension, Sets, Flattening, Custom Sort, Prime Logic ===

# 31. Find Duplicates
def find_duplicates(lst):
    # TODO: Return list of values that appear more than once
    # See: dictionary or set
    pass

# Tests
print(find_duplicates([1, 2, 2, 3, 3, 3]))  # Expected: [2, 3]
print(find_duplicates([1, 2, 3]))          # Expected: []
print(find_duplicates([]))                # Expected: []
print(find_duplicates(['a', 'b', 'a']))   # Expected: ['a']

# 32. Remove Duplicates (Preserve Order)
def remove_duplicates(lst):
    # TODO: Return list without duplicates, preserve order
    # See: set and loop
    pass

# Tests
print(remove_duplicates([1, 2, 2, 3]))     # Expected: [1, 2, 3]
print(remove_duplicates([1, 1, 1]))        # Expected: [1]
print(remove_duplicates([]))              # Expected: []
print(remove_duplicates(['a', 'b', 'a']))  # Expected: ['a', 'b']

# (Remaining 33–60 continue in same style...)

# 33. Invert Dictionary (value -> key)
def invert_dict(d):
    # TODO: Return dictionary with keys and values swapped
    # See: dict comprehension
    pass

# Tests
print(invert_dict({'a': 1, 'b': 2}))     # Expected: {1: 'a', 2: 'b'}
print(invert_dict({}))                   # Expected: {}
print(invert_dict({'x': 10}))            # Expected: {10: 'x'}
print(invert_dict({'one': 1, 'two': 2})) # Expected: {1: 'one', 2: 'two'}

# 34. Merge Lists into Dictionary
def merge_lists(keys, values):
    # TODO: Return a dictionary from keys and values
    # See: zip()
    pass

# Tests
print(merge_lists(['a', 'b'], [1, 2]))     # Expected: {'a': 1, 'b': 2}
print(merge_lists([], []))                # Expected: {}
print(merge_lists(['x'], [10]))           # Expected: {'x': 10}
print(merge_lists(['a', 'b'], [1]))       # Expected: {'a': 1}

# 35. Only Numbers from Mixed List
def only_numbers(items):
    # TODO: Return list of numbers (int, float only)
    # See: isinstance()
    pass

# Tests
print(only_numbers([1, 'a', 3.5, True]))    # Expected: [1, 3.5]
print(only_numbers(['1', 2, 3.0]))          # Expected: [2, 3.0]
print(only_numbers([]))                    # Expected: []
print(only_numbers([None, 0, 4]))          # Expected: [0, 4]

# 36. Most Vowels in Word
def most_vowels(words):
    # TODO: Return word with most vowels
    # See: max() with key
    pass

# Tests
print(most_vowels(['hi', 'hello', 'world']))     # Expected: 'hello'
print(most_vowels(['sky', 'try']))               # Expected: 'sky'
print(most_vowels(['']))                         # Expected: ''
print(most_vowels(['aeiou', 'a']))               # Expected: 'aeiou'

# 37. Find Prime Numbers in Range
def find_primes(n):
    # TODO: Return list of primes ≤ n
    # See: loop, modulo
    pass

# Tests
print(find_primes(10))     # Expected: [2, 3, 5, 7]
print(find_primes(1))      # Expected: []
print(find_primes(2))      # Expected: [2]
print(find_primes(20))     # Expected: [2, 3, 5, 7, 11, 13, 17, 19]

# 38. Flatten Dictionary to Key:Value Strings
def flatten_dict(d):
    # TODO: Return list like ['a:1', 'b:2']
    # See: f-strings or str formatting
    pass

# Tests
print(flatten_dict({'a': 1, 'b': 2}))       # Expected: ['a:1', 'b:2']
print(flatten_dict({}))                    # Expected: []
print(flatten_dict({'x': 10}))             # Expected: ['x:10']
print(flatten_dict({'one': 'uno'}))        # Expected: ['one:uno']

# 39. Common Keys in Dicts
def common_keys(d1, d2):
    # TODO: Return list of keys in both dictionaries
    # See: set intersection
    pass

# Tests
print(common_keys({'a': 1}, {'a': 2}))             # Expected: ['a']
print(common_keys({'x': 1}, {'y': 2}))             # Expected: []
print(common_keys({'a': 1, 'b': 2}, {'b': 3}))     # Expected: ['b']
print(common_keys({}, {}))                        # Expected: []

# 40. Index of Minimum Value
def index_of_min(lst):
    # TODO: Return index of smallest value
    # See: enumerate(), min()
    pass

# Tests
print(index_of_min([3, 1, 2]))        # Expected: 1
print(index_of_min([0]))              # Expected: 0
print(index_of_min([5, -1, -2]))      # Expected: 2
print(index_of_min([10, 9, 10]))      # Expected: 1

# 41. Filter Even Numbers
def filter_evens(lst):
    # TODO: Return new list with only even numbers
    # See: list comprehension
    pass

# Tests
print(filter_evens([1, 2, 3, 4]))       # Expected: [2, 4]
print(filter_evens([]))                # Expected: []
print(filter_evens([1, 3, 5]))          # Expected: []
print(filter_evens([0, 2, 8]))          # Expected: [0, 2, 8]

# 42. Sort Strings by Length
def sort_by_length(words):
    # TODO: Sort list by word length
    # See: sorted(), key=len
    pass

# Tests
print(sort_by_length(['hi', 'hello', 'a']))  # Expected: ['a', 'hi', 'hello']
print(sort_by_length(['one']))               # Expected: ['one']
print(sort_by_length([]))                    # Expected: []
print(sort_by_length(['abc', 'ab', 'abcd'])) # Expected: ['ab', 'abc', 'abcd']

# 43. Group by First Letter
def group_by_first_letter(words):
    # TODO: Group words by first letter
    # See: dictionary of lists
    pass

# Tests
print(group_by_first_letter(["apple", "apricot", "banana"]))  # {'a': ['apple', 'apricot'], 'b': ['banana']}
print(group_by_first_letter([]))                               # Expected: {}
print(group_by_first_letter(["dog", "deer"]))                  # {'d': ['dog', 'deer']}
print(group_by_first_letter(["zebra"]))                        # {'z': ['zebra']}

# 44. Count Characters (Case-Insensitive)
def count_characters(s):
    # TODO: Return character frequency dictionary (lowercase only)
    # See: dictionary, lower()
    pass

# Tests
print(count_characters("AaBb"))     # Expected: {'a': 2, 'b': 2}
print(count_characters(""))         # Expected: {}
print(count_characters("abcABC"))   # Expected: {'a': 2, 'b': 2, 'c': 2}
print(count_characters("123aA"))    # Expected: {'1': 1, '2': 1, '3': 1, 'a': 2}

# 45. All True?
def all_true(lst):
    # TODO: Return True if all elements are truthy
    # See: all()
    pass

# Tests
print(all_true([True, 1, "yes"]))   # Expected: True
print(all_true([True, 0]))          # Expected: False
print(all_true([]))                 # Expected: True
print(all_true([1, 2, 3]))          # Expected: True

# 46. Any True?
def any_true(lst):
    # TODO: Return True if any element is truthy
    # See: any()
    pass

# Tests
print(any_true([False, 0, ""]))     # Expected: False
print(any_true([0, "", "ok"]))      # Expected: True
print(any_true([]))                 # Expected: False
print(any_true([False, None, 1]))   # Expected: True

# 47. Merge Two Dicts
def merge_dicts(d1, d2):
    # TODO: Combine dictionaries (d2 overwrites d1)
    # See: dict.update()
    pass

# Tests
print(merge_dicts({'a': 1}, {'b': 2}))        # Expected: {'a': 1, 'b': 2}
print(merge_dicts({'x': 10}, {'x': 20}))      # Expected: {'x': 20}
print(merge_dicts({}, {'a': 1}))              # Expected: {'a': 1}
print(merge_dicts({'a': 1}, {}))              # Expected: {'a': 1}

# 48. Word Count in Sentence
def count_words(sentence):
    # TODO: Count number of words in sentence
    # See: str.split()
    pass

# Tests
print(count_words("Hello world"))           # Expected: 2
print(count_words("This is a test."))       # Expected: 4
print(count_words(""))                      # Expected: 0
print(count_words("One"))                   # Expected: 1

# 49. Dictionary Comprehension Squares
def square_dict(nums):
    # TODO: Return dict where key is number, value is square
    # See: dict comprehension
    pass

# Tests
print(square_dict([1, 2, 3]))        # Expected: {1: 1, 2: 4, 3: 9}
print(square_dict([]))              # Expected: {}
print(square_dict([0]))             # Expected: {0: 0}
print(square_dict([-1, 1]))         # Expected: {-1: 1, 1: 1}

# 50. Flatten 2D List
def flatten(matrix):
    # TODO: Return a flat list from 2D list
    # See: nested loops or comprehension
    pass

# Tests
print(flatten([[1, 2], [3, 4]]))       # Expected: [1, 2, 3, 4]
print(flatten([[5]]))                 # Expected: [5]
print(flatten([[]]))                  # Expected: []
print(flatten([[1], [2, 3]]))         # Expected: [1, 2, 3]
