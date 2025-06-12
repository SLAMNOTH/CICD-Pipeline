// File: main.bicep (Corrected)

@description('De primaire Azure-regio voor de implementatie.')
param location string

@description('De naam van de virtuele machine in de spoke.')
param vmName string = 'win-vm'

@description('De gebruikersnaam voor de administrator van de VM.')
param adminUsername string

@description('Het wachtwoord voor de administrator van de VM.')
@secure()
param adminPassword string

// Implementeer de Hub-module
module hub 'modules/hub.bicep' = {
  name: 'hubDeployment'
  params: {
    location: location
  }
}

// Implementeer de Spoke-module en geef de outputs van de hub door
module spoke 'modules/spoke.bicep' = {
  name: 'spokeDeployment'
  params: {
    location: location
    hubVnetId: hub.outputs.hubVnetId
    hubVnetName: hub.outputs.hubVnetName
    firewallPrivateIp: hub.outputs.firewallPrivateIp
  }
}

// Implementeer de VM-module in het subnet van de spoke
module vm 'modules/vm.bicep' = {
  name: 'vmDeployment'
  params: {
    location: location
    vmName: vmName
    subnetId: spoke.outputs.spokeSubnetId
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}
