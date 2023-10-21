# README

Provision a new container in Azure using GitHub Actions with support for multiple environments,
but a single container instance, per environment.

This repository is provided as a sample for how to use GitHub Actions to provision resources in Azure,
and how to deploy containers using Azure Container Instances using images on DockerHub.

Note that the values and parameters should be reviewed.

Access to Azure is done using OpenId connect.

## Parameters

This repository has secrets that needs to be mapped in the
[infrastructure yml file](.github/workflows/deploy-infrastructure.yml).

It also has parameter, some including default values to review in the [IaC bicep file](infrastructure/azure/main.bicep),
the parameters are described within the bicep file.
