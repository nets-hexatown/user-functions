# https://docs.microsoft.com/en-us/azure/storage/storage-powershell-guide-full#how-to-manage-azure-tables-and-table-entities

if ($PSScriptRoot){
    Import-Module ".\modules\SharePointPnPPowerShellOnline\2.14.1704.0\SharePointPnPPowerShellOnline.psd1"
    Import-Module ".\modules\Azure.Storage\2.8.0\Azure.Storage.psd1"
    Import-Module ".\modules\azuread\2.0.0.98\azuread.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
    Import-Module ".\modules\hexa-sharepoint.psm1"
}


Enter-Hexa $req $res $PSScriptRoot

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
write-output "$(get-date) Users Read"
write-output "----"

$users = @{}
$managers = @{}

foreach ($user in $entities) {
    $u = @{}
    $u.UserPrincipalName = $user.Properties["UserPrincipalName"].StringValue
    $u.Manager = $user.Properties["Manager"].StringValue

    if ($u["Manager"] -ne $null){
        if ($managers.ContainsKey($u["Manager"] ) -ne $true){
            $managers.Add($u["Manager"],$u["Manager"])
        }
    }

    $users.add($u.UserPrincipalName,$u) 
}


$root = $null




foreach ($manager in $managers.Values) {
    $thisManager = $users[$manager]
    $users[$manager].Managers = @() 
    $seekUp = $true
    while ($seekUp){
        $managersManagerId = $thisManager["Manager"]
        $managersManager = $users[$managersManagerId]
        if (($managersManagerId -ne $manager) -and ($managersManagerId -ne $null) -and ($managersManagerId -ne $last)){
            $users[$manager].Managers += $managersManagerId
        }
        else {
            $seekUp = $false
        }
        $thisManager = $users[$managersManagerId]
        $last = $managersManagerId
    }

}

Write-Output $org.Count;