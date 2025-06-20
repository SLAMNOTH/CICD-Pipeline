// File: modules/hub.bicep (Corrected)

@description('De locatie voor alle resources.')
param location string

@description('De naam voor het virtuele netwerk van de hub.')
param hubVnetName string = 'vnet-hub'

@description('De adresruimte voor het virtuele netwerk van de hub.')
param hubVnetAddressPrefix string = '10.0.0.0/16'

var firewallSubnetName = 'AzureFirewallSubnet'
var bastionSubnetName = 'AzureBastionSubnet'

// Publiek IP-adres en NAT Gateway voor uitgaand verkeer
resource natGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${hubVnetName}-nat-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource natGateway 'Microsoft.Network/natGateways@2023-05-01' = {
  name: '${hubVnetName}-nat'
  location: location
  sku: { name: 'Standard' }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      { id: natGatewayPublicIp.id }
    ]
  }
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: '10.0.1.0/26'
          // Koppel de NAT Gateway hier direct aan het subnet
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: '10.0.2.0/26'
        }
      }
    ]
  }
}

// Publiek IP-adres voor de Azure Firewall
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${hubVnetName}-fw-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// Azure Firewall resource
resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: '${hubVnetName}-fw'
  location: location
  properties: {
    sku: { name: 'AZFW_VNet', tier: 'Standard' }
    ipConfigurations: [
      {
        name: 'firewall-ip-config'
        properties: {
          publicIPAddress: { id: firewallPublicIp.id }
          subnet: { id: hubVnet.properties.subnets[0].id }
        }
      }
    ]
  }
}

// Publiek IP-adres voor Azure Bastion
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${hubVnetName}-bastion-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// Azure Bastion Host voor veilige RDP-toegang
resource bastionHost 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: '${hubVnetName}-bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ip-config'
        properties: {
          subnet: { id: hubVnet.properties.subnets[1].id }
          publicIPAddress: { id: bastionPublicIp.id }
        }
      }
    ]
  }
}

output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
