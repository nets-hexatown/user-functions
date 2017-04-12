# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

# Authorization script commandlet that builds on top of existing Insights comandlets. 
# This commandlet gets all events for the "Microsoft.Authorization" resource provider by calling the "Get-AzureRmResourceProviderLog" commandlet

function Get-AzureRmAuthorizationChangeLog { 
<#

.SYNOPSIS

Gets access change history for the selected subscription for the specified time range i.e. role assignments that were added or removed, including classic administrators (co-administrators and service administrators).
Maximum duration that can be queried is 15 days (going back up to past 90 days).


.DESCRIPTION

The Get-AzureRmAuthorizationChangeLog produces a report of who granted (or revoked) what role to whom at what scope within the subscription for the specified time range. 

The command queries all role assignment events from the Insights resource provider of Azure Resource Manager. Specifying the time range is optional. If both StartTime and EndTime parameters are not specified, the default query interval is the past 1 hour. Maximum duration that can be queried is 15 days (going back up to past 90 days).


.PARAMETER StartTime 

Start time of the query. Optional.


.PARAMETER EndTime 

End time of the query. Optional


.EXAMPLE 

Get-AzureRmAuthorizationChangeLog

Gets the access change logs for the past hour.


.EXAMPLE   

Get-AzureRmAuthorizationChangeLog -StartTime "09/20/2015 15:00" -EndTime "09/24/2015 15:00"

Gets all access change logs between the specified dates

Timestamp        : 2015-09-23 21:52:41Z
Caller           : admin@rbacCliTest.onmicrosoft.com
Action           : Revoked
PrincipalId      : 54401967-8c4e-474a-9fbb-a42073f1783c
PrincipalName    : testUser
PrincipalType    : User
Scope            : /subscriptions/9004a9fd-d58e-48dc-aeb2-4a4aec58606f/resourceGroups/TestRG/providers/Microsoft.Network/virtualNetworks/testresource
ScopeName        : testresource
ScopeType        : Resource
RoleDefinitionId : /subscriptions/9004a9fd-d58e-48dc-aeb2-4a4aec58606f/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c
RoleName         : Contributor


.EXAMPLE 

Get-AzureRmAuthorizationChangeLog  -StartTime ([DateTime]::Now - [TimeSpan]::FromDays(5)) -EndTime ([DateTime]::Now) | FT Caller, Action, RoleName, PrincipalName, ScopeType

Gets access change logs for the past 5 days and format the output

Caller                  Action                  RoleName                PrincipalName           ScopeType
------                  ------                  --------                -------------           ---------
admin@contoso.com       Revoked                 Contributor             User1                   Subscription
admin@contoso.com       Granted                 Reader                  User1                   Resource Group
admin@contoso.com       Revoked                 Contributor             Group1                  Resource

.LINK

New-AzureRmRoleAssignment

.LINK

Get-AzureRmRoleAssignment

.LINK

Remove-AzureRmRoleAssignment

#>

    [CmdletBinding()] 
    param(  
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage = "The start time. Optional
             If both StartTime and EndTime are not provided, defaults to querying for the past 1 hour. Maximum allowed difference in StartTime and EndTime is 15 days")] 
        [DateTime] $StartTime,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage = "The end time. Optional. 
            If both StartTime and EndTime are not provided, defaults to querying for the past 1 hour. Maximum allowed difference in StartTime and EndTime is 15 days")] 
        [DateTime] $EndTime
    ) 
    PROCESS { 
         # Get all events for the "Microsoft.Authorization" provider by calling the Insights commandlet
         $events = Get-AzureRmLog -ResourceProvider "Microsoft.Authorization" -DetailedOutput -StartTime $StartTime -EndTime $EndTime
             
         $startEvents = @{}
         $endEvents = @{}
         $offlineEvents = @()

         # StartEvents and EndEvents will contain matching pairs of logs for when role assignments (and definitions) were created or deleted. 
         # i.e. A PUT on roleassignments will have a Start-End event combination and a DELETE on roleassignments will have another Start-End event combination
         $startEvents = $events | ? { $_.httpRequest -and $_.Status -ieq "Started" }
         $events | ? { $_.httpRequest -and $_.Status -ne "Started" } | % { $endEvents[$_.OperationId] = $_ }
         # This filters non-RBAC events like classic administrator write or delete
         $events | ? { $_.httpRequest -eq $null } | % { $offlineEvents += $_ } 

         $output = @()

         # Get all role definitions once from the service and cache to use for all 'startevents'
         $azureRoleDefinitionCache = @{}
         Get-AzureRmRoleDefinition | % { $azureRoleDefinitionCache[$_.Id] = $_ }

         $principalDetailsCache = @{}

         # Process StartEvents
         # Find matching EndEvents that succeeded and relating to role assignments only
         $startEvents | ? { $endEvents.ContainsKey($_.OperationId) `
             -and $endEvents[$_.OperationId] -ne $null `
             -and $endevents[$_.OperationId].OperationName.StartsWith("Microsoft.Authorization/roleAssignments", [System.StringComparison]::OrdinalIgnoreCase)  `
             -and $endEvents[$_.OperationId].Status -ieq "Succeeded"} |  % {
       
         $endEvent = $endEvents[$_.OperationId];
        
         # Create the output structure
         $out = "" | select Timestamp, Caller, Action, PrincipalId, PrincipalName, PrincipalType, Scope, ScopeName, ScopeType, RoleDefinitionId, RoleName
				 
         $out.Timestamp = Get-Date -Date $endEvent.EventTimestamp -Format u
         $out.Caller = $_.Caller
         if ($_.HttpRequest.Method -ieq "PUT") {
            $out.Action = "Granted"
            if ($_.Properties.Content.ContainsKey("requestbody")) {
                $messageBody = ConvertFrom-Json $_.Properties.Content["requestbody"]
            }
             
          $out.Scope =  $_.Authorization.Scope
        } 
        elseif ($_.HttpRequest.Method -ieq "DELETE") {
            $out.Action = "Revoked"
            if ($endEvent.Properties.Content.ContainsKey("responseBody")) {
                $messageBody = ConvertFrom-Json $endEvent.Properties.Content["responseBody"]
            }
        }

        if ($messageBody) {
            # Process principal details
            $out.PrincipalId = $messageBody.properties.principalId
            if ($out.PrincipalId -ne $null) { 
				# Get principal details by querying Graph. Cache principal details and read from cache if present
				$principalId = $out.PrincipalId 
                
				if($principalDetailsCache.ContainsKey($principalId)) {
					# Found in cache
                    $principalDetails = $principalDetailsCache[$principalId]
                } else { # not in cache
		            $principalDetails = "" | select Name, Type
                    $user = Get-AzureRmADUser -ObjectId $principalId
                    if ($user) {
                        $principalDetails.Name = $user.DisplayName
                        $principalDetails.Type = "User"    
                    } else {
                        $group = Get-AzureRmADGroup -ObjectId $principalId
                        if ($group) {
                            $principalDetails.Name = $group.DisplayName
                            $principalDetails.Type = "Group"        
                        } else {
                            $servicePrincipal = Get-AzureRmADServicePrincipal -objectId $principalId
                            if ($servicePrincipal) {
                                $principalDetails.Name = $servicePrincipal.DisplayName
                                $principalDetails.Type = "Service Principal"                        
                            }
                        }
                    }              
					# add principal details to cache
                    $principalDetailsCache.Add($principalId, $principalDetails);
	            }

                $out.PrincipalName = $principalDetails.Name
                $out.PrincipalType = $principalDetails.Type
            }

			# Process scope details
            if ([string]::IsNullOrEmpty($out.Scope)) { $out.Scope = $messageBody.properties.Scope }
            if ($out.Scope -ne $null) {
				# Remove the authorization provider details from the scope, if present
			    if ($out.Scope.ToLower().Contains("/providers/microsoft.authorization")) {
					$index = $out.Scope.ToLower().IndexOf("/providers/microsoft.authorization") 
					$out.Scope = $out.Scope.Substring(0, $index) 
				}

              	$scope = $out.Scope 
				$resourceDetails = "" | select Name, Type
                $scopeParts = $scope.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)
                $len = $scopeParts.Length

                if ($len -gt 0 -and $len -le 2 -and $scope.ToLower().Contains("subscriptions"))	{
                    $resourceDetails.Type = "Subscription"
                    $resourceDetails.Name  = $scopeParts[1]
                } elseif ($len -gt 0 -and $len -le 4 -and $scope.ToLower().Contains("resourcegroups")) {
                    $resourceDetails.Type = "Resource Group"
                    $resourceDetails.Name  = $scopeParts[3]
                    } elseif ($len -ge 6 -and $scope.ToLower().Contains("providers")) {
                        $resourceDetails.Type = "Resource"
                        $resourceDetails.Name  = $scopeParts[$len -1]
                        }
                
				$out.ScopeName = $resourceDetails.Name
                $out.ScopeType = $resourceDetails.Type
            }

			# Process Role definition details
            $out.RoleDefinitionId = $messageBody.properties.roleDefinitionId
			
            if ($out.RoleDefinitionId -ne $null) {
								
				#Extract roleDefinitionId Guid value from the fully qualified id string.
				$roleDefinitionIdGuid= $out.RoleDefinitionId.Substring($out.RoleDefinitionId.LastIndexOf("/")+1)

                if ($azureRoleDefinitionCache[$roleDefinitionIdGuid]) {
                    $out.RoleName = $azureRoleDefinitionCache[$roleDefinitionIdGuid].Name
                } else {
                    $out.RoleName = ""
                }
            }
        }
        $output += $out
    } # start event processing complete

    # Filter classic admins events
    $offlineEvents | % {
        if($_.Status -ne $null -and $_.Status -ieq "Succeeded" -and $_.OperationName -ne $null -and $_.operationName.StartsWith("Microsoft.Authorization/ClassicAdministrators", [System.StringComparison]::OrdinalIgnoreCase)) {
            
            $out = "" | select Timestamp, Caller, Action, PrincipalId, PrincipalName, PrincipalType, Scope, ScopeName, ScopeType, RoleDefinitionId, RoleName
            $out.Timestamp = Get-Date -Date $_.EventTimestamp -Format u
            $out.Caller = "Subscription Admin"

            if($_.operationName -ieq "Microsoft.Authorization/ClassicAdministrators/write"){
                $out.Action = "Granted"
            } 
            elseif($_.operationName -ieq "Microsoft.Authorization/ClassicAdministrators/delete"){
                $out.Action = "Revoked"
            }

            $out.RoleDefinitionId = $null
            $out.PrincipalId = $null
            $out.PrincipalType = "User"
            $out.Scope = "/subscriptions/" + $_.SubscriptionId
            $out.ScopeType = "Subscription"
            $out.ScopeName = $_.SubscriptionId
                                
            if($_.Properties -ne $null){
                $out.PrincipalName = $_.Properties.Content["adminEmail"]
                $out.RoleName = "Classic " + $_.Properties.Content["adminType"]
            }
                     
            $output += $out
        }
    } # end offline events

    $output | Sort Timestamp
} 
} # End commandlet
 

# SIG # Begin signature block
# MIIkGwYJKoZIhvcNAQcCoIIkDDCCJAgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD1aIG6oFrw5Hw0
# KihOeY9wUbQ9YuZoQAqgPB6b76kKyqCCDZMwggYRMIID+aADAgECAhMzAAAAjoeR
# pFcaX8o+AAAAAACOMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTYxMTE3MjIwOTIxWhcNMTgwMjE3MjIwOTIxWjCBgzEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjENMAsGA1UECxMETU9Q
# UjEeMBwGA1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEA0IfUQit+ndnGetSiw+MVktJTnZUXyVI2+lS/qxCv
# 6cnnzCZTw8Jzv23WAOUA3OlqZzQw9hYXtAGllXyLuaQs5os7efYjDHmP81LfQAEc
# wsYDnetZz3Pp2HE5m/DOJVkt0slbCu9+1jIOXXQSBOyeBFOmawJn+E1Zi3fgKyHg
# 78CkRRLPA3sDxjnD1CLcVVx3Qv+csuVVZ2i6LXZqf2ZTR9VHCsw43o17lxl9gtAm
# +KWO5aHwXmQQ5PnrJ8by4AjQDfJnwNjyL/uJ2hX5rg8+AJcH0Qs+cNR3q3J4QZgH
# uBfMorFf7L3zUGej15Tw0otVj1OmlZPmsmbPyTdo5GPHzwIDAQABo4IBgDCCAXww
# HwYDVR0lBBgwFgYKKwYBBAGCN0wIAQYIKwYBBQUHAwMwHQYDVR0OBBYEFKvI1u2y
# FdKqjvHM7Ww490VK0Iq7MFIGA1UdEQRLMEmkRzBFMQ0wCwYDVQQLEwRNT1BSMTQw
# MgYDVQQFEysyMzAwMTIrYjA1MGM2ZTctNzY0MS00NDFmLWJjNGEtNDM0ODFlNDE1
# ZDA4MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0Nv
# ZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsG
# AQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01p
# Y0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkq
# hkiG9w0BAQsFAAOCAgEARIkCrGlT88S2u9SMYFPnymyoSWlmvqWaQZk62J3SVwJR
# avq/m5bbpiZ9CVbo3O0ldXqlR1KoHksWU/PuD5rDBJUpwYKEpFYx/KCKkZW1v1rO
# qQEfZEah5srx13R7v5IIUV58MwJeUTub5dguXwJMCZwaQ9px7eTZ56LadCwXreUM
# tRj1VAnUvhxzzSB7pPrI29jbOq76kMWjvZVlrkYtVylY1pLwbNpj8Y8zon44dl7d
# 8zXtrJo7YoHQThl8SHywC484zC281TllqZXBA+KSybmr0lcKqtxSCy5WJ6PimJdX
# jrypWW4kko6C4glzgtk1g8yff9EEjoi44pqDWLDUmuYx+pRHjn2m4k5589jTajMW
# UHDxQruYCen/zJVVWwi/klKoCMTx6PH/QNf5mjad/bqQhdJVPlCtRh/vJQy4njpI
# BGPveJiiXQMNAtjcIKvmVrXe7xZmw9dVgh5PgnjJnlQaEGC3F6tAE5GusBnBmjOd
# 7jJyzWXMT0aYLQ9RYB58+/7b6Ad5B/ehMzj+CZrbj3u2Or2FhrjMvH0BMLd7Hald
# G73MTRf3bkcz1UDfasouUbi1uc/DBNM75ePpEIzrp7repC4zaikvFErqHsEiODUF
# he/CBAANa8HYlhRIFa9+UrC4YMRStUqCt4UqAEkqJoMnWkHevdVmSbwLnHhwCbww
# ggd6MIIFYqADAgECAgphDpDSAAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5
# MDlaFw0yNjA3MDgyMTA5MDlaMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIw
# MTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQ
# TTS68rZYIZ9CGypr6VpQqrgGOBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULT
# iQ15ZId+lGAkbK+eSZzpaF7S35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYS
# L+erCFDPs0S3XdjELgN1q2jzy23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494H
# DdVceaVJKecNvqATd76UPe/74ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZ
# PrGMXeiJT4Qa8qEvWeSQOy2uM1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5
# bmR/U7qcD60ZI4TL9LoDho33X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGS
# rhwjp6lm7GEfauEoSZ1fiOIlXdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADh
# vKwCgl/bwBWzvRvUVUvnOaEP6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON
# 7E1JMKerjt/sW5+v/N2wZuLBl4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xc
# v3coKPHtbcMojyyPQDdPweGFRInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqw
# iBfenk70lrC8RqBsmNLg1oiMCwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFEhuZOVQBdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQM
# HgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud
# IwQYMBaAFHItOgIxkEO5FAVO4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0
# dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0Nl
# ckF1dDIwMTFfMjAxMV8wM18yMi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUF
# BzAChkJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0Nl
# ckF1dDIwMTFfMjAxMV8wM18yMi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGC
# Ny4DMIGDMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2RvY3MvcHJpbWFyeWNwcy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcA
# YQBsAF8AcABvAGwAaQBjAHkAXwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZI
# hvcNAQELBQADggIBAGfyhqWY4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4s
# PvjDctFtg/6+P+gKyju/R6mj82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKL
# UtCw/WvjPgcuKZvmPRul1LUdd5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7
# pKkFDJvtaPpoLpWgKj8qa1hJYx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft
# 0N3zDq+ZKJeYTQ49C/IIidYfwzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4
# MnEnGn+x9Cf43iw6IGmYslmJaG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxv
# FX1Fp3blQCplo8NdUmKGwx1jNpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG
# 0QaxdR8UvmFhtfDcxhsEvt9Bxw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf
# 0AApxbGbpT9Fdx41xtKiop96eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkY
# S//WsyNodeav+vyL6wuA6mk7r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrv
# QQqxP/uozKRdwaGIm1dxVk5IRcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIV
# 3jCCFdoCAQEwgZUwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAA
# AI6HkaRXGl/KPgAAAAAAjjANBglghkgBZQMEAgEFAKCBzDAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkq
# hkiG9w0BCQQxIgQgVW8hIT6d7+U1f0D4CSnpO5Rf+PK9yNHAyJbxSrgYA9IwYAYK
# KwYBBAGCNwIBDDFSMFCgNoA0AE0AaQBjAHIAbwBzAG8AZgB0ACAAQQB6AHUAcgBl
# ACAAUABvAHcAZQByAFMAaABlAGwAbKEWgBRodHRwOi8vQ29kZVNpZ25JbmZvIDAN
# BgkqhkiG9w0BAQEFAASCAQA0r5lLsh8VCPAIBqmUcXzszt6HfTYU2ozlbPF916GF
# 1XaTw3KsRoV5rtlD2v9ao+zun2JR4X3Su7N7fjDDjJfry+1s0H6ThcKHhtXeq4m0
# QbXyb0EtqYdiTIArEG1IoiRGxsh9+3lGYyJ1XVUBFVznT0aLWAq1hlcyNJJyK9wT
# zlY9T/hHof/SnL0qiYLP1+oGByUv+dBnx/nAY6D+Vi8O81aCeoEVNkOHrYTew5/Q
# VcUd95dlpN7Rd/QEtlrU/NeMdaSBW7ykNyfmMoYe5gML5TMe9hcCcE8MzWjIV70V
# OM1jjUc4nwM7vWEltS8DJDn8QsM4Uh6xYCzWn4C4t3zSoYITSjCCE0YGCisGAQQB
# gjcDAwExghM2MIITMgYJKoZIhvcNAQcCoIITIzCCEx8CAQMxDzANBglghkgBZQME
# AgEFADCCAT0GCyqGSIb3DQEJEAEEoIIBLASCASgwggEkAgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEICfaV9Gge43MhG3pciHXgOlTuQEhw3aul3ZZWSQo
# awuZAgZY1Uyb5CYYEzIwMTcwNDA0MDEzODU1LjQ2NVowBwIBAYACAfSggbmkgbYw
# gbMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsT
# BE1PUFIxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjpCQkVDLTMwQ0EtMkRCRTEl
# MCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCDs0wggZxMIIE
# WaADAgECAgphCYEqAAAAAAACMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9v
# dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0xMDA3MDEyMTM2NTVaFw0y
# NTA3MDEyMTQ2NTVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqR0NvHcRijog7PwTl/X6f2mUa3RU
# ENWlCgCChfvtfGhLLF/Fw+Vhwna3PmYrW/AVUycEMR9BGxqVHc4JE458YTBZsTBE
# D/FgiIRUQwzXTbg4CLNC3ZOs1nMwVyaCo0UN0Or1R4HNvyRgMlhgRvJYR4YyhB50
# YWeRX4FUsc+TTJLBxKZd0WETbijGGvmGgLvfYfxGwScdJGcSchohiq9LZIlQYrFd
# /XcfPfBXday9ikJNQFHRD5wGPmd/9WbAA5ZEfu/QS/1u5ZrKsajyeioKMfDaTgaR
# togINeh4HLDpmc085y9Euqf03GS9pAHBIAmTeM38vMDJRF1eFpwBBU8iTQIDAQAB
# o4IB5jCCAeIwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFNVjOlyKMZDzQ3t8
# RhvFM2hahW1VMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIB
# hjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fO
# mhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9w
# a2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggr
# BgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGgBgNVHSAB
# Af8EgZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggrBgEF
# BQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBt
# AGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAB+aIUQ3ixuCYP4FxAz2do6Eh
# b7Prpsz1Mb7PBeKp/vpXbRkws8LFZslq3/Xn8Hi9x6ieJeP5vO1rVFcIK1GCRBL7
# uVOMzPRgEop2zEBAQZvcXBf/XPleFzWYJFZLdO9CEMivv3/Gf/I3fVo/HPKZeUqR
# UgCvOA8X9S95gWXZqbVr5MfO9sp6AG9LMEQkIjzP7QOllo9ZKby2/QThcJ8ySif9
# Va8v/rbljjO7Yl+a21dA6fHOmWaQjP9qYn/dxUoLkSbiOewZSnFjnXshbcOco6I8
# +n99lmqQeKZt0uGc+R38ONiU9MalCpaGpL2eGq4EQoO4tYCbIjggtSXlZOz39L9+
# Y1klD3ouOVd2onGqBooPiRa6YacRy5rYDkeagMXQzafQ732D8OE7cQnfXXSYIghh
# 2rBQHm+98eEA3+cxB6STOvdlR3jo+KhIq/fecn5ha293qYHLpwmsObvsxsvYgrRy
# zR30uIUBHoD7G4kqVDmyW9rIDVWZeodzOwjmmC3qjeAzLhIp9cAvVCch98isTtoo
# uLGp25ayp0Kiyc8ZQU3ghvkqmqMRZjDTu3QyS99je/WZii8bxyGvWbWu3EQ8l1Bx
# 16HSxVXjad5XwdHeMMD9zOZN+w2/XU/pnR4ZOC+8z1gFLu8NoFA12u8JJxzVs341
# Hgi62jbb01+P3nSISRIwggTaMIIDwqADAgECAhMzAAAAoaX9ue6n/J6dAAAAAACh
# MA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4X
# DTE2MDkwNzE3NTY0OFoXDTE4MDkwNzE3NTY0OFowgbMxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIxJzAlBgNVBAsTHm5D
# aXBoZXIgRFNFIEVTTjpCQkVDLTMwQ0EtMkRCRTElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAJvQAXnmIq96fBt1HvO3Z9Yd3qfeADTYEvkH6gh7H01NyoWUeqt2ayoHRY1R
# J9O2XUalJcZiFHmLT8zmLPXsn016HTQiNiq4w+LsxVDt0/1DwS2/xfD6z8yEkOui
# prJtV6CPuWFw1EnOiC+DLjuBSpO1SUrEZcmWheQv+qzi2FcdM/a+EOfCUhsT4PkU
# Nqizm/TbFfD00mt9LbhVzhHpVv+U6SEOu5FXzJwVeXDNjqzT44GZmMMOB9/bc8XP
# KWP1Puw3GHpz9iR1tfzJN5QwVwfVoEAVTQsWsObVN1082NOrvIeXh3pVc0thQ8Hz
# CYiSvs645YRKPBY3nEHOIJeByAkCAwEAAaOCARswggEXMB0GA1UdDgQWBBSrXLmC
# vnEq1Y/g6LIpz/ob07f6SDAfBgNVHSMEGDAWgBTVYzpcijGQ80N7fEYbxTNoWoVt
# VTBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtp
# L2NybC9wcm9kdWN0cy9NaWNUaW1TdGFQQ0FfMjAxMC0wNy0wMS5jcmwwWgYIKwYB
# BQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
# cGtpL2NlcnRzL01pY1RpbVN0YVBDQV8yMDEwLTA3LTAxLmNydDAMBgNVHRMBAf8E
# AjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBCwUAA4IBAQAjYEy4
# BVTpZ8m+OTwVMsMTyLMAkH8XM5v9di9dTBKz6LAkov6y9B+oso4uThAHXOj3NIru
# NB3o4USG+B7b3j0SlIfBmg9D4Jv6FGGrtuoS46qIatdld+UHW9BQU9HFWtQoLypK
# UXkfeTkqd8dh5SN/KgXaJp7VQLbiX9w6E3TlOv2q+z8C/Cv5+CBSWyjKXbIgKO4d
# HvSKhLwXUuqzEnGaLB0bTg140duTDSReF4hJVCH82Fwm0OkT4WzKTr8HuDv54Zwv
# RgxlOpxFsAmnc0wsa7bXFmPg/HI4maYFzTKRQaJe+rvXrQ57hcvzD3c7eDLTT5aR
# FEgjxoqXl1gd/aVBoYIDdjCCAl4CAQEwgeOhgbmkgbYwgbMxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIxJzAlBgNVBAsT
# Hm5DaXBoZXIgRFNFIEVTTjpCQkVDLTMwQ0EtMkRCRTElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaIlCgEBMAkGBSsOAwIaBQADFQCCron1tOY/
# FlwgvBfkwcNAzTnraKCBwjCBv6SBvDCBuTELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBO
# VFMgRVNOOjU3RjYtQzFFMC01NTRDMSswKQYDVQQDEyJNaWNyb3NvZnQgVGltZSBT
# b3VyY2UgTWFzdGVyIENsb2NrMA0GCSqGSIb3DQEBBQUAAgUA3I1mvjAiGA8yMDE3
# MDQwNDAwMjYzOFoYDzIwMTcwNDA1MDAyNjM4WjB0MDoGCisGAQQBhFkKBAExLDAq
# MAoCBQDcjWa+AgEAMAcCAQACAgiPMAcCAQACAhiWMAoCBQDcjrg+AgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwGgCjAIAgEAAgMW42ChCjAIAgEAAgMH
# oSAwDQYJKoZIhvcNAQEFBQADggEBAF2e2fvTfP/rc+FJbqqDEsOxVuSzPc3sF0CH
# sL4IM2moxLTqDXbILfXR/CcJWMqZCw930oiJ0Awzy0UsdvQIFxTnDMCB24cFnlXL
# 7lxF3sbb4r3o/lBIKumvzUdR4wlMBSP8k2W8wzXnEs341gIzV4vD97MKHoZroal5
# ZflKoOj+iazjoxD84aFtGjHGWoQYo2eY7O3Tw3s28acDK3oQSGnVrnMY84j/tpVO
# g4EW0CPPkopa1mHgSKBSz0rId9RxiQ+xGnE236IVdKBZy2T6rwmHSuqHVKqk4gRU
# rMs2RtYQrBE/lwGkXoojZ9Wx0XLav3HOvgmvL3jjbqs0bCbgPqgxggL1MIIC8QIB
# ATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAKGl/bnup/ye
# nQAAAAAAoTANBglghkgBZQMEAgEFAKCCATIwGgYJKoZIhvcNAQkDMQ0GCyqGSIb3
# DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCBQP/i2KetCjiEyxczUT4zdE0R5e4dwPz72
# hwroONsxYzCB4gYLKoZIhvcNAQkQAgwxgdIwgc8wgcwwgbEEFIKuifW05j8WXCC8
# F+TBw0DNOetoMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAC
# EzMAAAChpf257qf8np0AAAAAAKEwFgQUTP/Oi3wDiZ5MuydKYM/7XyH3YywwDQYJ
# KoZIhvcNAQELBQAEggEAGK+dHa8lSaVpD1TbInOpoPKOngOh3jKFghPuBrzee3AZ
# 6guBZwXt/RR74BG5A259/t8ZuJBaxW3stmKeA/GfFi7KZWKlb2LMe9dwjQkm/xi7
# veIrp9ULh63cqPnQAUFBvXZqI5lVHXm3/MXxx0LiVe93ljVt7n3qNTl8wqfaOL1P
# HQK0XgEelxYCRHtsaG4Cl8F3bT90QrxBRHsx8LFjSGioat5fo0T7ED/vSfK0jvr/
# UJ4D0fMSDd3CpEsKyrIfcJ2NtfGL8UXh98fr4WcfHdzDcxNAaiOZAxZ51wb+dBL7
# hJ7jdhF0dVktPW8kdyKl9kl8P/DmY8VclcFZ2rrKQA==
# SIG # End signature block
