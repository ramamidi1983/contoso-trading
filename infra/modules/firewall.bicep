param location string
param suffix string
param tags object
param firewallSubnetId string

// ── Public IP for Azure Firewall ──

resource fwPip 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-fw-${suffix}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// ── Azure Firewall ──

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: 'fw-${suffix}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          publicIPAddress: { id: fwPip.id }
          subnet: { id: firewallSubnetId }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'allow-outbound'
        properties: {
          priority: 100
          action: { type: 'Allow' }
          rules: [
            {
              name: 'allow-all-outbound'
              protocols: [ 'Any' ]
              sourceAddresses: [ '10.0.0.0/16' ]
              destinationAddresses: [ '*' ]
              destinationPorts: [ '*' ]
            }
          ]
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'allow-azure-services'
        properties: {
          priority: 200
          action: { type: 'Allow' }
          rules: [
            {
              name: 'allow-azure-monitor'
              sourceAddresses: [ '10.0.0.0/16' ]
              protocols: [ { protocolType: 'Https', port: 443 } ]
              targetFqdns: [
                '*.monitor.azure.com'
                '*.ods.opinsights.azure.com'
                '*.oms.opinsights.azure.com'
                '*.blob.core.windows.net'
                '*.applicationinsights.azure.com'
              ]
            }
            {
              name: 'allow-acr'
              sourceAddresses: [ '10.0.0.0/16' ]
              protocols: [ { protocolType: 'Https', port: 443 } ]
              targetFqdns: [
                '*.azurecr.io'
                'mcr.microsoft.com'
                '*.data.mcr.microsoft.com'
              ]
            }
            {
              name: 'allow-container-apps'
              sourceAddresses: [ '10.0.0.0/16' ]
              protocols: [ { protocolType: 'Https', port: 443 } ]
              targetFqdns: [
                '*.azurecontainerapps.dev'
                'management.azure.com'
                'login.microsoftonline.com'
              ]
            }
          ]
        }
      }
    ]
  }
}

// ── Route Table — force all egress through firewall ──

resource routeTable 'Microsoft.Network/routeTables@2024-01-01' = {
  name: 'rt-fw-${suffix}'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = fwPip.properties.ipAddress
output routeTableId string = routeTable.id
output firewallName string = firewall.name
