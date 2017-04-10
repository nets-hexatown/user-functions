
# Adoption
> This function  is in a early alpha, make a fork and start contributing is you can see any purpose of this!

User adoption tracked by reading out indicators from Azure. Initial focus is to track that a user have:

- [x] Display Name
- [x] User Principial Name (UPN)
- [ ] First date seen
- [ ] Last date seen
- [ ] Is active
- [ ] Core license: E1 or E3 or E5
- [ ] Enrolled a Windows 10 device - name of last device enrolled
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

