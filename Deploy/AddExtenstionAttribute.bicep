// Define parameters
@description('Provide a name for the Function App that consists of alphanumerics. Name must be globally unique in Azure and cannot start or end with a hyphen.')
param FunctionAppName string
@allowed([
  'Y1'
  'EP1'
  'EP2'
  'EP3'
])
@description('Select the desired App Service Plan of the Function App. Select Y1 for free consumption based deployment.')
param FunctionAppServicePlanSKU string = 'Y1'
@description('Provide any tags required by your organization (optional)')
param Tags object = {}
@description('Provide Azure AD group ID')
param AzureADGroupID string

// Define variables
var UniqueString = uniqueString(resourceGroup().id)
var FunctionAppNameNoDash = replace(FunctionAppName, '-', '')
var FunctionAppNameNoDashUnderScore = replace(FunctionAppNameNoDash, '_', '')
var StorageAccountName = toLower('${take(FunctionAppNameNoDashUnderScore, 17)}${take(UniqueString, 5)}sa')
var Website_ContenshareName = toLower('${take(FunctionAppNameNoDashUnderScore, 17)}${take(UniqueString, 5)}sa')
var FunctionAppServicePlanName = '${FunctionAppName}-fa-plan'
var FunctionAppInsightsName = '${FunctionAppName}-fa-ai'

// Create storage account for Function App
resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: StorageAccountName
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties:{
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
  }
  tags: Tags
}

// Create app service plan for Function App
resource appserviceplan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: FunctionAppServicePlanName
  location: resourceGroup().location
  kind: 'Windows'
  sku: {
    name: FunctionAppServicePlanSKU
  }
  tags: Tags
}

// Create application insights for Function App
resource FunctionAppInsightsComponents 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: FunctionAppInsightsName
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
  tags: union(Tags, {
    'hidden-link:${resourceId('Microsoft.Web/sites', FunctionAppInsightsName)}': 'Resource'
  })
}

// Create function app
resource FunctionApp 'Microsoft.Web/sites@2020-12-01' = {
  name: FunctionAppName
  location: resourceGroup().location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appserviceplan.id
    containerSize: 1536
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      powerShellVersion: '~7'
      scmType: 'None'
      appSettings: [
        {
          name: 'AADGroupObjectId'
          value: AzureADGroupID
        }        
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(FunctionAppInsightsComponents.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: reference(FunctionAppInsightsComponents.id, '2020-02-02-preview').ConnectionString
        } 
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageaccount.name};AccountKey=${storageaccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageaccount.name};AccountKey=${storageaccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(Website_ContenshareName)
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'AzureWebJobsDisableHomepage'
          value: 'true'
        }
        {
          name: 'DebugLogging'
          value: 'False'
        }
      ]
    }
  }
  tags: Tags
}

// Add ZipDeploy for Function App
resource FunctionAppZipDeploy 'Microsoft.Web/sites/extensions@2015-08-01' = {
  parent: FunctionApp
  name: 'ZipDeploy'
    properties: {
        packageUri: 'https://github.com/sandytsang/AddExtensionAttribute/releases/download/v1.0/AddExtensionAttribute.zip'
    }
}
