#!ps1
#maxlength=100000
#timeout=90000
function Invoke-InstallSAI {


    [CmdLetBinding()]
    param(
        [Parameter()]
        [string]
        $SourceDir = "\\endicottcomm.internal\NETLOGON\Staging\Software",
        [Parameter()]
        [string]
        $keyboard = "kyb_pc104R.map",
        [Parameter()]
        [string]
        $CMC = "CMC_15.0_b1238",
        [Parameter()]
        [switch]
        $Install,
        [Parameter()]
        [switch]
        $Cleanup,
        [Parameter()]
        [switch]
        $STLCommon
    )
    Begin {
        $verbosePreference = 'Continue'
        $DateStamp = Get-Date -Format yyyyMMddTHHmmss
        $LogFile = ("{0} - {1}.log" -f $DateStamp, $MyInvocation.MyCommand)
        Start-Transcript $env:TEMP\$logFile

        [bool]$Elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        If (!($Elevated)) {
            Write-Verbose "Not an Administrator - Exiting"
            Throw "Installing the Startel Agent Interface requires elevation."
        }


        $startMenuFolder = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startel Services"
        if (-not (Test-Path -Path $startMenuFolder)) { New-Item -ItemType Directory -Path $startMenuFolder }
        if (-not (Test-Path -Path c:\$CMC)) { New-Item -ItemType Directory -Path C:\$CMC }
        $robocopyParams = @("/E", "/MT:32")
        $SAIPath = "C:\Startel Agent Interface"
        $shortcuts = @("$env:USERPROFILE\Desktop\SAI*.lnk",
            "C:\Users\Public\Desktop\SAI*.lnk",
            "$env:USERPROFILE\Desktop\Startel Agent Interface*.lnk",
            "C:\Users\Public\Desktop\Startel Agent Interface*.lnk",
            "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startel Services\SAI*.lnk",
            "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startel Services\Startel Agent Interface*.lnk"
        )

        if ($cleanup) {
            $shortcuts | ForEach-Object {
                Write-Verbose "Removing Item $_"
                Remove-Item -Path $_ -Force -ErrorAction 'SilentlyContinue'
            }
        }

        if ($STLCommon) {
            if ((Get-Item -Path C:\STLCommon).LinkType -eq 'SymbolicLink') {
                Write-Verbose "Removing Symbolic Link for C:\STLCommon"
                (Get-Item -Path C:\STLCommon).Delete()
            }
            else {
                Write-Verbose "Deleting Existing Directory for C:\STLCommon"
                Remove-Item -Path C:\STLCommon -Recurse -Force -Confirm:$false -ErrorAction 'SilentlyContinue'
            }
            Write-Verbose "Copying STLCommon to C:\$CMC\STLCommon"
            Robocopy.exe $SourceDir\$CMC\STLCommon C:\$CMC\STLCommon $robocopyParams /PURGE
            Write-Verbose "Making Symbolic Link for C:\STLCommon from C:\Startel\STLCommon"
            cmd.exe /C MKLINK /D C:\STLCommon C:\$CMC\STLCommon

            Write-Verbose "Installing msxml.msi & vcredist files"
            Start-Process "msiexec.exe" -ArgumentList "/qn /norestart /i c:\STLcommon\msxml.msi /L*V $env:TEMP\msxml.Log" -Wait -NoNewWindow
            Start-Process "C:\STLCommon\vcredist_x86_2012.exe" -ArgumentList "/install /quiet /norestart /log $env:TEMP\vcredist_x86_2012.Log" -Wait -NoNewWindow
            Start-Process "C:\STLCommon\vcredist_x86_2013.exe" -ArgumentList "/install /quiet /norestart /log $env:TEMP\vcredist_x86_2013.Log" -Wait -NoNewWindow
            Start-Process "C:\STLCommon\vcredist_x86_2015.exe" -ArgumentList "/install /quiet /norestart /log $env:TEMP\vcredist_x86_2015.Log" -Wait -NoNewWindow

            Write-Verbose "Registering EAGetmail"
            Start-Process "regsvr32" -ArgumentList "/s /u EAGetMail.dll" -Wait -NoNewWindow
            Start-Process "regsvr32" -ArgumentList "/s /i C:\STLCommon\EAGetMail.dll" -Wait -NoNewWindow
        }



        if (-not (Test-Path $startMenuFolder )) {
            Write-Verbose "Creating Start Menu Folder"
            New-Item -Name $startMenuFolder -ItemType directory
        }
    }
    Process {
        Write-Verbose "Copying $SourceDir\$CMC files to C:\$CMC"
        Robocopy.exe "$SourceDir\$CMC\Startel Agent Interface" "C:\$CMC\Startel Agent Interface" $robocopyParams
        if ((Get-Item -Path $SAIPath).LinkType -eq 'SymbolicLink') {
            Write-Verbose "Deleting Symbolic Link to C:\Startel Agent Interface"
            (Get-Item -Path $SAIPath).Delete()
        }
        else {
            Write-Verbsoe "Deleting files at C:\Startel Agent Interface"
            Remove-Item -Path $SAIPath -Recurse -Force -Confirm:$false -ErrorAction 'SilentlyContinue'
        }
        Write-Verbose "Creating Symbolic Link to C:\$CMC\Startel Agent Interface at $SAIpath"
        cmd.exe /C MKLINK /D $SAIPath "C:\$CMC\Startel Agent Interface"
        Write-Verbose "Copying Fonts to System directory"
        Copy-Item -Path $SAIPath\Fonts\Arialld.ttf  -Destination $env:windir\Fonts -Force
        Copy-Item -Path $SAIPath\Fonts\Arialldb.ttf  -Destination $env:windir\Fonts -Force
        Write-Verbose "Setting Registry Keys for Fonts"
        Set-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "Arial alternative (TrueType)" -Value "arialld.ttf" -Force
        Set-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "Arial alternative Bold (TrueType)" -Value "arialldb.ttf" -Force

        Write-Verbose "Setting Keyboard Mapping to $keyboard"
        (Get-Content $SAIPath\sai.ini) -replace '^(KEYMAPFILE=)(.*)', "`$1$SAIPath\$keyboard" | Set-Content $SAIPath\sai.ini

        Write-Verbose "Resetting Desktop Shortcut"
        Remove-Item -Path "$($env:PUBLIC)\Desktop\Startel Agent Interface.lnk" -Force -ErrorAction 'SilentlyContinue'
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$($env:PUBLIC)\Desktop\Startel Agent Interface.lnk")
        $Shortcut.TargetPath = "$SAIPath\SAI.EXE"
        $Shortcut.WorkingDirectory = $SAIPath
        $Shortcut.Save()

        Write-Verbose "Resetting Start Menu Shortcut"
        Remove-Item -Path "$($env:ALLUSERSPROFILE)\Microsoft\Windows\Start Menu\Programs\Startel Services\Startel Agent Interface.lnk" -Force -ErrorAction 'SilentlyContinue'
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$($env:ALLUSERSPROFILE)\Microsoft\Windows\Start Menu\Programs\Startel Services\Startel Agent Interface.lnk")
        $Shortcut.TargetPath = "$SAIPath\SAI.EXE"
        $Shortcut.WorkingDirectory = $SAIPath
        $Shortcut.Save()

    }
    End {
        Write-Verbose "Finished Installing Startel Agent Interface"
        Stop-Transcript
    }
}
Invoke-InstallSAI -SourceDir "\\NJ-DC1\NETLOGON\Staging\Software\Startel" -keyboard "kyb_pc104R.map" -CMC "CMC_15.0_b1238"-Install:$true -Cleanup:$true -STLCommon:$true