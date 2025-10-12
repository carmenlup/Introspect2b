@description('The location for the resources')
param location string

@description('The name of the Azure Container Apps environment')
param containerEnvironmentName string // value received from command parameters

@description('The Id of the Log Analytics workspace')
param logAnalyticsWorkspaceId string // value received from command parameters

@description('The key of the Log Analytics workspace')
param logAnalyticsWorkspaceKey string // value received from command parameters

resource logAnalyticsWorkspace 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2025-02-02-preview' = {
  name: containerEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspaceId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
        dynamicJsonColumns: false
      }
    }
    zoneRedundant: false
    kedaConfiguration: {}
    daprConfiguration: {}
    customDomainConfiguration: {}
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
        enableFips: false
      }
    ]
    peerAuthentication: {
      mtls: {
        enabled: false
      }
    }
    peerTrafficConfiguration: {
      encryption: {
        enabled: false
      }
    }
    publicNetworkAccess: 'Enabled'
  }
}
