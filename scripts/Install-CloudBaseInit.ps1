# Check if C:\temp exists
if(!(Test-Path -Path "C:\temp"))
{
    New-Item -Path c:\ -Name temp -ItemType Directory
}

# Download CloudbaseInitSetup_Stable_x64
(New-Object System.Net.WebClient).DownloadFile('https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi','C:\temp\CloudbaseInitSetup_Stable_x64.msi')

# Start Install CloudbaseInitSetup_Stable_x64

Start-Process msiexec -ArgumentList '/i "C:\temp\CloudbaseInitSetup_Stable_x64.msi" /qb /norestart /l*v "c:\temp\install.log" USERNAME="windows" USERGROUPS="Administrators" INJECTMETADATAPASSWORD="TRUE" LOGGINGSERIALPORTNAME="COM1"' -Wait -PassThru

# Don't require changing password on first logon, disable winrm basic auth and http listener
Add-Content "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" '
first_logon_behaviour=no
activate_windows=true
real_time_clock_utc=false
ntp_enable_service=true
ntp_use_dhcp_config=false
plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin, cloudbaseinit.plugins.windows.ntpclient.NTPClientPlugin, cloudbaseinit.plugins.windows.createuser.CreateUserPlugin, cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin, cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin, cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin, cloudbaseinit.plugins.common.sshpublickeys.SetUserSSHPublicKeysPlugin, cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin, cloudbaseinit.plugins.common.userdata.UserDataPlugin, cloudbaseinit.plugins.windows.licensing.WindowsLicensingPlugin
metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService, cloudbaseinit.metadata.services.httpservice.HttpService
'

# Set registry key so SetUserPasswordPlugin doesn't run on reboot even if it fails
New-Item -Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts" -Name "SetUserPasswordPlugin-fix.ps1" -ItemType "file" -Value '
$p = reg query "HKLM\SOFTWARE\Cloudbase Solutions\Cloudbase-Init"
reg add "$p\Plugins" /v SetUserPasswordPlugin /t REG_DWORD /d 1 /f
'

New-Item -Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts" -Name "time.ps1" -ItemType "file" -Value '
# Allow large time corrections (up to 12 hours)
w32tm /config /update /maxposphasecorrection:43200 /maxnegphasecorrection:43200
'
Set-Service -Name "cloudbase-init" -StartupType Automatic
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\cloudbase-init" -Name "DelayedAutostart" -Value 1

Write-Host "Cloudbase-Init setup done!"
