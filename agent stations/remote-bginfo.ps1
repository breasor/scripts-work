#!ps1
#timeout=90000
$VerbosePreference = "continue"
Import-Module BitsTransfer

$bgInfoFolder = "C:\BgInfo"
$bgInfoUrl = "https://download.sysinternals.com/files/BGInfo.zip"
$logonBgiUrl = "https://ansastatic.blob.core.windows.net/remote-setup/logon.bgi"

Write-Verbose "Download Started"
New-Item -ItemType Directory -Force -Path $bgInfoFolder
Start-BitsTransfer -Source $bgInfoUrl -Destination $env:TEMP\bginfo.zip
Write-Verbose "Extracting Archive"
Expand-Archive -LiteralPath $env:TEMP\bginfo.zip -DestinationPath $bgInfoFolder -Force
Remove-Item $env:TEMP\bginfo.zip
Remove-Item $bgInfoFolder\eula.txt
Write-Verbose "Downloading bgi script"
Invoke-WebRequest -Uri $logonBgiUrl -OutFile $bgInfoFolder\logon.bgi
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -PropertyType String -Value "C:\BgInfo\Bginfo64.exe C:\BgInfo\logon.bgi /timer:0 /nolicprompt"
Start-Process "$bgInfoFolder\bginfo64.exe" -ArgumentList "$bgInfoFolder\logon.bgi /timer:0 /nolicprompt" -Wait -NoNewWindow