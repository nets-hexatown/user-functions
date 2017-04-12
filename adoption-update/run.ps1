#*********************************************************
#  User Adoption Tracking
#  ----------------------
#
# version 0.1 baseline
# version 0.2 change modules inclusing strategy thx to
#             https://docs.microsoft.com/en-us/powershell/azure/install-adv2?view=azureadps-2.0
#
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

# foreach ($u in $ul.keys) {
#     $manager = Get-AzureADUserManager -ObjectId $u
    
#     if (($manager -eq $null) -or ($manager.ObjectId -eq $user.ObjectId)){
#         $root.childs += $user
#     }else {
#         $i = $ul.Get_Item($u)
#         $i.manager.ObjectId = $manager.ObjectId
#         $ul.Set_Item($u,$i)
#         Write-Output "has manager"
        
#     }
# }
#write-output $users
#SharePointConnect
#SharePointCreateUserAdoptionList  $userAdoptionListname


#Function Add-Entity: Adds an employee entity to a table.
function Add-Entity() {
    [CmdletBinding()]
    param(
        $table,
        [String]$partitionKey,
        [String]$rowKey,
        [String]$json
    )

    $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $partitionKey, $rowKey
    $entity.Properties.Add("JSON", $json)
    

    $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($entity))
}

$Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY

$TableName = "Users$($global:O365TENANT)"
$table = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore

if ($table -eq $null) {
    $table =  New-AzureStorageTable -Name $TableName -Context $ctx
}

foreach ($user in $users) {
    $json = convertto-json  $user
    Add-Entity -partitionKey "users" -table $table -rowKey $user.objectId -json $json 
    write-host "." -NoNewline
}
  




#$result = $users



Exit-Hexa $result






