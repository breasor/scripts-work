function Invoke-InstallSAC {


    [CmdLetBinding()]
param(
    [Parameter()]
    [string]
    $SourceDir = "\\endicottcomm.internal\NETLOGON\Staging\Software\Startel",
    [Parameter()]
    [string]
    $CMC = "CMC_15.0_b1238",
    [Parameter()]
    [switch]
    $Cleanup
)
Begin {

    $verbosePreference = 'Continue'
    $DateStamp = Get-Date -Format yyyyMMddTHHmmss
    $LogFile = ("{0} - {1}.log" -f $DateStamp, $MyInvocation.MyCommand)
    Start-Transcript $env:TEMP\$logFile

    [bool]$Elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    If (!($Elevated)) { Throw "Installing the Startel Administrative Controls requires elevation." }

    $startMenuFolder = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startel Services"
    if (-not (Test-Path -Path $startMenuFolder)) { New-Item -ItemType Directory -Path $startMenuFolder }
    $robocopyParams = @("/E", "/MT:32")
    $SACPath = "C:\Startel Administrative Controls"

    $shortcuts = @("$env:USERPROFILE\Desktop\SAC*.lnk",
        "C:\Users\Public\Desktop\SAC*.lnk",
        "$env:USERPROFILE\Desktop\Startel Administrative Controls*.lnk",
        "C:\Users\Public\Desktop\Startel Administrative Controls*.lnk",
        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startel Services\SAC*.lnk",
        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startel Services\Startel Administrative Controls*.lnk"
    )

    if ($cleanup) {
        $shortcuts | ForEach-Object {
            Remove-Item -Path $_ -Force -ErrorAction 'SilentlyContinue'
        }
    }

    if (-not (Test-Path $startMenuFolder )) {
        New-Item -Name $startMenuFolder -ItemType directory
    }
}
Process {
    Robocopy.exe "$SourceDir\$CMC\Startel Administrative Controls" "C:\$CMC\Startel Administrative Controls" $robocopyParams
    (Get-Item -Path $SACPath).Delete()
    cmd.exe /C MKLINK /D $SACPath "C:\$CMC\Startel Administrative Controls"

    Remove-Item -Path "$($env:PUBLIC)\Desktop\Startel Administrative Controls.lnk" -Force -ErrorAction 'SilentlyContinue'
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$($env:PUBLIC)\Desktop\Startel Administrative Controls.lnk")
    $Shortcut.TargetPath = "$SACPath\SAC.EXE"
    $Shortcut.WorkingDirectory = $SACPath
    $Shortcut.Save()


    Remove-Item -Path "$($env:ALLUSERSPROFILE)\Microsoft\Windows\Start Menu\Programs\Startel Services\Startel Administrative Controls.lnk" -Force -ErrorAction 'SilentlyContinue'
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$($env:ALLUSERSPROFILE)\Microsoft\Windows\Start Menu\Programs\Startel Services\Startel Administrative Controls.lnk")
    $Shortcut.TargetPath = "$SACPath\SAC.EXE"
    $Shortcut.WorkingDirectory = $SACPath
    $Shortcut.Save()

}
End {

}
}
Invoke-InstallSAC -SourceDir "\\endicottcomm.internal\NETLOGON\Staging\Software\Startel" -CMC "CMC_15.0_b1238" -Cleanup:$true