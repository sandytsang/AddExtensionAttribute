# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

#Connect to Microsoft Graph
$BaseURI = 'https://graph.microsoft.com/'
$URI = "${Env:MSI_ENDPOINT}?resource=${BaseURI}&api-version=2017-09-01"
$Response = Invoke-RestMethod -Method Get -Headers @{Secret = $Env:MSI_SECRET } -Uri $URI
$accessToken = $response.access_token
$Global:AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer " + $accessToken
    }


try {
    #Get Server group membership
    $GroupObjectId = "788637d5-2271-43df-9f62-31650ea58f0b" #Change this to your AAD Group ID
    $Servers = Invoke-MSGraphOperation -Get -Resource "groups/$GroupObjectId/members" -APIVersion Beta

    #Add extensionAttribute1
$body = @'
{
    "extensionAttributes": {
        "extensionAttribute1": "WindowsServer"
    }
}
'@

    foreach ($Server in $Servers) {
        try {
            $DeviceId = $Server.id
            $ServerName = $Server.displayName
            $GraphResponse = Invoke-MSGraphOperation -Patch -Resource "devices/$DeviceId" -APIVersion Beta -Body $body
            $Output = "ExtensionAtribute is added to $ServerName"
            write-output $Output
        }
        catch [System.Exception]{
            $Output = "Add ExtensionAtribute on $ServerName failed. Error: $($_.Exception.Message)"
            write-output $Output
        }
    }
}
catch [System.Exception]{
    write-output "$($_.Exception.Message)"
}



