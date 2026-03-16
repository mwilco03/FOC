# =============================================================================
# Nmap Training Lab - Windows Teardown
# =============================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "[-] Run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "  This will:" -ForegroundColor Yellow
Write-Host "    - Stop all 27 containers" -ForegroundColor Yellow
Write-Host "    - Remove all containers and networks" -ForegroundColor Yellow
Write-Host "    - Delete CTFd database volume (scores, accounts)" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Type YES to confirm"
if ($confirm -eq "YES") {
    docker compose down -v
    Write-Host "[+] Lab torn down." -ForegroundColor Green
} else {
    Write-Host "[-] Cancelled." -ForegroundColor Yellow
}

Read-Host "Press Enter to close"
