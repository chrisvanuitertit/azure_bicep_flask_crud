/*
  Bicep Template for Deploying a Virtual Network, Security Groups, Load Balancer, and Azure Container Instance (ACI)

  Description:
  This template deploys an Azure environment including a Virtual Network (VNet) with two subnets (public and private), 
  Network Security Groups (NSG) for both subnets, and a Load Balancer with backend pool configuration. 
  It also provisions an Azure Container Instance (ACI) within the private subnet, configured with a pull from Azure Container Registry (ACR) 
  for the container image and secure environment variables. The load balancer is set up with a health probe to ensure availability of the container.
  Additionally, a Log Analytics workspace is created for monitoring and diagnostics purposes.
*/

// PARAMETERS
param aciName string = 'CVUContainerInstance'
param acrName string = 'CVUContainerRegistry'
param location string = 'westeurope'

// CREATE VIRTUAL NETWORK AND PROVIDE GLOBAL RANGE
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'CVUVirtualNetwork'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [
      // CREATE PUBLIC SUBNET AND ASSIGN 10.0.0.0/24 RANGE
      {
        name: 'CVUPublicSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          // LINK TO PUBLIC NETWORK SECURITY GROUP
          networkSecurityGroup: {
            id: nsgPublic.id
          }
        }
      }
      // CREATE PRIVATE SUBNET AND ASSIGN 10.0.1.0/24 RANGE
      {
        name: 'CVUPrivateSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            // LINK TO PRIVATE NETWORK SECURITY GROUP
            id: nsgPrivate.id
          }
          // DELEGATE SUBNET CONTROL TO ACI, ALLOWS ACI TO DEPLOY CONTAINER GROUPS WITHIN THIS SUBNET
          delegations: [
            {
              name: 'delegation-aci'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

// CREATE SECURITY GROUP FOR PUBLIC SUBNET
resource nsgPublic 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'CVUSecurityGroupPublic'
  location: location
  properties: {
    securityRules: [
      // INBOUND RULE: ONLY ALLOW HTTP TO PUBLIC SUBNET (FROM OUTSIDE)
      {
        name: 'Allow-Inbound-HTTP'
        properties: {
          priority: 100
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '10.0.0.0/24'
          access: 'Allow'
          direction: 'Inbound'
        }
      }
      // OUTBOUND RULE: ALLOW HTTP FROM PUBLIC SUBNET (TO PRIVATE SUBNET)
      {
        name: 'Allow-Outbound-HTTP'
        properties: {
          priority: 100
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '10.0.0.0/24'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          direction: 'Outbound'
        }
      }
    ]
  }
}

// CREATE SECURITY GROUP FOR PRIVATE SUBNET
resource nsgPrivate 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'CVUSecurityGroupPrivate'
  location: location
  properties: {
    securityRules: [
      // INBOUND RULE: ONLY ALLOW HTTP TO PRIVATE SUBNET (FROM PUBLIC SUBNET)
      {
        name: 'Allow-Inbound-HTTP'
        properties: {
          priority: 100
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.1.0/24'
          access: 'Allow'
          direction: 'Inbound'
        }
      }
      // OUTBOUND RULE: ONLY ALLOW HTTP FROM PRIVATE SUBNET (TO PUBLIC SUBNET)
      {
        name: 'Allow-Outbound-HTTP'
        properties: {
          priority: 100
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '10.0.1.0/24'
          destinationAddressPrefix: 'AzureLoadBalancer'
          access: 'Allow'
          direction: 'Outbound'
        }
      }
    ]
  }
}

//PUBLIC IP FOR LOAD BALANCER
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'CVUPublicIP'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// DEPLOY AZURE CONTAINER INSTANCE
resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: aciName
  location: location
  properties: {
    containers: [
      // CONTAINER IMAGE & SETTINGS & PORT MAP
      {
        name: 'crude-flask'
        properties: {
          image: '${acrName}.azurecr.io/crude-flask:latest'
          ports: [ { port: 80 } ]
          resources: { 
            requests: { 
              cpu: 1 
              memoryInGB: 1
            } 
          }
          environmentVariables: [ { name: 'ENVIRONMENT', value: 'production' } ]
        }
      }
    ]
    // ACR CREDENTIALS AND URL
    imageRegistryCredentials: [
      {
        server: '${acrName}.azurecr.io'
        username: acr.listCredentials().username
        password: acr.listCredentials().passwords[0].value
      }
    ]
    // PRIVATE IP ADDRESS
    ipAddress: { type: 'Private', ports: [ { protocol: 'TCP', port: 80 } ] }
    subnetIds: [ { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'CVUPrivateSubnet') } ]
    osType: 'Linux'
    // LINK LOGS TO LOG ANAALYTICS WORKSPACE
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalyticsWorkspace.properties.customerId
        workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// REFERENCE TO EXISTING CONTAINER REGISTRY
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// STORES THE PRIVATE IP OF ACI IN A VARIABLE
var aciPrivateIP = aci.properties.ipAddress.ip

// LOAD BALANCER SETTINGS
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: 'CVULoadBalancer'
  location: location
  sku: { name: 'Standard' }
  properties: {
    // ASSIGN FRONT END PUBLIC IP ADDRESS
    frontendIPConfigurations: [
      {
        name: 'frontend'
        properties: {
          publicIPAddress: { id: publicIP.id }
        }
      }
    ]
    // GIVE NAME TO BACK END POOL
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    // ASSIGN NETWORKS
    loadBalancingRules: [
      {
        // LOAD BALANCING RULE NAME
        name: 'http-rule'
        properties: {
          // FRONTEND IP REFERENCE
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'CVULoadBalancer', 'frontend')
          }
          // BACKEND POOL REFERENCE
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'CVULoadBalancer', 'backendPool')
          }
          // HEALTH PROBE REFERENCE
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'CVULoadBalancer', 'http-probe')
          }
          protocol: 'TCP'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
        }
      }
    ]
    // CONTAINER HEALTH CHECK PROBE ON PORT 80
    probes: [
      {
        name: 'http-probe'
        properties: {
          protocol: 'TCP'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
}


// BACK END POOL CONFIGURATION
resource backendPoolConfig 'Microsoft.Network/loadBalancers/backendAddressPools@2023-04-01' = {
  parent: loadBalancer
  name: 'backendPool'
  properties: {
    loadBalancerBackendAddresses: [
      {
        name: 'aci-backend'
        properties: {
          ipAddress: aciPrivateIP
          virtualNetwork: {
            id: vnet.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'CVUPrivateSubnet')
          }
        }
      }
    ]
  }
}

// LOGGING SETTINGS
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'CVULogs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// OUTPUT IP VALUE SO IT CAN REFERENCED
output aciPrivateIP string = aciPrivateIP
