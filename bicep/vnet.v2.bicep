@description('The Azure region to deploy to.')
@metadata({
  strongType: 'location'
})
param location string = resourceGroup().location

@description('The object to use as a location to location short code map.')
param locationCodes object

@description('The name of the environment')
@allowed([
  'dev'
  'tst'
  'uat'
  'prd'
])
param env string

@description('''
The base VNet name without prefixes.
- The name will be lower-cased.
- The correct prefixes and suffixes will be added for location and environment.
- Example: "My-Net" becomes "vnet-weu-dev-my-net-abc123".
''')
@minLength(2)
@maxLength(18)
param name string

@description('The list of VNet address prefixes. Make sure the addresses do not overlap with any VNets that you intend to peer with.')
param vnetAddressPrefixes array

@description('''
An object array of names and IP address ranges for each subnet in the virtual networks.
- The name will be lower-cased.
- The name should not exceed 50 characters to allow for prefixes (this is not enforced), the Azure max is 80.
- The correct prefixes and suffixes will be added for location and environment.
- Example: "Web-Apps" becomes "snet-weu-dev-web-apps-abc123".
The object structure is:
```
{
  name: 'subnet-name'
  ipAddressRange: '10.10.5.0/24'
  enablePrivateEndpointNetworkPolicies: false
  delegations: [
    {
        name: 'Microsoft.Web.serverFarms'
        properties: {
            serviceName: 'Microsoft.Web/serverFarms'
        }
    }
  ]
}
```
''')
param subnets array

@description('Name of the NetworkSecurityGroup to connect')
param networkSecurityGroup string

var locationCode = toLower(locationCodes[location])
var vnetName = toLower('vnet-${locationCode}-${env}-${name}')

var networkSecurityGroupName = replace(replace(networkSecurityGroup, '{{locationCode}}', locationCode), '{{env}}', env)


@description('Create/Update Network Security Group')
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  name: networkSecurityGroupName
}

var subnetProperties = [for subnet in subnets: {
  name: toLower('snet-${subnet.name}')
  properties: {
    addressPrefix: subnet.ipAddressRange
    privateEndpointNetworkPolicies: subnet.PrivateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegations: subnet.delegations
    serviceEndpoints: subnet.serviceEndpoints
    networkSecurityGroup: nsg.id == '' ? null : {
      id: nsg.id
    }
    applicationGatewayIpConfigurations: subnet.name == 'agw' ? [
      {
        id: resourceId('Microsoft.Network/applicationGateways/gatewayIPConfigurations', 'agw-${locationCode}-${env}-newbhi', 'appGatewayIpConfig')
      }
    ] : []
  }
}]

@description('Connect Virtual Network to Network Security Group')
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName
  location: location
  properties:{
    addressSpace:{
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: subnetProperties
  }

  resource snets 'subnets' existing = [for subnet in subnetProperties: {
    name: subnet.name
  }]
}

output vnetId string = vnet.id
output subnetInfo array = [for i in range(0, length(subnetProperties)): {
  id: vnet::snets[i].id
  name: vnet::snets[i].name
}]
