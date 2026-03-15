rem @echo off

rem ============================
rem 1. Add Two Numbers
rem ============================
set /p a=Enter first number: 
set /p b=Enter second number: 
rem TODO: Calculate and display the sum of a and b
set /a sum=
echo Sum: %sum%
pause

rem ============================
rem 2. Greet the User
rem ============================
set /p name=Enter your name: 
rem TODO: Print a greeting using the user's name
echo Hello, !
pause

rem ============================
rem 3. Even or Odd
rem ============================
set /p num=Enter a number: 
rem TODO: Determine if the number is even or odd
set /a remainder=%num% %% 2
if %remainder%==0 (
    echo The number is even.
) else (
    echo The number is odd.
)
pause

rem ============================
rem 4. Create and Write to a File
rem ============================
set /p fname=Enter file name (no extension): 
set /p text=Enter text to write: 
rem TODO: Write text into the given file
> .txt echo 
echo File created.
pause

rem ============================
rem 5. Count from 1 to 10
rem ============================
rem TODO: Use a loop to print numbers 1 through 10
for %%i in () do (
    echo %%i
)
pause

rem ============================
rem 6. Password Check
rem ============================
set /p password=Enter password: 
rem TODO: Check if password is "secret123"
if ""=="" (
    echo Access granted.
) else (
    echo Access denied.
)
pause

rem ============================
rem 7. File Exists Checker
rem ============================
set /p filename=Enter a file name: 
rem TODO: Check if the file exists
if exist "" (
    echo File exists.
) else (
    echo File does not exist.
)
pause

rem ============================
rem 8. Basic Menu
rem ============================
echo Choose an option:
echo 1. Greet
echo 2. Show Date
echo 3. Exit
set /p choice=Your choice: 
rem TODO: Handle each menu option
if "%choice%"=="1" (
    echo Hello!
) else if "%choice%"=="2" (
    date /t
) else if "%choice%"=="3" (
    exit
) else (
    echo Invalid choice.
)
pause

rem ============================
rem 9. Multiply Two Numbers
rem ============================
set /p x=Enter first number: 
set /p y=Enter second number: 
rem TODO: Multiply x and y
set /a product=
echo Product: %product%
pause

rem ============================
rem 10. Rename .txt Files with _backup
rem ============================
rem TODO: Append _backup to all .txt filenames
for %%f in (*.txt) do (
    ren "%%f" "%%~nf_backup.txt"
)
echo All files renamed.
pause

rem ============================
rem 11. String Length
rem ============================
set /p str=Enter a string: 
rem TODO: Count and display the number of characters in the string
rem HINT: Use a loop to go through each character
setlocal enabledelayedexpansion
set len=0
:countloop
set char=!str:~%len%,1!
if "!char!"=="" goto done
set /a len+=1
goto countloop
:done
echo Length: %len%
endlocal
pause

rem ============================
rem 12. Nested Loop: Multiplication Table
rem ============================
rem TODO: Print a 5x5 multiplication table using nested loops
for /l %%i in (1,1,5) do (
    for /l %%j in (1,1,5) do (
        set /a prod=%%i * %%j
        call echo %%i x %%j = %%prod%%
    )
    echo ---
)
pause

rem ============================
rem 13. Reverse a String
rem ============================
set /p input=Enter a word to reverse: 
rem TODO: Reverse the string manually
setlocal enabledelayedexpansion
set reversed=
for /l %%i in (0,1,1000) do (
    set char=!input:~%%i,1!
    if "!char!"=="" goto endrev
    set reversed=!char!!reversed!
)
:endrev
echo Reversed: !reversed!
endlocal
pause

rem ============================
rem 14. Login with Retry (Goto)
rem ============================
rem TODO: Allow up to 3 attempts to enter the correct password
set attempts=0
:login
set /p pw=Enter password: 
if "%pw%"=="letmein" (
    echo Access granted.
    goto endlogin
)
set /a attempts+=1
if %attempts% GEQ 3 (
    echo Too many attempts. Access denied.
    goto endlogin
)
echo Wrong password. Try again.
goto login
:endlogin
pause

rem ============================
rem 15. Capitalize First Letter
rem ============================
set /p word=Enter a word: 
rem TODO: Capitalize the first letter of the word
setlocal enabledelayedexpansion
set first=!word:~0,1!
set rest=!word:~1!
rem Assumes input is lowercase, ASCII only
rem Simple trick to convert first letter to uppercase:
for %%a in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if /i "!first!"=="%%a" set first=%%a
)
echo Capitalized: !first!!rest!
endlocal
pause
