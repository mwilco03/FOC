# =============================================================================
# Nmap Training Lab - Windows Deploy Script
# Run from PowerShell (Admin): .\deploy.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

function Write-Info($msg)    { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)     { Write-Host "[-] $msg" -ForegroundColor Red }
function Write-Step($msg)    { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

# ---------------------------------------------------------------------------
# Must be admin
# ---------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Err "This script must be run as Administrator."
    Write-Err "Right-click PowerShell > 'Run as Administrator', then try again."
    Read-Host "Press Enter to exit"
    exit 1
}

# ---------------------------------------------------------------------------
# Check and install prerequisites
# ---------------------------------------------------------------------------
Write-Step "Checking prerequisites"

# --- winget ---
$hasWinget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $hasWinget) {
    Write-Err "winget is not available. Install 'App Installer' from the Microsoft Store."
    Write-Err "https://aka.ms/getwinget"
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Docker Desktop ---
$hasDocker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $hasDocker) {
    Write-Warn "Docker Desktop is not installed."
    $install = Read-Host "Install Docker Desktop now? (Y/n)"
    if ($install -eq "" -or $install -match "^[Yy]") {
        Write-Info "Installing Docker Desktop via winget..."
        winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Docker Desktop installation failed."
            Read-Host "Press Enter to exit"
            exit 1
        }
        Write-Warn "Docker Desktop installed. A RESTART may be required for Hyper-V/WSL2."
        $restart = Read-Host "Restart now? (Y/n)"
        if ($restart -eq "" -or $restart -match "^[Yy]") {
            Restart-Computer -Force
        }
        Write-Warn "After restart, run this script again."
        Read-Host "Press Enter to exit"
        exit 0
    } else {
        Write-Err "Docker Desktop is required. Cannot continue."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# --- Docker daemon running? ---
$dockerRunning = $false
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
} catch {}

if (-not $dockerRunning) {
    Write-Warn "Docker daemon is not running. Starting Docker Desktop..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
    Write-Info "Waiting for Docker to start (up to 120 seconds)..."
    for ($i = 1; $i -le 60; $i++) {
        Start-Sleep -Seconds 2
        try {
            docker info 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $dockerRunning = $true
                break
            }
        } catch {}
        if ($i % 10 -eq 0) { Write-Host "  Still waiting... ($($i * 2)s)" -ForegroundColor Gray }
    }
    if (-not $dockerRunning) {
        Write-Err "Docker failed to start after 120 seconds."
        Write-Err "Open Docker Desktop manually, wait for it to finish starting, then run this script again."
        Read-Host "Press Enter to exit"
        exit 1
    }
}
Write-Info "Docker is running"

# --- docker compose ---
try {
    docker compose version 2>&1 | Out-Null
} catch {
    Write-Err "docker compose not found. Update Docker Desktop to the latest version."
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Git Bash (for setup.sh) ---
$gitBash = "C:\Program Files\Git\bin\bash.exe"
$hasGitBash = Test-Path $gitBash
$hasWSL = Get-Command wsl -ErrorAction SilentlyContinue

if (-not $hasGitBash -and -not $hasWSL) {
    Write-Warn "Neither Git Bash nor WSL found. Git Bash is needed to run the CTFd setup script."
    $install = Read-Host "Install Git for Windows now? (Y/n)"
    if ($install -eq "" -or $install -match "^[Yy]") {
        Write-Info "Installing Git for Windows via winget..."
        winget install Git.Git --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Git installation failed."
            Read-Host "Press Enter to exit"
            exit 1
        }
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $hasGitBash = Test-Path $gitBash
        if (-not $hasGitBash) {
            Write-Warn "Git installed but bash not found at expected path."
            Write-Warn "You may need to close and reopen PowerShell, then run this script again."
            Read-Host "Press Enter to exit"
            exit 1
        }
        Write-Info "Git for Windows installed"
    } else {
        Write-Warn "Continuing without bash. CTFd setup will need to be run manually."
    }
}

Write-Info "All prerequisites met"

# ---------------------------------------------------------------------------
# Clean slate if requested
# ---------------------------------------------------------------------------
if ($args -contains "--clean") {
    Write-Step "Clean deploy - tearing down existing lab"
    docker compose down -v 2>$null
}

# ---------------------------------------------------------------------------
# Build and start
# ---------------------------------------------------------------------------
Set-Location $PSScriptRoot

Write-Step "Building and starting containers"
Write-Info "This may take 5-10 minutes on first run (downloading images + building)..."
docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Err "docker compose up failed. Check the output above for errors."
    Read-Host "Press Enter to exit"
    exit 1
}

# ---------------------------------------------------------------------------
# Wait for CTFd
# ---------------------------------------------------------------------------
Write-Step "Waiting for CTFd"
$ctfdReady = $false
for ($i = 1; $i -le 60; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:8000" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200 -or $resp.StatusCode -eq 302) {
            $ctfdReady = $true
            break
        }
    } catch {}
    Start-Sleep -Seconds 2
    if ($i % 10 -eq 0) { Write-Host "  Still waiting... ($($i * 2)s)" -ForegroundColor Gray }
}

if (-not $ctfdReady) {
    Write-Err "CTFd didn't respond after 120 seconds."
    Write-Warn "Containers may still be starting. Check: docker compose ps"
    Write-Warn "Once CTFd is up, run manually: bash ctfd/setup.sh http://localhost:8000"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Info "CTFd is up"

# ---------------------------------------------------------------------------
# Run CTFd setup
# ---------------------------------------------------------------------------
Write-Step "Configuring CTFd (admin, teams, challenges, theme)"

$setupScript = Join-Path $PSScriptRoot "ctfd/setup.sh"
$projectUnix = ($PSScriptRoot -replace '\\','/') -replace '^([A-Z]):','/$1'.ToLower()

if (Test-Path $gitBash) {
    & $gitBash --login -c "cd '$($PSScriptRoot -replace '\\','/')' && bash ctfd/setup.sh http://localhost:8000"
} elseif ($hasWSL) {
    $wslPath = ($PSScriptRoot -replace '\\','/') -replace '^([A-Z]):',{ "/mnt/" + $_.Groups[1].Value.ToLower() }
    wsl bash -c "cd '$wslPath' && bash ctfd/setup.sh http://localhost:8000"
} else {
    Write-Warn "No bash interpreter found. CTFd setup skipped."
    Write-Warn "Install Git for Windows, then run: bash ctfd/setup.sh http://localhost:8000"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$hostIP = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch "Loopback|vEthernet|WSL|Docker" -and $_.PrefixOrigin -match "Dhcp|Manual" } |
    Select-Object -First 1).IPAddress
if (-not $hostIP) { $hostIP = "localhost" }

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
docker compose ps --format "table {{.Name}}\t{{.Status}}"
Write-Host ""
Write-Host "  LAB IS READY" -ForegroundColor Green
Write-Host ""
Write-Host "  STUDENTS" -ForegroundColor Cyan
Write-Host "  Terminal:           http://${hostIP}" -ForegroundColor White
Write-Host "  Direct Access:      http://${hostIP}:4201 through :4210" -ForegroundColor White
Write-Host "  CTFd Scoreboard:    http://${hostIP}:8000" -ForegroundColor White
Write-Host "  Slides:             http://${hostIP}:8888/slides" -ForegroundColor White
Write-Host ""
Write-Host "  INSTRUCTOR" -ForegroundColor Cyan
Write-Host "  CTFd Admin:         http://${hostIP}:8000/admin  (admin / NmapLab2024!)" -ForegroundColor White
Write-Host "  Solution Guide:     http://${hostIP}:8888/solutions  (instructor / instructor2024)" -ForegroundColor White
Write-Host "  Manual Unlock:      http://${hostIP}:8888/api/unlock/Host%20Discovery" -ForegroundColor White
Write-Host ""
Write-Host "  Challenges start LOCKED. The lab-controller auto-unlocks" -ForegroundColor Gray
Write-Host "  categories as students complete the previous one (50% threshold)." -ForegroundColor Gray
Write-Host "  Knowledge Check is available immediately during the lecture." -ForegroundColor Gray
Write-Host ""
Write-Host "  Credentials:        ctfd\credentials.txt" -ForegroundColor White
Write-Host "  Teardown:           .\teardown.ps1" -ForegroundColor White
Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to close"
