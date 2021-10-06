
# Assign static variables
$MSIObjectID = "7ba08f0a-1571-4345-a30a-6fb39273fcb6" #change this to your object id

# Authenticate against Azure AD, as Global Administrator
Connect-AzureAD

$MSGraphAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph (graph.microsoft.com) application ID
$MSGraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$($MSGraphAppId)'"
$RoleNames = @("Device.ReadWrite.All", "GroupMember.Read.All" )

# Assign each roles to Managed System Identity, first validate they exist
foreach ($RoleName in $RoleNames) {
    $AppRole = $MSGraphServicePrincipal.AppRoles | Where-Object Value -match "$RoleName" 
    New-AzureAdServiceAppRoleAssignment -ObjectId $MSIObjectID -PrincipalId $MSIObjectID -ResourceId $MSGraphServicePrincipal.ObjectId -Id $AppRole.Id
}

