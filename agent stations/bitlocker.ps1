# Format USB key and label it RECOVERYKEY

$RecoveryDisk = (Get-WmiObject -Query "Select * From Win32_LogicalDisk" | ? { $_.driveType -eq 2 -and $_.volumename -eq "RECOVERYKEY"}).DeviceID
New-Item -ItemType Directory -Path $recoverydisk\Recovery -Force
Get-BitLockerVolume C: | Enable-BitLocker -SkipHardwareTest -EncryptionMethod Aes128 -RecoveryKeyPath "$RecoveryDisk\Recovery" -RecoveryKeyProtector
