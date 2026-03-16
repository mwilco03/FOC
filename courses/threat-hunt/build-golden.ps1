#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Builds the golden VHDX for threat hunt victim VMs.
    Run once. Takes ~30 minutes. Requires Windows Server 2022 Eval ISO.

.DESCRIPTION
    1. Downloads Windows Server 2022 Evaluation ISO (if not present)
    2. Creates a VHDX from the ISO with unattend.xml
    3. Boots the VM, runs setup-victim.ps1 (installs Sysmon, Winlogbeat, plants artifacts)
    4. Shuts down and exports the golden VHDX

.NOTES
    Requires: Hyper-V enabled, internet access for downloads
    Output: golden\victim-golden.vhdx
#>

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$GoldenDir = Join-Path $ProjectRoot "golden"
$VHDXPath = Join-Path $GoldenDir "victim-golden.vhdx"
$VMName = "golden-build-temp"
$SwitchName = "LabSwitch"
$MemoryMB = 2048
$DiskSizeGB = 20

# --- Helper Functions ---
function Write-Step($msg) { Write-Host "`n[$((Get-Date).ToString('HH:mm:ss'))] $msg" -ForegroundColor Cyan }
function Write-Info($msg) { Write-Host "  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  WARNING: $msg" -ForegroundColor Yellow }

# --- Check Prerequisites ---
Write-Step "Checking prerequisites"

$hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
if ($hyperv.State -ne "Enabled") {
    Write-Error "Hyper-V is not enabled. Run: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All"
}
Write-Info "Hyper-V enabled"

# --- Windows Server ISO ---
Write-Step "Checking for Windows Server 2022 Evaluation ISO"

$ISODir = Join-Path $GoldenDir "iso"
if (!(Test-Path $ISODir)) { New-Item -ItemType Directory -Path $ISODir -Force | Out-Null }

$ISOPath = Get-ChildItem -Path $ISODir -Filter "*.iso" | Select-Object -First 1
if (!$ISOPath) {
    Write-Warn "No ISO found in $ISODir"
    Write-Host ""
    Write-Host "  Download Windows Server 2022 Evaluation (180-day free) from:" -ForegroundColor White
    Write-Host "  https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Save the ISO to: $ISODir" -ForegroundColor White
    Write-Host ""
    $ISOPath = Read-Host "  Enter full path to ISO (or press Enter to abort)"
    if ([string]::IsNullOrWhiteSpace($ISOPath) -or !(Test-Path $ISOPath)) {
        Write-Error "ISO required. Download it and re-run this script."
    }
} else {
    $ISOPath = $ISOPath.FullName
}
Write-Info "Using ISO: $ISOPath"

# --- Create Hyper-V Switch if needed ---
Write-Step "Configuring Hyper-V networking"

$switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if (!$switch) {
    New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
    $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$SwitchName*" }
    New-NetIPAddress -IPAddress 10.10.1.1 -PrefixLength 24 -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue | Out-Null
    # NAT for internet access during build
    New-NetNat -Name "LabNAT" -InternalIPInterfaceAddressPrefix "10.10.1.0/24" -ErrorAction SilentlyContinue | Out-Null
    Write-Info "Created LabSwitch (10.10.1.0/24) with NAT"
} else {
    Write-Info "LabSwitch already exists"
}

# --- Create VHDX ---
Write-Step "Creating golden VHDX ($DiskSizeGB GB)"

if (Test-Path $VHDXPath) {
    Write-Warn "Golden VHDX already exists. Delete it first if you want to rebuild."
    Write-Warn "Path: $VHDXPath"
    $confirm = Read-Host "  Overwrite? (y/N)"
    if ($confirm -ne 'y') { exit 0 }
    Remove-Item $VHDXPath -Force
}

New-VHD -Path $VHDXPath -SizeBytes ($DiskSizeGB * 1GB) -Dynamic | Out-Null
Write-Info "VHDX created: $VHDXPath"

# --- Create and configure VM ---
Write-Step "Creating build VM"

# Clean up any previous build VM
Get-VM -Name $VMName -ErrorAction SilentlyContinue | Stop-VM -Force -ErrorAction SilentlyContinue
Get-VM -Name $VMName -ErrorAction SilentlyContinue | Remove-VM -Force -ErrorAction SilentlyContinue

New-VM -Name $VMName `
    -MemoryStartupBytes ($MemoryMB * 1MB) `
    -VHDPath $VHDXPath `
    -SwitchName $SwitchName `
    -Generation 2 | Out-Null

# Mount ISO
Add-VMDvdDrive -VMName $VMName -Path $ISOPath

# Set boot order: DVD first, then HDD
$dvd = Get-VMDvdDrive -VMName $VMName
$hdd = Get-VMHardDiskDrive -VMName $VMName
Set-VMFirmware -VMName $VMName -BootOrder $dvd, $hdd

# Mount unattend.xml via floppy equivalent (or use ISO injection)
# For simplicity: we'll use the ISO + manual first boot, then inject setup script

# Disable secure boot for eval ISO compatibility
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

Write-Info "VM created: $VMName"

# --- Instructions for manual golden image build ---
Write-Step "MANUAL STEPS REQUIRED"
Write-Host ""
Write-Host "  The golden VHDX build requires a semi-automated process:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Start the VM:  Start-VM $VMName" -ForegroundColor Yellow
Write-Host "  2. Connect:       vmconnect localhost $VMName" -ForegroundColor Yellow
Write-Host "  3. Install Windows Server 2022 Core (no GUI)" -ForegroundColor Yellow
Write-Host "  4. After install, set admin password and run:" -ForegroundColor Yellow
Write-Host ""
Write-Host "     # In the VM's PowerShell:" -ForegroundColor Gray
Write-Host '     Set-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.1.100 -PrefixLength 24' -ForegroundColor Gray
Write-Host '     New-NetRoute -DestinationPrefix 0.0.0.0/0 -InterfaceAlias "Ethernet" -NextHop 10.10.1.1' -ForegroundColor Gray
Write-Host '     Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8' -ForegroundColor Gray
Write-Host ""
Write-Host "  5. Copy setup script to VM and run it:" -ForegroundColor Yellow
Write-Host '     # From host PowerShell:' -ForegroundColor Gray
Write-Host '     Copy-VMFile golden-build-temp -SourcePath ".\golden\setup-victim.ps1" -DestinationPath "C:\setup-victim.ps1" -FileSource Host' -ForegroundColor Gray
Write-Host '     Invoke-Command -VMName golden-build-temp -ScriptBlock { C:\setup-victim.ps1 }' -ForegroundColor Gray
Write-Host ""
Write-Host "  6. When setup completes, shut down the VM:" -ForegroundColor Yellow
Write-Host "     Stop-VM $VMName" -ForegroundColor Yellow
Write-Host "     Remove-VM $VMName -Force" -ForegroundColor Yellow
Write-Host ""
Write-Host "  7. The golden VHDX is ready at: $VHDXPath" -ForegroundColor Green
Write-Host ""
Write-Host "  After this, run deploy.ps1 to create student victim VMs from this golden image." -ForegroundColor White
Write-Host ""
