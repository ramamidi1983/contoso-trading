param location string
param suffix string
param tags object
param pgSubnetId string = ''
param vnetId string = ''

// Private DNS zone required for VNet-integrated PostgreSQL
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (!empty(pgSubnetId)) {
  name: '${suffix}.private.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(pgSubnetId)) {
  parent: privateDnsZone
  name: 'vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: 'pg-${suffix}'
  location: location
  tags: tags
  sku: { name: 'Standard_B1ms'
    tier: 'Burstable' }
  properties: {
    version: '15'
    administratorLogin: 'appadmin'
    administratorLoginPassword: 'Tr@ding${uniqueString(suffix)}!'
    storage: { storageSizeGB: 32 }
    network: !empty(pgSubnetId) ? {
      delegatedSubnetResourceId: pgSubnetId
      privateDnsZoneArmResourceId: privateDnsZone.id
    } : {}
  }
  dependsOn: [
    vnetLink
  ]
}

resource db 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-12-01-preview' = {
  parent: server
  name: 'tradingdb'
}

resource fw 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-12-01-preview' = if (empty(pgSubnetId)) {
  parent: server
  name: 'AllowAzure'
  properties: { startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0' }
}

output connStr string = 'Host=${server.properties.fullyQualifiedDomainName};Database=tradingdb;Username=appadmin;Password=Tr@ding${uniqueString(suffix)}!'
