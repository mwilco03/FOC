#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deploy the Threat Hunt CTF Lab.
    Creates 5 Hyper-V victim VMs (from golden VHDX) + Docker Compose stack (ELK, Arkime, CTFd, students).

.NOTES
    Prerequisites:
    - Hyper-V enabled
    - Docker Desktop installed (Linux containers mode)
    - Golden VHDX built (run build-golden.ps1 first)
    - Copy .env.example to .env and customize
#>

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Write-Step($n, $msg) { Write-Host "`n[$n] $msg" -ForegroundColor Cyan }
function Write-Info($msg) { Write-Host "  [+] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "  [X] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║    THREAT HUNT LAB — DEPLOY          ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Cyan

# --- Load .env ---
if (!(Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Warn "Created .env from .env.example — review and customize if needed"
    } else {
        Write-Err "No .env file found"
        exit 1
    }
}
Get-Content ".env" | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
    }
}

$StudentCount = [int]($env:STUDENT_COUNT ?? "5")
$GoldenVHDX = $env:GOLDEN_VHDX_PATH ?? ".\golden\victim-golden.vhdx"
$SwitchName = $env:VM_SWITCH_NAME ?? "LabSwitch"
$VMMemory = [int]($env:VM_MEMORY_MB ?? "1536") * 1MB
$Subnet = $env:VM_SUBNET ?? "10.10.1"

# ===========================================================================
# STEP 1: Prerequisites
# ===========================================================================
Write-Step 1 "Checking prerequisites"

# Hyper-V
$hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
if ($hyperv.State -ne "Enabled") {
    Write-Err "Hyper-V not enabled. Run: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All"
    exit 1
}
Write-Info "Hyper-V enabled"

# Docker
try { docker version | Out-Null } catch {
    Write-Err "Docker not available. Install Docker Desktop."
    exit 1
}
Write-Info "Docker available"

# Golden VHDX
if (!(Test-Path $GoldenVHDX)) {
    Write-Err "Golden VHDX not found at $GoldenVHDX"
    Write-Err "Run build-golden.ps1 first to create it."
    exit 1
}
Write-Info "Golden VHDX: $GoldenVHDX"

# ===========================================================================
# STEP 2: Hyper-V Networking
# ===========================================================================
Write-Step 2 "Configuring Hyper-V network"

$switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if (!$switch) {
    New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
    $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$SwitchName*" }
    New-NetIPAddress -IPAddress "$Subnet.1" -PrefixLength 24 -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue | Out-Null
    New-NetNat -Name "LabNAT" -InternalIPInterfaceAddressPrefix "$Subnet.0/24" -ErrorAction SilentlyContinue | Out-Null
    Write-Info "Created $SwitchName ($Subnet.0/24)"
} else {
    Write-Info "$SwitchName already exists"
}

# ===========================================================================
# STEP 3: Create Victim VMs
# ===========================================================================
Write-Step 3 "Creating victim VMs (differencing disks)"

$vmDir = Join-Path $PSScriptRoot "vm-disks"
if (!(Test-Path $vmDir)) { New-Item -ItemType Directory -Path $vmDir -Force | Out-Null }

for ($i = 1; $i -le $StudentCount; $i++) {
    $vmName = "victim-$i"
    $diffVHDX = Join-Path $vmDir "$vmName.vhdx"

    # Skip if already running
    $existing = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if ($existing -and $existing.State -eq "Running") {
        Write-Info "$vmName already running"
        continue
    }

    # Remove stale VM
    if ($existing) {
        Stop-VM -Name $vmName -Force -ErrorAction SilentlyContinue
        Remove-VM -Name $vmName -Force
    }

    # Create differencing disk
    if (Test-Path $diffVHDX) { Remove-Item $diffVHDX -Force }
    New-VHD -ParentPath (Resolve-Path $GoldenVHDX).Path -Path $diffVHDX -Differencing | Out-Null

    # Create VM
    New-VM -Name $vmName -MemoryStartupBytes $VMMemory -VHDPath $diffVHDX -SwitchName $SwitchName -Generation 2 | Out-Null
    Set-VMFirmware -VMName $vmName -EnableSecureBoot Off
    Start-VM -Name $vmName

    Write-Info "$vmName created ($Subnet.$($i + 10)) — booting..."
}

# ===========================================================================
# STEP 4: Wait for VMs
# ===========================================================================
Write-Step 4 "Waiting for VMs to boot and accept WinRM"

for ($i = 1; $i -le $StudentCount; $i++) {
    $vmName = "victim-$i"
    $vmIP = "$Subnet.$($i + 10)"

    Write-Host "  Waiting for $vmName ($vmIP)..." -NoNewline
    $ready = $false
    for ($attempt = 1; $attempt -le 60; $attempt++) {
        try {
            Test-WSMan -ComputerName $vmIP -ErrorAction Stop | Out-Null
            $ready = $true
            break
        } catch {
            Start-Sleep -Seconds 3
            if ($attempt % 10 -eq 0) { Write-Host "." -NoNewline }
        }
    }
    if ($ready) {
        Write-Host " ready" -ForegroundColor Green
    } else {
        Write-Host " TIMEOUT" -ForegroundColor Red
        Write-Warn "$vmName not responding on WinRM. It may still be booting."
    }
}

# ===========================================================================
# STEP 5: Port Forwarding
# ===========================================================================
Write-Step 5 "Configuring port forwarding (host → VMs)"

for ($i = 1; $i -le $StudentCount; $i++) {
    $hostPort = 59850 + $i
    $vmIP = "$Subnet.$($i + 10)"

    # Remove existing portproxy rule
    netsh interface portproxy delete v4tov4 listenport=$hostPort listenaddress=0.0.0.0 2>$null

    # Add portproxy: host:59851 → VM:5985
    netsh interface portproxy add v4tov4 listenport=$hostPort listenaddress=0.0.0.0 connectport=5985 connectaddress=$vmIP | Out-Null

    Write-Info "Port $hostPort → $vmIP`:5985 (victim-$i)"
}

# Firewall rule for WinRM forwarding
New-NetFirewallRule -DisplayName "ThreatHuntLab-WinRM" -Direction Inbound -Protocol TCP -LocalPort 59851-59855 -Action Allow -ErrorAction SilentlyContinue | Out-Null

# ===========================================================================
# STEP 6: Docker Compose
# ===========================================================================
Write-Step 6 "Starting Docker Compose stack (ELK, Arkime, CTFd, students)"

docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Err "docker compose up failed"
    exit 1
}

# ===========================================================================
# STEP 7: Wait for ELK
# ===========================================================================
Write-Step 7 "Waiting for Elasticsearch"

$elkReady = $false
for ($i = 1; $i -le 60; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:9200/_cluster/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200) { $elkReady = $true; break }
    } catch {}
    Start-Sleep -Seconds 3
    if ($i % 10 -eq 0) { Write-Host "  Still waiting... ($($i * 3)s)" -ForegroundColor Gray }
}
if ($elkReady) { Write-Info "Elasticsearch ready" }
else { Write-Warn "Elasticsearch may still be starting" }

# ===========================================================================
# STEP 8: CTFd Setup
# ===========================================================================
Write-Step 8 "Configuring CTFd"

$gitBash = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $gitBash) {
    & $gitBash --login -c "cd '$($PSScriptRoot -replace '\\','/')' && bash ctfd/setup.sh http://localhost:8000"
} else {
    Write-Warn "Git bash not found. Run manually: bash ctfd/setup.sh http://localhost:8000"
}

# ===========================================================================
# SUMMARY
# ===========================================================================
$hostIP = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch "Loopback|vEthernet|WSL|Docker" -and $_.PrefixOrigin -match "Dhcp|Manual" } |
    Select-Object -First 1).IPAddress
if (-not $hostIP) { $hostIP = "localhost" }

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  THREAT HUNT LAB IS READY" -ForegroundColor Green
Write-Host ""
Write-Host "  STUDENTS" -ForegroundColor Cyan
Write-Host "  Terminal:     http://${hostIP}" -ForegroundColor White
Write-Host "  Kibana:       http://${hostIP}:5601" -ForegroundColor White
Write-Host "  Arkime:       http://${hostIP}:8005" -ForegroundColor White
Write-Host "  CTFd:         http://${hostIP}:8000" -ForegroundColor White
Write-Host "  Slides:       http://${hostIP}:8888/slides" -ForegroundColor White
Write-Host ""
Write-Host "  INSTRUCTOR" -ForegroundColor Cyan
Write-Host "  CTFd Admin:   http://${hostIP}:8000/admin  (admin / ThreatHuntLab2024!)" -ForegroundColor White
Write-Host "  Solutions:    http://${hostIP}:8888/solutions  (instructor / instructor2024)" -ForegroundColor White
Write-Host "  ES Health:    http://${hostIP}:9200/_cluster/health" -ForegroundColor White
Write-Host ""
Write-Host "  VICTIM VMs" -ForegroundColor Cyan
for ($i = 1; $i -le $StudentCount; $i++) {
    Write-Host "  victim-$i`:     PS Remote port $($59850 + $i)  ($Subnet.$($i + 10))" -ForegroundColor White
}
Write-Host ""
Write-Host "  Teardown:     .\teardown.ps1" -ForegroundColor White
Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
