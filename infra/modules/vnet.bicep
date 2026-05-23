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
        name: 'snet-pg'
        properties: {
          addressPrefix: '10.0.9.0/24'
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL.flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
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
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output caeSubnetId string = vnet.properties.subnets[0].id
output pgSubnetId string = vnet.properties.subnets[1].id
output peSubnetId string = vnet.properties.subnets[2].id
output firewallSubnetId string = vnet.properties.subnets[3].id
