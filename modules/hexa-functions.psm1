#  https://github.com/SharePoint/PnP-PowerShell/tree/master/Documentation
function Enter-Hexa{
    param($req,$res,$this)


write-output "This '$this'"
if ($this){
    $global:testing = $true
    $Global:result = "$this\output.json"
    $triggerInput = "$this\input.json"
    $inputJSON = Get-Content $triggerInput -Raw
    $Global:request =  ConvertFrom-Json -InputObject $inputJSON
}
else {
    $global:result = $res
    $Global:request =  Get-Content $req -Raw | ConvertFrom-Json 
}



$code = $env:O365ADMINPWD
$username = $env:O365ADMIN
$tenant = $env:O365TENANT

write-output "**  Initializing  ***************************"
write-output "Req '$req'" 
write-output "Request '$request'" 
write-output "Tenant '$tenant'" 
write-output "*********************************************"

$Password = convertto-securestring $code -asplaintext -force
$Global:credentials  = new-object System.Management.Automation.psCredential $username, $Password -ErrorAction:Stop

}

function Exit-Hexa{
param(
        $result
    )

write-output "**  DONE  ***********************************"


$resultJson = ConvertTo-Json -InputObject $result
#$_binding.log = $result
Out-File -Encoding Ascii -FilePath $global:result -inputObject $resultJson

if ($global:testing){
    write-output "TEST RESULT:"

    Write-Output $resultJson
}

write-output "*********************************************"

}