Overview

This Bicep template deploys a complete Azure infrastructure, including:

A Virtual Network (VNet) with two subnets (public and private).

Network Security Groups (NSG) for controlling inbound and outbound traffic.

A Load Balancer with backend pool configuration and health probe.

An Azure Container Instance (ACI) deployed in the private subnet.

Integration with Azure Container Registry (ACR) for pulling container images.

Logging and monitoring through a Log Analytics workspace.

Resources Deployed

Virtual Network

Name: CVUVirtualNetwork

Address space: 10.0.0.0/16

Public Subnet: 10.0.0.0/24

Private Subnet: 10.0.1.0/24

Network Security Groups

Public Subnet NSG

Allows inbound HTTP traffic from the Internet.

Allows outbound HTTP traffic to the Internet.

Private Subnet NSG

Allows inbound HTTP traffic from the Public Subnet.

Allows outbound HTTP traffic to the Load Balancer.

Load Balancer

Public IP Address: Static assignment.

Backend Pool: Configured for ACI.

Health Probe: TCP on port 80.

Load Balancing Rule: Frontend port 80 to backend port 80.

Azure Container Instance (ACI)

Container Name: crude-flask

Image: Pulled from Azure Container Registry.

Port Mapping: Exposes port 80.

CPU/Memory: 1 CPU, 1GB RAM.

Environment Variables: Supports custom variables.

Networking: Private IP within the CVUPrivateSubnet.

Logging: Integrated with Azure Log Analytics.

Azure Container Registry (ACR)

ACR is referenced as an existing resource for pulling container images securely.

Logging & Monitoring

Log Analytics Workspace is created for diagnostic data collection.

The ACI logs are sent to the workspace.

Parameters

aciName: Name of the Azure Container Instance.

acrName: Name of the Azure Container Registry.

location: Azure region where resources are deployed.

Outputs

aciPrivateIP: The private IP address of the deployed ACI.

Deployment Instructions

Ensure you have the Azure CLI installed and logged in.

Navigate to the directory containing this Bicep file.

Run the following command to deploy the template:

az deployment group create --resource-group <YourResourceGroup> --template-file main.bicep --parameters aciName=<YourACIName> acrName=<YourACRName> location=<AzureRegion>

After deployment, retrieve the ACI private IP from the outputs using:

az deployment group show --resource-group <YourResourceGroup> --name <DeploymentName> --query properties.outputs.aciPrivateIP.value

Notes

The private subnet is delegated to ACI, enabling containerized workloads.

The Load Balancer ensures high availability for ACI services.

Ensure that your ACR is configured for authentication before deployment.

Logs and monitoring help diagnose issues efficiently.

This template simplifies the deployment of a secure, scalable, and monitored Azure infrastructure using Bicep.