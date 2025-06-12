// File: main.bicepparam

using './main.bicep'

param location = 'westeurope'
param vmName = 'win-vm-workload-01'
param adminUsername = 'azureuser'

// BELANGRIJK: Sla wachtwoorden nooit als platte tekst op.
// Gebruik Azure Key Vault-referenties of geef dit wachtwoord veilig door via je Azure DevOps-pipeline.
// Voor een lokale test kun je het hier invullen, maar commit dit nooit naar Git.
param adminPassword = 'Uw_Zeer_Complexe_Wachtwoord_123!'
