function Add-HexaUser() {
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
    $global:TableOperations += 1
    if ($PSScriptRoot){
      #  write-host "." -NoNewline  # Will fail in Function app
    }

}

function Get-HexaTable($name){
    $Ctx = New-AzureStorageContext -StorageAccountName (Get-Parameter "HEXAUSERSTORAGEACCOUNT")   -StorageAccountKey (Get-Parameter "HEXAUSERSTORAGEACCOUNTKEY")
    $TableName = "$name$($global:O365TENANT)"
    $table = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore
    if ($table -eq $null) {
        $table =  New-AzureStorageTable -Name $TableName -Context $ctx
    }
    return $table
}


function Update-LicensesUser() {
    [CmdletBinding()]
    param(
        $table,
        $entity,
        [String]$e3License,
        [String]$emsLicense
    )

    $entity.Properties.Add("HasLicenseE3",$e3License)
    $entity.Properties.Add("HasLicenseEMS",$emsLicense)

    $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Merge($entity))
    $global:TableOperations += 1
    if ($PSScriptRoot){
      #  write-host "." -NoNewline  # Will fail in Function app
    }

}


function Get-TableItems($TableName,$columns){

    $Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY

    $TableName = "$TableName$($global:O365TENANT)"
    $userTable = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore

    #Create a table query.
    $query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery

    #Define columns to select.
    $list = New-Object System.Collections.Generic.List[string]
    
    foreach ($column in $columns) {
        $list.Add($column)    
    }


    #Set query details.
    #$query.FilterString = "ID gt 0"
    $query.SelectColumns = $list
    $query.TakeCount = 2000000

    #Execute the query.
    #write-output "$(get-date) Reading users from Storage Table"
    $entities = $userTable.CloudTable.ExecuteQuery($query)
    return  $entities

}


function Copy-HexaUsers(){
Hexa-Log   "Reading Users" 
$users = Get-AzureADUser  -top 2000000 
Hexa-Log  "got $($users.count) users"

$global:TableOperations = 0 
$userTable = get-hexatable "Users"
foreach ($user in $users) {
    $json = ConvertTo-Json -InputObject $user
    Add-HexaUser -partitionKey "users" -table $userTable -rowKey $user.objectId -json $json 
}
Hexa-Log "Table operations $($global:TableOperations) completed"
}


function HasLicense ($licenses,$licenseKey){
    foreach ($license in $licenses) {
        if ($license.SkuPartNumber -eq $licenseKey){
            return $true
        }
    }
}
function Update-Licenses(){
$entities = Get-TableItems "Users" "RowKey","UserPrincipalName","DisplayName"

Hexa-Log "$(get-date) Processing Licenses"

$Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY

$userTable = get-hexatable "Users"
foreach ($user in $entities) {
    
    $userObjectId = $user.RowKey
    $licences = Get-AzureADUserLicenseDetail -ObjectId  $userObjectId
  
    Update-LicensesUser -table $userTable -entity $user -e3License  (HasLicense $licences "ENTERPRISEPACK")  -emsLicense  (HasLicense $licences "EMS") 
    

}

hexa-log "$($org.Count) Licenses Processed"
}


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

function Update-Device(){
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
$query.TakeCount = 2000000

#Execute the query.
Hexa-Log "Reading users from Storage Table"
$entities = $userTable.CloudTable.ExecuteQuery($query)

#write-output "$(get-date) Devices Processed"

Hexa-Log " Processing Devices"

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
        Add-Device -table $table -userId $u.UserPrincipalName -devices ($userDevices -join ",") -json (convertto-json $devices)
    }

}

Hexa-Log "Devices Processed"
}
