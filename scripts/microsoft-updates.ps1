$ErrorActionPreference = "Stop"

Write-Host "Stopping Windows Update and Orchestrator Services..."
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name UsoSvc -Force -ErrorAction SilentlyContinue

# Define standard and policy registry paths
$auPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
$polAuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

# Ensure the paths actually exist before trying to write to them
if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
if (-not (Test-Path $polAuPath)) { New-Item -Path $polAuPath -Force | Out-Null }

Write-Host "Applying Windows Update Registry Keys..."

# Standard Auto Update settings
Set-ItemProperty -Path $auPath -Name "EnableFeaturedSoftware" -Value 1 -Type DWord
Set-ItemProperty -Path $auPath -Name "IncludeRecommendedUpdates" -Value 1 -Type DWord
Set-ItemProperty -Path $auPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord
Set-ItemProperty -Path $auPath -Name "RebootRelaunchTimeoutEnabled" -Value 0 -Type DWord

# Policy Auto Update settings
Set-ItemProperty -Path $polAuPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord

# 0: Automatic Updates is enabled (default)
# 1: Automatic Updates is disabled
Set-ItemProperty -Path $polAuPath -Name "NoAutoUpdate" -Value 1 -Type DWord

Write-Host "Starting Windows Update and Orchestrator Services..."
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
Start-Service -Name UsoSvc -ErrorAction SilentlyContinue

Write-Host "Windows Update configuration complete!"
