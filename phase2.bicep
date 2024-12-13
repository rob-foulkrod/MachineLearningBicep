param amlWorkspaceName string
param location string

resource amlWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-10-01' existing = {
  name: amlWorkspaceName
}

resource updatedWorkspace 'Microsoft.MachineLearningServices/workspaces@2023-04-01' = {
  name: amlWorkspace.name
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource computeInstance 'Microsoft.MachineLearningServices/workspaces/computes@2023-04-01' = {
  parent: amlWorkspace
  name: 'amlci18'
  location: location
  properties: {
    disableLocalAuth: true
    computeType: 'ComputeInstance'
    computeLocation: location
    properties: {
      vmSize: 'STANDARD_DS11_V2'
      applicationSharingPolicy: 'Shared'
    }
  }
}

output computeInstanceName string = computeInstance.name
output amlWorkspaceName string = amlWorkspace.name
