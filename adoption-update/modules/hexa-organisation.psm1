function Add-Manager() {
    [CmdletBinding()]
    param(
        $table,
        [String]$partitionKey,
        [String]$managerId,
        [String]$json
    )

    $manager = convertfrom-json -InputObject $json
    $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $partitionKey, $managerId
    $user = $users[$managerId]
    if ($user["Department"] -ne $null) {
        $entity.Properties.Add("Department", $user["Department"])
    }
    if ($user["DisplayName"] -ne $null) {
        $entity.Properties.Add("DisplayName", $user["DisplayName"])
    }

    for ($i = 0; $i -lt $manager.Managers.Count; $i++) {
        $level = $manager.Managers.Count - $i
        $entity.Properties.Add("L$level", $manager.Managers[$i])
    }
    
    $ownLevel = ($manager.Managers.Count+1)
    $entity.Properties.Add("L$ownLevel", $managerId)

    $entity.Properties.Add("ManagerLevel",$ownLevel )
    
#    $entity.Properties.Add("JSON", $json)
    $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($entity))
}

function Build-Organisation(){
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
Hexa-Log "Reading users from Storage Table"
$entities = $table.CloudTable.ExecuteQuery($query)


$users = @{}
$managers = @{}

foreach ($user in $entities) {
    $u = @{}
    $userObject = convertfrom-json $user.Properties["JSON"].StringValue
    $u.UserPrincipalName = $user.Properties["UserPrincipalName"].StringValue
    $u.Department = $userObject.Department
    $u.DisplayName = $userObject.DisplayName
    $u.Manager = $user.Properties["Manager"].StringValue

    if ($u["Manager"] -ne $null){
        if ($managers.ContainsKey($u["Manager"] ) -ne $true){
            $managers.Add($u["Manager"],$u["Manager"])
        }
    }

    $users.add($u.UserPrincipalName,$u) 
}

Hexa-Log "Users Read"

$root = $null



Hexa-Log "Processing Managers"

$Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY

$TableName = "Managers$($global:O365TENANT)TEMP"
$table = Get-AzureStorageTable -Name $TableName -Context $Ctx -ErrorAction Ignore

if ($table -eq $null) {
    $table =  New-AzureStorageTable -Name $TableName -Context $ctx
}


foreach ($manager in $managers.Values) {
    $thisManager = $users[$manager]
    $users[$manager].Managers = @() 
    $seekUp = $true
    $last = $null
    while ($seekUp){
        if ($thisManager["Manager"] -eq $null){
            $seekUp = $false
        }
        else
        {
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
    $json = ConvertTo-Json  $users[$manager]
    Add-Manager -json $json -table $table -partitionKey "managers" -managerId $users[$manager]["UserPrincipalName"]

}

Hexa-Log "$($org.Count) Managers Processed"
}
