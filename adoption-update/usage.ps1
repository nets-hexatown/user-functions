# 



if ($PSScriptRoot){
    Import-Module ".\modules\SharePointPnPPowerShellOnline\2.14.1704.0\SharePointPnPPowerShellOnline.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
    Import-Module ".\modules\hexa-sharepoint.psm1"
}


Enter-Hexa $req $res $PSScriptRoot

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $global:credentials -Authentication Basic -AllowRedirection
Import-PSSession $Session
#$O365ClientOSReport = Get-O365ClientOSReport  -StartDate 03/15/2017 -EndDate 04/15/2017 | select Date,Name,Version,Count,Category,Summary,DisplayOrder #| format-table
write-output "done"
return


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


#Set query details.
#$query.FilterString = "ID gt 0"
$query.SelectColumns = $list
$query.TakeCount = 20000

#Execute the query.
write-output "$(get-date) Reading users from Storage Table"
$entities = $userTable.CloudTable.ExecuteQuery($query)

function HasLicense ($licenses,$licenseKey){
    foreach ($license in $licenses) {
        if ($license.SkuPartNumber -eq $licenseKey){
            return $true
        }
    }
}



function Update-User() {
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
}

write-output "$(get-date) Processing Licenses"

$Ctx = New-AzureStorageContext $global:HEXAUSERSTORAGEACCOUNT -StorageAccountKey $global:HEXAUSERSTORAGEACCOUNTKEY


foreach ($user in $entities) {
    $u = @{}
    $userObjectId = $user.RowKey
    
    $licences = Get-AzureADUserLicenseDetail -ObjectId  $userObjectId
  
    Update-User -table $userTable -entity $user -e3License  (HasLicense $licences "ENTERPRISEPACK")  -emsLicense  (HasLicense $licences "EMS") 
    write-host "." -NoNewline

}

write-output "$(get-date) Licenses Processed"

Write-Output $org.Count;