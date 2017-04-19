#  https://github.com/SharePoint/PnP-PowerShell/tree/master/Documentation
$initConfig = @"
{
    "version": "0.1.0",
    "active": "test",
    "configurations": [
        {
            "name": "production",
            "environment": [
                {
                    "O365ADMIN": "*****@tenant.onmicrosoft.com",
                    "O365ADMINPWD": "*******",
                    "O365TENANT": "tenant"
                }
            ]
        },
        {
            "name": "test",
            "environment": [
                {
                    "O365ADMIN": "*****@test-tenant.onmicrosoft.com",
                    "O365ADMINPWD": "*******",
                    "O365TENANT": "test-tenant"
                }
            ]
        }
    ]
}
"@
function Enter-Hexa{
    param($req,$res,$this)

    #TODO: Check Environment

    $global:o365AdminPwd = $env:O365ADMINPWD
    $global:o365Admin = $env:O365ADMIN
    $global:o365Tenant = $env:O365TENANT
    $global:HEXAUSERSTORAGEACCOUNT = $env:HEXAUSERSTORAGEACCOUNT
    $global:HEXAUSERSTORAGEACCOUNTKEY = $env:HEXAUSERSTORAGEACCOUNTKEY
    
    if ($this){
      #  write-host -ForegroundColor "green" "Testing '$this'"
        $config = get-content "$this\..\config.json" -raw -ErrorAction:SilentlyContinue | ConvertFrom-Json
        if ($config -eq $null){
            Set-Content "$this\..\config.json" -Value $initConfig
            # Write-Host -ForegroundColor "white" -BackgroundColor "red" "Missing configuration file, new created"
            exit 
        }
        if ($config){
           # Write-Host -ForegroundColor "green"  "Active config '$($config.active)'"
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
        $Global:resultOutPutFileName = "$this\output.json"
        $triggerInput = "$this\input.json"
        $inputJSON = Get-Content $triggerInput -Raw
        $Global:request =  ConvertFrom-Json -InputObject $inputJSON
    }
    else {
        $Global:resultOutPutFileName = $res
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

function Get-Parameter{
    param(
        $name
    )
    

    $result = Get-Variable -Name $name -Scope Global
    if ($result -eq $null){
        Write-Output "Environment variable '$name' is not set"
        exit 
    }
    $v = $result.value
    return $v.ToString()

}

function Exit-Hexa{
    param(
        $result
    )

    write-output "**  DONE  ***********************************"


    $resultJson = ConvertTo-Json -InputObject $result
    #$_binding.log = $result
    Out-File -Encoding Ascii -FilePath $global:resultOutPutFileName -inputObject $resultJson

    if ($global:testing){
        write-output "TEST RESULT:"

        Write-Output $resultJson
    }

    write-output "*********************************************"

}

function Hexa-Log($text){
    if ($global:hexaLog  -eq $null){
        $global:hexaLog = @()
    }
    
    $global:hexaLog += "$(get-date -Format 'HH:mm:ss')  $text"
}

function Output-Hexalog(){
if ($global:hexaLog -ne $null){
    foreach ($item in $global:hexaLog) {
        Write-Output $item
    }
}
}
