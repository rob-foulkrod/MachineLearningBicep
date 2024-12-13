param location string = 'eastus2'
param prefix string = ''
param baseName string = '${prefix}${uniqueString(resourceGroup().id, deployment().name)}'
param currentUserId string

var tags = {
  Environment: 'Production'
  Project: 'AML Workspace'
  DeployedBy: 'Bicep'
}

//Vnet
module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.1' = {
  name: 'virtualNetworkDeployment'
  params: {
    name: '${baseName}-vnet'
    location: location
    addressPrefixes: [
      '10.2.0.0/16'
    ]
    subnets: [
      {
        addressPrefix: '10.2.0.0/24'
        name: 'default'
      }
      {
        addressPrefix: '10.2.1.0/24'
        name: 'GatewaySubnet'
      }
    ]
  }
}

//Storage Account
module storageAccount 'br/public:avm/res/storage/storage-account:0.14.3' = {
  name: 'storageAccountDeployment'

  params: {
    name: '${baseName}storage'
    tags: tags
    allowBlobPublicAccess: false
    defaultToOAuthAuthentication: true // Default to Entra ID Authentication
    supportsHttpsTrafficOnly: true
    kind: 'StorageV2'
    location: location
    skuName: 'Standard_LRS'
    blobServices: {
      enabled: true
    }
    fileServices: {
      enabled: true
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

//container registery
module registry 'br/public:avm/res/container-registry/registry:0.6.0' = {
  name: 'registryDeployment'
  params: {
    name: '${baseName}registry'
    acrSku: 'Premium'
    location: location
    acrAdminUserEnabled: true
    networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Disabled'
  }
}

//Key vault
module vault 'br/public:avm/res/key-vault/vault:0.11.0' = {
  name: 'vaultDeployment'
  params: {
    name: '${baseName}vault'
    tags: tags
    enablePurgeProtection: false
    enableRbacAuthorization: true
    enableVaultForDeployment: true
    enableVaultForDiskEncryption: true
    enableVaultForTemplateDeployment: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    location: location
  }
}

//App Insights Workspace
module operationalworkspace 'br/public:avm/res/operational-insights/workspace:0.9.0' = {
  name: 'operationalworkspaceDeployment'
  params: {
    name: '${baseName}workspace'
    location: location
  }
}

//Application Insights
module component 'br/public:avm/res/insights/component:0.4.2' = {
  name: 'componentDeployment'
  params: {
    name: '${baseName}insights'
    workspaceResourceId: operationalworkspace.outputs.resourceId
    location: location
  }
}

module virtualNetworkGateway 'br/public:avm/res/network/virtual-network-gateway:0.5.0' = {
  name: 'virtualNetworkGatewayDeployment'
  params: {
    clusterSettings: {
      clusterMode: 'activeActiveNoBgp'
    }
    gatewayType: 'Vpn'
    name: '${baseName}gateway'
    vNetResourceId: virtualNetwork.outputs.resourceId
    allowRemoteVnetTraffic: true
    disableIPSecReplayProtection: true
    enableBgpRouteTranslationForNat: true
    enablePrivateIpAddress: true

    location: location
    publicIpZones: [
      1
    ]
    skuName: 'VpnGw2AZ'
    vpnGatewayGeneration: 'Generation2'
    vpnType: 'RouteBased'
  }
}

module workspace 'br/public:avm/res/machine-learning-services/workspace:0.9.0' = {
  name: 'workspaceDeployment'
  params: {
    name: '${baseName}workspace'
    sku: 'Basic'
    associatedApplicationInsightsResourceId: component.outputs.resourceId
    associatedKeyVaultResourceId: vault.outputs.resourceId
    associatedStorageAccountResourceId: storageAccount.outputs.resourceId
    associatedContainerRegistryResourceId: registry.outputs.resourceId
    location: location
    tags: tags
    publicNetworkAccess: 'Disabled'
    managedIdentities: {
      systemAssigned: true
    }
    hbiWorkspace: false
    managedNetworkSettings: {
      isolationMode: 'AllowInternetOutbound'
      // outboundRules: {
      //   rule: {
      //     category: 'UserDefined'
      //     destination: {
      //       serviceResourceId: storageAccount.outputs.resourceId
      //       subresourceTarget: 'blob'
      //     }
      //     type: 'PrivateEndpoint'
      //   }
      // }
    }
  }
}

//Add the AML Identity's permissions

//Automatically assigned by the system - Commented out
//Storage Blob Data Contributor: ba92f5b4-2d11-453d-a403-e96b0029c9fe
// module amlIdentityRoleStorageBlobDataContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   name: 'amlIdentityRoleStorageBlobDataContributorDeployment'
//   params: {
//     roleName: 'Storage Blob Data Contributor'
//     description: 'Assign Storage Blob Data Contributor role to the managed Identity on the ML Workspace'
//     principalId: workspace.outputs.systemAssignedMIPrincipalId!
//     resourceId: storageAccount.outputs.resourceId
//     roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
//     principalType: 'ServicePrincipal'
//   }
// }

// Storage Table Data Contributor: 0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3
module amlIdentityRoleStorageTableDataContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'amlIdentityRoleStorageTableDataContributorDeployment'
  params: {
    roleName: 'Storage Table Data Contributor'
    description: 'Assign Storage Table Data Contributor role to the managed Identity on the ML Workspace'
    principalId: workspace.outputs.systemAssignedMIPrincipalId!
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
    principalType: 'ServicePrincipal'
  }
}

// Automaitcally assigned by the system - Commented out
//Storage File Data Privileged Contributor: 69566ab7-960f-475b-8e7c-b3118f30c6bd
// module amlIdentityRoleStorageFileDataPrivilegedContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   name: 'amlIdentityRoleStorageFileDataPrivilegedContributorDeployment'
//   params: {
//     roleName: 'Storage File Data Privileged Contributor'
//     description: 'Assign Storage File Data Privileged Contributor role to the managed Identity on the ML Workspace'
//     principalId: workspace.outputs.systemAssignedMIPrincipalId!
//     resourceId: storageAccount.outputs.resourceId
//     roleDefinitionId: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
//     principalType: 'ServicePrincipal'
//   }
// }

// All three assignments now for the current user
module currentUserRoleStorageBlobDataContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'currentUserRoleStorageBlobDataContributorDeployment'
  params: {
    roleName: 'Storage Blob Data Contributor'
    description: 'Assign Storage Blob Data Contributor role to the managed Identity on the ML Workspace'
    principalId: currentUserId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'User'
  }
}

module currentUserRoleStorageBlobDataContributorstorageTableDataContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'currentUserRoleStorageBlobDataContributorstorageTableDataContributorDeployment'
  params: {
    roleName: 'Storage Table Data Contributor'
    description: 'Assign Storage Table Data Contributor role to the managed Identity on the ML Workspace'
    principalId: currentUserId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
    principalType: 'User'
  }
}

module currentUserRoleStorageFileDataPrivilegedContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'currentUserRoleStorageFileDataPrivilegedContributorDeployment'
  params: {
    roleName: 'Storage File Data Privileged Contributor'
    description: 'Assign Storage File Data Privileged Contributor role to the managed Identity on the ML Workspace'
    principalId: currentUserId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
    principalType: 'User'
  }
}

output amlWorkspaceId string = workspace.outputs.resourceId
output amlWorkspaceName string = workspace.outputs.name
output storageAccountId string = storageAccount.outputs.resourceId
output keyVaultId string = vault.outputs.resourceId
output vnetId string = virtualNetwork.outputs.resourceId
