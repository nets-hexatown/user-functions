#  https://github.com/SharePoint/PnP-PowerShell/tree/master/Documentation
function Enter-Hexa{
    param($req,$res,$this)

    $global:o365AdminPwd = $env:O365ADMINPWD
    $global:o365Admin = $env:O365ADMIN
    $global:o365Tenant = $env:O365TENANT

    write-output "This '$this'"
    if ($this){
        $config = get-content "$this\..\config.json" -raw -ErrorAction:SilentlyContinue | ConvertFrom-Json

        if ($config){
            Write-Output  "Active config '$($config.active)'"
            foreach ($configuration in $config.configurations) {
                if ($config.active -eq $configuration.name){
                    foreach ($env in $configuration.environment) {
                        foreach ($pair in $env){
                            foreach ($property in $pair.PSObject.Properties) {
                                
                                 Set-Variable -Name $property.Name  -Value $property.Value  -Scope Global
                                }
                            
                        }
                    }
                }
            }
        }
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





    write-output "**  Initializing  ***************************"
    write-output "Req '$req'" 
    write-output "Request '$request'" 
    write-output "o365Tenant '$o365Tenant'" 
    write-output "*********************************************"

    $Password = convertto-securestring $global:o365AdminPwd -asplaintext -force
    $Global:credentials  = new-object System.Management.Automation.psCredential $global:o365Admin, $Password -ErrorAction:Stop

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