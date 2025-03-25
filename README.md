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

Deployment Instructions

Install AZURE CLI

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
  gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
AZ_DIST=$(lsb_release -cs)
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${AZ_DIST}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources
sudo apt-get update
sudo apt-get install azure-cli

Deployment

az login
az deployment sub create --location westeurope --template-file Azure_Resource_Group.bicep
az acr login --name CVUContainerRegistry
az deployment group create --resource-group CVUResourceGroup --template-file Azure_Container_Registry.bicep
az deployment group create --resource-group CVUResourceGroup --template-file Azure_Infrastructure.bicep
