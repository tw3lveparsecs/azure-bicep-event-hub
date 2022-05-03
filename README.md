# Event Hub
This module creates an Azure Event Hub Namespace.

You can optionally configure firewall and network rules, event hubs, diagnostics and resource lock.

## Usage

### Example 1 - Event Hub Namespace with diagnostics and resource lock
```bicep
param deploymentName string = 'eh${utcNow()}'
param location string = resourceGroup().location

module eventHub 'eventhub.bicep' = {
  name: deploymentName
  params: {
    eventHubNamespaceName: 'myEventHubNamespace'
    location: location
    eventHubSku: 'Standard'
    resourcelock: 'CanNotDelete'
    enableDiagnostics: true    
    diagnosticLogAnalyticsWorkspaceId: 'myLogAnalyticsWorkspaceResourceId'
  }
}
```

### Example 2 - Event Hub Namespace with network rules
```bicep
param deploymentName string = 'eh${utcNow()}'
param location string = resourceGroup().location

module eventHub 'eventhub.bicep' = {
  name: deploymentName
  params: {
    eventHubNamespaceName: 'myEventHubNamespace'
    location: location
    eventHubSku: 'Standard'
    networkRuleSet: {
      defaultAction: 'Deny'
      publicNetworkAccess: 'Enabled'
      trustedServiceAccessEnabled: true
      ipRules: [
        {
          ipMask: '172.32.0.10'
          action: 'Allow'
        }
      ]
      virtualNetworkRules: [
        {
          ignoreMissingVnetServiceEndpoint: true
          subnet: {
            id: 'MySubnetResourceId'
          }
        }
      ]
    }
  }
}
```

### Example 3 - Event Hub Namespace with event hubs
```bicep
param deploymentName string = 'eh${utcNow()}'
param location string = resourceGroup().location

module eventHub 'eventhub.bicep' = {
  name: deploymentName
  params: {
    eventHubNamespaceName: 'myEventHubNamespace'
    location: location
    eventHubSku: 'Standard'    
    eventHubs: [
      {
        eventHubName: 'eventHub1'
        messageRetentionInDays: 1
        partitionCount: 1
        captureSettings: {
          provider: 'StorageAccount'
          archiveNameFormat: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
          blobContainer: 'capture'
          storageAccountResourceId: 'MyStorageAccountResourceId'
        }
      }
      {
        eventHubName: 'eventHub2'
        messageRetentionInDays: 1
        partitionCount: 1
      }
    ]
  }
}
```