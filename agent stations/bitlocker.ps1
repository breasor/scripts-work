# Export the BitLocker recovery keys for all drives and display them at the Command Prompt.
$RecoveryDisk = (Get-WmiObject -Query "Select * From Win32_LogicalDisk" | ? { $_.driveType -eq 2 }).DeviceID
New-Item -ItemType Directory -Path $recoverydisk\Recovery -Force
$SerialNo = (Get-CimInstance -ClassName Win32_Bios).serialnumber
$BitlockerVolume = Get-BitLockerVolume C:
$KeyProtectors = @($BitlockerVolume.KeyProtector)

$KeyProtectors | where {$_.KeyProtectorType -eq "RecoveryPassword"} | Out-File "$RecoveryDisk\recovery\$serialNo recovery keys.txt"


