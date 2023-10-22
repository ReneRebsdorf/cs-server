# README

Provision a new container in Azure using GitHub Actions with support for multiple environments,
but a single container instance, per environment.

This repository is provided as a sample for how to use GitHub Actions to provision resources in Azure,
and how to deploy containers using Azure Container Instances using images on DockerHub.

Note that the values and parameters should be reviewed.

Access to Azure is done using OpenId connect.

## Prerequisites

- 1 Azure subscription
  - Register the resource providers for the subscription with:
    - az account set --subscription `subscription id`
    - az provider register --namespace `X`
      (where X is the provider name as listed in the [bicep file](infrastructure/azure/main.bicep))
      e.g. Microsoft.OperationalInsights, Microsoft.Storage, Microsoft.App.
  - n Resource groups (1 for each environment)
- n Azure App Registrations with OpenId connect configured for the github repository hosting the code
  - Access such as 'Contributor' given for each app registration to each corresponding resource group
- Repository or Environment secrets and variables as described below

## Parameters

This repository has secrets that needs to be verified and added where needed:

- The [workflow yml file](.github/workflows/deploy-infrastructure.yml) lists the needed env vars and secrets
- The [IaC bicep file](infrastructure/azure/main.bicep) describes the values for these params and shows their usage
