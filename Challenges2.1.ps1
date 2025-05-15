# PowerShell Administrative Challenges
# Ordered: Trivial → Advanced
# (Drivers & BCDedit skipped; new sections injected)

#===================================
# Scripting Basics
#===================================

# 1. Greet User
# Objective: Return a greeting for a given name.
# Expected: Greet-User -Name "Alice" ➜ "Hello, Alice!"
# Helper: Research string interpolation in PowerShell.
function Greet-User {
    param([string]$Name)
    # TODO: Implement greeting logic
    return
}
Write-Output (Greet-User -Name "Alice")  # Expected: Hello, Alice!

# 2. Add Two Numbers
# Objective: Return the sum of two integers.
# Expected: Add-Numbers -A 5 -B 7 ➜ 12
# Helper: Review arithmetic operators (+).
function Add-Numbers {
    param([int]$A, [int]$B)
    # TODO: Return sum of $A and $B
    return
}
Write-Output (Add-Numbers -A 5 -B 7)    # Expected: 12

# 3. Convert to Uppercase
# Objective: Convert a string to all uppercase.
# Expected: To-Upper "hello" ➜ HELLO
# Helper: Research .ToUpper() string method.
function To-Upper {
    param([string]$Text)
    # TODO: Return $Text in uppercase
    return
}
Write-Output (To-Upper "hello")        # Expected: HELLO

# 4. Format Date
# Objective: Format a DateTime as YYYY-MM-DD.
# Expected: Format-Date -Date (Get-Date "2020-01-01") ➜ 2020-01-01
# Helper: Research Get-Date -Format.
function Format-Date {
    param([datetime]$Date)
    # TODO: Format $Date as "yyyy-MM-dd"
    return
}
Write-Output (Format-Date -Date (Get-Date "2020-01-01"))  # Expected: 2020-01-01

# 5. Get Month Name
# Objective: Map month number to month name.
# Expected: Get-MonthName -Month 1 ➜ January
# Helper: Use switch or array mapping.
function Get-MonthName {
    param([int]$Month)
    # TODO: Return month name for $Month
    return
}
Write-Output (Get-MonthName -Month 1)   # Expected: January

# 6. Calculate Average
# Objective: Compute average of a numeric array.
# Expected: Get-Average -Numbers @(2,3,5) ➜ 3.333333
# Helper: Sum array and divide by count.
function Get-Average {
    param([int[]]$Numbers)
    # TODO: Return (sum of $Numbers)/(count of $Numbers)
    return
}
Write-Output (Get-Average -Numbers @(2,3,5))  # Expected: 3.333333

# 7. Check Substring
# Objective: Test if $Substring is in $String.
# Expected: Test-Substring -String "PowerShell" -Substring "Shell" ➜ True
# Helper: Research .Contains() or -like.
function Test-Substring {
    param([string]$String, [string]$Substring)
    # TODO: Return $true if $Substring in $String
    return
}
Write-Output (Test-Substring -String "PowerShell" -Substring "Shell")  # Expected: True

# 8. Find Maximum
# Objective: Return the larger of two numbers.
# Expected: Find-Maximum -X 3 -Y 10 ➜ 10
# Helper: Use if/else.
function Find-Maximum {
    param([int]$X, [int]$Y)
    # TODO: Return max($X, $Y)
    return
}
Write-Output (Find-Maximum -X 3 -Y 10)  # Expected: 10

# 9. Check Even Number
# Objective: Return True if number is even.
# Expected: Is-Even -Number 4 ➜ True
# Helper: Use modulus (%) operator.
function Is-Even {
    param([int]$Number)
    # TODO: Return $true if $Number % 2 -eq 0
    return
}
Write-Output (Is-Even -Number 4)  # Expected: True

#10. Generate Range
# Objective: Output numbers 1 through N.
# Expected: Generate-Range -N 3 ➜ 1 2 3
# Helper: Use 1..$N or a loop.
function Generate-Range {
    param([int]$N)
    # TODO: Generate 1..$N sequence
    return
}
Write-Output (Generate-Range -N 3)  # Expected: 1 2 3

#11. While Loop Timer
# Objective: Count down from $Seconds to 0.
# Expected: Countdown-Timer -Seconds 3 ➜ 3 2 1 0
# Helper: Research while loops.
function Countdown-Timer {
    param([int]$Seconds)
    # TODO: Loop and output countdown
    return
}
Write-Output (Countdown-Timer -Seconds 3)  

#12. ForEach Loop Over Files
# Objective: List file names in a folder using loop.
# Expected: List-FileNames -Path "C:\Temp" ➜ file1.txt, file2.log
# Helper: foreach over Get-ChildItem.
function List-FileNames {
    param([string]$Path)
    # TODO: Loop files and return names
    return
}
Write-Output (List-FileNames -Path "C:\Temp")  

#13. Square Function
# Objective: Return square of a number.
# Expected: Square -N 4 ➜ 16
# Helper: Multiply $N by itself.
function Square {
    param([int]$N)
    # TODO: Return $N * $N
    return
}
Write-Output (Square -N 4)  # Expected: 16

#14. Switch Statement
# Objective: Map status codes to messages.
# Expected: Get-StatusMessage -Code 404 ➜ Not Found
# Helper: Use switch.
function Get-StatusMessage {
    param([int]$Code)
    # TODO: Switch for 200,404,500 else Unknown
    return
}
Write-Output (Get-StatusMessage -Code 404)  # Expected: Not Found

#===================================
# File System Tasks
#===================================

#15. Get Current Working Directory
# Objective: Return current directory path.
# Expected: Get-WorkingDirectory ➜ C:\Users\Username
# Helper: Research Get-Location.
function Get-WorkingDirectory {
    param()
    # TODO: Return Get-Location
    return
}
Write-Output (Get-WorkingDirectory)     # Expected: C:\Users\Username

#16. Change Directory
# Objective: Set the current location.
# Expected: Change-Directory -Path "C:\Windows" ➜ C:\Windows
# Helper: Research Set-Location.
function Change-Directory {
    param([string]$Path)
    # TODO: Change directory using Set-Location
    return
}
Write-Output (Change-Directory -Path "C:\Windows")  # Expected: Now in C:\Windows

#17. List Files in Directory
# Objective: List file names in a folder.
# Expected: List-Files -Path "C:\Windows" ➜ explorer.exe, notepad.exe
# Helper: Research Get-ChildItem.
function List-Files {
    param([string]$Path)
    # TODO: Return file names via Get-ChildItem
    return
}
Write-Output (List-Files -Path "C:\Windows")  # Expected: explorer.exe, notepad.exe

#18. List Files Recursively
# Objective: List all files under a folder tree.
# Expected: Get-FilesRecursive -Path "." ➜ ./sub\a.txt
# Helper: Use Get-ChildItem -Recurse.
function Get-FilesRecursive {
    param([string]$Path)
    # TODO: Use -Recurse to list all files
    return
}
Write-Output (Get-FilesRecursive -Path ".")  # Expected: nested file paths

#19. Get File Size
# Objective: Return file size in bytes.
# Expected: Get-FileSize -Path ".\file.txt" ➜ 1024
# Helper: (Get-Item).Length.
function Get-FileSize {
    param([string]$Path)
    # TODO: Return (Get-Item $Path).Length
    return
}
Write-Output (Get-FileSize -Path ".\file.txt")  # Expected: 1024

#20. Create New File
# Objective: Create an empty file.
# Expected: New-File -Path ".\test.txt" ➜ True
# Helper: New-Item -ItemType File.
function New-File {
    param([string]$Path)
    # TODO: Create file if not exists
    return
}
Write-Output (New-File -Path ".\test.txt")  # Expected: True

#21. Delete File
# Objective: Remove a file if it exists.
# Expected: Remove-File -Path ".\test.txt" ➜ True
# Helper: Test-Path + Remove-Item.
function Remove-File {
    param([string]$Path)
    # TODO: Delete file if exists
    return
}
Write-Output (Remove-File -Path ".\test.txt")  # Expected: True

#22. Copy Files by Extension
# Objective: Copy all .txt files between folders.
# Expected: Copy-FilesByExtension -SourceDir ".\src" -DestinationDir ".\dest" -Extension ".txt" ➜ count
# Helper: Get-ChildItem -Filter + Copy-Item.
function Copy-FilesByExtension {
    param([string]$SourceDir, [string]$DestinationDir, [string]$Extension)
    # TODO: Copy matching files and return count
    return
}
Write-Output (Copy-FilesByExtension -SourceDir ".\src" -DestinationDir ".\dest" -Extension ".txt")  # Expected: 2

#23. Find Text in File
# Objective: Return lines containing text in a file.
# Expected: Find-TextInFile -Path ".\sample.txt" -Text "hello" ➜ matching lines
# Helper: Select-String.
function Find-TextInFile {
    param([string]$Path, [string]$Text)
    # TODO: Return lines matching $Text
    return
}
Write-Output (Find-TextInFile -Path ".\sample.txt" -Text "hello")  # Expected: hello world

#24. List Recent Files
# Objective: List files modified in last N days.
# Expected: Get-RecentFiles -Path "." -Days 7 ➜ recent files
# Helper: LastWriteTime comparison.
function Get-RecentFiles {
    param([string]$Path, [int]$Days)
    # TODO: Filter by LastWriteTime
    return
}
Write-Output (Get-RecentFiles -Path "." -Days 7)  # Expected: recent1.txt

#25. Read File Content
# Objective: Return entire file content.
# Expected: Get-FileContent -Path ".\sample.txt" ➜ file lines
# Helper: Get-Content.
function Get-FileContent {
    param([string]$Path)
    # TODO: Return file content
    return
}
Write-Output (Get-FileContent -Path ".\sample.txt")  # Expected: all lines

#26. Write File Content
# Objective: Overwrite file with provided text.
# Expected: Set-FileContent -Path ".\out.txt" -Content "Hello" ➜ True
# Helper: Set-Content.
function Set-FileContent {
    param([string]$Path, [string]$Content)
    # TODO: Write $Content to file
    return
}
Write-Output (Set-FileContent -Path ".\out.txt" -Content "Hello")  # Expected: True

#===================================
# Environment Variables & Streams
#===================================

#27. Get Environment Variable
# Objective: Return the value of an environment variable.
# Expected: Get-EnvVar -Name "PATH" ➜ "C:\Windows\System32;..."
# Helper: Use Get-ChildItem Env: or [Environment]::GetEnvironmentVariable().
function Get-EnvVar {
    param([string]$Name)
    # TODO: Return environment variable value
    return
}
Write-Output (Get-EnvVar -Name "PATH")  # Expected: PATH value

#28. Set Environment Variable
# Objective: Set a new environment variable for current session.
# Expected: Set-EnvVar -Name "FOO" -Value "Bar" ➜ $env:FOO="Bar"
# Helper: $env:Name = "Value" or SetEnvironmentVariable().
function Set-EnvVar {
    param([string]$Name, [string]$Value)
    # TODO: Set environment variable
    return
}
Write-Output (Set-EnvVar -Name "FOO" -Value "Bar")  # Expected: True

#29. Remove Environment Variable
# Objective: Remove an environment variable from current session.
# Expected: Remove-EnvVar -Name "FOO" ➜ $env:FOO removed
# Helper: Remove-Item Env:Name.
function Remove-EnvVar {
    param([string]$Name)
    # TODO: Remove environment variable
    return
}
Write-Output (Remove-EnvVar -Name "FOO")  # Expected: True

#30. Redirect Output Example
# Objective: Demonstrate output redirection to a file.
# Expected: Redirect-Output -Command "Get-Date" -FilePath ".\date.txt" ➜ date.txt contains date
# Helper: Use > and >> operators.
function Redirect-Output {
    param([string]$Command, [string]$FilePath)
    # TODO: Run $Command and redirect output to $FilePath
    return
}
Write-Output (Redirect-Output -Command "Get-Date" -FilePath ".\date.txt")  # Expected: True

#31. Pipeline Example
# Objective: Pipe command output into a filter.
# Expected: Pipeline-Example -Command "Get-ChildItem . -Recurse" -Filter "ps1" ➜ list .ps1 files
# Helper: Use | Where-Object.
function Pipeline-Example {
    param([string]$Command, [string]$Filter)
    # TODO: Invoke $Command and filter results by extension $Filter
    return
}
Write-Output (Pipeline-Example -Command "Get-ChildItem . -Recurse" -Filter "ps1")  # Expected: .ps1 files

#===================================
# Help & Discovery
#===================================

#32. Show Command Help
# Objective: Display help for a cmdlet or executable.
# Expected: Show-Help -Name "Copy-Item" ➜ help text
# Helper: Use Get-Help or /?.
function Show-Help {
    param([string]$Name)
    # TODO: Invoke help for $Name
    return
}
Write-Output (Show-Help -Name "Copy-Item")  # Expected: help info

#33. Get All Commands
# Objective: List all available commands.
# Expected: Get-Commands ➜ all cmdlets, functions, aliases
# Helper: Use Get-Command.
function Get-Commands {
    param()
    # TODO: Return Get-Command
    return
}
Write-Output (Get-Commands)  # Expected: command list

#34. Show Parameter Info
# Objective: Show detailed parameter info for a cmdlet.
# Expected: Show-Params -Name "Get-ChildItem" ➜ parameter descriptions
# Helper: Get-Help -Parameter.
function Show-Params {
    param([string]$Name)
    # TODO: Invoke Get-Help -Parameter for $Name
    return
}
Write-Output (Show-Params -Name "Get-ChildItem")  # Expected: parameter info

#===================================
# File Attributes & Permissions
#===================================

#35. Set Read-Only Attribute
# Objective: Mark a file as read-only.
# Expected: Set-FileAttributeReadOnly -Path ".\file.txt" ➜ file is read-only
# Helper: Use attrib +r.
function Set-FileAttributeReadOnly {
    param([string]$Path)
    # TODO: Set file attribute to ReadOnly
    return
}
Write-Output (Set-FileAttributeReadOnly -Path ".\file.txt")  # Expected: True

#36. Remove Hidden Attribute
# Objective: Unh hide a file.
# Expected: Remove-FileAttributeHidden -Path ".\secret.txt" ➜ file unhidden
# Helper: Use attrib -h.
function Remove-FileAttributeHidden {
    param([string]$Path)
    # TODO: Remove Hidden attribute
    return
}
Write-Output (Remove-FileAttributeHidden -Path ".\secret.txt")  # Expected: True

#37. Take Ownership
# Objective: Grant current user ownership of a file.
# Expected: Take-Ownership -Path ".\file.txt" ➜ ownership assigned
# Helper: Use takeown /f.
function Take-Ownership {
    param([string]$Path)
    # TODO: Invoke takeown for $Path
    return
}
Write-Output (Take-Ownership -Path ".\file.txt")  # Expected: True

#38. Modify ACL (icacls)
# Objective: Grant Read permission to a user.
# Expected: Set-FileAcl -Path ".\file.txt" -User "User" -Permission "R" ➜ permission set
# Helper: Use icacls.
function Set-FileAcl {
    param([string]$Path, [string]$User, [string]$Permission)
    # TODO: Invoke icacls to set ACL
    return
}
Write-Output (Set-FileAcl -Path ".\file.txt" -User "User" -Permission "R")  # Expected: True

#===================================
# System Information
#===================================

#39. Get System Info
# Objective: Retrieve a summary of system information.
# Expected: Get-SystemInfo ➜ system summary text
# Helper: Use systeminfo.
function Get-SystemInfo {
    param()
    # TODO: Invoke systeminfo and return output
    return
}
Write-Output (Get-SystemInfo)  # Expected: OS, RAM, BIOS info

#===================================
# Processes & Services
#===================================

#40. List All Running Processes
#===================================
# Objective: Return names of all running processes.
# Expected: Get-RunningProcesses ➜ "explorer", "svchost", etc.
# Helper: Use Get-Process.
function Get-RunningProcesses {
    param()
    # TODO: Return all process names
    return
}
Write-Output (Get-RunningProcesses)  # Expected: process list

#41. Check If a Process is Running
#===================================
# Objective: Return True if a process exists.
# Expected: Is-ProcessRunning -Name "notepad" ➜ True/False
# Helper: Get-Process -Name.
function Is-ProcessRunning {
    param([string]$Name)
    # TODO: Return $true if process exists
    return
}
Write-Output (Is-ProcessRunning -Name "notepad")  # Expected: True/False

#42. Kill a Process by Name
#===================================
# Objective: Terminate all instances of a process.
# Expected: Kill-Process -Name "notepad" ➜ closes Notepad
# Helper: Stop-Process -Name.
function Kill-Process {
    param([string]$Name)
    # TODO: Stop all processes matching $Name
    return
}
Write-Output (Kill-Process -Name "notepad")  # Expected: True

#43. List All Services and Their States
#===================================
# Objective: Return each service and its status.
# Expected: Get-AllServices ➜ "Spooler: Running", ...
# Helper: Use Get-Service.
function Get-AllServices {
    param()
    # TODO: Return service Name and Status
    return
}
Write-Output (Get-AllServices)  # Expected: service list

#44. Start a Windows Service
#===================================
# Objective: Start a service if stopped.
# Expected: Start-ServiceByName -Name "Spooler" ➜ True
# Helper: Start-Service.
function Start-ServiceByName {
    param([string]$Name)
    # TODO: Start the specified service
    return
}
Write-Output (Start-ServiceByName -Name "Spooler")  # Expected: True

#45. Stop a Windows Service
#===================================
# Objective: Stop a service if running.
# Expected: Stop-ServiceByName -Name "Spooler" ➜ True
# Helper: Stop-Service.
function Stop-ServiceByName {
    param([string]$Name)
    # TODO: Stop the specified service
    return
}
Write-Output (Stop-ServiceByName -Name "Spooler")  # Expected: True

#46. Restart a Windows Service
#===================================
# Objective: Restart a service (stop then start).
# Expected: Restart-ServiceByName -Name "wuauserv" ➜ True
# Helper: Restart-Service.
function Restart-ServiceByName {
    param([string]$Name)
    # TODO: Restart the specified service
    return
}
Write-Output (Restart-ServiceByName -Name "wuauserv")  # Expected: True

#47. Get Services by Startup Type
#===================================
# Objective: List services by StartMode (Auto/Manual/Disabled).
# Expected: Get-ServicesByStartupType -Type "Automatic" ➜ list
# Helper: Get-CimInstance Win32_Service.
function Get-ServicesByStartupType {
    param([string]$Type)
    # TODO: Filter services by StartMode
    return
}
Write-Output (Get-ServicesByStartupType -Type "Automatic")  # Expected: service names

#48. Find Service by Name
#===================================
# Objective: Search services with names matching a string.
# Expected: Find-Service -Name "Print" ➜ Print Spooler
# Helper: Get-Service -DisplayName.
function Find-Service {
    param([string]$Name)
    # TODO: Filter services by name/display name
    return
}
Write-Output (Find-Service -Name "Print")  # Expected: Print Spooler

#===================================
# Scheduled Tasks
#===================================

#49. Schedule a Script Task
#===================================
# Objective: Create a scheduled task to run a script hourly.
# Expected: Schedule-Script -TaskName "HourlyTest" -ScriptPath "C:\Scripts\Test.ps1" ➜ True
# Helper: Register-ScheduledTask.
function Schedule-Script {
    param([string]$TaskName, [string]$ScriptPath)
    # TODO: Register a scheduled task
    return
}
Write-Output (Schedule-Script -TaskName "HourlyTest" -ScriptPath "C:\Scripts\Test.ps1")  # Expected: True

#50. List All Scheduled Tasks
#===================================
# Objective: List scheduled tasks and statuses.
# Expected: List-ScheduledTasks ➜ task list
# Helper: Get-ScheduledTask.
function List-ScheduledTasks {
    param()
    # TODO: Return scheduled tasks
    return
}
Write-Output (List-ScheduledTasks)  # Expected: task list

#51. Run Scheduled Task Now
#===================================
# Objective: Trigger a scheduled task immediately.
# Expected: Run-TaskNow -TaskName "HourlyTest" ➜ True
# Helper: Start-ScheduledTask.
function Run-TaskNow {
    param([string]$TaskName)
    # TODO: Start scheduled task
    return
}
Write-Output (Run-TaskNow -TaskName "HourlyTest")  # Expected: True

#52. Disable a Scheduled Task
#===================================
# Objective: Disable a scheduled task.
# Expected: Disable-ScheduledTask -TaskName "HourlyTest" ➜ True
# Helper: Disable-ScheduledTask.
function Disable-ScheduledTask {
    param([string]$TaskName)
    # TODO: Disable task
    return
}
Write-Output (Disable-ScheduledTask -TaskName "HourlyTest")  # Expected: True

#53. Delete a Scheduled Task
#===================================
# Objective: Remove a scheduled task permanently.
# Expected: Delete-ScheduledTask -TaskName "HourlyTest" ➜ True
# Helper: Unregister-ScheduledTask.
function Delete-ScheduledTask {
    param([string]$TaskName)
    # TODO: Unregister scheduled task
    return
}
Write-Output (Delete-ScheduledTask -TaskName "HourlyTest")  # Expected: True

#===================================
# User & Group Management
#===================================

#54. Create Local User
#===================================
# Objective: Add a new local user with a password.
# Expected: Add-LocalUser -Name "Bob" -Password "P@ssw0rd" ➜ True
# Helper: New-LocalUser.
function Add-LocalUser {
    param([string]$Name, [string]$Password)
    # TODO: Create local user
    return
}
Write-Output (Add-LocalUser -Name "Bob" -Password "P@ssw0rd")  # Expected: True

#55. Remove Local User
#===================================
# Objective: Delete a local user account.
# Expected: Remove-LocalUser -Name "Bob" ➜ True
# Helper: Remove-LocalUser.
function Remove-LocalUser {
    param([string]$Name)
    # TODO: Remove local user
    return
}
Write-Output (Remove-LocalUser -Name "Bob")  # Expected: True

#56. Add User to Group
#===================================
# Objective: Add a user to a local group.
# Expected: Add-LocalGroupMember -Group "Administrators" -Member "Bob" ➜ True
# Helper: Add-LocalGroupMember.
function Add-LocalGroupMember {
    param([string]$Group, [string]$Member)
    # TODO: Add user to group
    return
}
Write-Output (Add-LocalGroupMember -Group "Administrators" -Member "Bob")  # Expected: True

#57. Remove User from Group
#===================================
# Objective: Remove a user from a local group.
# Expected: Remove-LocalGroupMember -Group "Administrators" -Member "Bob" ➜ True
# Helper: Remove-LocalGroupMember.
function Remove-LocalGroupMember {
    param([string]$Group, [string]$Member)
    # TODO: Remove user from group
    return
}
Write-Output (Remove-LocalGroupMember -Group "Administrators" -Member "Bob")  # Expected: True

#===================================
# Networking Tools
#===================================

#58. Get Local IP Address
#===================================
# Objective: Return the primary IPv4 address.
# Expected: Get-IP ➜ 192.168.1.10
# Helper: Get-NetIPAddress.
function Get-IP {
    param()
    # TODO: Return IPv4 address
    return
}
Write-Output (Get-IP)  # Expected: 192.168.1.10

#59. Release and Renew IP Address
#===================================
# Objective: Release and renew DHCP lease.
# Expected: Refresh-IP ➜ new IP assigned
# Helper: ipconfig /release; ipconfig /renew or Invoke-NetAdapter.
function Refresh-IP {
    param()
    # TODO: Release and renew DHCP
    return
}
Write-Output (Refresh-IP)  # Expected: New IP

#60. Ping a Remote Host
#===================================
# Objective: Test connectivity via ping.
# Expected: Test-Connectivity -Host "8.8.8.8" ➜ True/False
# Helper: Test-Connection -Quiet.
function Test-Connectivity {
    param([string]$Host)
    # TODO: Ping and return result
    return
}
Write-Output (Test-Connectivity -Host "8.8.8.8")  # Expected: True

#61. Run Traceroute to Host
#===================================
# Objective: Trace route to a target.
# Expected: Trace-Host -Target "google.com" ➜ hop list
# Helper: tracert.
function Trace-Host {
    param([string]$Target)
    # TODO: Invoke tracert
    return
}
Write-Output (Trace-Host -Target "google.com")  # Expected: hop list

#62. Show All Network Interfaces
#===================================
# Objective: List adapters, status, IPs.
# Expected: Get-NetworkInterfaces ➜ adapter info
# Helper: Get-NetAdapter; Get-NetIPAddress.
function Get-NetworkInterfaces {
    param()
    # TODO: Return adapter details
    return
}
Write-Output (Get-NetworkInterfaces)  # Expected: interface list

#63. Display TCP Listening Ports
#===================================
# Objective: List listening TCP ports.
# Expected: Get-TCPListeners ➜ port/process.
# Helper: Get-NetTCPConnection -State Listen.
function Get-TCPListeners {
    param()
    # TODO: List listening ports
    return
}
Write-Output (Get-TCPListeners)  # Expected: port list

#64. Check If Port is Listening
#===================================
# Objective: Return True if a port is listening.
# Expected: Is-PortListening -Port 80 ➜ True/False
# Helper: Get-NetTCPConnection.
function Is-PortListening {
    param([int]$Port)
    # TODO: Return listening state
    return
}
Write-Output (Is-PortListening -Port 80)  # Expected: True

#65. List Active Network Connections
#===================================
# Objective: Show active TCP/UDP connections.
# Expected: Get-NetworkConnections ➜ connection list
# Helper: Get-NetTCPConnection.
function Get-NetworkConnections {
    param()
    # TODO: Return active connections
    return
}
Write-Output (Get-NetworkConnections)  # Expected: connection list

#===================================
# Registry Editing
#===================================

#66. Read a Registry Value
#===================================
# Objective: Retrieve a registry entry.
# Expected: Get-RegistryValue -Path "HKLM:\...\CurrentVersion" -Name "ProgramFilesDir" ➜ "C:\Program Files"
# Helper: Get-ItemProperty.
function Get-RegistryValue {
    param([string]$Path, [string]$Name)
    # TODO: Return registry value
    return
}
Write-Output (Get-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "ProgramFilesDir")

#67. Set a Registry Value
#===================================
# Objective: Create or update a registry entry.
# Expected: Set-RegistryValue -Path "HKCU:\Software\MyKey" -Name "Mode" -Value "On" ➜ True
# Helper: Set-ItemProperty.
function Set-RegistryValue {
    param([string]$Path, [string]$Name, [object]$Value)
    # TODO: Set registry value
    return
}
Write-Output (Set-RegistryValue -Path "HKCU:\Software\MyKey" -Name "Mode" -Value "On")

#68. Remove a Registry Value
#===================================
# Objective: Delete a registry entry.
# Expected: Remove-RegistryValue -Path "HKCU:\Software\MyKey" -Name "Mode" ➜ True
# Helper: Remove-ItemProperty.
function Remove-RegistryValue {
    param([string]$Path, [string]$Name)
    # TODO: Remove registry value
    return
}
Write-Output (Remove-RegistryValue -Path "HKCU:\Software\MyKey" -Name "Mode")

#69. Check If RDP is Enabled
#===================================
# Objective: Return True if fDenyTSConnections = 0.
# Expected: Is-RDPEnabled ➜ True/False
# Helper: Query Term Server registry key.
function Is-RDPEnabled {
    param()
    # TODO: Return $true if RDP enabled
    return
}
Write-Output (Is-RDPEnabled)  # Expected: True/False

#70. Set Cmd AutoRun
#===================================
# Objective: Configure CMD AutoRun command.
# Expected: Set-CmdAutorun -Command "echo Hi" ➜ True
# Helper: Registry HKCU:\...\Command Processor\AutoRun.
function Set-CmdAutorun {
    param([string]$Command)
    # TODO: Set AutoRun key
    return
}
Write-Output (Set-CmdAutorun -Command "echo Hi")  # Expected: True

#71. Add Defender Exclusion
#===================================
# Objective: Exclude folder from Defender.
# Expected: Add-DefenderExclusion -Path "C:\Tools" ➜ True
# Helper: Add-MpPreference.
function Add-DefenderExclusion {
    param([string]$Path)
    # TODO: Add exclusion
    return
}
Write-Output (Add-DefenderExclusion -Path "C:\Tools")  # Expected: True

#===================================
# Background Jobs
#===================================

#72. Start a Background Job
#===================================
# Objective: Ping host asynchronously.
# Expected: Start-BackgroundPing -Host "8.8.8.8" ➜ Job object
# Helper: Start-Job.
function Start-BackgroundPing {
    param([string]$Host)
    # TODO: Start ping job
    return
}
Write-Output (Start-BackgroundPing -Host "8.8.8.8")  # Expected: Job object

#73. List All Background Jobs
#===================================
# Objective: List current PS jobs.
# Expected: Get-AllJobs ➜ job list
# Helper: Get-Job.
function Get-AllJobs {
    param()
    # TODO: Return Get-Job
    return
}
Write-Output (Get-AllJobs)  # Expected: job list

#74. Receive Output from a Job
#===================================
# Objective: Retrieve results from a job.
# Expected: Get-JobOutput -JobId 1 ➜ output
# Helper: Receive-Job.
function Get-JobOutput {
    param([int]$JobId)
    # TODO: Return job results
    return
}
Write-Output (Get-JobOutput -JobId 1)  # Expected: job output

#75. Remove Completed Jobs
#===================================
# Objective: Delete jobs in Completed state.
# Expected: Clear-FinishedJobs ➜ True
# Helper: Get-Job | Where-Object | Remove-Job.
function Clear-FinishedJobs {
    param()
    # TODO: Remove completed jobs
    return
}
Write-Output (Clear-FinishedJobs)  # Expected: True

#===================================
# PowerShell Remoting
#===================================

#76. Test PS Remoting
#===================================
# Objective: Verify WinRM availability.
# Expected: Test-PSRemoting -ComputerName "localhost" ➜ True
# Helper: Test-WSMan.
function Test-PSRemoting {
    param([string]$ComputerName)
    # TODO: Test PS Remoting
    return
}
Write-Output (Test-PSRemoting -ComputerName "localhost")  # Expected: True

#77. Invoke Remote Command
#===================================
# Objective: Run a script block remotely.
# Expected: Invoke-RemoteCommand -ComputerName "localhost" -ScriptBlock { hostname } ➜ hostname
# Helper: Invoke-Command.
function Invoke-RemoteCommand {
    param([string]$ComputerName, [scriptblock]$ScriptBlock)
    # TODO: Invoke remote script block
    return
}
Write-Output (Invoke-RemoteCommand -ComputerName "localhost" -ScriptBlock { hostname })  # Expected: LOCALHOST

#78. Enter Remote Session
#===================================
# Objective: Start interactive PS session.
# Expected: Enter-RemoteShell -ComputerName "localhost" ➜ PS prompt changes
# Helper: Enter-PSSession.
function Enter-RemoteShell {
    param([string]$ComputerName)
    # TODO: Enter PS session
    return
}
Write-Output (Enter-RemoteShell -ComputerName "localhost")  # Expected: PS session

#79. Copy File to Remote
#===================================
# Objective: Transfer file via PSSession.
# Expected: Copy-ToRemote -Session $s -Source "C:\a.txt" -Destination "C:\b.txt" ➜ True
# Helper: Copy-Item -ToSession.
function Copy-ToRemote {
    param($Session, [string]$Source, [string]$Destination)
    # TODO: Copy file to remote
    return
}
# Test example omitted for brevity

#80. Start Remote Job
#===================================
# Objective: Run a background job remotely.
# Expected: Start-RemoteJob -ComputerName "localhost" -ScriptBlock { Get-Process } ➜ Job object
# Helper: Invoke-Command -AsJob.
function Start-RemoteJob {
    param([string]$ComputerName, [scriptblock]$ScriptBlock)
    # TODO: Run remote job
    return
}
Write-Output (Start-RemoteJob -ComputerName "localhost" -ScriptBlock { Get-Process })  # Expected: Job object

#81. Get Services from Multiple Computers
#===================================
# Objective: Retrieve services from multiple hosts.
# Expected: Get-RemoteServices -ComputerNames @("A","B") ➜ grouped services
# Helper: Invoke-Command on multiple computers.
function Get-RemoteServices {
    param([string[]]$ComputerNames)
    # TODO: Get services from each
    return
}
Write-Output (Get-RemoteServices -ComputerNames @("localhost","127.0.0.1"))  # Expected: services list

#82. Restart Remote Computer
#===================================
# Objective: Restart a remote system.
# Expected: Restart-RemoteComputer -ComputerName "localhost" ➜ True
# Helper: Restart-Computer -ComputerName.
function Restart-RemoteComputer {
    param([string]$ComputerName)
    # TODO: Restart remote computer
    return
}
Write-Output (Restart-RemoteComputer -ComputerName "localhost")  # Expected: True
