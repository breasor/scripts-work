# Create a Shortcut to OC-ENDIRDS1
$TargetFile = "$env:SystemRoot\System32\mstsc.exe"
$ShortcutFile = "$env:Public\Desktop\Endicott RDS1.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = "/v:oc-endirds1.endicottcomm.internal"
$Shortcut.Save()
