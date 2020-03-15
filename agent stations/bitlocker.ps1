# Format USB key and label it RECOVERYKEY

$RecoveryDisk = (Get-WmiObject -Query "Select * From Win32_LogicalDisk" | ? { $_.driveType -eq 2 -and $_.volumename -eq "RECOVERYKEY"}).DeviceID
New-Item -ItemType Directory -Path $recoverydisk\Recovery -Force
Get-BitLockerVolume C: | Enable-BitLocker -SkipHardwareTest -EncryptionMethod XtsAes128 -RecoveryKeyPath "$RecoveryDisk\Recovery" -RecoveryKeyProtector
Restart-Computer -Delay 15

# Export the BitLocker recovery keys for all drives and display them at the Command Prompt.
$BitlockerVolumers = Get-BitLockerVolume
$BitlockerVolumers |
ForEach-Object {
$MountPoint = $_.MountPoint
$RecoveryKey = [string]($_.KeyProtector).RecoveryPassword
if ($RecoveryKey.Length -gt 5) {
Write-Output ("The drive $MountPoint has a BitLocker recovery key $RecoveryKey.")
}
}
