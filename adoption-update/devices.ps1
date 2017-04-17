# https://docs.microsoft.com/en-us/azure/storage/storage-powershell-guide-full#how-to-manage-azure-tables-and-table-entities

if ($PSScriptRoot){
    Import-Module ".\modules\hexa-functions.psm1"
    Import-Module ".\modules\hexa-sharepoint.psm1"
}


Enter-Hexa $req $res $PSScriptRoot



Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop


$Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY

$TableName = "Users$($global:O365TENANT)"
$userTable = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore

#Create a table query.
$query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery

#Define columns to select.
$list = New-Object System.Collections.Generic.List[string]
$list.Add("RowKey")
$list.Add("UserPrincipalName")
$list.Add("DisplayName")

$list.Add("JSON")

#Set query details.
#$query.FilterString = "ID gt 0"
$query.SelectColumns = $list
$query.TakeCount = 20000

#Execute the query.
write-output "$(get-date) Reading users from Storage Table"
$entities = $userTable.CloudTable.ExecuteQuery($query)




#write-output "$(get-date) Devices Processed"
function Add-Device() {
    [CmdletBinding()]
    param(
        $table,
        [String]$partitionKey,
        [String]$userId,
        [String]$devices,
        [String]$json
        
    )

    $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $partitionKey, $userId
    
    $entity.Properties.Add("Devices",$devices)

    
    $entity.Properties.Add("JSON", $json)
    $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($entity))
}

write-output "$(get-date) Processing Devices"

$Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY

$TableName = "Windows10$($global:O365TENANT)"
$table = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore

if ($table -eq $null) {
    $table =  New-AzureStorageTable -Name $TableName -Context $ctx
}

foreach ($user in $entities) {
    $u = @{}
    $userObject = convertfrom-json $user.Properties["JSON"].StringValue
    $u.UserPrincipalName = $user.Properties["UserPrincipalName"].StringValue
    $u.DisplayName = $userObject.DisplayName
    
    $devices = Get-AzureADUserOwnedDevice -ObjectId $userObject.ObjectId
    $userDevices = @()
    foreach ($device in $devices) {
        if ($device.DeviceOSType -eq "Windows"){
           $userDevices += "$($device.DisplayName) ($($device.DeviceOSVersion))" 
        }
    }
    
    if ($userDevices.count -gt 0){
       # write-host "X" -NoNewline
        Add-Device -table $table -userId $u.UserPrincipalName -devices ($userDevices -join ",") -json (convertto-json $devices)
    }else {
       # write-host "." -NoNewline
    }

}

write-output "$(get-date) Devices Processed"

Write-Output $org.Count;