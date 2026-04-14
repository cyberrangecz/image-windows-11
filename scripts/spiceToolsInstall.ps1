$ProgressPreference = 'SilentlyContinue'

# 1. Security Configuration
# Force TLS 1.2 and bypass SSL certificate validation for restricted environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# 2. Import Red Hat Certificate
certutil -f -AddStore "TrustedPublisher" "A:\redhat.cer"

# 3. Network Wait Loop (Approx. 3 minutes max)
Write-Host "Waiting for network connectivity..."
$hasNetwork = $false
for ($i = 1; $i -le 40; $i++) {
    if (Test-Connection -ComputerName google.com -Count 1 -Quiet) {
        $hasNetwork = $true
        Write-Host "Connected."
        break
    }
    Write-Host "Attempt $i/40: No connection. Retrying in 5s..."
    Start-Sleep -Seconds 5
}

# 4. Download and Install
if ($hasNetwork) {
    $url  = "https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe"
    $path = "$env:TEMP\spice-guest-tools.exe"

    try {
        Write-Host "Downloading Spice Tools..."
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $path)
        
        Write-Host "Starting silent installation..."
        # /S = Silent, /norestart = Prevent unexpected reboots during unattend
        Start-Process -FilePath $path -ArgumentList "/S", "/norestart" -Wait
        Write-Host "Installation complete."
    }
    catch {
        Write-Error "Action failed: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path $path) { Remove-Item $path -Force }
    }
}
else {
    Write-Error "Network timeout. Spice Tools installation skipped."
}
