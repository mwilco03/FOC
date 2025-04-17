# ==========================================
# 🌟 PowerShell Scaffolding Challenges (1–40)
# Format: Clean, Testable, Functional
# ==========================================

#================
# 1. Add Two Numbers
#================
function Add-TwoNumbers {
    param($a, $b)
    # TODO: Return the sum of a and b
    return
}
Write-Output (Add-TwoNumbers 2 3)         # Expected: 5
Write-Output (Add-TwoNumbers -1 1)        # Expected: 0
Write-Output (Add-TwoNumbers 100 250)     # Expected: 350
Write-Output (Add-TwoNumbers 0 0)         # Expected: 0

#================
# 2. Greet User by Name
#================
function Greet-User {
    param($name)
    # TODO: Return "Hello, <name>!"
    return
}
Write-Output (Greet-User "Alex")          # Expected: Hello, Alex!
Write-Output (Greet-User "Taylor")        # Expected: Hello, Taylor!
Write-Output (Greet-User "Jordan")        # Expected: Hello, Jordan!
Write-Output (Greet-User "")              # Expected: Hello, !

#================
# 3. Print Numbers 1 to 5
#================
function Print-Numbers1To5 {
    # TODO: Return an array of numbers 1 to 5
    return
}
Write-Output (Print-Numbers1To5)          # Expected: 1 2 3 4 5
Write-Output (Print-Numbers1To5)          # Expected: 1 2 3 4 5
Write-Output (Print-Numbers1To5)          # Expected: 1 2 3 4 5
Write-Output (Print-Numbers1To5)          # Expected: 1 2 3 4 5

#================
# 4. Count Words in a Sentence
#================
function Count-Words {
    param($sentence)
    # TODO: Return number of words using .Split()
    return
}
Write-Output (Count-Words "PowerShell is fun")     # Expected: 3
Write-Output (Count-Words "One two three four")    # Expected: 4
Write-Output (Count-Words "Hi")                    # Expected: 1
Write-Output (Count-Words "")                      # Expected: 1

#================
# 5. Reverse a String
#================
function Reverse-String {
    param($text)
    # TODO: Return the reversed string
    return
}
Write-Output (Reverse-String "PowerShell")         # Expected: llehSrewoP
Write-Output (Reverse-String "abc")                # Expected: cba
Write-Output (Reverse-String "12345")              # Expected: 54321
Write-Output (Reverse-String "")                   # Expected: (empty)

#================
# 6. Convert to Uppercase
#================
function To-Upper {
    param($text)
    # TODO: Return string in uppercase
    return
}
Write-Output (To-Upper "hello")                    # Expected: HELLO
Write-Output (To-Upper "PowerShell")               # Expected: POWERSHELL
Write-Output (To-Upper "")                         # Expected: (empty)
Write-Output (To-Upper "123abc!")                  # Expected: 123ABC!

#================
# 7. Multiply Two Numbers
#================
function Multiply {
    param($a, $b)
    # TODO: Return a * b
    return
}
Write-Output (Multiply 2 3)                        # Expected: 6
Write-Output (Multiply -1 10)                      # Expected: -10
Write-Output (Multiply 0 99)                       # Expected: 0
Write-Output (Multiply 7 7)                        # Expected: 49

#================
# 8. Is Even
#================
function Is-Even {
    param($n)
    # TODO: Return $true if even, else $false
    return
}
Write-Output (Is-Even 2)                           # Expected: True
Write-Output (Is-Even 7)                           # Expected: False
Write-Output (Is-Even 0)                           # Expected: True
Write-Output (Is-Even -4)                          # Expected: True

#================
# 9. Repeat String
#================
function Repeat-String {
    param($text, $count)
    # TODO: Return $text repeated $count times
    return
}
Write-Output (Repeat-String "Hi" 3)                # Expected: HiHiHi
Write-Output (Repeat-String "a" 5)                 # Expected: aaaaa
Write-Output (Repeat-String "" 4)                  # Expected: (empty)
Write-Output (Repeat-String "wow" 2)               # Expected: wowwow

#================
# 10. Join Array with Commas
#================
function Join-With-Commas {
    param($array)
    # TODO: Return comma-separated string
    return
}
Write-Output (Join-With-Commas @("a", "b", "c"))   # Expected: a,b,c
Write-Output (Join-With-Commas @("one"))           # Expected: one
Write-Output (Join-With-Commas @(""))              # Expected: 
Write-Output (Join-With-Commas @("1", "2", "3"))   # Expected: 1,2,3

#================
# 11. Calculate Factorial
#================
function Get-Factorial {
    param($n)
    # TODO: Return factorial using a loop
    return
}
Write-Output (Get-Factorial 0)                     # Expected: 1
Write-Output (Get-Factorial 5)                     # Expected: 120
Write-Output (Get-Factorial 3)                     # Expected: 6
Write-Output (Get-Factorial 1)                     # Expected: 1

#================
# 12. Check Palindrome
#================
function Is-Palindrome {
    param($text)
    # TODO: Return true if $text equals its reverse
    return
}
Write-Output (Is-Palindrome "level")               # Expected: True
Write-Output (Is-Palindrome "madam")               # Expected: True
Write-Output (Is-Palindrome "hello")               # Expected: False
Write-Output (Is-Palindrome "a")                   # Expected: True

#================
# 13. Convert Celsius to Fahrenheit
#================
function Convert-CtoF {
    param($c)
    # TODO: Return (c * 9/5) + 32
    return
}
Write-Output (Convert-CtoF 0)                      # Expected: 32
Write-Output (Convert-CtoF 100)                    # Expected: 212
Write-Output (Convert-CtoF -40)                    # Expected: -40
Write-Output (Convert-CtoF 37)                     # Expected: 98.6

#================
# 14. Square Each Number in Array
#================
function Square-Each {
    param($array)
    # TODO: Return array with each number squared
    return
}
Write-Output (Square-Each @(1, 2, 3))              # Expected: 1 4 9
Write-Output (Square-Each @(0, 5, -2))             # Expected: 0 25 4
Write-Output (Square-Each @())                     # Expected: (empty)
Write-Output (Square-Each @(10))                   # Expected: 100

#================
# 15. Sum of Array
#================
function Sum-Array {
    param($array)
    # TODO: Return sum of all elements
    return
}
Write-Output (Sum-Array @(1, 2, 3))                # Expected: 6
Write-Output (Sum-Array @(10, -10, 5))             # Expected: 5
Write-Output (Sum-Array @(0, 0, 0))                # Expected: 0
Write-Output (Sum-Array @())                       # Expected: 0

#================
# 16. Get File Extension
#================
function Get-Extension {
    param($filename)
    # TODO: Return the extension of the file
    return
}
Write-Output (Get-Extension "report.pdf")          # Expected: pdf
Write-Output (Get-Extension "archive.tar.gz")      # Expected: gz
Write-Output (Get-Extension "no_extension")        # Expected: no_extension
Write-Output (Get-Extension ".hiddenfile")         # Expected: hiddenfile

#================
# 17. Count Character Occurrences
#================
function Count-Chars {
    param($text)
    # TODO: Return a hashtable of character counts
    return
}
Write-Output (Count-Chars "banana")                # Expected: b=1 a=3 n=2
Write-Output (Count-Chars "aabbcc")                # Expected: a=2 b=2 c=2
Write-Output (Count-Chars "xyz")                   # Expected: x=1 y=1 z=1
Write-Output (Count-Chars "")                      # Expected: (empty)

#================
# 18. Remove Vowels
#================
function Remove-Vowels {
    param($text)
    # TODO: Return string without vowels
    return
}
Write-Output (Remove-Vowels "PowerShell")          # Expected: PwrShll
Write-Output (Remove-Vowels "AEIOUaeiou")           # Expected: (empty)
Write-Output (Remove-Vowels "banana")              # Expected: bnn
Write-Output (Remove-Vowels "")                    # Expected: (empty)

#================
# 19. Replace Word in Sentence
#================
function Replace-Word {
    param($text, $old, $new)
    # TODO: Replace $old with $new in $text
    return
}
Write-Output (Replace-Word "I love apples" "apples" "oranges")    # Expected: I love oranges
Write-Output (Replace-Word "dog dog dog" "dog" "cat")              # Expected: cat cat cat
Write-Output (Replace-Word "nothing to replace" "x" "y")           # Expected: nothing to replace
Write-Output (Replace-Word "" "a" "b")                             # Expected: (empty)

#================
# 20. Format Date as yyyy-MM-dd
#================
function Get-TodayFormatted {
    # TODO: Return today's date as "yyyy-MM-dd"
    return
}
Write-Output (Get-TodayFormatted)  # Example: 2025-04-17
Write-Output (Get-TodayFormatted)
Write-Output (Get-TodayFormatted)
Write-Output (Get-TodayFormatted)

#================
# 21. Count Lines in File
#================
function Count-Lines {
    param($filePath)
    # TODO: Return line count using Get-Content
    return
}
Write-Output (Count-Lines "test.txt")              # Expected: (depends on file)
Write-Output (Count-Lines "empty.txt")             # Expected: 0
Write-Output (Count-Lines "multi.txt")             # Expected: (example: 4)
Write-Output (Count-Lines "nofile.txt")            # Expected: (error or 0)

#================
# 22. Base64 Encode Text
#================
function Encode-Base64 {
    param($text)
    # TODO: Return Base64 encoded version of $text
    return
}
Write-Output (Encode-Base64 "hello")               # Expected: aGVsbG8=
Write-Output (Encode-Base64 "PowerShell")          # Expected: UG93ZXJTaGVsbA==
Write-Output (Encode-Base64 "")                    # Expected: (empty)
Write-Output (Encode-Base64 "123")                 # Expected: MTIz

#================
# 23. Base64 Decode Text
#================
function Decode-Base64 {
    param($encoded)
    # TODO: Decode Base64 back to plain text
    return
}
Write-Output (Decode-Base64 "aGVsbG8=")            # Expected: hello
Write-Output (Decode-Base64 "UG93ZXJTaGVsbA==")    # Expected: PowerShell
Write-Output (Decode-Base64 "")                    # Expected: (empty)
Write-Output (Decode-Base64 "MTIz")                # Expected: 123

#================
# 24. Convert String to Char Array
#================
function To-CharArray {
    param($text)
    # TODO: Return array of characters
    return
}
Write-Output (To-CharArray "abc")                  # Expected: a b c
Write-Output (To-CharArray "")                     # Expected: (empty)
Write-Output (To-CharArray "1234")                 # Expected: 1 2 3 4
Write-Output (To-CharArray "Power")                # Expected: P o w e r

#================
# 25. Compare Two Strings (Case Insensitive)
#================
function Compare-Strings {
    param($a, $b)
    # TODO: Return true if equal ignoring case
    return
}
Write-Output (Compare-Strings "Hello" "hello")     # Expected: True
Write-Output (Compare-Strings "Test" "TEST")       # Expected: True
Write-Output (Compare-Strings "One" "Two")         # Expected: False
Write-Output (Compare-Strings "" "")               # Expected: True

#================
# 26. Remove Duplicates from Array
#================
function Remove-Duplicates {
    param($array)
    # TODO: Return array with duplicates removed
    return
}
Write-Output (Remove-Duplicates @(1, 2, 2, 3))       # Expected: 1 2 3
Write-Output (Remove-Duplicates @("a", "b", "a"))    # Expected: a b
Write-Output (Remove-Duplicates @())                # Expected: (empty)
Write-Output (Remove-Duplicates @(5, 5, 5, 5))       # Expected: 5

#================
# 27. Top 3 Most Common Words
#================
function Top3-Words {
    param($text)
    # TODO: Return top 3 most common words
    return
}
Write-Output (Top3-Words "apple banana apple orange apple banana")   # Expected: apple banana orange
Write-Output (Top3-Words "one two two three three three")            # Expected: three two one
Write-Output (Top3-Words "")                                         # Expected: (empty)
Write-Output (Top3-Words "a a b b c c d")                             # Expected: a b c

#================
# 28. Format Date as yyyy-MM-dd
#================
function Format-Date {
    param($date)
    # TODO: Return date as "yyyy-MM-dd"
    return
}
Write-Output (Format-Date (Get-Date "2025-01-01"))  # Expected: 2025-01-01
Write-Output (Format-Date (Get-Date "2000-12-31"))  # Expected: 2000-12-31
Write-Output (Format-Date (Get-Date))               # Expected: today's date
Write-Output (Format-Date "2023-04-17")             # Expected: 2023-04-17

#================
# 29. Secure Password Entry (Demo Plain)
#================
function Read-PasswordPlain {
    # TODO: Read a secure password and return plain text (for demo)
    return
}
Write-Output (Read-PasswordPlain)     # Expected: your input
Write-Output (Read-PasswordPlain)     # Expected: your input
Write-Output (Read-PasswordPlain)     # Expected: your input
Write-Output (Read-PasswordPlain)     # Expected: your input

#================
# 30. List Unique File Extensions in Directory
#================
function List-FileExtensions {
    param($path)
    # TODO: Return sorted list of unique file extensions
    return
}
Write-Output (List-FileExtensions ".")              # Example: .ps1 .txt
Write-Output (List-FileExtensions "C:\Windows")     # Depends on contents
Write-Output (List-FileExtensions "C:\EmptyDir")    # Expected: (empty)
Write-Output (List-FileExtensions $env:TEMP)        # Depends on contents

#================
# 31. Create and Access Dynamic Variables
#================
function Dynamic-Variables {
    # TODO: Create var1, var2, var3 and access var2
    return
}
Write-Output (Dynamic-Variables)                    # Expected: 20 (if var2 = 2 * 10)
Write-Output (Dynamic-Variables)                    # Expected: 20
Write-Output (Dynamic-Variables)                    # Expected: 20
Write-Output (Dynamic-Variables)                    # Expected: 20

#================
# 32. Build and Execute Command
#================
function Run-Command {
    param($cmd)
    # TODO: Run using Invoke-Expression
    return
}
Write-Output (Run-Command "Get-Date")               # Expected: current date/time
Write-Output (Run-Command "Write-Output 'Hello'")   # Expected: Hello
Write-Output (Run-Command "")                       # Expected: (nothing)
Write-Output (Run-Command "2 + 2")                  # Expected: 4

#================
# 33. Time a ScriptBlock
#================
function Time-Code {
    param([ScriptBlock]$Code)
    # TODO: Measure execution time
    return
}
Time-Code { Start-Sleep 1 }                         # Expected: ~1 second
Time-Code { Start-Sleep 2 }                         # Expected: ~2 seconds
Time-Code { }                                       # Expected: near zero
Time-Code { 1..10000 | % { $_ * 2 } }               # Expected: small delay

#================
# 34. Nested Hashtable Lookup
#================
function Get-ServerOS {
    param($servers, $name)
    # TODO: Return the OS of the given server
    return
}
$servers = @{
    Web01 = @{ IP = "10.1.1.1"; OS = "Windows" }
    DB01 = @{ IP = "10.1.1.2"; OS = "Linux" }
}
Write-Output (Get-ServerOS $servers "Web01")        # Expected: Windows
Write-Output (Get-ServerOS $servers "DB01")         # Expected: Linux
Write-Output (Get-ServerOS $servers "Unknown")      # Expected: (null)
Write-Output (Get-ServerOS @{} "X")                 # Expected: (null)

#================
# 35. Compare Two Arrays for Matches
#================
function Find-CommonItems {
    param($a, $b)
    # TODO: Return items that appear in both arrays
    return
}
Write-Output (Find-CommonItems @("a","b") @("b","c"))   # Expected: b
Write-Output (Find-CommonItems @(1,2,3) @(3,4,5))        # Expected: 3
Write-Output (Find-CommonItems @() @(1))                # Expected: (empty)
Write-Output (Find-CommonItems @("x") @("y"))           # Expected: (empty)

#================
# 36. File Size and Age Summary
#================
function File-Stats {
    param($path)
    # TODO: Return file name, size in KB, and age in days
    return
}
Write-Output (File-Stats ".")                          # Expected: list of files with size/age
Write-Output (File-Stats $env:TEMP)
Write-Output (File-Stats "C:\Windows")
Write-Output (File-Stats "InvalidPath")                # Expected: (error or empty)

#================
# 37. Read File Using .NET
#================
function Read-FileNet {
    param($file)
    # TODO: Use [System.IO.File] to read content
    return
}
Write-Output (Read-FileNet "test.txt")                 # Expected: file contents
Write-Output (Read-FileNet "empty.txt")                # Expected: (empty)
Write-Output (Read-FileNet "nofile.txt")               # Expected: error
Write-Output (Read-FileNet "")                         # Expected: error

#================
# 38. Download File
#================
function Download-File {
    param($url, $dest)
    # TODO: Use WebClient to download file
    return
}
Download-File "https://example.com/test.txt" "$env:TEMP\test.txt"
Download-File "https://google.com" "$env:TEMP\google.html"
Download-File "" "$env:TEMP\fail.txt"
Download-File "invalid-url" "C:\fail.txt"

#================
# 39. Stop Selected Services
#================
function Stop-SelectedService {
    # TODO: Use Out-GridView -PassThru to select and stop services
    return
}
Stop-SelectedService    # Expected: interactive service selector

#================
# 40. Auto-Generate Script Templates
#================
function Generate-Scripts {
    param($names)
    # TODO: Write a basic .ps1 template for each name
    return
}
Generate-Scripts @("init", "cleanup", "deploy")        # Expected: init.ps1 etc.
Generate-Scripts @("test")                             # Expected: test.ps1
Generate-Scripts @()                                   # Expected: (nothing)
Generate-Scripts @("script1", "script2")               # Expected: 2 files
#================
# 41. Use Splatting to Call Get-Process
#================
function Get-ProcessesSplat {
    param($name, $count)
    # TODO: Use splatting to call Get-Process with Name and -First $count
    return
}
Write-Output (Get-ProcessesSplat "powershell" 1)    # Expected: 1 PowerShell process (if running)
Write-Output (Get-ProcessesSplat "explorer" 2)      # Expected: Up to 2 Explorer processes
Write-Output (Get-ProcessesSplat "" 5)              # Expected: Error or empty
Write-Output (Get-ProcessesSplat "notepad" 0)       # Expected: Empty

#================
# 42. Create Custom Object for File Info
#================
function Get-FileSummary {
    param($path)
    # TODO: Return [PSCustomObject] with Name, SizeKB, Extension
    return
}
Write-Output (Get-FileSummary "C:\Windows\notepad.exe")  # Expected: Object with name/size/ext
Write-Output (Get-FileSummary ".\script.ps1")            # Depends on file
Write-Output (Get-FileSummary "nofile.txt")              # Expected: Error or null
Write-Output (Get-FileSummary "")                        # Expected: Error

#================
# 43. Filter Files by Modified Date Range
#================
function Get-RecentFiles {
    param($path, $days)
    # TODO: Return files modified in last $days
    return
}
Write-Output (Get-RecentFiles "." 7)                     # Expected: Files from last week
Write-Output (Get-RecentFiles $env:TEMP 1)               # Expected: Recent temp files
Write-Output (Get-RecentFiles "C:\Windows" 0)            # Expected: Modified today
Write-Output (Get-RecentFiles "." -1)                    # Expected: Empty

#================
# 44. Safe Division with Try/Catch
#================
function Divide-Safely {
    param($a, $b)
    # TODO: Return result or "Division by zero" if $b is 0
    return
}
Write-Output (Divide-Safely 10 2)                        # Expected: 5
Write-Output (Divide-Safely 10 0)                        # Expected: Division by zero
Write-Output (Divide-Safely -15 3)                       # Expected: -5
Write-Output (Divide-Safely 0 1)                         # Expected: 0

#================
# 45. Invoke ScriptBlock with Parameters
#================
function Run-Logic {
    param([ScriptBlock]$code, $x, $y)
    # TODO: Invoke scriptblock with parameters
    return
}
Write-Output (Run-Logic { param($a,$b) $a + $b } 5 10)   # Expected: 15
Write-Output (Run-Logic { param($a,$b) $a * $b } 2 3)    # Expected: 6
Write-Output (Run-Logic { param($a,$b) "$a:$b" } "x" "y") # Expected: x:y
Write-Output (Run-Logic { param($a,$b) $a - $b } 9 4)    # Expected: 5

#================
# 46. Count File Types in Folder
#================
function Count-FileExtensions {
    param($path)
    # TODO: Return hashtable with file extensions and counts
    return
}
Write-Output (Count-FileExtensions ".")                 # Expected: e.g., .ps1=3, .txt=5
Write-Output (Count-FileExtensions "C:\Windows")        # Depends on contents
Write-Output (Count-FileExtensions $env:TEMP)           # Depends on temp files
Write-Output (Count-FileExtensions "C:\Invalid")        # Expected: Error or null

#================
# 47. Get Running Processes Over Memory Limit
#================
function Get-HighMemoryProcs {
    param($limitMB)
    # TODO: Return processes using more than $limitMB memory
    return
}
Write-Output (Get-HighMemoryProcs 100)                  # Expected: Processes >100MB
Write-Output (Get-HighMemoryProcs 500)                  # Expected: Fewer matches
Write-Output (Get-HighMemoryProcs 0)                    # Expected: All processes
Write-Output (Get-HighMemoryProcs 999999)               # Expected: Empty

#================
# 48. Get Registry Value (HKCU)
#================
function Get-RegistryValue {
    param($path, $name)
    # TODO: Read registry value from HKCU:\$path\$name
    return
}
Write-Output (Get-RegistryValue "Environment" "TEMP")   # Expected: Path to TEMP
Write-Output (Get-RegistryValue "Console" "ColorTable00") # Expected: Color value
Write-Output (Get-RegistryValue "Bogus" "Nothing")      # Expected: Error or null
Write-Output (Get-RegistryValue "" "")                  # Expected: Error

#================
# 49. Validate JSON String
#================
function Validate-JSON {
    param($json)
    # TODO: Return $true if valid JSON, $false otherwise
    return
}
Write-Output (Validate-JSON '{"name":"Test"}')          # Expected: True
Write-Output (Validate-JSON '{"a":1,"b":2}')             # Expected: True
Write-Output (Validate-JSON '{bad json}')               # Expected: False
Write-Output (Validate-JSON "")                         # Expected: False

#================
# 50. Convert CSV to Objects with Filtering
#================
function Import-CSVFiltered {
    param($path, $column, $value)
    # TODO: Import CSV, return rows where $column -eq $value
    return
}
Write-Output (Import-CSVFiltered "data.csv" "Status" "Active")  # Expected: Matching rows
Write-Output (Import-CSVFiltered "users.csv" "Role" "Admin")    # Depends on file
Write-Output (Import-CSVFiltered "none.csv" "Any" "X")          # Expected: (empty or error)
Write-Output (Import-CSVFiltered "data.csv" "" "")              # Expected: Error or all

#================
# 51. Parse JSON Text with ConvertFrom-Json
#================
function Parse-Json {
    param($json)
    # TODO: 
    # Use ConvertFrom-Json to turn JSON text into a PowerShell object
    # Hint: You can also use Invoke-RestMethod to fetch live JSON
    # Try with: https://microsoftedge.github.io/Demos/json-dummy-data/people.json
    return
}
Write-Output (Parse-Json '{"name":"Alice","age":30}').name     # Expected: Alice
Write-Output (Parse-Json '{"name":"Bob","city":"NYC"}').city   # Expected: NYC
Write-Output (Parse-Json '{}')                                 # Expected: empty object
Write-Output (Parse-Json '[{"x":1},{"x":2}]').Count            # Expected: 2

#================
# 52. Parse CSV Text with ConvertFrom-Csv
#================
function Parse-Csv {
    param($csvText)
    # TODO: 
    # Use ConvertFrom-Csv to convert CSV text into PowerShell objects
    # Hint: Try downloading real CSV with Invoke-WebRequest or Invoke-RestMethod
    # Use: https://raw.githubusercontent.com/datablist/sample-csv-files/main/files/people/people-100.csv
    return
}
$csv1 = "Name,Age`nAlice,30`nBob,25"
$csv2 = "Product,Price`nPen,1.2`nNotebook,3.5"
$csv3 = "Item,Qty`nA,1"
$csv4 = "InvalidHeader"

Write-Output (Parse-Csv $csv1)[0].Name        # Expected: Alice
Write-Output (Parse-Csv $csv2)[1].Price       # Expected: 3.5
Write-Output (Parse-Csv $csv3).Count          # Expected: 1
Write-Output (Parse-Csv $csv4)                # Expected: Error or empty

#================
# 53. Parse INI-Style Text with ConvertFrom-StringData
#================
function Parse-StringData {
    param($text)
    # TODO: Use ConvertFrom-StringData to convert key-value lines
    return
}
$data1 = @"
key1=value1
key2=value2
"@
$data2 = "name=Server01`nip=192.168.1.100"
$data3 = "a=1`nb=2`nc=3"
$data4 = ""

Write-Output (Parse-StringData $data1).key1    # Expected: value1
Write-Output (Parse-StringData $data2).ip      # Expected: 192.168.1.100
Write-Output (Parse-StringData $data3).c       # Expected: 3
Write-Output (Parse-StringData $data4)         # Expected: (empty)

#================
# 54. Convert Object to JSON (Use With Caution!)
#================
function Object-ToJson {
    param($object)
    # ⚠️ WARNING: ConvertTo-Json flattens nested objects after depth 2 by default!
    # TODO: Convert $object to JSON. Use -Depth 10 if needed.
    return
}
$person = [PSCustomObject]@{ Name = "Alice"; Details = @{ Age = 30; City = "LA" } }
$server = [PSCustomObject]@{ Name = "Web01"; Status = "Online" }
$simple = [PSCustomObject]@{ A = 1; B = 2 }
$list   = 1, 2, 3

Write-Output (Object-ToJson $person)         # Expected: Proper JSON with nested values
Write-Output (Object-ToJson $server)         # Expected: {"Name":"Web01","Status":"Online"}
Write-Output (Object-ToJson $simple)         # Expected: {"A":1,"B":2}
Write-Output (Object-ToJson $list)           # Expected: [1,2,3]

#================
# 55. Convert Downloaded JSON File to PSObject List
#================
function Import-JsonFile {
    param($filePath)
    # TODO: Read a JSON file, convert to object, and return count of top-level entries
    return
}
Write-Output (Import-JsonFile "$env:TEMP\people.json")     # Expected: Count or .Length
Write-Output (Import-JsonFile "$env:TEMP\employees.json")  # Depends on file
Write-Output (Import-JsonFile "nofile.json")               # Expected: error or null
Write-Output (Import-JsonFile "")                          # Expected: error
