# Define variables
$phase1File = "phase1.bicep"
$phase2File = "phase2.bicep"

$resourceGroupName = "demo-ml-rg"
$location = "eastus2"
$deploymentName = "deploy-ml-$(Get-Date -Format 'yyyyMMdd')"
$prefix = 'aml'

# get the current users principal id
$currentUserId = az ad signed-in-user show --query id -o tsv

# Check if the 'az ml' extension is installed
# the script will fail after many minutes if the extension is not installed
. ./CheckExtensions.ps1 -extensionName "ml"

# Create resource group
az group create --name $resourceGroupName --location $location

# Deploy Bicep file
$deployment = az deployment group create `
    --name $deploymentName --resource-group $resourceGroupName `
    --template-file $phase1File `
    --parameters location=$location prefix=$prefix currentUserId=$currentUserId `
    --query "properties.outputs" `
    --output json

$outputs = $deployment | ConvertFrom-Json
$storageAccountId = $outputs.storageAccountId.value

# get the current subscriptionid
$subscriptionId = az account show --query id -o tsv

#list the ML workspaces in the resourcegroup $resourceGroupName and store the first workspace name in the variable $workspaceName
$workspaceName = az ml workspace list --resource-group $resourceGroupName --subscription $subscriptionId --query [0].name -o tsv

az ml workspace provision-network --subscription $subscriptionId -g $resourceGroupName -n $workspaceName

$deployment = az deployment group create --name $deploymentName --resource-group $resourceGroupName `
    --template-file $phase2File `
    --parameters location=$location amlWorkspaceName=$workspaceName  `
    --query "properties.outputs" `
    --output json

$outputs = $deployment | ConvertFrom-Json
$computeInstanceName = $outputs.computeInstanceName.value

write-host "Enabling Managed Identity for the Compute Instance"
$id = az ml compute update -n $computeInstanceName -g more-ml-rg -w $workspaceName --identity-type SystemAssigned --query "identity.principal_id" --output tsv

write-host "Assigning Storage File Data Privileged Contributor role to the Compute Instance Managed Identity"
az role assignment create --role "Storage File Data Privileged Contributor" --assignee $id --scope $storageAccountId

write-host "Restarting the Compute Instance"
az ml compute restart -n $computeInstanceName -g $resourceGroupName -w $workspaceName

write-host "Completed deployment"