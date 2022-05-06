@description('Event Hub namespace name.')
param eventHubNamespaceName string

@description('Location of the resource.')
param location string

@description('Object containing resource tags.')
param tags object = {}

@description('Specifies the messaging tier for Event Hub Namespace.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param eventHubSku string

@description('Event Hubs throughput units. Basic or Standard tiers, value should be 0 to 20 throughput units. Premium  tier, value should be 0 to 10 throughput units.')
@minValue(1)
@maxValue(20)
param skuCapacity int = 1

@description('Disable SAS authentication for the Event Hubs namespace')
param disableLocalAuth bool = false

@description('Enable auto inflate for the Event Hubs namespace')
param enableAutoInflate bool = false

@description('Upper limit of throughput units when AutoInflate is enabled, value should be within 0 to 20 throughput units.')
param maximumThroughputUnits int = 0

@description('Enable kafka for the Event Hubs namespace')
param enablekafka bool = false

@description('Enable zone redundancy for the Event Hubs namespace')
param zoneRedundant bool = true

@description('Rule definitions governing the KeyVault network access.')
@metadata({
  defaultAction: 'The default action when no rules match. Accepted values: "Allow", "Deny".'
  publicNetworkAccess: 'Allow traffic over public network. Accepted values: "Disabled", "Enabled".'
  trustedServiceAccessEnabled: 'Allow Azure trusted services access. Accepted values: "true", "false".'
  ipRules: [
    {
      action: 'Allow'
      ipMask: 'IPv4 address or CIDR range'
    }
  ]
  virtualNetworkRules: [
    {
      ignoreMissingVnetServiceEndpoint: 'Whether to ignore if vnet subnet is missing service endpoints. Accepted values: "true", "false".'
      subnet: {
        id: 'Full resource id of a vnet subnet.'
      }
    }
  ]
})
param networkRuleSet object = {}

@description('Event Hubs associated with the Event Hub namespace.')
@metadata({
  eventHubName: 'Name of the Event Hub.'
  messageRetentionInDays: 'Number of days to retain the events for this Event Hub, value should be 1 to 7 days.'
  partitionCount: 'Number of partitions created for the Event Hub, allowed values are from 1 to 32 partitions.'
  captureSettings: {
    provider: 'StorageAccount or DataLake.'
    archiveNameFormat: 'Blob naming convention for archive, e.g. {Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}.'
    blobContainer: 'Blob container name. Only required when provider is StorageAccount.'
    storageAccountResourceId: 'Resource id of the storage account to be used to create the blobs. Only required when provider is StorageAccount.'
    dataLakeAccountName: 'The Azure Data Lake Store name for the captured events. Only required when provider is DataLake.'
    dataLakeFolderPath: 'The destination folder path for the captured events. Only required when provider is DataLake.'
    dataLakeSubscriptionId: 'The subscription id for the destination Data Lake account. Only required when provider is DataLake.'
    enabled: 'Whether capture is enabled. Accepted values: "true", "false". Defaults to "true".'
    encoding: 'The encoding format of capture description. Defaults to "Avro".'
    intervalInSeconds: 'The frequency with which the capture to Azure Blobs will happen, value should between 60 to 900 seconds. Defaults to "300" seconds.'
    sizeLimitInBytes: 'The amount of data built up in your Event Hub before an capture operation. Defaults to "314572800".'
    skipEmptyArchives: 'Skip Empty Archives. Accepted values: "true", "false". Defaults to "false".'
  }
})
param eventHubs array = []

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Specify the type of resource lock.')
param resourcelock string = 'NotSpecified'

@description('Enable diagnostic logs')
param enableDiagnostics bool = false

@allowed([
  'allLogs'
  'audit'
])
@description('Specify the type of diagnostic logs to monitor.')
param diagnosticLogGroup string = 'allLogs'

@description('Storage account resource id. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountId string = ''

@description('Log analytics workspace resource id. Only required if enableDiagnostics is set to true.')
param diagnosticLogAnalyticsWorkspaceId string = ''

@description('Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Event hub name. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubName string = ''

var lockName = toLower('${eventHubNamespace.name}-${resourcelock}-lck')
var diagnosticsName = '${eventHubNamespace.name}-dgs'

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: eventHubNamespaceName
  location: location
  tags: tags
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: skuCapacity
  }
  properties: {
    isAutoInflateEnabled: enableAutoInflate
    maximumThroughputUnits: maximumThroughputUnits
    disableLocalAuth: disableLocalAuth
    zoneRedundant: zoneRedundant
    kafkaEnabled: enablekafka
  }
}

resource eventHubNamespaceNetworkRuleSet 'Microsoft.EventHub/namespaces/networkRuleSets@2021-11-01' = if (!empty(networkRuleSet)) {
  parent: eventHubNamespace
  name: 'default'
  properties: {
    publicNetworkAccess: contains(networkRuleSet, 'publicNetworkAccess') ? networkRuleSet.publicNetworkAccess : null
    defaultAction: contains(networkRuleSet, 'defaultAction') ? networkRuleSet.defaultAction : null
    trustedServiceAccessEnabled: contains(networkRuleSet, 'trustedServiceAccessEnabled') ? networkRuleSet.trustedServiceAccessEnabled : null
    virtualNetworkRules: contains(networkRuleSet, 'virtualNetworkRules') ? networkRuleSet.virtualNetworkRules : null
    ipRules: contains(networkRuleSet, 'ipRules') ? networkRuleSet.ipRules : null
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = [for eh in eventHubs: {
  parent: eventHubNamespace
  name: eh.eventHubName
  properties: {
    messageRetentionInDays: eh.messageRetentionInDays
    partitionCount: eh.partitionCount
    captureDescription: contains(eh, 'captureSettings') ? {
      destination: {
        name: eh.captureSettings.provider == 'StorageAccount' ? 'EventHubArchive.AzureBlockBlob' : 'EventHubArchive.AzureDataLake'
        properties: {
          archiveNameFormat: contains(eh.captureSettings, 'archiveNameFormat') ? eh.captureSettings.archiveNameFormat : null
          blobContainer: contains(eh.captureSettings, 'blobContainer') ? eh.captureSettings.blobContainer : null
          dataLakeAccountName: contains(eh.captureSettings, 'dataLakeAccountName') ? eh.captureSettings.dataLakeAccountName : null
          dataLakeFolderPath: contains(eh.captureSettings, 'dataLakeFolderPath') ? eh.captureSettings.dataLakeFolderPath : null
          dataLakeSubscriptionId: contains(eh.captureSettings, 'dataLakeSubscriptionId') ? eh.captureSettings.dataLakeSubscriptionId : null
          storageAccountResourceId: contains(eh.captureSettings, 'storageAccountResourceId') ? eh.captureSettings.storageAccountResourceId : null
        }
      }
      enabled: contains(eh.captureSettings, 'enabled') ? eh.captureSettings.enabled : true
      encoding: contains(eh.captureSettings, 'encoding') ? eh.captureSettings.encoding : 'Avro'
      intervalInSeconds: contains(eh.captureSettings, 'intervalInSeconds') ? eh.captureSettings.intervalInSeconds : 300
      sizeLimitInBytes: contains(eh.captureSettings, 'sizeLimitInBytes') ? eh.captureSettings.sizeLimitInBytes : 314572800
      skipEmptyArchives: contains(eh.captureSettings, 'skipEmptyArchives') ? eh.captureSettings.skipEmptyArchives : false
    } : null
  }
}]

resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (resourcelock != 'NotSpecified') {
  name: lockName
  properties: {
    level: resourcelock
    notes: (resourcelock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: eventHubNamespace
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: eventHubNamespace
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    logs: [
      {
        categoryGroup: diagnosticLogGroup
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output name string = eventHubNamespace.name
output id string = eventHubNamespace.id
