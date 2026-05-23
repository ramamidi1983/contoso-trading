param location string
param suffix string
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'vnet-${suffix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
    subnets: [
      {
        name: 'snet-cae'
        properties: {
          addressPrefix: '10.0.0.0/21'   // /21 required by Container Apps
        }
      }
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: '10.0.10.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.11.0/26'   // /26 minimum for Azure Firewall
        }
      }
      {
        name: 'snet-sre-agent'
        properties: {
          addressPrefix: '10.0.12.0/28'
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output caeSubnetId string = vnet.properties.subnets[0].id
output peSubnetId string = vnet.properties.subnets[1].id
output firewallSubnetId string = vnet.properties.subnets[2].id
output sreAgentSubnetId string = vnet.properties.subnets[3].id
