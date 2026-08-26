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
          name: 'WEBSITE_WEBDEPLOY_USE_SCM'
          value: 'false'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
      ]
    }
  }
}

var privateEndpointName = 'pe-${appName}'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
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
}

module addToPrivateDns 'AddToPrivateDns.bicep' = {
  name: 'addToPrivateDns'
  params: {
    privateDnsZoneName: privateDnsZoneName
    privateEndpointName: privateEndpointName
    appResourceGroupName: resourceGroup().name
    appName: appName
  }
  dependsOn: [privateEndpoint]
  scope: resourceGroup(rgSharedResources)
}

@description('Resource ID of the App Service.')
output appServiceId string = AppServiceApp.id

@description('Object ID of the system-assigned identity, for downstream role assignments.')
output principalId string = AppServiceApp.identity.principalId

