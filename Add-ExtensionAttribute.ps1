<#
.SYNOPSIS
    This script is for adding extension Attribute to server devices that are in Domain Servers group
    This script requires two Microsoft Graph permission 
    - Device.ReadWrite.All
    - GroupMember.Read.All

.DESCRIPTION
    This script will add extension Attribute to Azure AD device

.NOTES
    File name: Add-ExtensionAttribute.ps1
    VERSION: 1.0.0
    AUTHOR: Sandy Zeng
    Created:  2021-09-23
    COPYRIGHT:
    Sandy Zeng / https://www.cloudway.com


.VERSION HISTORY:
    1.0.0 - (2021-09-23) Script created
          
#>

try {
    #Require MSAL.PS module
    Import-Module -Name MSAL.PS
    Import-Module -Name MSGraphRequest

    #Get Token if running in local machine
    $Tenant = "jticorp.onmicrosoft.com"
    $Global:AuthenticationHeader = Get-AccessToken -TenantID $Tenant -ClientID "f38c1076-cbf2-4" #Change this to your own client ID

    #Get Server group membership
    $GroupObjectId = "788637d5-2271-43b" #Change this to your AAD Group ID
    $Servers = Invoke-MSGraphOperation -Get -Resource "groups/$GroupObjectId/members" -APIVersion Beta

    #Add extensionAttribute1
$body = @'
{
    "extensionAttributes": {
        "extensionAttribute1": "Windows10"
    }
}
'@

    foreach ($Server in $Servers) {
        $DeviceId = $Server.id
        $ServerName = $Server.displayName
        Invoke-MSGraphOperation -Patch -Resource "devices/$DeviceId" -APIVersion Beta -Body $body
        Write-Output "ExtensionAtribute is added to $ServerName "
    }
}
catch [System.Exception]{
    Write-Error  "Error Installing updates: $($_.Exception.Message)"
}
