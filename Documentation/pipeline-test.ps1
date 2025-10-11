# this document contain powershell script to test the pipeline inline scripts for deploy resources using bicep files
# and to test the azure cli commands used in the pipeline

# --- ACR Test ---
# Declare variables
$containerRegistryName = "introspect2bacr"
$resourceGroup = "introspect-2-b"
$acrBicepFile = "aca-deploy.bicep"
$location = "westeurope"

# Check if the ACR resource exists
Write-Host "Checking if ACR resource exists: $containerRegistryName"

try {
        $acrExists = az acr show --name $containerRegistryName --query "name" --output tsv 2>$null
        Write-Host "Value of acrExists: $acrExists"

        if ($acrExists) {
            Write-Host "Azure Container Registry $containerRegistryName already exists. Deployment will not proceed."
            # exit 1
        } else {
            Write-Host "Azure Container Registry $containerRegistryName does not exist. Proceeding with deployment."
        }

        # Deploy the ACR using the Bicep template
        Write-Host "Deploying Azure Container Registry using Bicep..."
        az deployment group create `
            --resource-group $resourceGroup `
            --template-file $acrBicepFile `
            --parameters containerRegistryName=$containerRegistryName location=$location
        Write-Host "Deployment completed successfully."
    } 
catch {
         Write-Host "An error occurred during the deployment process."
         Write-Host "Error details: $($_.Exception.Message)"
         # exit 1
      }


# --- Container Environment Resource exists ---
# Declare variables
$containerEnvironmentName = "claimstatus-container-app-env"
$containerEnvBicepFile = "container-env.bicep"
$logAnalyticsWorkspaceName = "workspace-intospect2b-logs"
$location = "westeurope"
$resourceGroup = "introspect-2-b"

Write-Host "Value of containerEnvNameExists: $containerEnvironmentName"
try {
        $containerEnvironmentNameExist= az containerapp env show --name $containerEnvironmentName --query "name" --output tsv 2>$null
        Write-Host "Value of containerEnvNameExists: $containerEnvironmentNameExist"
        
        if ($containerEnvironmentNameExist) {
	    	Write-Host "Container Environment $containerEnvironmentName already exists. Deployment will not proceed."
	    	# exit 1
	    } else {
	    	Write-Host "Container Environment $containerEnvironmentName does not exist. Proceeding with deployment."
	    }

        az deployment group create \
            --resource-group $(resourceGroup) \
            --template-file $(containerEnvBicepFile) \
            --parameters containerEnvironmentName=$(containerEnvironmentName) location=$(location) logAnalyticsWorkspaceName=$(logAnalyticsWorkspaceName)
    
    } catch {
    Write-Host "An error occurred during the deployment process."
    Write-Host "Error details: $($_.Exception.Message)"
    # exit 1
}

