
# Adoption
> This function  is in a early alpha, make a fork and start contributing is you can see any purpose of this!

User adoption tracked by reading out indicators from Azure. Initial focus is to track that a user have:

- [x] Display Name
- [x] User Principial Name (UPN)
- [ ] First date seen
- [ ] Last date seen
- [ ] Is active
- [x] Core license: E3 and/or EMS
- [x] Enrolled a Windows 10 device - name of enrolled devices
- [ ] Number of licenses actived for Microsoft Office365 ProPlus
- [ ] Last date tracked on OneDrive for Business usage
- [ ] Last date tracked on Skype for  for Business usage
- [ ] Last date tracked on Yammer usage
- [ ] Last date tracked on Workplace usage

Status is stored in a SharePoint list named "User Adoption Status"

## Required environment variables

O365ADMIN
O365TENANT
O365ADMINPWD

### Setting the variables using a Windows console window

    SET O365ADMIN=admin@xxxxx.onmicrosoft.com
    SET O365TENANT=xxxxx
    SET O365ADMINPWD=********

### Setting the variables in Azure Functions
[Configuring Azure Functions](../_docs/CONFIGURE.md)


### Sample data

#### User with all licenses
```json
 {
        "ExtensionProperty":  {
                                  "odata.type":  "Microsoft.DirectoryServices.User",
                                  "deletionTimestamp":  null,
                                  "facsimileTelephoneNumber":  null
                              },
        "DeletionTimeStamp":  null,
        "ObjectId":  "*************************",
        "ObjectType":  "User",
        "AccountEnabled":  true,
        "AssignedLicenses":  [
                                 "class AssignedLicense {\n  DisabledPlans: System.Collections.Generic.List`1[System.String]\n  SkuId: 84a661c4-e949-4bd2-a560-ed7766fcaf2b\n}\n",
                                 "class AssignedLicense {\n  DisabledPlans: System.Collections.Generic.List`1[System.String]\n  SkuId: b05e124f-c7cc-45a0-a6aa-8cf78c946968\n}\n",
                                 "class AssignedLicense {\n  DisabledPlans: System.Collections.Generic.List`1[System.String]\n  SkuId: c7df2760-2c81-4ef7-b578-5b5392b571df\n}\n"
                             ],
        "AssignedPlans":  [
                              "class AssignedPlan {\n  AssignedTimestamp: 18-12-2016 08:22:19\n  CapabilityStatus: Enabled\n  Service: AADPremiumService\n  ServicePlanId: 41781fb2-bc02-4b7c-bd55-b576c07bb09d\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 18-12-2016 08:22:19\n  CapabilityStatus: Enabled\n  Service: MultiFactorService\n  ServicePlanId: 8a256a2b-b617-496d-b51b-e76466e88db0\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 18-12-2016 08:22:19\n  CapabilityStatus: Enabled\n  Service: AADPremiumService\n  ServicePlanId: eec0eb4f-6444-4f95-aba0-50c24d67f998\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 18-12-2016 08:22:19\n  CapabilityStatus: Enabled\n  Service: SCO\n  ServicePlanId: c1ec4a95-1f05-45b3-a911-aa3fa01094f5\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 18-12-2016 08:22:19\n  CapabilityStatus: Enabled\n  Service: RMSOnline\n  ServicePlanId: 6c57d4b6-3b23-47a5-9bc9-69f17b4947b3\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 18-12-2016 08:22:19\n  CapabilityStatus: Enabled\n  Service: RMSOnline\n  ServicePlanId: 5689bec4-755d-4753-8b61-40975025187c\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 18-12-2016 08:22:19\n  CapabilityStatus: Enabled\n  Service: Adallom\n  ServicePlanId: 2e2ddb96-6af9-4b1d-a3f0-d6ecfd22edb2\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: SharePoint\n  ServicePlanId: e95bec33-7c88-4a70-8e19-b10bd9d0c014\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: SharePoint\n  ServicePlanId: 5dbe027f-2339-4123-9542-606e4d348a72\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: exchange\n  ServicePlanId: efb87545-963c-4e0d-99df-69c6916d9eb0\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: MicrosoftCommunicationsOnline\n  ServicePlanId: 0feaeb32-d00e-4d66-bd5a-43b5b83db82c\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: MicrosoftOffice\n  ServicePlanId: 43de0ff5-c92c-492b-9116-175376d08c38\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: YammerEnterprise\n  ServicePlanId: 7547a3fe-08ee-4ccb-b430-5077c5041653\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: RMSOnline\n  ServicePlanId: bea4c11e-220a-4e6d-8eb8-8ea15d019f90\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: ProjectWorkManagement\n  ServicePlanId: b737dad2-2f6c-4c65-90e3-ca563267e8b9\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: PowerBI\n  ServicePlanId: 70d33638-9c74-4d01-bfd3-562de28bd4ba\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: MicrosoftCommunicationsOnline\n  ServicePlanId: 3e26ee1f-8a5f-4d52-aee2-b81ce45c8f40\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: MicrosoftCommunicationsOnline\n  ServicePlanId: 4828c8ec-dc2e-4779-b502-87ac9ce28ab7\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: Sway\n  ServicePlanId: a23b959c-7ce8-4e57-9140-b90eb88a9e97\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: exchange\n  ServicePlanId: 34c0d7a0-a70f-4668-9238-47f9fc208882\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: exchange\n  ServicePlanId: 9f431833-0334-42de-a7dc-70aa40db46db\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: exchange\n  ServicePlanId: 4de31727-a228-4ec3-a5bf-8e45b5ca48cc\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: Adallom\n  ServicePlanId: 8c098270-9dd4-4350-9b30-ba4703f3b36b\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: TeamspaceAPI\n  ServicePlanId: 57ff2da0-773e-42df-b2af-ffb7a2317929\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: PowerAppsService\n  ServicePlanId: 9c0dab89-a30c-4117-86e7-97bda240acd2\n}\n",
                              "class AssignedPlan {\n  AssignedTimestamp: 17-12-2016 18:42:31\n  CapabilityStatus: Enabled\n  Service: ProcessSimple\n  ServicePlanId: 07699545-9485-468e-95b6-2fca3738be01\n}\n"
                          ],
        "City":  null,
        "CompanyName":  null,
        "Country":  "DK",
        "CreationType":  null,
        "Department":  null,
        "DirSyncEnabled":  null,
        "DisplayName":  "Niels Gregers Johansen",
        "FacsimilieTelephoneNumber":  null,
        "GivenName":  "Niels Gregers",
        "IsCompromised":  null,
        "ImmutableId":  null,
        "JobTitle":  null,
        "LastDirSyncTime":  null,
        "Mail":  "niels@365admin.net",
        "MailNickName":  "niels",
        "Mobile":  "+45 29487624",
        "OnPremisesSecurityIdentifier":  null,
        "OtherMails":  [
                           "niels@timeboxer.dk"
                       ],
        "PasswordPolicies":  null,
        "PasswordProfile":  null,
        "PhysicalDeliveryOfficeName":  null,
        "PostalCode":  null,
        "PreferredLanguage":  "en-US",
        "ProvisionedPlans":  [
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: MicrosoftCommunicationsOnline\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: MicrosoftCommunicationsOnline\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: MicrosoftCommunicationsOnline\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: exchange\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: exchange\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: exchange\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: exchange\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: SharePoint\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: SharePoint\n}\n",
                                 "class ProvisionedPlan {\n  CapabilityStatus: Enabled\n  ProvisioningStatus: Success\n  Service: exchange\n}\n"
                             ],
        "ProvisioningErrors":  [

                               ],
        "ProxyAddresses":  [
                               "smtp:niels@365adm.onmicrosoft.com",
                               "SMTP:niels@365admin.net"
                           ],
        "RefreshTokensValidFromDateTime":  "\/Date(1482000119000)\/",
        "ShowInAddressList":  null,
        "SignInNames":  [

                        ],
        "SipProxyAddress":  "niels@365admin.net",
        "State":  null,
        "StreetAddress":  null,
        "Surname":  "Johansen",
        "TelephoneNumber":  null,
        "UsageLocation":  "DK",
        "UserPrincipalName":  "niels@365admin.net",
        "UserType":  "Member"
    },
```