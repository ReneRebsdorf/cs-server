// Resource Group deployment
// of container app and associated resources
// for hosting a Counter-Strike 2 server
// in a container on Azure

// Refs:
// - https://hub.docker.com/r/joedwards32/cs2
// - https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers

// Azure Resource params
param location string = 'SwedenCentral'
param logAnalyticsDataRetention int = 30
param logAnalyticsDailyQuotaGb int = 1
param logAnalyticsWorkspaceName string = 'cs2server-logs'
param containerAppEnvName string = 'cs2server-env'
param containerAppName string = 'cs2server'
param baseTime string = utcNow()

// Container Environment params
@secure()
param STEAMUSER string
@secure()
param STEAMPASS string
@description('Steam Guard key - use the most recent')
@secure()
param STEAMGUARD string
@secure()
param CS2_RCONPW string
@secure()
param CS2_PW string
// Visible name of the server
param CS2_SERVERNAME string
// CS2 server listen port tcp_udp
param CS2_PORT string = '701'
param CS2_LAN string = '0'
param CS2_MAXPLAYERS string = '16'
// Game type, see https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers
param CS2_GAMETYPE string = '0'
// Game mode, see https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers
param CS2_GAMEMODE string = '0'
param CS2_MAPGROUP string = 'mg_active'
param CS2_STARTMAP string = 'de_inferno'
param CS2_ADDITIONAL_ARGS string = ''
// 0 - easy, 1 - normal, 2 - hard, 3 - expert
param CS2_BOT_DIFFICULTY string = '3'
param CS2_BOT_QUOTA string = '9'
param CS2_BOT_QUOTA_MODE string = 'fill'

var fileShareName = 'cs2data'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logAnalyticsDataRetention
    workspaceCapping: {
      dailyQuotaGb: logAnalyticsDailyQuotaGb
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: uniqueString(resourceGroup().id, containerAppName)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
  resource files 'fileServices' = {
    name: 'default'
    resource shares 'shares' = {
      name: fileShareName
    }
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: containerAppEnvName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
  resource storages 'storages' = {
    name: 'MyAzureFiles'
    properties: {
      azureFile: {
        accountName: storageAccount.name
        accountKey: storageAccount.listKeys().keys[0].value
        shareName: fileShareName
        accessMode: 'ReadWrite'
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-10-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: int(CS2_PORT)
      }
      secrets: [
        {
          name: 'STEAMUSER-secret'
          value: STEAMUSER
        }
        {
          name: 'STEAMPASS-secret'
          value: STEAMPASS
        }
        {
          name: 'STEAMGUARD-secret'
          value: STEAMGUARD
        }
        {
          name: 'CS2_RCONPW-secret'
          value: CS2_RCONPW
        }
        {
          name: 'CS2_PW-secret'
          value: CS2_PW
        }
      ]
    }
    template: {
      revisionSuffix: uniqueString(baseTime)
      containers: [
        {
          name: containerAppName
          image: 'hub.docker.com/joedwards32/cs2:latest'
          resources: {
            cpu: 2
            memory: '2Gi'
          }
          env: [
            {
              name: 'STEAMUSER'
              secretRef: 'STEAMUSER-secret'
            }
            {
              name: 'STEAMPASS'
              secretRef: 'STEAMPASS-secret'
            }
            {
              name: 'STEAMGUARD'
              secretRef: 'STEAMGUARD-secret'
            }
            {
              name: 'CS2_RCONPW'
              secretRef: 'CS2_RCONPW-secret'
            }
            {
              name: 'CS2_PW'
              secretRef: 'CS2_PW-secret'
            }
            {
              name: 'CS2_SERVERNAME'
              value: CS2_SERVERNAME
            }
            {
              name: 'CS2_PORT'
              value: CS2_PORT
            }
            {
              name: 'CS2_LAN'
              value: CS2_LAN
            }
            {
              name: 'CS2_MAXPLAYERS'
              value: CS2_MAXPLAYERS
            }
            {
              name: 'CS2_GAMETYPE'
              value: CS2_GAMETYPE
            }
            {
              name: 'CS2_GAMEMODE'
              value: CS2_GAMEMODE
            }
            {
              name: 'CS2_MAPGROUP'
              value: CS2_MAPGROUP
            }
            {
              name: 'CS2_STARTMAP'
              value: CS2_STARTMAP
            }
            {
              name: 'CS2_ADDITIONAL_ARGS'
              value: CS2_ADDITIONAL_ARGS
            }
            {
              name: 'CS2_BOT_DIFFICULTY'
              value: CS2_BOT_DIFFICULTY
            }
            {
              name: 'CS2_BOT_QUOTA'
              value: CS2_BOT_QUOTA
            }
            {
              name: 'CS2_BOT_QUOTA_MODE'
              value: CS2_BOT_QUOTA_MODE
            }
          ]
          volumeMounts: [
            {
              mountPath: '/cs2-data'
              volumeName: fileShareName
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      volumes: [
        {
          name: fileShareName
          storageType: 'AzureFile'
          storageName: 'MyAzureFiles'
        }
      ]
    }
  }
}
