# https://docs.microsoft.com/en-us/azure/storage/storage-powershell-guide-full#how-to-manage-azure-tables-and-table-entities

if ($PSScriptRoot){
    Import-Module ".\modules\SharePointPnPPowerShellOnline\2.14.1704.0\SharePointPnPPowerShellOnline.psd1"
    Import-Module ".\modules\Azure.Storage\2.8.0\Azure.Storage.psd1"
    Import-Module ".\modules\azuread\2.0.0.98\azuread.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
    Import-Module ".\modules\hexa-sharepoint.psm1"
}


Enter-Hexa $req $res $PSScriptRoot



Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop
$devices = Get-AzureADUserOwnedDevice -ObjectId "53f9be00-744a-4b7c-af14-9728cc2d234a"  #$userObject.ObjectId 

$userDevices = @()

foreach ($device in $devices) {
    if ($device.DeviceOSVersion -eq "Windows 10"){
        $lastLogin = $device.ApproximateLastLogonTimeStamp
        $DisplayName = $device.DisplayName
        $DevicesOSType = $device.DeviceOSType
        $DevicesOSVersion = $device.DeviceOSVersion
        $userDevices += $DisplayName
    }
}


write-host $userDevices

return





$Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY

$TableName = "Users$($global:O365TENANT)"
$table = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore

#Create a table query.
$query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery

#Define columns to select.
$list = New-Object System.Collections.Generic.List[string]
$list.Add("RowKey")
$list.Add("UserPrincipalName")
$list.Add("DisplayName")
$list.Add("Manager")
$list.Add("JSON")

#Set query details.
#$query.FilterString = "ID gt 0"
$query.SelectColumns = $list
$query.TakeCount = 20000

#Execute the query.
write-output "$(get-date) Reading users from Storage Table"
$entities = $table.CloudTable.ExecuteQuery($query)


$users = @{}
$managers = @{}
foreach ($user in $entities) {
    $u = @{}
    $userObject = convertfrom-json $user.Properties["JSON"].StringValue
    $u.UserPrincipalName = $user.Properties["UserPrincipalName"].StringValue
    $u.DisplayName = $userObject.DisplayName


    $users.add($u.UserPrincipalName,$u) 
}

write-output "$(get-date) Users Read"


#write-output "$(get-date) Devices Processed"


Write-Output $org.Count;