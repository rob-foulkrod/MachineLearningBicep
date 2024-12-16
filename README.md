Follow the following steps to deploy this script in your Azure environment:
**If you do not have Azure CLI** download the following:
1. https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli
2. Install the az cli module: Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

Run this locally:
Step 1 - Login to Azure using **az login**
Step 2 - Clone the repo and change directory to MachineLearningBicep:
git clone https://github.com/rob-foulkrod/MachineLearningBicep.git
cd MachineLearningBicep
Step 3 - Run the script:
./run.ps1

