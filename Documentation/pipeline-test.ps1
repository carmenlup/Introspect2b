# this document contain powershell script to test the pipeline inline scripts for deploy resources using bicep files
# and to test the azure cli commands used in the pipeline

# --- ACR Test ---
# Declare variables
$containerRegistryName = "introspect2bacr"
$resourceGroup = "introspect-2-b"
$acrBicepFile = "acr-deploy.bicep"
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

# --- Log Analytics Workspace exists ---
# Declare variables
$logAnalyticsWorkspaceName = "workspace-intospect2b-logs"
$logAnalyticsBicepFile = "log-analytics-workspace-def.bicep"
$location = "westeurope"
$resourceGroup = "introspect-2-b"
Write-Host "Checking if Log Analytics Workspace exists: $logAnalyticsWorkspaceName"
try {
	$logAnalyticsWorkspaceNameExist= az monitor log-analytics workspace show --resource-group $resourceGroup --workspace-name $logAnalyticsWorkspaceName --query "name" --output tsv 2>$null
	Write-Host "Value of logAnalyticsWorkspaceNameExist: $logAnalyticsWorkspaceNameExist"
	if ($logAnalyticsWorkspaceNameExist) {
	   Write-Host "Log Analytics Workspace $logAnalyticsWorkspaceName already exists. Deployment will not proceed."
	   # exit 1
	} else {
	   Write-Host "Log Analytics Workspace $logAnalyticsWorkspaceName does not exist. Proceeding with deployment."
	   az deployment group create `
			--resource-group $resourceGroup `
			--template-file $logAnalyticsBicepFile `
			--parameters logAnalyticsWorkspaceName=$logAnalyticsWorkspaceName location=$location
		Write-Host "Deployment completed successfully."
	}

	
	#exit 1
} catch {
	Write-Host "An error occurred during the deployment process."
	Write-Host "Error details: $($_.Exception.Message)"
	# exit 1
}

# --- Container Environment Resource exists ---
# Declare variables
$containerEnvironmentName = "claimstatus-container-app-env"
$containerEnvBicepFile = "container-environment-def.bicep"
$logAnalyticsWorkspaceName = "workspace-intospect2b-logs"
$location = "westeurope"
$resourceGroup = "introspect-2-b"

Write-Host "Value of containerEnvNameExists: $containerEnvironmentName"
try {
    $containerEnvironmentNameExist= az containerapp env show --name $containerEnvironmentName --resource-group $resourceGroup --query "name" --output tsv 2>$null
    Write-Host "Value of containerEnvNameExists: $containerEnvironmentNameExist"
    if ($containerEnvironmentNameExist) {
       Write-Host "Container Environment $containerEnvironmentName already exists. Deployment will not proceed."
       # exit 1
    } else {
       Write-Host "Container Environment $containerEnvironmentName does not exist. Proceeding with deployment."
       
       az deployment group create `
            --resource-group $resourceGroup `
            --template-file $containerEnvBicepFile `
            --parameters containerEnvironmentName=$containerEnvironmentName `
                location=$location 
                logAnalyticsWorkspaceName=$logAnalyticsWorkspaceName
        Write-Host "Deployment completed successfully."
    }

    
    #exit 1
} catch {
    Write-Host "An error occurred during the deployment process."
    Write-Host "Error details: $($_.Exception.Message)"
    # exit 1
}



# --- CLI commands for respources--
# create resource group
az group create --name "introspect-2-b" --location "westeurope"
# create log analytics workspace
az deployment group create `
  --resource-group "introspect-2-b" `
  --template-file "log-analytics-workspace-def.bicep" `
  --parameters logAnalyticsWorkspaceName="workspace-intospect2b-logs" `
        location="westeurope"

$workspaceKey = az monitor log-analytics workspace get-shared-keys `
  --resource-group introspect-2-b `
  --workspace-name workspace-intospect2b-logs `
  --query primarySharedKey `
  --output tsv
Write-Host "Log Analytics Workspace Key: $workspaceKey"

az deployment group create `
  --resource-group "introspect-2-b" `
  --template-file "container-environment-def.bicep" `
  --parameters containerEnvironmentName="claimstatus-container-app-env" 
    location="westeurope" 
    logAnalyticsWorkspaceId="<replace with log analytics workspace id>"
    logAnalyticsWorkspaceKey="<replace with log analytics workspace key>"

az deployment group create `
--resource-group "introspect-2-b" `
--template-file "aca-deploy.bicep" `
--parameters acrName="introspect2bacr" `
            acrLoginServer="introspect2bacr.azurecr.io" `
            containerAppName="claim-status-app" `
            containerImage="introspect2bacr.azurecr.io/claimstatus:latest" `
            location="westeurope" `
            environmentName="claimstatus-container-app-env" `
            logAnalyticsWorkspaceName="workspace-intospect2b-logs" `
            logAnalyticsSku="PerGB2018" `
            cpu="0.5" `
            memory="1.0Gi"

            az monitor log-analytics workspace get-shared-keys `
             --resource-group "introspect-2-b" `
             --workspace-name "workspace-intospect2b-logs" `
             --query primarySharedKey -o tsv 