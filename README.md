# General considerations
Deploy a Claim Status API in Azure Container Apps (ACA) by API Management
(APIM). Implement: GET /claims/{id} (status) and POST /claims/{id}/summarize (calls Azure
OpenAI to return a summary from mock notes). Secure and automate via Azure DevOps
CI/CD with image scanning and enable observability.

# Architecture Overview
The solution implements a modern cloud-native architecture with the following components:

- Azure Container Apps: Serverless container hosting platform
- Azure Container Registry: Secure container image storage
- Azure API Management: API gateway with policies and rate limiting
- Azure OpenAI: gpt-4o-mini for claim summarization
- Azure Log Analytics: Centralized logging and monitoring
- Azure Application Insights: Application performance monitoring

# Introspect1B Solution overview
### Project Structure
- ClaimStatus/ — service source + Dockerfile.
- mocks/claims.json, mocks/notes.json (5–8 claim records; 3–4 notes blobs).
- apim/ — APIM policy files or export.
- iac/ — Bicep/Terraform templates.
- pipelines/azure-pipelines.yml — Azure DevOps pipeline.
- scans/ — link/screenshots to Defender findings
- observability/ — saved KQL queries and sample screenshots.
- README.md — instructions, GenAI prompts used, how to run/tests.
----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

# ClaimStatus API Documentation
This document provides an overview of the ClaimStatus API which is a asp.net core web api application.
The API is designed to manage and track the status of claims within a system. 
It allows users to retrieve claim statuses by their unique identifiers and provides a summary of all claim statuses integrated with OpenAI for enhanced insights.
For more details, please refer to the [ClaimStatus API Documentation](ClaimStatus/Documentation/StepByStepImplementation.md).


----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

# Local setup considerations
## Prerequisites

1. [Docker](https://docs.docker.com/desktop/) installed and running on your machine.
2. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed on your machine.
3. Visual Studio 2022 or later with .NET Core SDK installed. You can download it from [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/).
4. An Azure subscription. If you don't have one, you can create a free account at [Azure Free Account](https://azure.microsoft.com/en-us/free/).
5. An Azure OpenAI resource. You can create one with <b> `Option 1: Allow all networks` </b>by following the instructions at [Create an Azure OpenAI resource](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/create-resource?pivots=web-portal).
	- Make sure to note down the endpoint URL and API key for later use.

## Run and Test the ClaimStatus API Locally 
ClaimStatus API is a simple ASP.NET Core Web API application that provides endpoints to get claim status and summarize claim notes using Azure OpenAI.
It provide a secure configuration using user-secrets for local development.
1. Setup user-secrets:
	- right-click on the `ClaimStatus` project in Visual Studio and select `Manage User Secrets`.
	- This will open a `secrets.json` file. Add your Azure OpenAI API key and endpoint in the following format:

	```json
	{
	  "OpenAIConfig": {
		"Endpoint:": "replace with YOUR-OPENAI_ENDPOINTURL",
		"DeploymentName": "replace with your OpenAI deployment name created at Preresuisites point 5 ",
		"ApiKey": "replace with YOUR-OPENAI-APIKey"
	  }
	}
	````
2. Run the ClaimStatus API:
	- Set `ClaimStatus` as the startup project in Visual Studio.
	- Press `F5` to run the application. This will start the API and open Swagger UI in your default web browser.
	- You can test the endpoints using Swagger UI or any API testing tool like Postman.



## Run and Test the Microservices from Docker on Local machine
1. Open a terminal under solution folder run docker compose up command to build and run the microservices in Docker containers:
   
----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
# Deployment on azure
This section provides instructions for deploying the microservices to Azure using Azure Container Registry (ACR) and Azure Container Apps (ACA).

## Deployment to Azure Container Registry (ACR) 
##### 1. Login to azure
```
az login --tenant YOUR_TENANT_ID_
```
##### 2 Create the resource group
```
az group create --name introspect-1-b --location westeurope
```
##### 3. Create the ACR registry
```
az acr create --resource-group introspect-1-b --name introspect1bacr --sku Basic
```

##### 4 Get the ACR login server name
```
az acr show --name introspect1bacr --query loginServer --output table
```
##### 5. Tag the Docker image for ClaimStatus 
You need to ensure your local Docker immage exists before tagging it. 
If you have not built the Docker image yet, you can do so by running the following command in the ProductService directory:
```
docker build -t claimstatus:latest .
```
Then, tag the Docker image for claimstatus:
```
docker tag claimstatus introspect1bacr.azurecr.io/productservice:latest
```

##### 6. Login to the ACR registry
```
az acr login --name introspect1bacr
```

##### 7. Push the Docker image to ACR for ProductService
```
docker push introspect1bacr.azurecr.io/claimstatus:latest
```


##### 10. Verify the images in ACR
```
az acr repository list --name introspect1bacr --output table
```
Both productservice and orderservice should be listed in the output.

# Deployment to Azure Container Apps (ACA) using Azure Portal

##### 1. Deploy ProductService in ACA
1. Go to azure portal and create a new Azure Container App.
2. Select respurce group `introspect-1-b` 
3. Conteiner App Name: `productservice-app`
4. Click on Create new environment
	- Set the environment name to `my-container-app-env` and select the resource group `introspect-1-b`.
	- Go to Monitoring tab and click Create New Log Analytics Workspace
		- Set the name to `workspace-intospect1b-logs`
		
  		![analytics workspace](Documentation/Images/CreateACABasics.jpg "Analytics Workspace")

5. In the Container tab
    - Select the container registry `introspect1bacr.azurecr.io`
	- Select image `productservice`
	- Select tag `latest`
	- Authentication type: `Secret`
	- Delpoyment Stack : `.NET`

	![contianer config](Documentation/Images/CreateAcaContainerACR.jpg "ContainerACR Config")

6. Go to Ingress tab
	- Enable ingress
	- Acccept trafic from anyware
	- Target port: `8080`

	![ingress config](Documentation/Images/CreateAcaIngress.jpg "Ingress Config")

7. Press Review and create, Then Create

8. Check the deployment status in the Azure Portal. 
It may take a few minutes for the Container App to be created and the container to be deployed.
After resource was deployed check your `productservice-app` Container App and make sure it is running:
- Go to the `productservice-app` resource in Azure Portal.
- Copy the URL from the Overview tab and replace `<productappURL>`in the link below
```
<productappURL>/swagger/index.html
```
Your link sould look like this:
```
https://productservice-app.jollypond-a6f1a425.westeurope.azurecontainerapps.io/swagger/index.html
```
- 



# Test communication between ProductService and OrderService using Dapr on Azure
You can test the communication between ProductService and OrderService using Dapr by invoking the endpoints defined in the ProductService API.
In Swagger UI, go to create endpoint and create a product.
### Example HTTP Requests for Create a Product
```http
POST https://<productappURL>/api/products
Content-Type: application/json

{
  "id": 100,
  "name": "Procuct check communication Azure",
  "price": 1,
  "stock": 3
}
```
1. The above request creates a new product in the ProductService.
![Create Product on Azure](Documentation/Images/ProductCreatedSwaggerjpg.jpg "Create Product on Azure")
2. After the product is created, the ProductService will publish an event to Dapr pub/sub, which can be consumed by the OrderService 
3. Check the logs frot both services to ensure that the event was published and consumed successfully.
   - In the `productservice-app` logs, you should see a message indicating that a product was created and an event was published.

	![ProductService Event Published](Documentation/Images/ProductPublishMeessage.jpg "ProductService Event Published")]

   - In the `orderservice-app` logs, you should see a message indicating that an event was received and processed.

	![OrderService Event Consumed](Documentation/Images/OrderSubscribeMeessage.jpg "OrderService Event Consumed")

## Documentation & learnings
For further reading and learning about Azure Container Apps, Dapr, and microservices architecture, you can refer to the following resources:
1. Container apps documentation: [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
1. Microsoft Dapr documentation: [Dapr Documentation](https://learn.microsoft.com/en-us/azure/container-apps/dapr-overview)
1. Azure Container Apps Tutorial: [Azure Container Apps Tutorial](https://youtu.be/jfYJEcDOOkI?si=ePbJMgg2l6Ru-Zna)
