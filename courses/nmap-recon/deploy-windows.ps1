# =============================================================================
# deploy-windows.ps1 — Deploy nmap training lab on Windows via Docker Desktop
#
# Idempotent: safe to run multiple times. Use --clean for a fresh start.
# NO WSL required — Docker Desktop runs Linux containers natively.
#
# Usage:
#   .\deploy-windows.ps1            # Build and deploy (or update)
#   .\deploy-windows.ps1 --clean    # Tear down first, then deploy fresh
# =============================================================================

$ErrorActionPreference = "Stop"

# =============================================================================
# Constants
# =============================================================================

# Service ports (must match docker-compose.yml)
$PORT_TRAEFIK_WEB         = 80
$PORT_TRAEFIK_DASHBOARD   = 8080
$PORT_CTFD                = 8000
$PORT_LAB_CONTROLLER      = 8888
$PORT_STUDENT_DIRECT_BASE = 4201
$PORT_STUDENT_DIRECT_END  = 4210

# Retry/timeout tuning
$DOCKER_WAIT_ATTEMPTS     = 60
$DOCKER_WAIT_INTERVAL     = 2
$CTFD_WAIT_ATTEMPTS       = 60
$CTFD_WAIT_INTERVAL       = 2

# Docker Desktop paths (standard install locations)
$DOCKER_DESKTOP_PATHS = @(
    "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
    "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe",
    "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
)

# Git Bash paths (for running ctfd/setup.sh)
$GIT_BASH_PATHS = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
)

# Expected container count from docker-compose.yml
$EXPECTED_CONTAINERS      = 28

# =============================================================================
# Output helpers
# =============================================================================
function Write-Ok($msg)   { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[-] $msg" -ForegroundColor Red }
function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

# =============================================================================
# Utility: find first existing path from a list
# =============================================================================
function Find-FirstPath($paths) {
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

# =============================================================================
# Utility: retry a test block up to N times
# Complexity: O(attempts) — linear retry with early exit
# =============================================================================
function Retry-Until {
    param(
        [int]$Attempts,
        [int]$IntervalSec,
        [scriptblock]$Test
    )
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            if (& $Test) { return $true }
        } catch {}
        Start-Sleep -Seconds $IntervalSec
        if ($i % 10 -eq 0) {
            Write-Host "  Still waiting... ($($i * $IntervalSec)s)" -ForegroundColor Gray
        }
    }
    return $false
}

# =============================================================================
# Pre-flight: Docker Desktop
# =============================================================================
Write-Step "Checking Docker Desktop"

$hasDocker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $hasDocker) {
    Write-Err "Docker Desktop is not installed."
    Write-Err "Download from: https://www.docker.com/products/docker-desktop/"
    Write-Err "After installing, restart your terminal and run this script again."
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Docker daemon is running; if not, try to start Docker Desktop
$dockerRunning = $false
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
} catch {}

if (-not $dockerRunning) {
    $dockerExe = Find-FirstPath $DOCKER_DESKTOP_PATHS
    if ($dockerExe) {
        Write-Warn "Docker daemon not running. Starting Docker Desktop..."
        Start-Process $dockerExe -ErrorAction SilentlyContinue
    } else {
        Write-Warn "Docker daemon not running. Open Docker Desktop manually."
    }

    $dockerRunning = Retry-Until -Attempts $DOCKER_WAIT_ATTEMPTS `
                                 -IntervalSec $DOCKER_WAIT_INTERVAL `
                                 -Test { docker info 2>&1 | Out-Null; $LASTEXITCODE -eq 0 }

    if (-not $dockerRunning) {
        Write-Err "Docker did not start after $($DOCKER_WAIT_ATTEMPTS * $DOCKER_WAIT_INTERVAL) seconds."
        Write-Err "Open Docker Desktop, wait for startup, then run this script again."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Verify docker compose plugin
try {
    docker compose version 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "compose missing" }
} catch {
    Write-Err "Docker Compose plugin not found. Update Docker Desktop to the latest version."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Ok "Docker Desktop is running"

# =============================================================================
# Check for Git Bash (needed to run ctfd/setup.sh)
# =============================================================================
$gitBash = Find-FirstPath $GIT_BASH_PATHS
$hasGit = Get-Command git -ErrorAction SilentlyContinue

if (-not $gitBash -and -not $hasGit) {
    Write-Warn "Git is not installed. It is needed to run the CTFd setup script."
    Write-Warn "Download from: https://git-scm.com/download/win"
    Write-Warn "After installing Git, run this script again."
}

# =============================================================================
# Handle --clean flag (idempotent teardown)
# =============================================================================
Set-Location $PSScriptRoot

if ($args -contains "--clean") {
    Write-Step "Clean deploy - tearing down existing lab"
    docker compose down -v 2>$null
}

# =============================================================================
# Create .env if missing
# =============================================================================
if (-not (Test-Path ".env")) {
    Write-Ok "Creating .env from .env.example..."
    Copy-Item ".env.example" ".env"
}

# =============================================================================
# Build and start
# =============================================================================
Write-Step "Building and starting containers"
Write-Ok "First run downloads ~4GB of images — this may take several minutes..."

docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Err "docker compose up failed. Check the output above."
    Read-Host "Press Enter to exit"
    exit 1
}

# =============================================================================
# Wait for CTFd
# =============================================================================
Write-Step "Waiting for CTFd"

$ctfdReady = Retry-Until -Attempts $CTFD_WAIT_ATTEMPTS `
                          -IntervalSec $CTFD_WAIT_INTERVAL `
                          -Test {
                              $r = Invoke-WebRequest -Uri "http://localhost:$PORT_CTFD" `
                                   -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
                              $r.StatusCode -eq 200 -or $r.StatusCode -eq 302
                          }

if (-not $ctfdReady) {
    Write-Err "CTFd did not respond after $($CTFD_WAIT_ATTEMPTS * $CTFD_WAIT_INTERVAL) seconds."
    Write-Warn "Check status: docker compose ps"
    Write-Warn "Once ready, run: bash ctfd/setup.sh http://localhost:$PORT_CTFD"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Ok "CTFd is up"

# =============================================================================
# Seed CTFd challenges via Git Bash
# =============================================================================
Write-Step "Configuring CTFd (admin, teams, challenges, theme)"

$setupRan = $false

# Git Bash is required to run ctfd/setup.sh (bash script with curl/jq)
$gitBash = Find-FirstPath $GIT_BASH_PATHS
if ($gitBash) {
    Write-Ok "Found Git Bash at: $gitBash"
    $unixPath = ($PSScriptRoot -replace '\\','/').TrimEnd('/')
    & $gitBash --login -c "cd '$unixPath' && bash ctfd/setup.sh http://localhost:$PORT_CTFD"
    if ($LASTEXITCODE -eq 0) {
        $setupRan = $true
    } else {
        Write-Err "CTFd setup script failed (exit code $LASTEXITCODE)"
        Write-Warn "Check the output above for errors. You can re-run manually:"
        Write-Warn "  & '$gitBash' --login -c `"cd '$unixPath' && bash ctfd/setup.sh`""
    }
} else {
    Write-Err "Git Bash NOT FOUND — cannot run CTFd setup script."
    Write-Err ""
    Write-Err "  The CTFd setup script requires bash. Install Git for Windows:"
    Write-Err "    1. Download from: https://git-scm.com/download/win"
    Write-Err "    2. Run the installer (default options are fine)"
    Write-Err "    3. Close and reopen PowerShell"
    Write-Err "    4. Re-run this script: .\deploy-windows.ps1"
    Write-Err ""
    Write-Err "  Alternatively, install via winget:"
    Write-Err "    winget install Git.Git"
    Write-Err ""
    Write-Warn "Containers are running but CTFd has NO challenges or users."
    Write-Warn "The lab is NOT usable until setup completes."
}

# =============================================================================
# Verify deployment
# =============================================================================
Write-Step "Verifying deployment"
Start-Sleep -Seconds 5

$failures = 0

# Declarative HTTP checks: label -> URL
$serviceChecks = @{
    "Student terminals (port $PORT_TRAEFIK_WEB)"           = "http://localhost:$PORT_TRAEFIK_WEB"
    "CTFd scoreboard (port $PORT_CTFD)"                    = "http://localhost:$PORT_CTFD"
    "Lab controller (port $PORT_LAB_CONTROLLER)"           = "http://localhost:$PORT_LAB_CONTROLLER"
    "Direct student-1 (port $PORT_STUDENT_DIRECT_BASE)"    = "http://localhost:$PORT_STUDENT_DIRECT_BASE"
}

foreach ($entry in $serviceChecks.GetEnumerator()) {
    try {
        $r = Invoke-WebRequest -Uri $entry.Value -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($r.StatusCode -eq 200) {
            Write-Ok "$($entry.Key): OK"
        } else {
            Write-Err "$($entry.Key): HTTP $($r.StatusCode)"
            $failures++
        }
    } catch {
        Write-Err "$($entry.Key): FAIL"
        $failures++
    }
}

# Container count
$running = (docker compose ps -q 2>$null | Measure-Object -Line).Lines
if ($running -ge $EXPECTED_CONTAINERS) {
    Write-Ok "Running containers: $running/$EXPECTED_CONTAINERS"
} else {
    Write-Err "Only $running/$EXPECTED_CONTAINERS containers running"
    $failures++
}

# =============================================================================
# Detect host IP (skip loopback, Docker, and virtual adapters)
# =============================================================================
$hostIP = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.InterfaceAlias -notmatch "Loopback|vEthernet|WSL|Docker" -and
        $_.PrefixOrigin -match "Dhcp|Manual"
    } |
    Select-Object -First 1).IPAddress
if (-not $hostIP) { $hostIP = "localhost" }

# =============================================================================
# Summary
# =============================================================================
Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
if ($failures -eq 0) {
    Write-Host "  DEPLOYMENT SUCCESSFUL - all checks passed" -ForegroundColor Green
} else {
    Write-Host "  DEPLOYMENT COMPLETE - $failures check(s) failed" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  Student Terminal:   http://${hostIP}:${PORT_TRAEFIK_WEB}" -ForegroundColor White
Write-Host "  Direct Terminals:   http://${hostIP}:${PORT_STUDENT_DIRECT_BASE} - ${PORT_STUDENT_DIRECT_END}" -ForegroundColor White
Write-Host "  CTFd Scoreboard:    http://${hostIP}:${PORT_CTFD}" -ForegroundColor White
Write-Host "  Lab Controller:     http://${hostIP}:${PORT_LAB_CONTROLLER}" -ForegroundColor White
Write-Host "  Traefik Dashboard:  http://${hostIP}:${PORT_TRAEFIK_DASHBOARD}" -ForegroundColor White
Write-Host ""
Write-Host "  Credentials:        see .env and ctfd\credentials.txt" -ForegroundColor White
Write-Host "  Teardown:           .\deploy-windows.ps1 --clean" -ForegroundColor White
Write-Host ""
Write-Host "  NOTE: UDP scanning (nmap -sU) may be unreliable on Docker" -ForegroundColor Yellow
Write-Host "  Desktop due to its user-space network stack. SYN and TCP" -ForegroundColor Yellow
Write-Host "  connect scans work correctly." -ForegroundColor Yellow
Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to close"
