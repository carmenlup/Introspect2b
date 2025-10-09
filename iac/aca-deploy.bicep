// template for Claim Status API infrastructure
// Deploys: Container Apps Environment, Container App, Log Analytics

// Container Apps Environment, Container App,
@description('ACR Name')
param acrName string = 'introspect2bacr'

@description('ACR login server')
param acrLoginServer string = 'introspect2bacr.azurecr.io'

@description('The name of the Azure Container App')
param containerAppName string = 'claim-status-app'

@description('The container image to deploy')
param containerImage string = 'introspect2bacr.azurecr.io/claimstatus:latest'

@description('The location for the resources')
param location string = resourceGroup().location

@description('The name of the Azure Container Apps environment')
param environmentName string = 'claimstatus-container-app-env'

@description('The name of the Azure Log Analytics workspace')
param logAnalyticsWorkspaceName string = 'workspace-intospect2b-logs'

@description('The SKU for the Log Analytics workspace')
param logAnalyticsSku string = 'PerGB2018'

@description('The CPU and memory configuration for the container app')
param cpu string = '0.5'
param memory string = '1.0Gi'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

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

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2025-02-02-preview' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        //sharedKey: logAnalyticsWorkspace.properties.sharedKeys.primarySharedKey
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
resource containerApp 'Microsoft.App/containerapps@2025-02-02-preview' = {
  name: containerAppName
  location: location
  kind: 'containerapps'
  identity: {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    environmentId: containerAppEnvironment.id
    workloadProfileName: 'Consumption'
    configuration: {
      secrets: [
        {
          name: 'reg-pswd-795c8fae-9629'
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 0
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
        stickySessions: {
          affinity: 'none'
        }
      }
      registries: [
        {
          server: acrLoginServer
          username: acr.name
          passwordSecretRef: 'reg-pswd-795c8fae-9629'
        }
      ]
      identitySettings: []
      runtime: {
        dotnet: {
          autoConfigureDataProtection: false
        }
      }
      maxInactiveRevisions: 100
    }
    template: {
      containers: [
        {
          image: containerImage
          imageType: 'ContainerImage'
          name: containerAppName
          resources: {
            cpu: json(cpu)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        cooldownPeriod: 300
        pollingInterval: 30
      }
    }
  }
}
