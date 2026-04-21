$ErrorActionPreference = "Stop"

# 1. Install OpenSSH Server
Write-Host "Checking OpenSSH Server status..."
$sshCap = Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

if ($sshCap.State -ne 'Installed') {
    Write-Host "Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
    Write-Host "Installation complete."
} else {
    Write-Host "OpenSSH Server is already installed."
}

# 2. Configure Service Startup
Write-Host "Configuring sshd service to Automatic..."
Set-Service -Name sshd -StartupType 'Automatic'

# 3. Initial Start (Required to generate the default sshd_config file)
Write-Host "Starting sshd service to generate default config..."
Start-Service sshd

# 4. Configure Firewall (Delete and Recreate)
Write-Host "Configuring Windows Firewall for SSH (Port 22)..."
$ruleName = 'OpenSSH-Server-In-TCP'

if (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue) {
    Write-Host "Existing rule found. Deleting..."
    Remove-NetFirewallRule -Name $ruleName
}

Write-Host "Creating fresh firewall rule..."
New-NetFirewallRule -Name $ruleName -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any | Out-Null

# 5. Harden sshd_config
Write-Host "Configuring sshd_config (Enabling PubKey, Disabling Password Auth)..."
$configPath = "C:\ProgramData\ssh\sshd_config"

# Brief pause to ensure the service had time to generate the file on a fresh install
if (-not (Test-Path $configPath)) {
    Start-Sleep -Seconds 2
}

if (Test-Path $configPath) {
    $config = Get-Content -Path $configPath -Raw

    # Use Regex (?m) multiline mode to catch lines securely regardless of current state
    $config = $config -replace '(?m)^#?PubkeyAuthentication\s+.*', 'PubkeyAuthentication yes'
    $config = $config -replace '(?m)^#?PasswordAuthentication\s+.*', 'PasswordAuthentication no'
    $config = $config -replace '(?m)^Match Group administrators', '#Match Group administrators'
    $config = $config -replace '(?m)^AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys', '#AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys'

    $config | Set-Content -Path $configPath
    Write-Host "Config updated successfully."
} else {
    Write-Host "WARNING: sshd_config not found at $configPath."
}

# 6. Restart Service to apply config changes
Write-Host "Restarting sshd service to apply new configuration..."
Restart-Service sshd

# force file creation
New-item -Path $env:USERPROFILE -Name .ssh -ItemType Directory -force

# Copy key
Write-Output "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" | Out-File $env:USERPROFILE\.ssh\authorized_keys -Encoding ascii

Write-Host "OpenSSH Server setup complete!"
