@description('Azure region for the app and its private endpoint.')
param location string = resourceGroup().location

@description('Name of the App Service, also used for the private endpoint and DNS A-records.')
param appName string

@description('Resource group holding the shared App Service plan, VNet and private DNS zone.')
param rgSharedResources string

@description('Name of the existing shared App Service plan.')
param aspName string

@description('Private DNS zone the app is registered in, e.g. privatelink.azurewebsites.net.')
param privateDnsZoneName string

@description('Name of the existing shared virtual network.')
param vnetName string

@description('Subnet hosting the private endpoint (inbound).')
param subnetName string

@description('Delegated subnet used for regional VNet integration (outbound).')
param connectivitySubnet string

@description('Linux runtime stack, e.g. NODE|24-lts.')
param stackVersion string

@description('Startup command for the container.')
param startCommand string


resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' existing = {
  name: aspName
  scope: resourceGroup(rgSharedResources)
}

resource AppServiceApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    publicNetworkAccess: 'Disabled'
    virtualNetworkSubnetId: resourceId(rgSharedResources,'Microsoft.Network/virtualNetworks/subnets', vnetName, connectivitySubnet)
    vnetRouteAllEnabled: true
    siteConfig: {
      linuxFxVersion: stackVersion
      appCommandLine: startCommand
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      http20Enabled: true
      remoteDebuggingEnabled: false
      appSettings: [
        {
          // The SPA is built in CI and deployed prebuilt, so Oryx must not build on deploy.
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
      ]
    }
  }
}

var privateEndpointName = 'pe-${appName}'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
  scope: resourceGroup(rgSharedResources)
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    customNetworkInterfaceName: '${privateEndpointName}-nic'
    subnet: {
      id: resourceId(rgSharedResources,'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          groupIds: ['sites']
          privateLinkServiceId: AppServiceApp.id
        }
      }
    ]
  }

  // Azure derives the A-records from the endpoint itself (including <appName>.scm)
  // and removes them again when the endpoint is deleted.
  resource dnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: replace(privateDnsZoneName, '.', '-')
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}

@description('Resource ID of the App Service.')
output appServiceId string = AppServiceApp.id

@description('Object ID of the system-assigned identity, for downstream role assignments.')
output principalId string = AppServiceApp.identity.principalId

