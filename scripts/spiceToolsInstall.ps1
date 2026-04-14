# 1. Security Configuration
# Enable all common protocols to ensure the handshake doesn't fail
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# ... (Sections 2 and 3 remain the same) ...

# 4. Download and Install
if ($hasNetwork) {
    $url  = "https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe"
    $path = "$env:TEMP\spice-guest-tools.exe"

    try {
        Write-Host "Downloading Spice Tools..."
        # Added -UseBasicParsing to bypass IE engine requirement
        Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing -ErrorAction Stop
        
        Write-Host "Starting silent installation..."
        Start-Process -FilePath $path -ArgumentList "/S", "/norestart" -Wait
        Write-Host "Installation complete."
    }
    catch {
        # Fallback: If Invoke-WebRequest fails, try the .NET WebClient method
        try {
            Write-Host "Invoke-WebRequest failed. Attempting WebClient fallback..."
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($url, $path)
            
            Start-Process -FilePath $path -ArgumentList "/S", "/norestart" -Wait
            Write-Host "Installation complete (via WebClient)."
        }
        catch {
            Write-Error "Action failed: $($_.Exception.Message)"
        }
    }
    finally {
        if (Test-Path $path) { Remove-Item $path -Force }
    }
}
