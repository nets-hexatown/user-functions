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
        write-host "." -NoNewline  # Will fail in Function app
    }

}

function Get-HexaTable($name){
$Ctx = New-AzureStorageContext -StorageAccountName (Get-Parameter "HEXAUSERSTORAGEACCOUNT")   -StorageAccountKey (Get-Parameter "HEXAUSERSTORAGEACCOUNTKEY")
$TableName = "$name$($global:O365TENANT)"
$table = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore
if ($table -eq $null) {
    $table =  New-AzureStorageTable -Name $TableName -Context $ctx
}
return table
}


