# Clear temp folders
Get-ChildItem -Path 'C:\temp\' -Recurse | Remove-Item -Force -Recurse
Get-ChildItem -Path 'C:\Windows\temp' -Recurse | Remove-Item -Force -Recurse
