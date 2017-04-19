# If hosted in Azure Web Jobs modules are auto loaded
if ($PSScriptRoot){ 
    Import-Module ".\modules\azuread\2.0.0.109\azuread.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
}

Enter-Hexa $req $res $PSScriptRoot


$searchString =  $Global:request.searchString

Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop

#https://docs.microsoft.com/en-us/powershell/module/azuread/get-azureadgroup?view=azureadps-2.0
$groups = Get-AzureADGroup -SearchString $searchString

$result = @()


foreach ($group in $groups) {
    $groupData = @{}
    $groupData.DisplayName = $group.DisplayName
    $groupData.ObjectId = $group.ObjectId
    $groupData.ObjectType = $group.ObjectType
    $groupData.Description = $group.Description
    $groupData.DirSyncEnabled = $group.DirSyncEnabled
    $groupData.LastDirSyncTime = $group.LastDirSyncTime
    $groupData.SecurityEnabled = $group.SecurityEnabled

    $groupData.members = @()
    $members = Get-AzureADGroupMember -ObjectId $group.ObjectId
    foreach ($member in $members) {
        $memberData = @{}
        $memberData.UserPrincipalName = $member.UserPrincipalName
        $memberData.ObjectType = $member.ObjectType
        $memberData.ObjectId = $member.ObjectId
        $memberData.DisplayName = $member.DisplayName
        
        
        $groupData.members += $memberData


    }

    $result += $groupData
}


Exit-Hexa $result

