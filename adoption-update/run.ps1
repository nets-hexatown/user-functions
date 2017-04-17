# If hosted in Azure Web Jobs modules are auto loaded
if ($PSScriptRoot){ 
    Import-Module ".\modules\hexa-functions.psm1" -ErrorAction:SilentlyContinue
}

Enter-Hexa $req $res $PSScriptRoot
$name = "adoption-update"
$root = $PSScriptRoot
if ($root -eq $null)
{
    $root = "$($env:HOME)\wwwroot\$name"
}

"$root\readUsers.ps1"
"$root\updatelicenses.ps1"
"$root\buildorganisation.ps1"

Exit-Hexa $result

