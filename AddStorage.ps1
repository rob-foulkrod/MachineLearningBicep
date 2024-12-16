param (
    [string]$storageRGName,
    [string]$storageAccountName,
    [string]$workspaceRGName,
    [string]$workspaceName,
    [string]$computeInstanceName,
    [string]$userId
)

if (-not $userId) {
    # Get the current user's principal ID
    $userId = az ad signed-in-user show --query id -o tsv
}

if (-not $storageAccountName) {
    # Get the list of storage accounts in the subscription
    $storageAccounts = az storage account list --query "[].{name:name, resourceGroup:resourceGroup}" -o json | ConvertFrom-Json

    # Display the list of storage accounts as a menu
    Write-Host "Select a storage account:"
    for ($i = 0; $i -lt $storageAccounts.Count; $i++) {
        Write-Host "$($i + 1). $($storageAccounts[$i].name) (Resource Group: $($storageAccounts[$i].resourceGroup))"
    }

    # Ask the user to select a storage account
    $selection = Read-Host "Enter the number of the storage account"

    # Get the selected storage account name
    $storageAccountName = $storageAccounts[$selection - 1].name
    $storageRGName = $storageAccounts[$selection - 1].resourceGroup
}

if (-not $workspaceName) {
    # Get the list of Azure ML workspaces in the subscription
    $workspaces = az ml workspace list --query "[].{name:name, resourceGroup:resourceGroup}" -o json | ConvertFrom-Json

    # Display the list of workspaces as a menu
    Write-Host "Select an Azure ML workspace:"
    for ($i = 0; $i -lt $workspaces.Count; $i++) {
        Write-Host "$($i + 1). $($workspaces[$i].name) (Resource Group: $($workspaces[$i].resourceGroup))"
    }

    # Ask the user to select a workspace
    $selection = Read-Host "Enter the number of the workspace"

    # Get the selected workspace name
    $workspaceName = $workspaces[$selection - 1].name
    $workspaceRGName = $workspaces[$selection - 1].resourceGroup
} 

# now the compute instance name
if (-not $computeInstanceName) {
    # Get the list of compute instances in the workspace
    $computeInstances = az ml compute instance list --workspace-name $workspaceName --resource-group $workspaceRGName --query "[].{name:name}" -o json | ConvertFrom-Json

    # Display the list of compute instances as a menu
    Write-Host "Select a compute instance:"
    for ($i = 0; $i -lt $computeInstances.Count; $i++) {
        Write-Host "$($i + 1). $($computeInstances[$i].name)"
    }

    # Ask the user to select a compute instance
    $selection = Read-Host "Enter the number of the compute instance"

    # Get the selected compute instance name
    $computeInstanceName = $computeInstances[$selection - 1].name
}

# print variabes for debugging
Write-Host "storageRGName: $storageRGName"
Write-Host "storageAccountName: $storageAccountName"
Write-Host "workspaceRGName: $workspaceRGName"
Write-Host "workspaceName: $workspaceName"
Write-Host "computeInstanceName: $computeInstanceName"
Write-Host "userId: $userId"

# get the workspace identity
$workspaceIdentity = az ml workspace show --resource-group $workspaceRGName --workspace-name $workspaceName --query identity.principal_id -o tsv

#get the compute instance identity
$computeInstanceIdentity = az ml compute instance show --resource-group $workspaceRGName --workspace-name $workspaceName --name $computeInstanceName --query identity.principal_id -o tsv

# Permissions we will need to set on the storage account:
# Azure ML Workspace needs the following permissions on the storage account:
# Storage Account Contributor
# Storage Blob Data Contributor
# Storage File Data Privileged Contributor

Write-Host "Assigning Workspace Identity Permissions to the Storage Account"
Write-Host "Commands to execute..."
Write-Host "az role assignment create --role 'Storage Account Contributor' --assignee $workspaceIdentity --scope /subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
Write-Host "az role assignment create --role 'Storage Blob Data Contributor' --assignee $workspaceIdentity --scope /subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
Write-Host "az role assignment create --role 'Storage File Data Privileged Contributor' --assignee $workspaceIdentity --scope /subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

az role assignment create --role "Storage Account Contributor" --assignee $workspaceIdentity --scope "/subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
az role assignment create --role "Storage Blob Data Contributor" --assignee $workspaceIdentity --scope "/subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
az role assignment create --role "Storage File Data Privileged Contributor" --assignee $workspaceIdentity --scope "/subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

# Azure ML Compute Targets need the following permissions on the storage account:
# Storage Blob Data Contributor
# Storage File Data Privileged Contributor

Write-Host "Assigning Compute Instance Identity Permissions to the Storage Account"
Write-Host "Commands to execute..."
Write-Host "az role assignment create --role 'Storage Blob Data Contributor' --assignee $computeInstanceIdentity --scope /subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
Write-Host "az role assignment create --role 'Storage File Data Privileged Contributor' --assignee $computeInstanceIdentity --scope /subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

az role assignment create --role "Storage Blob Data Contributor" --assignee $computeInstanceIdentity --scope "/subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
az role assignment create --role "Storage File Data Privileged Contributor" --assignee $computeInstanceIdentity --scope "/subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

# Current User Identity needs the following permissions on the storage account:
# this is "Probably" already set so ignore any errors
# Storage Blob Data Contributor
# Storage File Data Privileged Contributor

Write-Host "Assigning Current User Identity Permissions to the Storage Account"
Write-Host "Commands to execute..."
Write-Host "az role assignment create --role 'Storage Blob Data Contributor' --assignee $userId --scope /subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
Write-Host "az role assignment create --role 'Storage File Data Privileged Contributor' --assignee $userId --scope /subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

az role assignment create --role "Storage Blob Data Contributor" --assignee $userId --scope "/subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
az role assignment create --role "Storage File Data Privileged Contributor" --assignee $userId --scope "/subscriptions/$subscriptionId/resourceGroups/$storageRGName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

