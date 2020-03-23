#region Office365
# Get Usermailboxes by domain
$DomainName = "domain.com"
Get-Mailbox -Filter "UserPrincipalName -like '*$($DomainName)'" -ResultSize Unlimited
# just user mailboxes (not shared)
Get-Mailbox -Filter "Userprincipalname -like '*$($DomainName)' -and RecipientTypeDetails -eq 'UserMailbox'" -ResultSize unlimited


# Get Distribution group membership
$identity = "username@domain.com"
$distinguishedName =  (Get-Mailbox -Identity $Identity).distinguishedname
Get-DistributionGroup -Filter "Members -like '$($distinguishedName)'" -ErrorAction silentlycontinue 

# Clear DG Membership - useful after user exit
$identity = "username@domain.com"
$distinguishedName =  (Get-Mailbox -Identity $Identity).distinguishedname
$group = Get-DistributionGroup -Filter "Members -like '$($distinguishedName)'" -ErrorAction silentlycontinue 
if ( $group -notlike "*Disabled*") { $group |  foreach-object { Remove-DistributionGroupMember -Identity $_.identity -Member $distinguishedName -Confirm:$false}}


#endregion

#region AD
# Empty Office AD Groups
Get-ADGroup -Filter * -Properties isCriticalSystemObject,Members).where({ (-not $_.isCriticalSystemObject) -and ($_.Members.Count -eq 0) }

# Clear AD Groups - useful after user leaves
$identity = "username"
$adgroups = Get-ADPrincipalGroupMembership -Identity $Identity
$adgroups | ForEach-Object { if ((Get-ADGroup $_ -Properties mail).mail) { Remove-ADGroupMember -Members $Identity -Identity $_ }}



#endregion

#region misc

#random pin code (change 4 to number of digits)
-join(1..4 | ForEach-Object {Get-Random -Minimum 0 -Maximum 10})

# check if elevated
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')

# Open a new elevated powershell window
Start-Process Powershell -Verb runas

#string validation (if funky chars exist)
$questionablestring = "asdlfjk32jka;vz3()@#42"
$questionablestring -match "[$([Regex]::Escape('/\[:;|=,+*?<>') + '\]' + '\"')]"

#get windows build
[Environment]::OSVersion

# get serial number
Get-CimInstance -ClassName Win32_Bios | select-object serialnumber

# Get process for port
$port = 80
Get-Process -Id (Get-NetTCPConnection -LocalPort $port).OwningProcess

#computer uptime
Get-CimInstance Win32_OperatingSystem | select-object csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}

# Enable Remote Desktop
New-PSSession -ComputerName "Computer"
(Get-WmiObject Win32_TerminalServiceSetting -Namespace root\cimv2\TerminalServices).SetAllowTsConnections(1,1) | Out-Null
(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\TerminalServices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0) | Out-Null
Get-NetFirewallRule -DisplayName "Remote Desktop*" | Set-NetFirewallRule -enabled true


#endregion