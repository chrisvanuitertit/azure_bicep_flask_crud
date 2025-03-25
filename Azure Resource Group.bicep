/*
  Bicep Template for Deploying a Resource Group

  Description:
  This Bicep file defines a resource group deployment at the subscription level.
  It allows users to specify a resource group name and location as parameters.
  The resource group is created using the 'Microsoft.Resources/resourceGroups' resource provider.
*/

// SCOPED AT SUBSCRIPTION LEVEL
targetScope = 'subscription'

// VARIABLES
param resourceGroupName string = 'CVUResourceGroup'
param location string = 'westeurope'

//GENERATE A RESOURCE GROUP
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}
