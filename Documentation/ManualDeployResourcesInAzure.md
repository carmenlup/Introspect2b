# Manual Deploymen of Resources in Azure
This document provides step-by-step instructions for manually deploying the related services In azure
The used servicis for ClaimStatus are:

1. Azure Container Registry (ACR) 
2. Azure Container Apps (ACA)
3. Azure Log Analytics Workspace
4. Azure Container Environment 
5. Api Management (APIM)
---
## 1. Deployment to Azure Container Registry (ACR) 
We will use Azure CLI for this objective.
##### 1.1 Login to azure
```
az login --tenant YOUR_TENANT_ID_
```
##### 1.2 Create the resource group
```
az group create --name introspect-2-b --location westeurope
```
##### 1.3. Create the ACR registry
- Check if your subscription is registered to use `Microsoft.ContainerRegistry` provider
	```
	az provider show --namespace Microsoft.ContainerRegistry --query "registrationState"
	```
- If the registrationState is `NotRegistered`, run the following command to register the provider:
	```
	az provider register --namespace Microsoft.ContainerRegistry
	```
- Wait registration to finish. You can check the result by running the command in step 1 again.
- Create the ACR registry
	```
	az acr create --resource-group introspect-2-b --name introspect2bacr --sku Basic
	```
- Enable the admin user account for the registry
	```
	az acr update -n introspect2bacr --admin-enabled true
	```
##### 1.4. Push an image to ACR
`a. Tag the Docker image for ClaimStatus`

- You need to ensure your local Docker immage exists before tagging it.

	If you have not built the Docker image yet, you can do so by running the following command solution folder (Introspect2b) and build image from there

	$\mathsf{\color{orange}Explenation!}$: We have external folders from project folders. I order to push to docker the external app context folder we need to buid the app from Introspect2b folder which is the solution folder

```
docker build -f ClaimStatus/Dockerfile -t claimstatus:latest .
```
- Then, tag the Docker image
```
docker tag claimstatus introspect2bacr.azurecr.io/claimstatus:latest
```
- Login to ACR
```
az acr login --name introspect2bacr
```
- Push Push the Docker image to ACR for ClaimStatus
```
docker push introspect2bacr.azurecr.io/claimstatus:latest
```
---
# 2. Deploy ClaimStatus in ACA
1. Go to azure portal and create a new Azure Container App.
2. Select respurce group `introspect-2-b` 
3. Conteiner App Name: `claim-status-app`
4. Environment and Log Analytics Workspece are created via pipeline so will be already available
   In case you need to create a new one follow the steps below:
	- Create new Container App Environment: `introspect-2-b-env`
	- Create new Log Analytics Workspace: `claimstatus-container-app-env`
	- Location: `West Europe`

   ![ACABasicConfig](Images/ACABasicConfig.jpg "ContainerACR Basic Config")

5. In the Container tab
    - Select the container registry `introspect1bacr.azurecr.io`
	- Select image `claimstatus`
	- Select tag `latest`
	- Authentication type: `Secret`
	- Delpoyment Stack : `.NET`

	![ACAContainerConfig](Images/ACAContainerConfig.jpg "ContainerACR Config")

6. Go to Ingress tab
	- Enable ingress
	- Acccept trafic from anyware
	- Target port: `8080`

	![ACAIngressConfig](Images/ACAIngressConfig.jpg "Ingress Config")

7. Press Review and create, than Create

8. Check the deployment status in the Azure Portal. 
It may take a few minutes for the Container App to be created and the container to be deployed.
After resource was deployed check your `claim-status-app` Container App and make sure it is running:
- Go to the `claim-status-app` resource in Azure Portal.
- Copy the URL from the Overview tab and replace `<calimstatusURL>`in the link below
```
<calimstatusURL>/swagger/index.html
```
Your link sould look like this:
```
https://claim-status-app.delightfulmoss-58bb48c4.westeurope.azurecontainerapps.io/swagger/index.html
```
- Open the link in your web browser to access the Swagger UI for the ClaimStatus API.
