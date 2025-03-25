/*
  Bicep Template for Deploying an Azure Container Registry (ACR) with a Pull Token

  Description:
  This template provisions an Azure Container Registry (ACR) with a 'Basic' SKU, 
  enables the admin user, and configures a pull token. The pull token is assigned 
  a scope map that allows read access to all repositories in the registry.
*/

// PARAMETERS FOR ACR TOKEN
param acrName string = 'CVUContainerRegistry'
param location string = 'westeurope'
param tokenName string = 'acipull'

//DEPLOY THE AZURE CONTAINER REGISTRY
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// CREATE A SCOPE MAP THAT ALLOWS READ ACCESS TO ALL REPOSITORIES IN THE REGISTRY
resource pullScopeMap 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-07-01' = {
  parent: acr
  name: 'pullScope'
  properties: {
    actions: [
      'repositories/*/content/read'
    ]
  }
}

// CREATE AN ACR TOKEN LINKED TO THE PULL SCOPE MAP
resource acrToken 'Microsoft.ContainerRegistry/registries/tokens@2023-07-01' = {
  parent: acr
  name: tokenName
  properties: {
    scopeMapId: pullScopeMap.id
    status: 'enabled'
  }
}

// OUTPUT THE ACR LOGIN SERVER URL & NAME SO THEY CAN BE REFERENCED IN DEPLOYMENTS
output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
