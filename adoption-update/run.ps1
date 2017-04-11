#*********************************************************
#  User Adoption Tracking
#  ----------------------
#
# version 0.1 baseline
# version 0.2 change modules inclusing strategy thx to
#             https://docs.microsoft.com/en-us/powershell/azure/install-adv2?view=azureadps-2.0
#
#*********************************************************

if ($PSScriptRoot){
    Import-Module ".\modules\hexa-functions.psm1"
    Import-Module ".\modules\SharePointPnPPowerShellOnline\2.14.1704.0\SharePointPnPPowerShellOnline.psd1"
    Import-Module ".\modules\azuread\2.0.0.98\azuread.psd1"
}

Enter-Hexa $req $res $PSScriptRoot


Connect-AzureAD -Credential $global:credentials

$users = Get-AzureADUser  -top 50  #| select MailNickName , DisplayName , UserPrincipalName, Mail, ObjectId # -All 

write-output $users

$tenant = $global:O365TENANT
$relativeUrl = $global:request.siteRelativeUrl
$url = "https://$tenant.sharepoint.com$relativeUrl"
Connect-PnPOnline -Url $url -Credentials ($global:credentials)

$userAdoptionListname = "User Adoption Status"

function CreateUserAdoptionList($userAdoptionListname){
    Remove-PnPList -Identity $userAdoptionListname -Force
    write-Output "Checking status list"
    $list = Get-PnPList $listname 
    if ($list -eq $null){

        Write-Output "Creating list $userAdoptionListname"
        New-PnPList -Title $userAdoptionListname -Template "Custom"
        Set-PnPList -Identity $userAdoptionListname -EnableVersioning $true
        Add-PnPField -List $userAdoptionListname -DisplayName "UPN" -InternalName "UPN" -Type:Text -AddToDefaultView
        Add-PnPField -List $userAdoptionListname -DisplayName "User Email" -InternalName "user_email" -Type:Text -AddToDefaultView
        Add-PnPField -List $userAdoptionListname -DisplayName "Location" -InternalName "location" -Type:Text  -AddToDefaultView
        Add-PnPField -List $userAdoptionListname -DisplayName "Country" -Type:Text -InternalName "country" -AddToDefaultView
        Add-PnPField -List $userAdoptionListname -DisplayName "Department ID" -InternalName "departmentid" -Type:Text -AddToDefaultView
        Add-PnPField -List $userAdoptionListname -DisplayName "L1" -InternalName "l1" -Type:Text  -AddToDefaultView
        Add-PnPField -List $userAdoptionListname -DisplayName "L2" -InternalName "l2" -Type:Text 
        Add-PnPField -List $userAdoptionListname -DisplayName "L3" -InternalName "l3" -Type:Text 
        Add-PnPField -List $userAdoptionListname -DisplayName "L4" -InternalName "l4" -Type:Text 
        Add-PnPField -List $userAdoptionListname -DisplayName "L5" -InternalName "l5" -Type:Text 

        # Add-PnPView -List $listname -Title "Overview" -Fields "Title","User Email" -SetAsDefault:$true -ViewType:Html

       
     }
}

CreateUserAdoptionList userAdoptionListname

Write-Output "Adding test entry"
$list = Get-PnPList $userAdoptionListname 
$usersInList = Get-PnPListItem -List $userAdoptionListname 

$allusers = $users | select UserPrincipalName
$knownusers = $usersInList | select UPN

# $itemcreateinfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
# $listitem = $list.AddItem($itemcreateinfo)
# $listitem["Title"] = "Niels (niels@365admin.net)"
# $listitem["user_email"] = "niels@365admin.net"
# $listitem.Update()
# Execute-PnPQuery


$result = $users



Exit-Hexa $result


