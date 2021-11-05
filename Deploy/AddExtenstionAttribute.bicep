// Define parameters
@description('Provide a name for the Function App that consists of alphanumerics. Name must be globally unique in Azure and cannot start or end with a hyphen.')
param FunctionAppName string

@description('Select the desired App Service Plan of the Function App. Select Y1 for free consumption based deployment.')
@allowed([
  'Y1'
  'EP1'
  'EP2'
  'EP3'
])
param FunctionAppServicePlanSKU string = 'Y1'

@description('Provide Azure AD group ID')
param AzureADGroupID string

@description('Select the disired Extension Attribute')
@allowed([
  'extensionAttribute1'
  'extensionAttribute2'
  'extensionAttribute3'
  'extensionAttribute4'
  'extensionAttribute5'
  'extensionAttribute6'
  'extensionAttribute7'
  'extensionAttribute8'
  'extensionAttribute9'
  'extensionAttribute10'
  'extensionAttribute11'
  'extensionAttribute12'
  'extensionAttribute13'
  'extensionAttribute14'
  'extensionAttribute15'
])
param ExtensionAttributeNumber string

@description('Provide disired Extension Attribute value')
param ExtensionAttributeValue string

@description('Provide any tags required by your organization, example {"FirstTag": "FirstValue", "SecondTag": "SecondValue"} (optional)')
param Tags object = {}

// Define variables
var UniqueString = uniqueString(resourceGroup().id)
var FunctionAppNameNoDash = replace(FunctionAppName, '-', '')
var FunctionAppNameNoDashUnderScore = replace(FunctionAppNameNoDash, '_', '')
var StorageAccountNameReplace = replace(replace(FunctionAppNameNoDashUnderScore, 'function', 'stor'), 'intune','')
var StorageAccountName = toLower('${take(StorageAccountNameReplace, 22)}')
var FunctionAppInsightsName = replace(FunctionAppName, 'function', 'appinsights')
var FunctionAppServicePlanName = replace(FunctionAppName, 'function', 'appsvcpln')
var Website_ContenshareName = toLower('${take(FunctionAppNameNoDashUnderScore, 17)}${take(UniqueString, 5)}sa')



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
          name: 'ExtensionAttributeNumber'
          value: ExtensionAttributeNumber
        }
        {
          name: 'ExtensionAttributeValue'
          value: ExtensionAttributeValue
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
        packageUri: 'https://github.com/sandytsang/AddExtensionAttribute/releases/download/v1.0/Add-ExtensionAttribute.zip'
    }
}
