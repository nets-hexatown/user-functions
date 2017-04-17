# https://blogs.technet.microsoft.com/treycarlee/2014/12/09/powershell-licensing-skus-in-office-365/

# If hosted in Azure Web Jobs modules are auto loaded
if ($PSScriptRoot){
    Import-Module ".\modules\azuread\2.0.0.98\azuread.psd1" -ErrorAction:SilentlyContinue
    Import-Module ".\modules\hexa-functions.psm1" -ErrorAction:SilentlyContinue
    Import-Module ".\modules\hexa-sharepoint.psm1" -ErrorAction:SilentlyContinue
    Import-Module ".\modules\hexa-users.psm1" -ErrorAction:SilentlyContinue
}

Enter-Hexa $req $res $PSScriptRoot
Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop

function HasLicense ($licenses,$licenseKey){
    foreach ($license in $licenses) {
        if ($license.SkuPartNumber -eq $licenseKey){
            return $true
        }
    }
}

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
