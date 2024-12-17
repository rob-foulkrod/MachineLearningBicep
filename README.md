Welcome to the Workspace Installer (v0.2). Follow the steps below to deploy this script in your Azure environment.

## Prerequisites

Ensure you have the Azure CLI installed. You can download and install it from the following link:
[Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)

## Running the Script Locally

It is recommended to run the installer locally instead of using CloudShell due to potential timeouts.

### Step 1: Login to Azure

Login to Azure using the following command and provide your credentials:
```powershell
az login
```

### Step 2: Clone the Repository

Clone the repository and navigate to the `MachineLearningBicep` directory:
```powershell
git clone https://github.com/rob-foulkrod/MachineLearningBicep.git
cd MachineLearningBicep
```

### Step 3: Run the Script

Execute the PowerShell script:
```powershell
./run.ps1
```

## Additional Configuration

- **resourceGroupName**: The name of the resource group. Default is `aml-rg`.
- **location**: The Azure region where the resources will be deployed. Default is `eastus2`.
- **prefix**: The prefix for naming resources. Default is `aml`.

### Example Usage with Parameters

To run the script with custom parameters, use the following command:

```powershell
./run.ps1 -resourceGroupName "myResourceGroup" -location "eastus" -prefix "myPrefix"
```

Alternatively, you can use the shorthand version:

```powershell
./run.ps1 -r "myResourceGroup" -l "eastus" -p "myPrefix"
```

