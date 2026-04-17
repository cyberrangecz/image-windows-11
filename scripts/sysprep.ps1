# Check if C:\temp exists
if(!(Test-Path -Path "C:\temp"))
{
    New-Item -Path c:\ -Name temp -ItemType Directory
}

# Check if cloudbase-init is installed
if (Test-Path -Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf") {
    cd "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf"
} else {
    cd "C:\temp"
    New-Item -Path c:\temp\ -Name Unattend.xml -ItemType File
    Set-Content C:\temp\Unattend.xml '
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <ProtectYourPC>1</ProtectYourPC>
      </OOBE>
    </component>
  </settings>
</unattend>
'
}

Start-Process -FilePath "C:\Windows\System32\sysprep\sysprep.exe" -ArgumentList '/generalize /oobe /unattend:Unattend.xml /quit' -Wait

Remove-Item -Path 'C:\temp' -Recurse -Force -ErrorAction SilentlyContinue
