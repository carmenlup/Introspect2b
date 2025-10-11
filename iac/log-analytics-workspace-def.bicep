// template for Claim Status API infrastructure
// Deploys:  Log Analytics

@description('The location for the resources')
param location string

@description('The name of the Azure Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('The SKU for the Log Analytics workspace')
param logAnalyticsSku string = 'PerGB2018'

@description('The name of the Azure Container Apps environment')
param containerEnvironmentName string // value received from command parameters

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: 30
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: json('-1')
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}
