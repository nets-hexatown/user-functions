Import-Module "..\modules\hexa-functions.psm1"
Import-Module "..\modules\SharePointPnPPowerShellOnline\2.14.1704.0\SharePointPnPPowerShellOnline.psd1"
#Import-Module "..\modules\SharePointPnPPowerShellOnlineAliases.psd1"

Enter-Hexa $req $res $PSScriptRoot

$tenant = $env:O365TENANT
$relativeUrl = $global:request.siteRelativeUrl
$url = "https://$tenant.sharepoint.com$relativeUrl"
Connect-PnPOnline -Url $url -Credentials ($global:credentials)

function CreateUserAdoptionList(){
    $listname = "User Adoption Status"
    # Remove-PnPList -Identity $listname -Force

    $list = Get-PnPList $listname 
    if ($list -eq $null){
        Write-Output "Creating list"
        New-PnPList -Title $listname -Template "Custom"
        Set-PnPList -Identity $listname -EnableVersioning $true
        Add-PnPField -List $listname -DisplayName "User Email" -InternalName "user_email" -Type:Text -AddToDefaultView
        Add-PnPField -List $listname -DisplayName "Location" -InternalName "location" -Type:Text  -AddToDefaultView
        Add-PnPField -List $listname -DisplayName "Country" -Type:Text -InternalName "country" -AddToDefaultView
        Add-PnPField -List $listname -DisplayName "Department ID" -InternalName "departmentid" -Type:Text -AddToDefaultView
        Add-PnPField -List $listname -DisplayName "L1" -InternalName "l1" -Type:Text  -AddToDefaultView
        Add-PnPField -List $listname -DisplayName "L2" -InternalName "l2" -Type:Text 
        Add-PnPField -List $listname -DisplayName "L3" -InternalName "l3" -Type:Text 
        Add-PnPField -List $listname -DisplayName "L4" -InternalName "l4" -Type:Text 
        Add-PnPField -List $listname -DisplayName "L5" -InternalName "l5" -Type:Text 

        # Add-PnPView -List $listname -Title "Overview" -Fields "Title","User Email" -SetAsDefault:$true -ViewType:Html

       $list = Get-PnPList $listname 
     }
$itemcreateinfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
$listitem = $list.AddItem($itemcreateinfo)
$listitem["Title"] = "Niels Gregers Johansen (ngjoh@nets.eu)"
$listitem["user_email"] = "ngjoh@nets.eu"
# $listitem["BackgroundImageLocation"] = "$onenote, $onenote"
# $listitem["LinkLocation"] = "$($targetSiteUri.LocalPath)/_layouts/15/WopiFrame.aspx?sourcedoc=$($targetSiteUri.AbsoluteUri)/SiteAssets/Team Site Notebook&action=editnew, $($targetSiteUri.LocalPath)/_layouts/15/WopiFrame.aspx?sourcedoc=$($targetSiteUri.AbsoluteUri)/SiteAssets/Team Site Notebook&action=editnew"
# $listitem["LaunchBehavior"] = "In page navigation"
# $listitem["TileOrder"] = "0"
$listitem.Update()
Execute-PnPQuery


}


CreateUserAdoptionList

Exit-Hexa $result


