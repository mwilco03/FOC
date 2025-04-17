#!/bin/bash

#================
# 1. Add Two Numbers
#================
add_two_numbers() {
  local a=$1
  local b=$2
  # TODO: Print the sum of $a and $b
}
add_two_numbers 2 3       # Expected: 5
add_two_numbers -1 1      # Expected: 0
add_two_numbers 0 0       # Expected: 0
add_two_numbers 100 250   # Expected: 350

#================
# 2. Greet User by Name
#================
greet_user() {
  local name="$1"
  # TODO: Print "Hello, <name>!"
}
greet_user "Alex"         # Expected: Hello, Alex!
greet_user "Taylor"       # Expected: Hello, Taylor!
greet_user "Jordan"       # Expected: Hello, Jordan!
greet_user ""             # Expected: Hello, !

#================
# 3. Print Numbers 1 to 5
#================
print_numbers_1_to_5() {
  # TODO: Use a loop to print 1 through 5 on one line
}
print_numbers_1_to_5      # Expected: 1 2 3 4 5

#================
# 4. Count Words in a Sentence
#================
count_words() {
  local sentence="$1"
  # TODO: Count words in $sentence
}
count_words "Bash is fun"           # Expected: 3
count_words "One two three four"    # Expected: 4
count_words "Hi"                    # Expected: 1
count_words ""                      # Expected: 0

#================
# 5. Reverse a String
#================
reverse_string() {
  local text="$1"
  # TODO: Reverse $text using rev or array
}
reverse_string "Bash"               # Expected: hsaB
reverse_string "12345"              # Expected: 54321
reverse_string "hello"              # Expected: olleh
reverse_string ""                   # Expected: (empty)

#================
# 6. Is Even
#================
is_even() {
  local n=$1
  # TODO: Print "true" if even, "false" otherwise
}
is_even 4      # Expected: true
is_even 3      # Expected: false
is_even 0      # Expected: true
is_even -2     # Expected: true

#================
# 7. Multiply Elements in an Array
#================
multiply_array() {
  local arr=("$@")
  # TODO: Multiply all elements and print result
}
multiply_array 1 2 3         # Expected: 6
multiply_array 4 5           # Expected: 20
multiply_array 10 0 2        # Expected: 0
multiply_array 7             # Expected: 7

#================
# 8. Get File Extension
#================
get_extension() {
  local file="$1"
  # TODO: Extract and print extension
}
get_extension "doc.txt"         # Expected: txt
get_extension "archive.tar.gz"  # Expected: gz
get_extension "README"          # Expected: (empty)
get_extension ".bashrc"         # Expected: bashrc

#================
# 9. Validate Email Format (Regex)
#================
validate_email() {
  local email="$1"
  # TODO: Use grep or [[ ]] to check email pattern
}
validate_email "user@example.com"   # Expected: valid
validate_email "bad@email"          # Expected: invalid
validate_email "a@b.c"              # Expected: valid
validate_email "notanemail"         # Expected: invalid

#================
# 10. Download File with curl
#================
download_file() {
  local url="$1"
  local dest="$2"
  # TODO: Use curl to download $url to $dest
  # Hint: Try https://raw.githubusercontent.com/datablist/sample-csv-files/main/files/people/people-100.csv
}
download_file "https://www.example.com/index.html" "/tmp/example.html"
download_file "https://google.com" "/tmp/google.html"
download_file "https://doesnotexist.bogus" "/tmp/fail.txt"
download_file "" "/tmp/invalid.txt"


#================
# 11. Sum Variable-Length Arguments
#================
sum_args() {
  # TODO: Accept any number of arguments and return their sum
}
sum_args 1 2 3         # Expected: 6
sum_args 10 5          # Expected: 15
sum_args 0             # Expected: 0
sum_args               # Expected: 0

#================
# 12. Count Lines in a File with While Read Line
#================
count_lines() {
  local file="$1"
  # TODO: Count number of lines using while read line
}
count_lines "/etc/passwd"      # Expected: (varies)
count_lines "empty.txt"        # Expected: 0
count_lines "nofile.txt"       # Expected: error
count_lines "$HOME/.bashrc"    # Expected: (varies)

#================
# 13. Case Matching CLI Menu
#================
show_menu() {
  local input="$1"
  # TODO: Use case to handle: start, stop, restart, exit
}
show_menu "start"      # Expected: Starting...
show_menu "stop"       # Expected: Stopping...
show_menu "restart"    # Expected: Restarting...
show_menu "exit"       # Expected: Exiting...

#================
# 14. Find and Replace with sed
#================
replace_text() {
  local file="$1"
  local search="$2"
  local replace="$3"
  # TODO: Use sed to replace text in-place (backup optional)
}
replace_text "demo.txt" "foo" "bar"
replace_text "sample.txt" "hello" "hi"
replace_text "nofile.txt" "x" "y"
replace_text "" "test" "TEST"

#================
# 15. Parse Delimited String with awk
#================
parse_fields() {
  local line="$1"
  # TODO: Use awk to print first and second field
}
parse_fields "name,age,city"         # Expected: name age
parse_fields "john,30,NY"            # Expected: john 30
parse_fields "a:b:c"                 # Expected: a b (if using FS=":")
parse_fields "onlyonefield"          # Expected: onlyonefield

#================
# 16. Loop Over Files in Directory (for loop)
#================
list_txt_files() {
  local dir="$1"
  # TODO: Loop over *.txt files in $dir and print filenames
}
list_txt_files "."                   # Expected: List of .txt files
list_txt_files "/tmp"               # Depends on files
list_txt_files "/etc"               # Likely none
list_txt_files "nofolder"           # Expected: error

#================
# 17. Check if File Exists and is Not Empty
#================
check_file() {
  local file="$1"
  # TODO: Print "exists", "empty", or "missing"
}
check_file "/etc/passwd"            # Expected: exists
check_file "empty.txt"              # Expected: empty
check_file "nofile.txt"             # Expected: missing
check_file ""                       # Expected: missing

#================
# 18. Read Key-Value Config into Variables
#================
load_config() {
  local file="$1"
  # TODO: Use while read and set values like NAME=value
}
load_config "config.env"            # Expected: export variables
load_config "sample.env"            # Expected: set values
load_config "missing.env"           # Expected: error
load_config ""                      # Expected: error

#================
# 19. Print Arguments in Reverse
#================
reverse_args() {
  # TODO: Reverse and print "$@" arguments
}
reverse_args one two three          # Expected: three two one
reverse_args "a" "b" "c" "d"        # Expected: d c b a
reverse_args ""                     # Expected: (empty or blank)
reverse_args apple                  # Expected: apple

#================
# 20. Validate IPv4 Address
#================
validate_ip() {
  local ip="$1"
  # TODO: Use regex or awk to check IPv4 format
}
validate_ip "192.168.0.1"           # Expected: valid
validate_ip "256.1.1.1"             # Expected: invalid
validate_ip "abc.def.ghi.jkl"       # Expected: invalid
validate_ip "127.0.0.1"             # Expected: valid

#!/bin/bash

#================
# 21. Reverse a String
#================
reverse_string() {
  local input="$1"
  # TODO: Reverse the input string (hint: use rev or array indexing)
}
reverse_string "bash"             # Expected: hsab
reverse_string "12345"            # Expected: 54321
reverse_string "level"            # Expected: level
reverse_string ""                 # Expected: (empty)

#================
# 22. Expand a Range with Brace Expansion
#================
expand_range() {
  local pattern="$1"
  # TODO: Expand a string like {1..5} or {a..d}
}
expand_range "{1..3}"             # Expected: 1 2 3
expand_range "{a..c}"             # Expected: a b c
expand_range "{01..03}"           # Expected: 01 02 03
expand_range "{5..1}"             # Expected: 5 4 3 2 1

#================
# 23. Count Unique Words
#================
count_unique_words() {
  local text="$1"
  # TODO: Use sort and uniq -c to count each word
}
count_unique_words "apple banana apple"   # Expected: apple=2 banana=1
count_unique_words "one one one"          # Expected: one=3
count_unique_words "a b c d a"            # Expected: a=2 b=1 c=1 d=1
count_unique_words ""                     # Expected: (empty)

#================
# 24. Sort Numbers and Remove Duplicates
#================
sort_unique() {
  local list="$1"
  # TODO: Sort and remove duplicates
}
sort_unique "3 1 2 3 1"         # Expected: 1 2 3
sort_unique "9 8 8 7 6"         # Expected: 6 7 8 9
sort_unique ""                 # Expected: (empty)
sort_unique "5 5 5 5"           # Expected: 5

#================
# 25. Parse JSON with jq
#================
parse_json_field() {
  local json="$1"
  local field="$2"
  # TODO: Return value of $field using jq
}
parse_json_field '{"name":"Alice","age":30}' "name"   # Expected: Alice
parse_json_field '{"a":1,"b":2}' "b"                  # Expected: 2
parse_json_field '{}' "x"                             # Expected: null
parse_json_field '' "key"                             # Expected: error

#================
# 26. Use awk to Track Unique Counters
#================
awk_counter() {
  # TODO: Read from stdin and count unique fields with awk
  # Hint: Use awk '{ count[$1]++ } END { for (k in count) print k, count[k] }'
  :
}
echo -e "a\na\nb\nc\na\nc" | awk_counter     # Expected: a 3, b 1, c 2
echo -e "x\ny\nz\nx\nx" | awk_counter        # Expected: x 3, y 1, z 1
echo "" | awk_counter                        # Expected: (empty)
echo -e "one\none\none" | awk_counter        # Expected: one 3

#================
# 27. CIDR Address Summary (Advanced Networking)
#================
cidr_summary() {
  local cidr="$1"
  # TODO:
  # 1. Validate CIDR (e.g. 192.168.1.0/24)
  # 2. Print: network address, usable IP range, gateway, broadcast, usable count
  # Hint: Use ipcalc, or parse bits manually (bit math)
}
cidr_summary "192.168.1.0/30"      # Expected: usable IPs: 2, gateway: .1, broadcast: .3
cidr_summary "10.0.0.0/24"         # Expected: usable IPs: 254
cidr_summary "172.16.0.0/16"       # Expected: usable IPs: 65534
cidr_summary "invalid"             # Expected: error

#================
# 28. Ping List of Hosts from File
#================
ping_hosts() {
  local file="$1"
  # TODO: Ping each line from $file, report reachable or not
}
ping_hosts "hosts.txt"            # Expected: host up/down
ping_hosts "/etc/hosts"           # Expected: parsed results
ping_hosts "nofile.txt"           # Expected: error
ping_hosts ""                     # Expected: error

#================
# 29. Parse /etc/passwd to Show UID >= 1000 Users
#================
list_normal_users() {
  # TODO: Use awk to filter users with UID >= 1000
}
list_normal_users                 # Expected: user list (no system accounts)
# Also test with cut + awk for formatting
list_normal_users                 # Expected: just usernames
list_normal_users                 # Expected: one-per-line
list_normal_users                 # Expected: readable output

#================
# 30. Count File Types Recursively
#================
count_file_types() {
  local path="$1"
  # TODO: Recursively count file extensions, like .sh, .txt, .conf
}
count_file_types "."             # Expected: .sh=10, .txt=5 (example)
count_file_types "/etc"          # Expected: .conf=.service=.d=...
count_file_types "/tmp"          # Depends on content
count_file_types "nofolder"      # Expected: error

#!/bin/bash

#================
# 31. Generate a Number Range (seq)
#================
generate_range() {
  local start=$1
  local end=$2
  # TODO: Use seq to print numbers from start to end
}
generate_range 1 5             # Expected: 1 2 3 4 5
generate_range 5 1             # Expected: 5 4 3 2 1
generate_range 10 10           # Expected: 10
generate_range -3 3            # Expected: -3 -2 -1 0 1 2 3

#================
# 32. Shuffle Array Elements (shuf)
#================
shuffle_array() {
  local items=("$@")
  # TODO: Print shuffled elements using shuf
}
shuffle_array apple banana cherry       # Expected: random order
shuffle_array 1 2 3 4 5                  # Expected: random order
shuffle_array hello                     # Expected: hello
shuffle_array                           # Expected: (empty)

#================
# 33. Reverse Array in Bash
#================
reverse_array() {
  local input=("$@")
  # TODO: Reverse order and print items
}
reverse_array a b c                     # Expected: c b a
reverse_array 1 2 3 4                   # Expected: 4 3 2 1
reverse_array                           # Expected: (empty)
reverse_array apple                     # Expected: apple

#================
# 34. Check if Command Exists (which)
#================
check_command() {
  local cmd="$1"
  # TODO: Use which or command -v to check for presence
}
check_command "bash"                   # Expected: found
check_command "curl"                   # Expected: found or not
check_command "nonexistenttool"        # Expected: not found
check_command ""                       # Expected: not found

#================
# 35. Encode String to Uppercase with tr
#================
to_upper() {
  local input="$1"
  # TODO: Use tr to convert to uppercase
}
to_upper "hello world"                # Expected: HELLO WORLD
to_upper "PowerShell"                # Expected: POWERSHELL
to_upper ""                          # Expected: (empty)
to_upper "123abc!"                   # Expected: 123ABC!

#================
# 36. Test Open Port with netcat
#================
port_check() {
  local host="$1"
  local port="$2"
  # TODO: Use nc to test if port is open
}
port_check "localhost" 22             # Expected: open or closed
port_check "google.com" 80            # Expected: open
port_check "localhost" 9999           # Expected: closed
port_check "" 80                      # Expected: error

#================
# 37. Remove Duplicate Lines from File (sort + uniq)
#================
deduplicate_file() {
  local file="$1"
  # TODO: Output deduplicated lines to stdout
}
deduplicate_file "file.txt"          # Expected: unique lines
deduplicate_file "duplicates.txt"    # Expected: no dupes
deduplicate_file "empty.txt"         # Expected: (empty)
deduplicate_file "nofile.txt"        # Expected: error

#================
# 38. Sum All Integers from stdin
#================
sum_input() {
  # TODO: Read from stdin, sum integers, ignore non-numbers
  :
}
echo -e "1\n2\n3" | sum_input          # Expected: 6
echo -e "5\n-2\napple\n10" | sum_input # Expected: 13
echo "" | sum_input                    # Expected: 0
echo -e "abc\nxyz" | sum_input         # Expected: 0

#================
# 39. Build and Run a Pipelined Command
#================
pipeline_grep_count() {
  local pattern="$1"
  local file="$2"
  # TODO: Grep $pattern in $file, count matches
}
pipeline_grep_count "bash" "/etc/passwd"     # Expected: count
pipeline_grep_count "nologin" "/etc/passwd"  # Expected: count
pipeline_grep_count "xyz" "/etc/passwd"      # Expected: 0
pipeline_grep_count "" ""                    # Expected: error

#================
# 40. Generate Password from /dev/urandom
#================
generate_password() {
  local length="$1"
  # TODO: Use tr and head to generate random alphanumeric password
}
generate_password 8               # Expected: 8-char random string
generate_password 12              # Expected: 12-char string
generate_password 0               # Expected: (empty or error)
generate_password                 # Expected: default or error

#!/bin/bash

#================
# 41. Print a Centered Banner
#================
print_banner() {
  local msg="$1"
  # TODO: Print $msg centered in a 60-char wide banner using '=' padding
}
print_banner "WELCOME"            # Expected: ========= WELCOME =========
print_banner "Hello, World!"      # Expected: ==== Hello, World! ====
print_banner ""                   # Expected: (just 60 '=')
print_banner "Bash Challenge"     # Expected: === Bash Challenge ===

#================
# 42. Associative Array with Compound Keys (⚠️ Not for Zsh)
#================
compound_map() {
  # TODO:
  # Use declare -A to create an associative array with keys like "user:role"
  # ⚠️ WARNING: Not supported in Zsh — Mac users must use bash
  declare -A user_roles
  # user_roles["alice:admin"]="true"
  # Hint: Loop and print user + role
}
compound_map                      # Expected: alice is admin, etc.
compound_map                      # Repeated: same output
compound_map                      # Run twice to confirm persistence
compound_map                      # Zsh warning if needed

#================
# 43. Validate Domain Name Format
#================
validate_domain() {
  local domain="$1"
  # TODO: Use regex to ensure valid FQDN (e.g. example.com)
}
validate_domain "example.com"      # Expected: valid
validate_domain "sub.domain.org"   # Expected: valid
validate_domain "not@valid"        # Expected: invalid
validate_domain ""                 # Expected: invalid

#================
# 44. Pretty Print Columns from Delimited Text
#================
print_table() {
  local file="$1"
  # TODO: Print CSV or tab-delimited data as aligned columns (hint: column -t)
}
print_table "data.csv"             # Expected: clean, aligned table
print_table "users.tsv"            # Expected: formatted table
print_table "empty.txt"            # Expected: (blank)
print_table "nofile.csv"           # Expected: error

#================
# 45. Quoting Nightmare: Safely Echo Arguments with Spaces
#================
quote_args() {
  # TODO: Print each argument on its own quoted line
}
quote_args "hello world" "bash is fun" "arg3"   # Expected: "hello world", etc.
quote_args " " ""                               # Expected: " ", ""
quote_args a b c                                # Expected: "a" "b" "c"
quote_args                                      # Expected: (no output)

#================
# 46. Print All Environment Variables Sorted
#================
print_env_sorted() {
  # TODO: Print env vars sorted by key, aligned (hint: env | sort)
}
print_env_sorted                 # Expected: alphabetical key list
print_env_sorted                 # Re-run to verify consistency
print_env_sorted                 # Output aligned nicely
print_env_sorted                 # All variables, like PATH etc.

#================
# 47. Indirect Expansion with Variable Names
#================
print_indirect() {
  local varname="$1"
  # TODO: Use indirect expansion to print the value of the named variable
}
myvar="BashPower"
print_indirect "myvar"           # Expected: BashPower
print_indirect "PATH"            # Expected: system path
print_indirect "UNSET_VAR"       # Expected: (empty or warning)
print_indirect ""                # Expected: (error)

#================
# 48. Colorize Output by Level
#================
log_color() {
  local level="$1"
  local msg="$2"
  # TODO: Print log with color based on level (INFO, WARN, ERROR)
}
log_color "INFO" "Starting process..."        # Expected: green text
log_color "WARN" "Check disk space."          # Expected: yellow text
log_color "ERROR" "Something failed!"         # Expected: red text
log_color "DEBUG" "This is hidden."           # Expected: default

#================
# 49. List and Kill Processes by Name
#================
kill_by_name() {
  local name="$1"
  # TODO: List matching processes and kill them (prompt/warning optional)
}
kill_by_name "sleep"             # Expected: kills sleep processes
kill_by_name "bash"              # ⚠️ Use with caution
kill_by_name "fakeprocess"       # Expected: no match
kill_by_name ""                  # Expected: error

#================
# 50. Run Command Timer with Summary
#================
time_command() {
  # TODO: Time how long a command takes and report duration + exit status
  local start=$(date +%s)
  "$@"
  local exit=$?
  local end=$(date +%s)
  echo "Exit: $exit | Time: $((end - start)) sec"
}
time_command sleep 2             # Expected: Exit 0, ~2 sec
time_command ls /               # Expected: Exit 0, fast
time_command false              # Expected: Exit 1
time_command ""                 # Expected: Error or usage
