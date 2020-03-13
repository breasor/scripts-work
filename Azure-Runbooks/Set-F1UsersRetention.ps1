Import-Module AzureAD
Import-Module Azure.Storage
Import-Module MsOnline 

$mailSettings = @{
    From = "Automation@ansafone.com"
    To = (Get-AutomationVariable -Name 'LicenseReportRecipient')
    Body = "End of Month License usage is attached to adjust billing for Endicott/Ephonamation"
    Subject = "Monthly Office/Azure License Usage"
    SMTPServer = "mail.ansafone.net"
    Port = 587
    UseSSL = $True
    
}

$SkuLookup = ($SubscribedSkus |?{$_.skupartnumber -eq "DESKLESSPACK"}).skuid

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

Select-AzureRmSubscription -SubscriptionId '8fb3f8da-3e25-4e16-9052-ecf2ad75405a'
Set-AzureRmCurrentStorageAccount -StorageAccountName ansastatic -ResourceGroupName "ANSA-PROD-RG"

$creds = Get-AutomationPSCredential -Name "svc.azureadposh"
$SMTPCreds = Get-AutomationPSCredential -Name 'SMTP Relay'

Connect-AzureAD -Credential $creds
Connect-ExchangeOnline -ConnectionUri https://outlook.office365.com/powershell-liveid/ -credential $creds

$SkuLookup = (Get-AzureADSubscribedSku | Where-Object {$_.skupartnumber -eq "DESKLESSPACK"}).skuid
$mailboxes = (Get-AzureADUser -all:$true | Where-Object {$_.AssignedLicenses.skuid -eq $SkuLookup}).mail
foreach ($Mailbox in $mailboxes) { 
    Write-Output "Setting ECP Compliance Policy on $mailbox"
    Get-Mailbox $mailbox -verbose | Set-Mailbox -RetentionPolicy "ININ Agent Retention Policy" -verbose 
    }
Get-PSSession | Remove-PSSession -Confirm:$false

Connect-ExchangeOnline -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -credential $creds

$EmailRetentionPolicy = Get-RetentionCompliancePolicy "F1 Email Retention"
$TeamsRetentionPolicy = Get-RetentionCompliancePolicy "F1 Teams Retention"

foreach ($Mailbox in $mailboxes) { 
    Write-Output "Setting Compliance/Retention on $mailbox"; 
    Set-RetentionCompliancePolicy -Identity $EmailRetentionPolicy.DistinguishedName -AddExchangeLocation $mailbox 
    Set-RetentionCompliancePolicy -Identity $TeamsRetentionPolicy.DistinguishedName -AddTeamsChatLocation $mailbox
    }

Get-PSSession | Remove-PSSession -Confirm:$false

RemoveBrokenOrClosedPSSession

