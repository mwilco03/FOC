#Requires -RunAsAdministrator
$ErrorActionPreference = "SilentlyContinue"
Set-Location $PSScriptRoot

Write-Host "Tearing down Threat Hunt Lab..." -ForegroundColor Yellow

# Stop and remove VMs
Get-VM -Name "victim-*" | Stop-VM -Force
Get-VM -Name "victim-*" | Remove-VM -Force
Remove-Item ".\vm-disks\*.vhdx" -Force

# Remove port forwarding
1..5 | ForEach-Object {
    netsh interface portproxy delete v4tov4 listenport=$($_ + 59850) listenaddress=0.0.0.0 2>$null
}

# Remove firewall rule
Remove-NetFirewallRule -DisplayName "ThreatHuntLab-WinRM" -ErrorAction SilentlyContinue

# Docker down
docker compose down -v

Write-Host "Lab torn down." -ForegroundColor Green
