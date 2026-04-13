certutil -f -AddStore "TrustedPublisher" "a:\redhat.cer"

# 1. Wait for Network Connectivity
$maxRetries = 30
$retryCount = 0
Write-Host "Waiting for internet connection..."

while ($retryCount -lt $maxRetries) {
    try {
        $result = Invoke-WebRequest -Uri "https://www.google.com" -Method Head -TimeoutSec 5 -ErrorAction Stop
        if ($result.StatusCode -eq 200) {
            Write-Host "Connected!"; break
        }
    } catch {
        Write-Host "Still waiting for network... ($($retryCount + 1)/$maxRetries)"
        Start-Sleep -Seconds 3
        $retryCount++
    }
}

# 2. Download and Install
$url = "https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe"
$dest = "$env:TEMP\spice-guest-tools.exe"

Write-Host "Downloading Spice Tools..."
$ProgressPreference = 'SilentlyContinue' # Speeds up download
Invoke-WebRequest -Uri $url -OutFile $dest

Write-Host "Installing..."
Start-Process -FilePath $dest -ArgumentList "/S" -Wait

# 3. Cleanup
Remove-Item $dest
