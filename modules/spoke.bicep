// File: modules/spoke.bicep

@description('De locatie voor alle resources.')
param location string

@description('De naam voor het virtuele netwerk van de spoke.')
param spokeVnetName string = 'vnet-spoke-workload'

@description('De adresruimte voor het virtuele netwerk van de spoke.')
param spokeVnetAddressPrefix string = '10.1.0.0/16'

@description('De resource ID van het virtuele netwerk van de hub.')
param hubVnetId string

@description('Het privé IP-adres van de Azure Firewall in de hub.')
param firewallPrivateIp string

var defaultSubnetName = 'snet-workload'

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: spokeVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: defaultSubnetName
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
  }
}

// Route Tabel om verkeer naar de Firewall te sturen
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: '${spokeVnetName}-rt'
  location: location
  properties: {
    routes: [
      {
        name: 'default-route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// Koppel de Route Tabel aan het subnet van de spoke
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: spokeVnet
  name: defaultSubnetName
  properties: {
    routeTable: {
      id: routeTable.id
    }
  }
}

// VNet Peering van Spoke naar Hub
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: spokeVnet
  name: '${spokeVnetName}-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true // Staat gebruik van de gateway in de hub toe
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

// VNet Peering van Hub naar Spoke
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: resourceId(split(hubVnetId, '/')[1], 'Microsoft.Network/virtualNetworks', split(hubVnetId, '/')[8])
  name: 'hub-to-${spokeVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true // Staat toe dat de spoke de hub-gateway gebruikt
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}

// Output die nodig is voor de VM-module
output spokeSubnetId string = subnet.id
