param location string
param amlWorkspaceName string
param amlComputeInstanceName string
param storageAccountId string

resource amlWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-10-01' existing = {
  name: amlWorkspaceName
}

resource updatedamlComputeInstance 'Microsoft.MachineLearningServices/workspaces/computes@2023-04-01' = {
  parent: amlWorkspace
  name: amlComputeInstanceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

//Storage File Data Privileged Contributor: 69566ab7-960f-475b-8e7c-b3118f30c6bd
module computeClusterRoleAssignmentFileDataPrivilegedContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'computeClusterRoleAssignmentFileDataPrivilegedContributorDeployment'
  params: {
    roleName: 'Storage File Data Privileged Contributor'
    description: 'Assign Storage File Data Privileged Contributor role to the managed Identity on the ML Workspace'
    principalId: updatedamlComputeInstance.identity.principalId
    resourceId: storageAccountId
    roleDefinitionId: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
    principalType: 'ServicePrincipal'
  }
}
