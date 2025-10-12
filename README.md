# General considerations

Deploy a Claim Status API in Azure Container Apps (ACA) by API Management
(APIM). Implement: GET /claims/{id} (status) and POST /claims/{id}/summarize (calls Azure
OpenAI to return a summary from mock notes). Secure and automate via Azure DevOps
CI/CD with image scanning and enable observability.

# Architecture Overview

The solution implements a modern cloud-native architecture with the following components:
How it works:

1. Code is developed and pushed to a GitHub repository.
1. An Azure DevOps pipeline is triggered on code push wich perform the next:
   - deploy Resources in Azure using bicep files
   - builds the application, runs tests, scans for vulnerabilities, and pushes the Docker image to Azure Container Registry (ACR).
1. The pipeline then deploys the application to Azure Container Apps (ACA) using Bicep templates.
1.

- Azure Container Apps: Serverless container hosting platform
- Azure Container Registry: Secure container image storage
- Azure API Management: API gateway with policies and rate limiting
- Azure OpenAI: gpt-4o-mini for claim summarization
- Azure Log Analytics: Centralized logging and monitoring
- Azure Application Insights: Application performance monitoring

# Introspect1B Solution overview

### Project Structure

```
Introspect2b					# Solution folder
├── ClaimStatus (Project)			# Main project containing the API implementation
│   ├── Controllers				# Contains API controllers for handling HTTP requests
│   │   └── ClaimsController.cs
│   ├── Models					# Defines data models used in the application
│   │   ├── ClaimDetail.cs
│   │   ├── Claims.cs
│   │   ├── Note.cs
│   │   └── Notes.cs
│   ├── Documentation				# Includes implementation guides and related images
│   │   ├── StepByStepImplementation.md
│   │   └── Images
│   ├── Dockerfile				# Dockerfile for containerizing the application
│   ├── ClaimStatus.csproj			# Project file defining dependencies and configurations
│   ├── Program.cs				# Entry point of the application
│   └── appsettings.json (optional)		# Configuration file for application settings
├── mocks					# Contains mock data for testing the API
│   ├── claims.json
│   └── notes.json
├── pipelines					# Stores CI/CD pipeline configurations
│   └── azure-pipelines.yml
├── iac						# Infrastructure as Code templates for resource provisioning
│   ├── acr-deploy.bicep
|	├── log-analytics-workspace-def.bicep
|	├── container-environment-def.bicep
|	├── aca-deploy.bicep
├── scans					# Stores security scan results or related artifacts
│   └── defender-findings.png
├── observability				# Resources for monitoring and observability
│   ├── queries.kql
│   └── sample-screenshots
│       └── observability-example.png
└── README.md					# Documentation for the solution
```

- TBRemovedLATER - ClaimStatus/ — service source + Dockerfile.
- TBRemovedLATER - mocks/claims.json, mocks/notes.json (5–8 claim records; 3–4 notes blobs).
- apim/ — APIM policy files or export.
- iac/ — Bicep/Terraform templates.
- TBRemovedLATER- pipelines/azure-pipelines.yml — Azure DevOps pipeline.
- scans/ — link/screenshots to Defender findings
- observability/ — saved KQL queries and sample screenshots.
  IP - README.md — instructions, GenAI prompts used, how to run/tests.

---

---

# ClaimStatus API Documentation

This document provides an overview of the ClaimStatus API which is a asp.net core web api application.
The API is designed to manage and track the status of claims within a system.
It allows users to retrieve claim statuses by their unique identifiers and provides a summary of all claim statuses integrated with OpenAI for enhanced insights.

For more details about implementation steps, and Testing please refer to the [ClaimStatus API Documentation](ClaimStatus/Documentation/StepByStepImplementation.md).

---

---

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
   ```

2. Run the ClaimStatus API:
   - Set `ClaimStatus` as the startup project in Visual Studio.
   - Press `F5` to run the application. This will start the API and open Swagger UI in your default web browser.
   - You can test the endpoints using Swagger UI or any API testing tool like Postman.

## Run and Test the Solution from Docker on Local machine

1. Open a terminal under solution folder run docker compose up command to build and run the microservices in Docker containers:
   ```powershell
   docker compose up --build
   ```
   This command builds the Docker images for both ProductService and OrderService and starts the containers.
   Your terminal should look like in immage below:

   ![ClaimAPI](Images/BuildAndStartDockerOnLocal.jpg "App Run in Docker Console")


2. Open a browser and navigate to the following URLs to access the Swagger UI for each microservice to test both are working.
   - ClaimStatus:
     [https://localhost:7238/swagger/index.html](https://localhost:7238/swagger/index.html)
     [http://localhost:5261/swagger/index.html](http://localhost:5261/swagger/index.html)

Remark: Use HTTPS for testing or comment UseHttpRedirection in Program.cs to test over HTTP
For more details about ClaimStatus

---

---

# Automation Overview

This section provides details about the implemented CI/CD pipeline and infrastructure as code (IaC) templates to automate the deployment process of the ClaimStatus API.

## Pipleline and IaC Overview

The implementation contain the pipeline and infrastructure as code (IaC) templates to automate the deployment process.
The pipeline is defined in the `pipelines/azure-pipelines.yml` file and uses Bicep templates located in the `iac/` folder.

**Remark 1**: For an easier maintainace and better understanding, each resource is defined in a separated Bicep file and also deployment of each resource is in a separated job in the pipeline defibition.
**Remark 2**: In real project the pipeline dedicated for code buld and resources deployment are separatesd. In this demo project, for simplicity, they are in the same pipeline.

## Pipeline stages

### Stage 1: **Deploy Mandatory Resources**:

At this stage resources are checked and deployed if not exist.
Resources are defined in the Bicep template and pileline uses them to deploy the resources in Azure.

The resources deployed bicep files are:

- Azure Container Registry (ACR),
- \*\*\* - Azure Container Apps (ACA),
- \*\*\* - Azure API Management (APIM),
- \*\*\* - Azure OpenAI,
- Azure Log Analytics,
- Azure Container Environment
  \*\*\* - Azure Application Insights.

### Stage2: **Build and Push Docker Images to ACR**:

Build the Docker images for the ClaimStatus API and push them to the Azure Container Registry (ACR).

---

---

# Deployment Process Considerations

The deployment process involves several steps to ensure that the ClaimStatus API is properly deployed and configured in Azure Container Apps (ACA).

## Description

The deployment process involves the following steps:

1. **Connect to Github Repository**: The source code for the ClaimStatus is hosted in a GitHub repository, which is connected to Azure DevOps for continuous integration and deployment (CI/CD).
1. **Build and Push Docker Images to ACR**: The microservice images are built and pushed to an Azure Container Registry (ACR) for secure storage and management.
1. **Deploy to Azure Container Apps (ACA)**: The microservices are deployed to Azure Container Apps (ACA) using Bicep templates for infrastructure as code (IaC).
1. **Set Up CI/CD Pipeline in Azure DevOps**: An automated CI/CD pipeline is created in Azure DevOps to streamline the build, test, and deployment processes.

Below are the detailed steps for the deployment process.

## Prerequisites

Few prerequisites are needed before starting the deployment process:
**Azure Portal**: Ensure you create create a resource group named `introspect-2-b` in West Europe region to host the resources.
**Azure DevOps Setup**: - a new project - needed connections: - github connection - Azure Container Registry connection - Azure Resource Manager connection - a new pipeline 3. **GitHub Repository**: The source code for the microservices should be hosted in a GitHub repository.

## 2. Azure DevOps Setup

In order to automate the deployment process, we will set up a CI/CD pipeline in Azure DevOps.

##### 2.1 Create a new project in Azure DevOps

- Go to your Azure DevOps organization and click on "New Project".
- Enter a name for your project (e.g., "introspect-2-b") and click "Create".

Documentation link: [Create a project](https://learn.microsoft.com/en-us/azure/devops/organizations/projects/create-project?view=azure-devops&tabs=preview-page)

##### 2.2. Setup GitHub connection

- In your Azure DevOps project, navigate to "Project Settings" > "Service connections".
- Click on "New service connection" and select "GitHub".
- Authenticate with your GitHub account and authorize Azure DevOps to access your repositories.

Documentation link: [Connect to GitHub](https://learn.microsoft.com/en-us/azure/devops/boards/github/connect-to-github?view=azure-devops)

#### 2.3 Create Azure Resource Manager connection

This will ensure that Azure DevOps can deploy resources to your Azure subscription.

- In your Azure DevOps project, navigate to "Project Settings" > "Service connections".
- Click on "New service connection" and select "Azure Resource Manager".
- Connect using the service principal (automatic) option and follow the prompts to authenticate and authorize Azure DevOps.
- Select the subscription and resource group `introspect-2-b` created on step 2.2.
- Use `azure-connection` for service connection name and save it.

Documentation link [Service connections](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml)

####

##### 2.3. Create secure connection to Azure Container Registry (ACR)

- In your Azure DevOps project, navigate to "Project Settings" > "Service connections".
- Click on "New service connection" and select "Docker Registry".
- Select "Azure Container Registry" as the registry type.
- Select the subscription and the ACR instance `introspect2bacr` created on step 1.3.
- Use `acr-connection` for service connection name and save it.

# Deployment to Azure Container Apps (ACA) using automation with bicep

This section provides instructions for deploying the ClaimStatus to Azure Container Apps (ACA) using azure pipelines.

1. Create a new pipeline in Azure DevOps

   - Go to your Azure DevOps project and navigate to the Pipelines section.
   - Click on "New Pipeline" and select "Azure Repos Git" as the source.
     Repository is in Github so select GitHub and authenticate if needed.

   - Select your repository containing the microservices code.
   - Choose "Starter pipeline" and replace the default YAML with the following configuration:

```yaml



##### 1. Deploy ProductService in ACA
1. Go to azure portal and create a new Azure Container App.
2. Select respurce group `introspect-1-b`
3. Conteiner App Name: `claimstatus-app`
4. Click on Create new environment
	- Set the environment name to `my-container-app-env` and select the resource group `introspect-2-b`.
	- Go to Monitoring tab and click Create New Log Analytics Workspace
		- Set the name to `workspace-intospect2b-logs`

  		![analytics workspace](Documentation/Images/CreateACABasics.jpg "Analytics Workspace")

5. In the Container tab
    - Select the container registry `introspect1bacr.azurecr.io`
	- Select image `claimstatus`
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

````
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
````

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
1. Azure Container Apps Tutorial: [Azure Container Apps Tutorial](https://youtu.be/jfYJEcDOOkI?si=ePbJMgg2l6Ru-Zna)
1. Bicep Documentation: [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
1. Bicep learning path [Deploy Azure resources by using Bicep and Azure Pipelines](https://learn.microsoft.com/en-us/training/paths/bicep-azure-pipelines/)
