param (
    [Alias("g", "resourceGroup")][string]$resourceGroupName = "aml-rg",
    [Alias("l")][string]$location = "eastus2",
    [Alias("p")][string]$prefix = 'aml'
)

write-host "Workspace Installer (v0.1)"
write-host ""

# Define variables
$mainFile = "main.bicep"
$deploymentName = "deploy-ml-$(Get-Date -Format 'yyyyMMddHHmmss')"

# get the current users principal id
$currentUserId = az ad signed-in-user show --query id -o tsv

# Check if the 'az ml' extension is installed
# the script will fail after many minutes if the extension is not installed
. ./CheckExtensions.ps1 -extensionName "ml"

# Create resource group
az group create --name $resourceGroupName --location $location

Write-Host "Deploying phase 1 - Creating most Resources"
Write-Host "Command to execute..."
Write-Host "az deployment group create --name $deploymentName --resource-group $resourceGroupName --template-file $mainFile --parameters location=$location prefix=$prefix currentUserId=$currentUserId --query 'properties.outputs' --output json"

write-host "Start time: $(Get-Date -Format 'HH:mm:ss')"
Write-host "Expect this to take approximately 20-25 minutes"

Write-Host "---"

# Deploy Bicep file
$deployment = az deployment group create `
    --name $deploymentName --resource-group $resourceGroupName `
    --template-file $mainFile `
    --parameters location=$location prefix=$prefix currentUserId=$currentUserId `
    --query "properties.outputs" `
    --output json


write-host "phase 1 outputs"
write-host $deployment
Write-Host "---"

$outputs = $deployment | ConvertFrom-Json
$storageAccountId = $outputs.storageAccountId.value

# get the current subscriptionid
$subscriptionId = az account show --query id -o tsv

#list the ML workspaces in the resourcegroup $resourceGroupName and store the first workspace name in the variable $workspaceName
$workspaceName = az ml workspace list --resource-group $resourceGroupName --subscription $subscriptionId --query [0].name -o tsv

Write-Host "Provisioning Network for Workspace"
write-host "Command to execute..."
write-host "az ml workspace provision-network --subscription $subscriptionId -g $resourceGroupName -n $workspaceName"
write-host "Start time: $(Get-Date -Format 'HH:mm:ss')"
Write-host "Expect this to take approximately 10 minutes"
write-host "---"

az ml workspace provision-network --subscription $subscriptionId -g $resourceGroupName -n $workspaceName

write-host "Enabling Public Access to Workspace"
write-host "Command to execute..."
write-host "az ml workspace update --name $workspaceName --resource-group $resourceGroupName --public-network-access Enabled"
write-host "---"

az ml workspace update --name $workspaceName --resource-group $resourceGroupName --public-network-access Enabled

$computeInstanceName = $prefix + "ci" + (Get-Date -Format 'yyyyMMddHHmmss')

write-host "Creating Compute Instance"
write-host "Command to execute..."
write-host "az ml compute create --name $computeInstanceName --resource-group $resourceGroupName --workspace-name $workspaceName --type ComputeInstance --size STANDARD_DS11_V2 --location $location --identity-type SystemAssigned --query 'identity.principal_id' --output tsv"
write-host "Start time: $(Get-Date -Format 'HH:mm:ss')"
Write-host "Expect this to take approximately 5 minutes"
write-host "---"

$id = az ml compute create --name $computeInstanceName `
    --resource-group $resourceGroupName `
    --workspace-name $workspaceName `
    --type ComputeInstance `
    --size STANDARD_DS11_V2 `
    --location $location `
    --identity-type SystemAssigned `
    --query "identity.principal_id" --output tsv

write-host "Assigning Storage File Data Privileged Contributor role to the Compute Instance Managed Identity"
write-host "Command to execute..."
write-host "az role assignment create --role 'Storage File Data Privileged Contributor' --assignee $id --scope $storageAccountId"

az role assignment create --role "Storage File Data Privileged Contributor" --assignee $id --scope $storageAccountId

write-host "Restarting the Compute Instance"
write-host "Command to execute..."
write-host "az ml compute restart -n $computeInstanceName -g $resourceGroupName -w $workspaceName"
write-host "Start time: $(Get-Date -Format 'HH:mm:ss')"
write-host "Expect this to take approximately 5 minutes"
write-host "---"


az ml compute restart -n $computeInstanceName -g $resourceGroupName -w $workspaceName


# ask the user if they want to add an additional storage account
$addStorage = Read-Host "Would you like to add permissions for an additional storage account? (y/n)"

if ($addStorage -eq "y") {
    . ./AddStorage.ps1 -workspaceRGName $resourceGroupName -workspaceName $workspaceName -computeInstanceName $computeInstanceName -userId $userId
}


write-host "Completed deployment"