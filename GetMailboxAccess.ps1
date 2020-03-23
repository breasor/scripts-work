<#
.SYNOPSIS
Returns a list of users with full access permissions to shared mailboxes.

.PARAMETER NoAccess
Using this switch will only return mailboxes that do not have any user assigned for full access.

.EXAMPLE
.\GetMailboxAccess.ps1 -NoAccess
#>

param(

[switch]$NoAccess
)
#requires -version 2

$Result = @(); 
$sharedMailboxes = get-mailbox -filter { IsShared -eq $true }
foreach($mailbox in $sharedMailboxes)
{
    $permissionsResult = New-Object System.Collections.ArrayList
    $permissions =  $mailbox | Get-MailboxPermission | ? { $_.AccessRights -match "FullAccess" } 
    $permissions | % { if ($_.Deny -eq $false -and $permissionsResult -notcontains $_.User) { $permissionsResult.Add($_.User.ToString()) | Out-Null } }
    $permissions | % { if ($_.Deny -eq $true -and $permissionsResult -contains $_.User) { $permissionsResult.Remove($_.User.ToString()) | Out-Null } }
    if ($NoAccess)
    {
        if ($permissionsResult.Count -eq 0)
        {
            New-Object PSObject -Property @{"Alias" = $mailbox.Alias; "EmailAddress" = $mailbox.PrimarySmtpAddress.ToString(); "FullAccess" = $permissionsResult}
        }
    } else {
        New-Object PSObject -Property @{"Alias" = $mailbox.Alias; "EmailAddress" = $mailbox.PrimarySmtpAddress.ToString(); "FullAccess" = $permissionsResult}
    }
}