#*********************************************************
#  User Adoption Tracking
#  ----------------------
#
# version 0.1 baseline
# version 0.2 change modules inclusing strategy thx to
#             https://docs.microsoft.com/en-us/powershell/azure/install-adv2?view=azureadps-2.0
#
# https://itfordummies.net/2016/09/13/measure-office-365-usage/
#*********************************************************

if ($PSScriptRoot){
    Import-Module ".\modules\SharePointPnPPowerShellOnline\2.14.1704.0\SharePointPnPPowerShellOnline.psd1"
    Import-Module ".\modules\Azure.Storage\2.8.0\Azure.Storage.psd1"
    Import-Module ".\modules\azuread\2.0.0.98\azuread.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
    Import-Module ".\modules\hexa-sharepoint.psm1"
}

Enter-Hexa $req $res $PSScriptRoot

Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop
write-output Get-Date
write-output "$(get-date) Reading users"
$users = Get-AzureADUser  -top 100000  # -All $true  #  -top 50  #| select MailNickName , DisplayName , UserPrincipalName, Mail, ObjectId # -All 
write-output "$(get-date) got $($users.count) users"


#SharePointConnect
#SharePointCreateUserAdoptionList  $userAdoptionListname

#Function Add-Entity: Adds an employee entity to a table.
function Add-User() {
    [CmdletBinding()]
    param(
        $table,
        [String]$partitionKey,
        [String]$rowKey,
        [String]$json
    )

    $user = convertfrom-json -InputObject $json

    $manager = Get-AzureADUserManager -ObjectId $user.ObjectId

    $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $partitionKey, $rowKey

    if ($user.DisplayName -ne $null) {
        $entity.Properties.Add("DisplayName", $user.DisplayName)
    }
    if ($manager -ne $null){
        $entity.Properties.Add("Manager", $manager.UserPrincipalName)
        $entity.Properties.Add("ManagerObjectId", $manager.ObjectId)
    }
    if ($user.Mail -ne $null) {
        $entity.Properties.Add("Mail", $user.Mail)
    }
    if ($user.UserPrincipalName -ne $null) {
        $entity.Properties.Add("UserPrincipalName", $user.UserPrincipalName)
    }
    if ($user.UserType -ne $null) {
        $entity.Properties.Add("UserType", $user.UserType)
    }
    if ($user.DirSyncEnabled -ne $null) {
        $entity.Properties.Add("DirSyncEnabled", $user.DirSyncEnabled)
    }
    $entity.Properties.Add("JSON", $json)

    

    $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::InsertOrMerge($entity))
}

$Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY

$TableName = "Users$($global:O365TENANT)"
$table = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore

if ($table -eq $null) {
    $table =  New-AzureStorageTable -Name $TableName -Context $ctx
}

foreach ($user in $users) {
    $json = ConvertTo-Json -InputObject $user
    
    Add-User -partitionKey "users" -table $table -rowKey $user.objectId -json $json 
    write-host "." -NoNewline
}
  




#$result = $users



Exit-Hexa $result






