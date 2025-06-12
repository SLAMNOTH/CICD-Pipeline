// File: modules/spoke.bicep (Corrected)

@description('De locatie voor alle resources.')
param location string

@description('De naam voor het virtuele netwerk van de spoke.')
param spokeVnetName string = 'vnet-spoke-workload'

@description('De adresruimte voor het virtuele netwerk van de spoke.')
param spokeVnetAddressPrefix string = '10.1.0.0/16'

@description('De resource ID van het virtuele netwerk van de hub.')
param hubVnetId string

@description('De naam van het virtuele netwerk van de hub.')
param hubVnetName string

@description('Het privé IP-adres van de Azure Firewall in de hub.')
param firewallPrivateIp string

var defaultSubnetName = 'snet-workload'

// Creëer een symbolische referentie naar het hub VNet, dat in een andere module bestaat.
resource hubVnetRef 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVnetName
}

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

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: spokeVnet
  name: defaultSubnetName
  properties: {
    routeTable: {
      id: routeTable.id
    }
  }
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: spokeVnet
  name: '${spokeVnetName}-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

// VNet Peering van Hub naar Spoke. Gebruik nu de correcte symbolische referentie.
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: hubVnetRef // Gebruik de symbolische referentie.
  name: 'hub-to-${spokeVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}

output spokeSubnetId string = subnet.id
