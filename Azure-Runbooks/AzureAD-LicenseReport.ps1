Import-Module AzureAD
Import-Module Azure.Storage

$mailSettings = @{
    From = "Automation@ansafone.com"
    To = (Get-AutomationVariable -Name 'LicenseReportRecipient')
    Body = "End of Month License usage is attached to adjust billing for Endicott/Ephonamation"
    Subject = "Monthly Office/Azure License Usage"
    SMTPServer = "mail.ansafone.net"
    Port = 587
    UseSSL = $True
    
}

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
#Get-AzureADUser -all:$true | ConvertTo-Json | Out-File $env:temp/users.json

Get-AzureStorageBlobContent -Container grmdata -Blob AccountInfo/users.json -Destination $env:temp/users.json
Get-AzureStorageBlobContent -Container grmdata -Blob skudata.csv -Destination $env:temp/skudata.csv


$users = Get-Content $env:temp/users.json -Raw | ConvertFrom-Json
$skudata = Import-Csv $env:temp/skudata.csv

$SubscribedSkus = Get-AzureADSubscribedSku | Select -Property Sku*,ConsumedUnits -ExpandProperty PrepaidUnits
$skudata
$AllUserDetails = foreach ($user in $users)
{
    $licenseDetails = Get-AzureADUserLicenseDetail -ObjectId $user.objectid | Select-Object SkuPartNumber
    
    foreach ($license in $licenseDetails) {
        [PSCustomObject]@{
            ObjectID = $user.ObjectID
            DisplayName = $user.DisplayName
            UserPrincipalName =$user.UserPrincipalName
            JobTitle = $user.JobTitle
            Department = $user.Department
            CompanyName = $user.CompanyName
            Office = $user.PhysicalDeliveryOfficeName
            Mail = $user.Mail
            ObjectType = $user.ObjectType
            UserType = $user.UserType
            License = $license.SkuPartNumber
            LicenseFriendly =  ($skudata -match $license.SkuPartNumber).SkuDisplayName
            LicenseCost = ($skudata -match $license.SkuPartNumber).cost
        }
    }
}

$AllUserDetails | Export-Csv -NoTypeInformation $env:temp/LicenseDetails.csv
Set-AzureStorageBlobContent -Container grmdata -File $env:temp/LicenseDetails.csv -Blob AccountInfo/LicenseDetails.csv -Force

Send-MailMessage @mailSettings -Attachments $env:temp/LicenseDetails.csv -Credential $SMTPCreds