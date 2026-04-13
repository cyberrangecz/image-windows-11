certutil -f -AddStore "TrustedPublisher" "a:\redhat.cer"

# 1. Wait for Network Connectivity (Extended for slower VM boots)
$maxRetries = 40
$retryCount = 0
$connected = $false

Write-Host "Waiting for network..."
while ($retryCount -lt $maxRetries) {
    if (Test-Connection -ComputerName google.com -Count 1 -Quiet) {
        $connected = $true
        Write-Host "Connected!"
        break
    }
    Write-Host "Still waiting... ($($retryCount + 1)/$maxRetries)"
    Start-Sleep -Seconds 5
    $retryCount++
}

if ($connected) {
    # 2. Download and Install
    $url = "https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe"
    $dest = "$env:TEMP\spice-guest-tools.exe"

    Write-Host "Downloading Spice Tools..."
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -ErrorAction Stop
        
        if (Test-Path $dest) {
            Write-Host "Installing..."
            # Using /S for silent and /norestart to prevent the VM from 
            # rebooting before the unattend process finishes.
            Start-Process -FilePath $dest -ArgumentList "/S", "/norestart" -Wait
            Write-Host "Installation finished."
        }
    } catch {
        Write-Error "Download failed: $($_.Exception.Message)"
    }
} else {
    Write-Error "No internet connection detected. Skipping Spice Tools install."
}

# 3. Cleanup
if (Test-Path $dest) { Remove-Item $dest -Force }
