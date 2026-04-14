# Clear temp folders, etc.
$folders = 'C:\temp', 'C:\Windows.old'
Remove-Item -Path $folders -Recurse -Force -ErrorAction SilentlyContinue

Get-ChildItem -Path 'C:\Windows\temp' -Recurse | Remove-Item -Force -Recurse
