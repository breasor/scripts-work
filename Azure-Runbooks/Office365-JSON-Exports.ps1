Import-Module AzureAD
Import-Module Azure.Storage

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
Connect-AzureAD -Credential $creds
Get-AzureADUser -all:$true | ConvertTo-Json | Out-File $env:temp/users.json

$groups = Get-AzureADMSGroup  -All:$true
#rue #-Filter "groupTypes/any(c:c eq 'Unified')"

$GroupMembers = New-Object System.Collections.Generic.List[System.Object]
$groups | ForEach-Object {
    $objectid = $_.id
    $name = $_.displayname
    $mail = $_.mail
    $members = Get-AzureADGroupMember -ObjectId $_.id -All:$true

    Write-Host "Gathering membership details for $name"
    $members | ForEach-Object {
        $memberObj = @{
            groupObject = $objectid
            groupName   = $name
            groupmail   = $mail
            memberId    = $_.objectid
            memberMail  = $_.mail
        }
        $GroupMembers.add($memberObj)
    }

}
$groups | ConvertTo-Json | Out-File $env:temp/groups.json
$GroupMembers | ConvertTo-Json | Out-File $env:temp/groupMembers.json



Set-AzureStorageBlobContent -Container grmdata -File $env:temp/users.json -Blob AccountInfo/users.json -Force
Set-AzureStorageBlobContent -Container grmdata -File $env:temp/groups.json -Blob AccountInfo/groups.json -Force
Set-AzureStorageBlobContent -Container grmdata -File $env:temp/groupMembers.json -Blob AccountInfo/groupMembers.json -Force

