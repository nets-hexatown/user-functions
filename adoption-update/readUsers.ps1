#*********************************************************
#  User Adoption Tracking
#  ----------------------
#
# version 0.1 baseline
# version 0.2 change modules inclusion strategy thx to
#             https://docs.microsoft.com/en-us/powershell/azure/install-adv2?view=azureadps-2.0
#
# https://itfordummies.net/2016/09/13/measure-office-365-usage/
# https://365lab.net/2017/01/03/create-simple-powerbi-reports-for-intune-through-the-microsoft-graph/
#*********************************************************

if ($PSScriptRoot){
    Import-Module ".\modules\SharePointPnPPowerShellOnline\2.14.1704.0\SharePointPnPPowerShellOnline.psd1"
    Import-Module ".\modules\Azure.Storage\2.8.0\Azure.Storage.psd1"
    Import-Module ".\modules\azuread\2.0.0.98\azuread.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
    Import-Module ".\modules\hexa-sharepoint.psm1"
    Import-Module ".\modules\hexa-users.psm1"
}

Enter-Hexa $req $res $PSScriptRoot
Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop

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

Exit-Hexa $result






