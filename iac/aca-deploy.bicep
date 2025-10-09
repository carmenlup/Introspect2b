// template for Claim Status API infrastructure
// Deploys: Container Registry, Container Apps Environment, Container App, API Management, Azure OpenAI, Log Analytics

// Container Apps Environment, Container App,
@description('The name of the Azure Container App')
param containerAppName string = 'claimstatus-app'

@description('The container image to deploy')
param containerImage string = 'introspect2bacr.azurecr.io/claimstatus:latest'

@description('The location for the resources')
param location string = resourceGroup().location

@description('The name of the Azure Container Apps environment')
param environmentName string = 'aca-environment'

@description('The name of the Azure Log Analytics workspace')
param logAnalyticsWorkspaceName string = 'aca-log-workspace'

@description('The SKU for the Log Analytics workspace')
param logAnalyticsSku string = 'PerGB2018'

@description('The CPU and memory configuration for the container app')
param cpu string = '0.5'
param memory string = '1.0Gi'

@description('The minimum and maximum number of replicas for scaling')
param minReplicas int = 1
param maxReplicas int = 3

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  sku: {
    name: logAnalyticsSku
  }
  properties: {}
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.properties.sharedKeys.primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: cpu
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}
