# If hosted in Azure Web Jobs modules are auto loaded
if ($PSScriptRoot){ 
    Import-Module ".\modules\hexa-functions.psm1" -ErrorAction:SilentlyContinue
}

Enter-Hexa $req $res $PSScriptRoot
$name = "adoption-update"
$root = $PSScriptRoot
if ($root -eq  $null)
{
    
    $root = ($env:HOME +  "\wwwroot\" + $name)
    Write-Output "Running in Azure '$root'"
}

Invoke-Expression "$root\readUsers.ps1"
Invoke-Expression "$root\updatelicenses.ps1"
Invoke-Expression "$root\buildorganisation.ps1"

Exit-Hexa $result

