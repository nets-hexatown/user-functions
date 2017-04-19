$userAdoptionListname = "User Adoption Status"
function SharePointConnect(){
    $tenant = $global:O365TENANT
    $relativeUrl = $global:request.siteRelativeUrl
    $url = "https://$tenant.sharepoint.com$relativeUrl"
    Connect-PnPOnline -Url $url -Credentials ($global:credentials) -ErrorAction:Stop

    

}
function SharePointCreateUserAdoptionList($userAdoptionListname){
    #Remove-PnPList -Identity $userAdoptionListname -Force
    write-Output "Checking status list"
    $list = Get-PnPList $userAdoptionListname 
    if ($list -eq $null){

        Write-Output "Creating list $userAdoptionListname"
        New-PnPList -Title $userAdoptionListname -Template "Custom" -ErrorAction:Stop
        Set-PnPList -Identity $userAdoptionListname -EnableVersioning $true
        Add-PnPField -List $userAdoptionListname -DisplayName "UserPrincipalName" -InternalName "UserPrincipalName" -Type:Text -AddToDefaultView
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

