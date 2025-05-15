#================
# 1. List Installed Drivers
#================
# Objective: Return a list of all installed system drivers.
# Expected: Get-InstalledDrivers ➜ List of driver names like "wuauserv", "Tcpip", "cdrom"
# Helper: Research 'PowerShell Get-WmiObject Win32_SystemDriver'

function Get-InstalledDrivers {
    param()
    # TODO: Return the names of all installed system drivers
    return
}
Write-Output (Get-InstalledDrivers)  # Expected: A list of driver names

#================
# 2. Find Kernel-Mode Drivers
#================
# Objective: Filter and return kernel-mode drivers currently running.
# Expected: Get-KernelDrivers ➜ Running drivers with path in System32 (e.g., "Tcpip")
# Helper: Research 'PowerShell Where-Object and PathName filters'

function Get-KernelDrivers {
    param()
    # TODO: Return actively running kernel-mode drivers
    return
}
Write-Output (Get-KernelDrivers)  # Expected: List of kernel drivers

#================
# 3. Check If a Driver is Running
#================
# Objective: Return $true or $false depending on if the specified driver is running.
# Expected: Is-DriverRunning "wuauserv" ➜ True or False
# Helper: Use Get-Service or Get-WmiObject to check driver state

function Is-DriverRunning {
    param($name)
    # TODO: Return $true if the driver is running, else $false
    return
}
Write-Output (Is-DriverRunning "wuauserv")   # Expected: True or False
Write-Output (Is-DriverRunning "Spooler")    # Expected: True or False

#================
# 4. Toggle a Driver
#================
# Objective: Start or stop a driver/service based on action input.
# Expected: Toggle-Driver "Spooler" "Stop" ➜ stops the Print Spooler service
#           Toggle-Driver "Spooler" "Start" ➜ starts the Print Spooler service
# Helper: Research 'PowerShell Start-Service Stop-Service'

function Toggle-Driver {
    param($name, [ValidateSet("Start","Stop")]$action)
    # TODO: Start or stop the driver/service by name
    return
}
Write-Output (Toggle-Driver "Spooler" "Stop")  # Expected: Service stopped
Write-Output (Toggle-Driver "Spooler" "Start") # Expected: Service started

#================
# 5. Get Driver File Metadata
#================
# Objective: Return the Name, Size, and LastWriteTime of the specified driver file.
# Expected: Get-DriverFileInfo "C:\Windows\System32\drivers\ndis.sys" ➜ Name: ndis.sys, Size: <int>, LastWriteTime: <datetime>
# Helper: Research 'PowerShell Get-Item file properties'

function Get-DriverFileInfo {
    param($path)
    # TODO: Return a custom object with Name, Size, and LastWriteTime
    return
}
Write-Output (Get-DriverFileInfo "C:\Windows\System32\drivers\ndis.sys")  
# Expected: Name: ndis.sys, Size: <int>, LastWriteTime: <datetime>

#================
# 6. Get Current Boot Configuration
#================
# Objective: Display the current boot entries using bcdedit.
# Expected: Get-BootConfig ➜ includes "Windows Boot Manager", identifiers, devices, paths.
# Helper: Research 'bcdedit /enum'

function Get-BootConfig {
    param()
    # TODO: Return the output of 'bcdedit' showing the current boot entries
    return
}
Write-Output (Get-BootConfig)  
# Expected: Output with boot entries and settings

#================
# 7. Check Firmware Type
#================
# Objective: Return whether the system is using UEFI or BIOS firmware.
# Expected: Get-FirmwareType ➜ "UEFI" or "BIOS"
# Helper: Research 'PowerShell Get-WmiObject Win32_ComputerSystem'

function Get-FirmwareType {
    param()
    # TODO: Return "UEFI" or "BIOS" depending on system firmware
    return
}
Write-Output (Get-FirmwareType)         # Expected: UEFI or BIOS

#================
# 8. List Bootable Partitions
#================
# Objective: Identify partitions flagged as Boot.
# Expected: Get-BootPartitions ➜ lists partitions DriveLetter and Boot flag.
# Helper: Research 'PowerShell Get-Partition' and BootFlag

function Get-BootPartitions {
    param()
    # TODO: Return all partitions flagged as "Boot"
    return
}
Write-Output (Get-BootPartitions)       # Expected: C: flagged as Boot, etc.

#================
# 9. Create New Boot Entry
#================
# Objective: Create a new boot entry in the BCD store.
# Expected: Add-BootEntry "SafeMode Test" "C:\Windows\System32\winload.exe" ➜ confirmation output
# Helper: Research 'bcdedit /copy' and '/set'

function Add-BootEntry {
    param($description, $path)
    # TODO: Use bcdedit to add a new boot entry with the given description and path
    return
}
Write-Output (Add-BootEntry "SafeMode Test" "C:\Windows\System32\winload.exe") 
# Expected: New boot entry created with GUID and settings

#================
# 10. Set Default Boot Entry
#================
# Objective: Configure which boot entry is used by default.
# Expected: Set-DefaultBootEntry "{current}" ➜ default set
# Helper: Research 'bcdedit /default {identifier}'

function Set-DefaultBootEntry {
    param($identifier)
    # TODO: Set the given boot entry as the default using bcdedit
    return
}
Write-Output (Set-DefaultBootEntry "{current}")     
# Expected: Boot entry default updated

#================
# 11. Set Boot Timeout
#================
# Objective: Change the timeout value for the boot menu.
# Expected: Set-BootTimeout 15 ➜ Timeout set to 15 seconds
#           Set-BootTimeout 0 ➜ Boots default entry immediately
# Helper: Research 'bcdedit /timeout seconds'

function Set-BootTimeout {
    param($seconds)
    # TODO: Use bcdedit to set the boot timeout
    return
}
Write-Output (Set-BootTimeout 15)       # Expected: Timeout set to 15 seconds
Write-Output (Set-BootTimeout 0)        # Expected: Boots default entry immediately

#================
# 12. Read a Registry Value
#================
# Objective: Retrieve the data of a specified registry value.
# Expected: Get-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName" ➜ "Windows 10 Pro"
# Helper: Research 'PowerShell Get-ItemProperty'

function Get-RegistryValue {
    param($path, $name)
    # TODO: Return the value of the specified registry key
    return
}
Write-Output (Get-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName")  
# Expected: Windows 10 Pro

#================
# 13. Set a Registry Value
#================
# Objective: Create or update a registry value.
# Expected: Set-RegistryValue "HKCU:\Software\TestKey" "Mode" "Enabled" ➜ value set
# Helper: Research 'New-ItemProperty' or 'Set-ItemProperty'

function Set-RegistryValue {
    param($path, $name, $value)
    # TODO: Create or update a registry value at the specified path
    return
}
Write-Output (Set-RegistryValue "HKCU:\Software\TestKey" "Mode" "Enabled")  
# Expected: Key 'TestKey' with value 'Mode=Enabled' now exists

#================
# 14. Remove a Registry Value
#================
# Objective: Delete a specified value from a registry key.
# Expected: Remove-RegistryValue "HKCU:\Software\TestKey" "Mode" ➜ value removed
# Helper: Research 'Remove-ItemProperty'

function Remove-RegistryValue {
    param($path, $name)
    # TODO: Delete the specified value from the registry key
    return
}
Write-Output (Remove-RegistryValue "HKCU:\Software\TestKey" "Mode")  
# Expected: Value 'Mode' removed from 'TestKey'

#================
# 15. Check If RDP is Enabled via Registry
#================
# Objective: Determine if Remote Desktop (RDP) is enabled on this system.
# Expected: Is-RDPEnabled ➜ True if fDenyTSConnections = 0, else False
# Helper: Research 'fDenyTSConnections registry value'

function Is-RDPEnabled {
    param()
    # TODO: Return $true if RDP is enabled (HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections = 0)
    return
}
Write-Output (Is-RDPEnabled)    # Expected: True or False

#================
# 16. Set Autorun for CMD
#================
# Objective: Configure CMD to execute a command each time it starts.
# Expected: Set-CmdAutorun "echo Welcome!" ➜ Autorun command set
# Helper: Research 'Registry HKCU:\Software\Microsoft\Command Processor\AutoRun'

function Set-CmdAutorun {
    param($command)
    # TODO: Set the AutoRun registry key to launch the provided command on CMD startup
    return
}
Write-Output (Set-CmdAutorun "echo Welcome!")  
# Expected: CMD now auto-prints "Welcome!" on launch

#================
# 17. Add Folder to Windows Defender Exclusions
#================
# Objective: Exclude a specified folder from Windows Defender scans.
# Expected: Add-DefenderExclusion "C:\Tools" ➜ Folder excluded
# Helper: Research 'Add-MpPreference -ExclusionPath'

function Add-DefenderExclusion {
    param($folderPath)
    # TODO: Add specified path to Defender's exclusion list
    return
}
Write-Output (Add-DefenderExclusion "C:\Tools")  
# Expected: Folder excluded from Defender scans

#================
# 18. List All Running Processes
#================
# Objective: Return the names of all currently running processes.
# Expected: Get-RunningProcesses ➜ "explorer", "svchost", "cmd", etc.
# Helper: Research 'Get-Process'

function Get-RunningProcesses {
    param()
    # TODO: Return the names of all running processes
    return
}
Write-Output (Get-RunningProcesses)  
# Expected: A list like "explorer", "svchost", "cmd", etc.

#================
# 19. Check If a Process is Running
#================
# Objective: Return $true if a process with the given name is running, else $false.
# Expected: Is-ProcessRunning "notepad" ➜ True if Notepad is running.
# Helper: Research 'Get-Process'

function Is-ProcessRunning {
    param($name)
    # TODO: Return $true if a process with the given name is running
    return
}
Write-Output (Is-ProcessRunning "notepad")    # Expected: True or False
Write-Output (Is-ProcessRunning "explorer")   # Expected: True

#================
# 20. Kill a Process by Name
#================
# Objective: Terminate all instances of the specified process.
# Expected: Kill-Process "notepad" ➜ closes Notepad.
# Helper: Research 'Stop-Process'

function Kill-Process {
    param($name)
    # TODO: Stop a process by name
    return
}
Write-Output (Kill-Process "notepad")  
# Expected: Terminates all instances of notepad (if running)

#================
# 21. Get System Uptime
#================
# Objective: Report how long the system has been running.
# Expected: Get-SystemUptime ➜ "1 day, 4 hours, 20 minutes"
# Helper: Research 'Win32_OperatingSystem LastBootUpTime'

function Get-SystemUptime {
    param()
    # TODO: Return how long the system has been running
    return
}
Write-Output (Get-SystemUptime)  
# Expected: "1 day, 4 hours, 20 minutes" or similar

#================
# 22. List All Services and Their States
#================
# Objective: Return each service name and its current status (Running/Stopped).
# Expected: Get-AllServices ➜ "Spooler: Running", "wuauserv: Stopped", etc.
# Helper: Research 'Get-Service'

function Get-AllServices {
    param()
    # TODO: Return a list of all services and whether they're running
    return
}
Write-Output (Get-AllServices)  
# Expected: Name and status for each service

#================
# 23. Start a Windows Service
#================
# Objective: Start the specified service if it is stopped.
# Expected: Start-ServiceByName "Spooler" ➜ starts Print Spooler.
# Helper: Research 'Start-Service'

function Start-ServiceByName {
    param($name)
    # TODO: Start the specified service
    return
}
Write-Output (Start-ServiceByName "Spooler")  
# Expected: Starts Print Spooler service

#================
# 24. Stop a Windows Service
#================
# Objective: Stop the specified service if it is running.
# Expected: Stop-ServiceByName "Spooler" ➜ stops Print Spooler.
# Helper: Research 'Stop-Service'

function Stop-ServiceByName {
    param($name)
    # TODO: Stop the specified service
    return
}
Write-Output (Stop-ServiceByName "Spooler")  
# Expected: Stops Print Spooler service

#================
# 25. Restart a Windows Service
#================
# Objective: Restart the specified service (stop then start).
# Expected: Restart-ServiceByName "wuauserv" ➜ restarts Windows Update.
# Helper: Research 'Restart-Service'

function Restart-ServiceByName {
    param($name)
    # TODO: Restart the specified service
    return
}
Write-Output (Restart-ServiceByName "wuauserv")  
# Expected: Windows Update service restarted

#================
# 26. Get Current Working Directory
#================
# Objective: Return the current directory path.
# Expected: Get-WorkingDirectory ➜ "C:\Users\Username"
# Helper: Research 'Get-Location'

function Get-WorkingDirectory {
    param()
    # TODO: Return the current directory path
    return
}
Write-Output (Get-WorkingDirectory)     # Expected: C:\Users\Username

#================
# 27. Change Directory
#================
# Objective: Change to the specified directory path.
# Expected: Change-Directory "C:\Windows" ➜ current path is C:\Windows.
# Helper: Research 'Set-Location'

function Change-Directory {
    param($path)
    # TODO: Change to the specified directory
    return
}
Write-Output (Change-Directory "C:\Windows")  
# Expected: Now in C:\Windows

#================
# 28. List All Files in a Folder
#================
# Objective: List file names in the given directory.
# Expected: List-Files "C:\Windows" ➜ explorer.exe, notepad.exe, etc.
# Helper: Research 'Get-ChildItem'

function List-Files {
    param($folderPath)
    # TODO: Return names of all files in the given directory
    return
}
Write-Output (List-Files "C:\Windows")  
# Expected: explorer.exe, notepad.exe, etc.

#================
# 29. Create a New Folder
#================
# Objective: Create a new directory at the specified path.
# Expected: Create-Folder "C:\Temp\MyTestFolder" ➜ folder created.
# Helper: Research 'New-Item -ItemType Directory'

function Create-Folder {
    param($path)
    # TODO: Create a folder at the given path
    return
}
Write-Output (Create-Folder "C:\Temp\MyTestFolder")  
# Expected: Folder C:\Temp\MyTestFolder created

#================
# 30. Delete a Folder
#================
# Objective: Remove the specified folder and its contents.
# Expected: Delete-Folder "C:\Temp\MyTestFolder" ➜ folder deleted.
# Helper: Research 'Remove-Item -Recurse'

function Delete-Folder {
    param($path)
    # TODO: Delete the folder at the given path (including contents)
    return
}
Write-Output (Delete-Folder "C:\Temp\MyTestFolder")  
# Expected: Folder deleted

#================
# 31. Create a New Text File with Content
#================
# Objective: Write text to a new file (creating it if necessary).
# Expected: Write-TextFile "C:\Temp\hello.txt" "Hello World!" ➜ file contains "Hello World!"
# Helper: Research 'Out-File' or 'Set-Content'

function Write-TextFile {
    param($path, $text)
    # TODO: Write the given text to the file path (create if not exists)
    return
}
Write-Output (Write-TextFile "C:\Temp\hello.txt" "Hello World!")  
# Expected: File hello.txt contains "Hello World!"

#================
# 32. Read Content from a File
#================
# Objective: Return the contents of the specified text file.
# Expected: Read-TextFile "C:\Temp\hello.txt" ➜ "Hello World!"
# Helper: Research 'Get-Content'

function Read-TextFile {
    param($path)
    # TODO: Return the contents of the file
    return
}
Write-Output (Read-TextFile "C:\Temp\hello.txt")  
# Expected: Hello World!

#================
# 33. Copy a File to New Location
#================
# Objective: Copy a file from source to destination.
# Expected: Copy-File "C:\Temp\hello.txt" "C:\Temp\Backup\hello.txt" ➜ file copied.
# Helper: Research 'Copy-Item'

function Copy-File {
    param($source, $destination)
    # TODO: Copy the file to the new location
    return
}
Write-Output (Copy-File "C:\Temp\hello.txt" "C:\Temp\Backup\hello.txt")  
# Expected: File copied

#================
# 34. Move a File
#================
# Objective: Move a file from source to destination.
# Expected: Move-File "C:\Temp\hello.txt" "C:\Temp\Moved\hello.txt" ➜ file moved.
# Helper: Research 'Move-Item'

function Move-File {
    param($source, $destination)
    # TODO: Move the file from source to destination
    return
}
Write-Output (Move-File "C:\Temp\hello.txt" "C:\Temp\Moved\hello.txt")  
# Expected: File relocated to new folder

#================
# 35. Delete a File
#================
# Objective: Delete the specified file.
# Expected: Delete-File "C:\Temp\Moved\hello.txt" ➜ file deleted.
# Helper: Research 'Remove-Item'

function Delete-File {
    param($path)
    # TODO: Delete the specified file
    return
}
Write-Output (Delete-File "C:\Temp\Moved\hello.txt")  
# Expected: File deleted

#================
# 36. Get Local IP Address
#================
# Objective: Return the primary IPv4 address of the local machine.
# Expected: Get-IP ➜ 192.168.1.10
# Helper: Research 'Get-NetIPAddress'

function Get-IP {
    param()
    # TODO: Return the IPv4 address of the local machine
    return
}
Write-Output (Get-IP)  
# Expected: 192.168.1.10 (or similar)

#================
# 37. Ping a Remote Host
#================
# Objective: Return $true if the specified host is reachable via ping, else $false.
# Expected: Test-Connectivity "8.8.8.8" ➜ True; "nohost.local" ➜ False.
# Helper: Research 'Test-Connection -Quiet'

function Test-Connectivity {
    param($hostname)
    # TODO: Ping the specified host and return if it's reachable
    return
}
Write-Output (Test-Connectivity "8.8.8.8")       # Expected: True
Write-Output (Test-Connectivity "nohost.local")  # Expected: False

#================
# 38. Run Traceroute to Host
#================
# Objective: Show the route packets take to a target host.
# Expected: Trace-Host "google.com" ➜ list of hop IPs.
# Helper: Research 'tracert' usage

function Trace-Host {
    param($target)
    # TODO: Perform a traceroute (use tracert)
    return
}
Write-Output (Trace-Host "google.com")  
# Expected: List of hop IPs toward google.com

#================
# 39. Show All Network Interfaces
#================
# Objective: List each network adapter's name, status, and IP.
# Expected: Get-NetworkInterfaces ➜ Ethernet: Up, IP=192.168.1.10; Wi-Fi: Down, etc.
# Helper: Research 'Get-NetAdapter', 'Get-NetIPAddress'

function Get-NetworkInterfaces {
    param()
    # TODO: Return name, status, and IP of each network adapter
    return
}
Write-Output (Get-NetworkInterfaces)  
# Expected: Ethernet, Wi-Fi, Virtual adapters listed with IPs

#================
# 40. Display TCP Listening Ports
#================
# Objective: List all TCP ports currently being listened on.
# Expected: Get-TCPListeners ➜ Port 80 - httpd, Port 443 - svchost, etc.
# Helper: Research 'Get-NetTCPConnection -State Listen'

function Get-TCPListeners {
    param()
    # TODO: List ports that are currently listening
    return
}
Write-Output (Get-TCPListeners)  
# Expected: List of ports and processes (e.g., 443 - svchost)

#================
# 41. Check If Port is Listening
#================
# Objective: Return $true if the specified port is in listening state.
# Expected: Is-PortListening 80 ➜ True; 9999 ➜ False.
# Helper: Research 'Get-NetTCPConnection'

function Is-PortListening {
    param($port)
    # TODO: Return $true if the port is in listening state
    return
}
Write-Output (Is-PortListening 80)    # Expected: True or False
Write-Output (Is-PortListening 9999)  # Expected: False

#================
# 42. List Active Network Connections
#================
# Objective: Show current TCP/UDP connections.
# Expected: Get-NetworkConnections ➜ list remote IPs, local ports, states like ESTABLISHED.
# Helper: Research 'Get-NetTCPConnection'

function Get-NetworkConnections {
    param()
    # TODO: Return all active TCP/UDP connections
    return
}
Write-Output (Get-NetworkConnections)  
# Expected: Remote IPs, local ports, states like ESTABLISHED

#================
# 43. Release and Renew IP Address (DHCP)
#================
# Objective: Release and renew the DHCP lease.
# Expected: Refresh-IP ➜ new IP assigned by DHCP server.
# Helper: Research 'ipconfig /release' and '/renew' or equivalent cmdlets

function Refresh-IP {
    param()
    # TODO: Release and renew the DHCP lease
    return
}
Write-Output (Refresh-IP)  
# Expected: New IP assigned by DHCP server

#================
# 44. Declare and Use a Variable
#================
# Objective: Assign a string to a variable and return it.
# Expected: Use-Variable ➜ "PowerShell is fun!"
# Helper: Research variable declaration

function Use-Variable {
    param()
    # TODO: Assign a string to a variable and return it
    return
}
Write-Output (Use-Variable)   # Expected: "PowerShell is fun!"

#================
# 45. Perform Arithmetic with Variables
#================
# Objective: Return the sum of two numbers.
# Expected: Add-Numbers 2 3 ➜ 5; 10 15 ➜ 25.
# Helper: Research arithmetic operators

function Add-Numbers {
    param($a, $b)
    # TODO: Return the sum of $a and $b
    return
}
Write-Output (Add-Numbers 2 3)     # Expected: 5
Write-Output (Add-Numbers 10 15)   # Expected: 25

#================
# 46. Get User Input
#================
# Objective: Prompt the user for input and return a greeting.
# Expected: Ask-Username ➜ prompts, then returns "Hello, <name>!"
# Helper: Research Read-Host

function Ask-Username {
    param()
    # TODO: Ask the user for their name and return "Hello, <name>!"
    return
}
Write-Output (Ask-Username)   # Expected (on prompt): Hello, Jordan!

#================
# 47. If Statement – Check Value
#================
# Objective: Return "Access granted" if role is "admin", else "Access denied".
# Expected: Is-Admin "admin" ➜ Access granted; "user" ➜ Access denied.
# Helper: Research if/else syntax

function Is-Admin {
    param($role)
    # TODO: Return "Access granted" if role is "admin", else "Access denied"
    return
}
Write-Output (Is-Admin "admin")     # Expected: Access granted
Write-Output (Is-Admin "user")      # Expected: Access denied

#================
# 48. ElseIf Chain
#================
# Objective: Return "Weekend" for Sat/Sun, "Weekday" for Mon-Fri, "Invalid" otherwise.
# Expected: Get-DayType "Monday" ➜ Weekday; "Sunday" ➜ Weekend; "Caturday" ➜ Invalid.
# Helper: Research elseif chains

function Get-DayType {
    param($day)
    # TODO: Return "Weekend" for Sat/Sun, "Weekday" for Mon-Fri, "Invalid" otherwise
    return
}
Write-Output (Get-DayType "Monday")    # Expected: Weekday
Write-Output (Get-DayType "Sunday")    # Expected: Weekend
Write-Output (Get-DayType "Caturday")  # Expected: Invalid

#================
# 49. While Loop Timer
#================
# Objective: Print a countdown from a given number to zero.
# Expected: Countdown-Timer 3 ➜ 3 2 1 0.
# Helper: Research while loops

function Countdown-Timer {
    param($seconds)
    # TODO: Loop and print countdown from $seconds to 0
    return
}
Write-Output (Countdown-Timer 3)  
# Expected:
# 3
# 2
# 1
# 0

#================
# 50. ForEach Loop Over Files
#================
# Objective: Return names of all files in a folder using a loop.
# Expected: List-FileNames "C:\Windows\System32" ➜ list of file names.
# Helper: Research foreach syntax

function List-FileNames {
    param($path)
    # TODO: Return names of all files in the folder using a loop
    return
}
Write-Output (List-FileNames "C:\Windows\System32")  
# Expected: List of file names (not directories)

#================
# 51. Function Reuse and Return
#================
# Objective: Return the square of a number.
# Expected: Square 4 ➜ 16; -3 ➜ 9.
# Helper: Research function calls

function Square {
    param($n)
    # TODO: Return the square of a number
    return
}
Write-Output (Square 4)    # Expected: 16
Write-Output (Square -3)   # Expected: 9

#================
# 52. Switch Statement
#================
# Objective: Return a message based on an HTTP status code.
# Expected: Get-StatusMessage 200 ➜ OK; 404 ➜ Not Found; 999 ➜ Unknown.
# Helper: Research switch statement

function Get-StatusMessage {
    param($code)
    # TODO: Use a switch to return a message for 200, 404, 500
    return
}
Write-Output (Get-StatusMessage 200)  # Expected: OK
Write-Output (Get-StatusMessage 404)  # Expected: Not Found
Write-Output (Get-StatusMessage 999)  # Expected: Unknown

#================
# 53. Filter Processes by Name
#================
# Objective: Return running processes matching a given name.
# Expected: Find-Process "svchost" ➜ multiple entries with Name=svchost.
# Helper: Research Get-Process | Where-Object

function Find-Process {
    param($name)
    # TODO: Return all running processes that match $name using a pipeline
    return
}
Write-Output (Find-Process "svchost")  
# Expected: Multiple entries with Name = svchost

#================
# 54. Filter by CPU Usage
#================
# Objective: Return processes using more CPU time than a threshold.
# Expected: Get-HighCPUProcesses 100 ➜ processes with CPU > 100.
# Helper: Research Get-Process CPU property and Where-Object

function Get-HighCPUProcesses {
    param($threshold)
    # TODO: Return processes using more CPU time than the threshold
    return
}
Write-Output (Get-HighCPUProcesses 100)  
# Expected: Any process with CPU(s) > 100

#================
# 55. Select Specific Process Properties
#================
# Objective: Show only Name and Id for all running processes.
# Expected: Select-ProcessProperties ➜ table of Name and Id.
# Helper: Research Select-Object

function Select-ProcessProperties {
    param()
    # TODO: Return just Name and Id for all running processes
    return
}
Write-Output (Select-ProcessProperties)  
# Expected: Output shows only Name and Id columns

#================
# 56. Format Output as a List
#================
# Objective: Display all properties of a named process using list format.
# Expected: List-ProcessDetails "explorer" ➜ all properties via Format-List.
# Helper: Research Format-List

function List-ProcessDetails {
    param($name)
    # TODO: Return all properties of a named process using Format-List
    return
}
Write-Output (List-ProcessDetails "explorer")  
# Expected: Name, Id, CPU, Path, etc.

#================
# 57. Get Services That Are Running
#================
# Objective: List all services where status is 'Running'.
# Expected: Get-RunningServices ➜ list of running services.
# Helper: Research Get-Service | Where-Object

function Get-RunningServices {
    param()
    # TODO: Return all services where status is 'Running'
    return
}
Write-Output (Get-RunningServices)  
# Expected: List of currently running Windows services

#================
# 58. Count Number of Running Processes
#================
# Objective: Count how many processes are currently running.
# Expected: Count-Processes ➜ integer count.
# Helper: Research Measure-Object

function Count-Processes {
    param()
    # TODO: Return how many processes are currently running
    return
}
Write-Output (Count-Processes)  
# Expected: An integer (e.g., 127)

#================
# 59. Sort Services by Status
#================
# Objective: Return all services sorted by their Status.
# Expected: Sort-ServicesByStatus ➜ grouped by Running then Stopped.
# Helper: Research Sort-Object

function Sort-ServicesByStatus {
    param()
    # TODO: Return all services sorted by Status (Running, Stopped)
    return
}
Write-Output (Sort-ServicesByStatus)  
# Expected: Services grouped by Running and Stopped

#================
# 60. Display Services as a Table
#================
# Objective: Show Name, Status, and StartType for each service in table format.
# Expected: Table-Services ➜ formatted table.
# Helper: Research Format-Table

function Table-Services {
    param()
    # TODO: Return Service Name, Status, and StartType in table format
    return
}
Write-Output (Table-Services)  
# Expected: Nicely formatted table with Name, Status, StartType

#================
# 61. Start a Background Job
#================
# Objective: Start a background job that pings a host multiple times.
# Expected: Start-BackgroundPing "8.8.8.8" ➜ Job object with Id and State.
# Helper: Research Start-Job

function Start-BackgroundPing {
    param($host)
    # TODO: Start a background job that pings the specified host
    return
}
Write-Output (Start-BackgroundPing "8.8.8.8")  
# Expected: Job object with Id and State

#================
# 62. Get All Background Jobs
#================
# Objective: List all current PowerShell jobs.
# Expected: Get-AllJobs ➜ list of jobs with Id, Name, State.
# Helper: Research Get-Job

function Get-AllJobs {
    param()
    # TODO: Return a list of all current PowerShell jobs
    return
}
Write-Output (Get-AllJobs)  
# Expected: List of jobs with Id, Name, and State

#================
# 63. Receive Output from a Job
#================
# Objective: Retrieve the results of a completed background job.
# Expected: Get-JobOutput 1 ➜ output from job ID 1.
# Helper: Research Receive-Job

function Get-JobOutput {
    param($jobId)
    # TODO: Return the output from the specified job
    return
}
Write-Output (Get-JobOutput 1)  
# Expected: Output from the background job with ID 1

#================
# 64. Remove All Completed Jobs
#================
# Objective: Remove jobs in the Completed state.
# Expected: Clear-FinishedJobs ➜ all completed jobs removed.
# Helper: Research Get-Job | Where-Object State -eq Completed | Remove-Job

function Clear-FinishedJobs {
    param()
    # TODO: Remove all jobs that are in Completed state
    return
}
Write-Output (Clear-FinishedJobs)  
# Expected: All completed jobs removed

#================
# 65. Schedule a Task to Run a Script
#================
# Objective: Create a scheduled task to run a script every hour.
# Expected: Schedule-Script "HourlyTest" "C:\Scripts\Test.ps1" ➜ task created.
# Helper: Research Register-ScheduledTask and New-ScheduledTaskTrigger

function Schedule-Script {
    param($taskName, $scriptPath)
    # TODO: Create a scheduled task that runs a script every hour
    return
}
Write-Output (Schedule-Script "HourlyTest" "C:\Scripts\Test.ps1")  
# Expected: Task created and visible in Task Scheduler

#================
# 66. List All Scheduled Tasks
#================
# Objective: List scheduled tasks and their current status.
# Expected: List-ScheduledTasks ➜ TaskName, State, LastRunTime.
# Helper: Research Get-ScheduledTask

function List-ScheduledTasks {
    param()
    # TODO: Return a list of scheduled tasks and their status
    return
}
Write-Output (List-ScheduledTasks)  
# Expected: TaskName, State, LastRunTime

#================
# 67. Manually Run a Scheduled Task
#================
# Objective: Trigger a scheduled task to run immediately.
# Expected: Run-TaskNow "HourlyTest" ➜ task launched.
# Helper: Research Start-ScheduledTask

function Run-TaskNow {
    param($taskName)
    # TODO: Run a scheduled task immediately
    return
}
Write-Output (Run-TaskNow "HourlyTest")  
# Expected: Task launched and output generated

#================
# 68. Disable a Scheduled Task
#================
# Objective: Disable a scheduled task so it no longer runs.
# Expected: Disable-ScheduledTask "HourlyTest" ➜ task disabled.
# Helper: Research Disable-ScheduledTask

function Disable-ScheduledTask {
    param($taskName)
    # TODO: Disable the specified task
    return
}
Write-Output (Disable-ScheduledTask "HourlyTest")  
# Expected: Task is now disabled

#================
# 69. Delete a Scheduled Task
#================
# Objective: Permanently remove a scheduled task.
# Expected: Delete-ScheduledTask "HourlyTest" ➜ task deleted.
# Helper: Research Unregister-ScheduledTask

function Delete-ScheduledTask {
    param($taskName)
    # TODO: Permanently remove a scheduled task by name
    return
}
Write-Output (Delete-ScheduledTask "HourlyTest")  
# Expected: Task deleted from Task Scheduler

#================
# 70. Test If Remote Machine is Reachable
#================
# Objective: Return $true if the remote host responds to ping.
# Expected: Test-RemoteHost "10.0.0.5" ➜ True/False.
# Helper: Research Test-Connection

function Test-RemoteHost {
    param($hostname)
    # TODO: Return $true if remote host is reachable via ping
    return
}
Write-Output (Test-RemoteHost "10.0.0.5")    # Expected: True or False

#================
# 71. Run a Command on Remote Machine
#================
# Objective: Execute a command via PS Remoting and return output.
# Expected: Invoke-RemoteCommand "SERVER01" "Get-Service Spooler" ➜ shows Spooler status.
# Helper: Research Invoke-Command

function Invoke-RemoteCommand {
    param($computerName, $command)
    # TODO: Execute the command remotely using Invoke-Command
    return
}
Write-Output (Invoke-RemoteCommand "SERVER01" "Get-Service Spooler")  
# Expected: Shows Spooler status from SERVER01

#================
# 72. Enter an Interactive Session
#================
# Objective: Start an interactive PS session on a remote machine.
# Expected: Enter-RemoteShell "SERVER01" ➜ PS prompt changes to [SERVER01].
# Helper: Research Enter-PSSession

function Enter-RemoteShell {
    param($computerName)
    # TODO: Enter an interactive PowerShell session with the remote machine
    return
}
Write-Output (Enter-RemoteShell "SERVER01")  
# Expected: PS prompt [SERVER01]

#================
# 73. Copy File to Remote Machine
#================
# Objective: Transfer a local file to a remote session.
# Expected: Copy-ToRemote $session "C:\Tools\script.ps1" "C:\RemoteTools\script.ps1" ➜ file copied.
# Helper: Research Copy-Item -ToSession

function Copy-ToRemote {
    param($session, $source, $destination)
    # TODO: Copy a file to a remote session using Copy-Item
    return
}
# Example:
# Write-Output (Copy-ToRemote $session "C:\Tools\script.ps1" "C:\RemoteTools\script.ps1")

#================
# 74. Start a Remote Job
#================
# Objective: Run a background job on a remote computer.
# Expected: Start-RemoteJob "SERVER01" { Get-Process } ➜ Job object with remote context.
# Helper: Research Invoke-Command -AsJob

function Start-RemoteJob {
    param($computerName, $scriptBlock)
    # TODO: Run a background job on a remote system
    return
}
Write-Output (Start-RemoteJob "SERVER01" { Get-Process })  
# Expected: Job object with remote computer context

#================
# 75. Get Services from Multiple Computers
#================
# Objective: Retrieve running services from multiple remote machines.
# Expected: Get-RemoteServices @("Server1","Server2") ➜ services grouped by computer.
# Helper: Research Invoke-Command with -ComputerName array

function Get-RemoteServices {
    param($computers)
    # TODO: Return the running services from all specified computers
    return
}
Write-Output (Get-RemoteServices @("SERVER01", "SERVER02"))  
# Expected: Services grouped by computer

#================
# 76. Reboot a Remote Computer
#================
# Objective: Restart the remote machine.
# Expected: Restart-RemoteComputer "SERVER01" ➜ remote computer reboot initiated.
# Helper: Research Restart-Computer

function Restart-RemoteComputer {
    param($computerName)
    # TODO: Restart the remote system
    return
}
Write-Output (Restart-RemoteComputer "SERVER01")  
# Expected: Remote computer begins restart
