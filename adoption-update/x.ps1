# https://docs.microsoft.com/en-us/azure/storage/storage-powershell-guide-full#how-to-manage-azure-tables-and-table-entities

if ($PSScriptRoot){
    Import-Module ".\modules\SharePointPnPPowerShellOnline\2.14.1704.0\SharePointPnPPowerShellOnline.psd1"
    Import-Module ".\modules\Azure.Storage\2.8.0\Azure.Storage.psd1"
    Import-Module ".\modules\azuread\2.0.0.98\azuread.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
    Import-Module ".\modules\hexa-sharepoint.psm1"
}


Enter-Hexa $req $res $PSScriptRoot

function HasLicense ($licenses,$licenseKey){
    foreach ($license in $licenses) {
        if ($license.SkuPartNumber -eq $licenseKey){
            return $true
        }
    }
}


Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop
$nielslicenses =  Get-AzureADUserLicenseDetail  -ObjectId "9beef235-49d8-49cd-8c28-aad5aeab084b" 
if (HasLicense $nielslicenses "ENTERPRISEPACK"){
    write-host "Niels has E3"
}
if (HasLicense $nielslicenses "EMS"){
    write-host "Niels has EMS"
}
$peterlicenses = Get-AzureADUserLicenseDetail -ObjectId "5a22db10-0c13-4bc3-8d36-9cc7b288c052" 
if (HasLicense $peterlicenses "ENTERPRISEPACK"){
    write-host "Peter E3"
}
if (HasLicense $peterlicenses "EMS"){
    write-host "Peter has E3"
}

write-host $devices

# https://blogs.technet.microsoft.com/treycarlee/2014/12/09/powershell-licensing-skus-in-office-365/