# run these indvidually as neeed - separate out and create batch file on USB...

# Software Installs
$VerbosePreference = "continue"
Import-Module BitsTransfer

# Download & install startel softphone
$softwareUrl = "https://github.com/breasor/scripts-work/raw/master/agent%20stations/Endicott/SoftPhoneSetup.msi"
Start-BitsTransfer -Source $softwareUrl -Destination $env:TEMP\SoftPhoneSetup.msi
Start-Process "msiexec.exe" -ArgumentList "/i $env:TEMP\SoftPhoneSetup.msi /qn"

# Download & install ResponderSetup.msi
$softwareUrl = "https://github.com/breasor/scripts-work/raw/master/agent%20stations/Endicott/ResponderSetup.msi"
Start-BitsTransfer -Source $softwareUrl -Destination $env:TEMP\ResponderSetup.msi
Start-Process "msiexec.exe" -ArgumentList "/i $env:TEMP\ResponderSetup.msi /qn"



# Download & install Silverlight
$VerbosePreference = "continue"
$softwareUrl = "https://github.com/breasor/scripts-work/raw/master/agent%20stations/Endicott/Silverlight_x64.exe"
Start-BitsTransfer -Source $softwareUrl -Destination $env:TEMP\Silverlight_x64.exe
Start-Process "$env:temp\Silverlight_x64.exe" -ArgumentList "/q"


# Download & install SophosSetup.exe
$VerbosePreference = "continue"
$softwareUrl = "https://github.com/breasor/scripts-work/raw/master/agent%20stations/Endicott/SophosSetup.exe"
Start-BitsTransfer -Source $softwareUrl -Destination $env:TEMP\SophosSetup.exe
Start-Process "$env:temp\SophosSetup.exe" -ArgumentList '--quiet --devicegroup="CSR Computers"'
