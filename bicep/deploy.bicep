targetScope = 'subscription'

// param rgName string
// param projectName string
// param cosmosdbName string
// param location string

@description('Deployment variable from parameter file')
param deployment object

@description('Environment to deploy')
@allowed([
  'dev'
  'tst'
  'uat'
  'prd'
])
param env string = deployment.env
// param locationCodes object
// param rgEnvironments object
var locationCodes = json(loadTextContent('location-codes.json'))
var rgEnvironments =json(loadTextContent('resourceGroup-environments.json'))
var locationCode = locationCodes[location]
var rgName = toUpper('RG-${locationCode}-${rgEnvironments[env]}-${deployment.projectName}')

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}
param location string = deployment.location

module webapp './webapp.bicep' = {
  name: '${deployment.webapp.appName}-${env}'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    webappName : '${deployment.webapp.appName}-${env}'
    skuName: deployment.webapp.skuName
    skuTier: deployment.webapp.skuTier
  }
}

module cosmos './cosmos.bicep'= if(!empty(deployment.cosmosDb)){
  name: 'dp-cosmosdb-${deployment.cosmosDb.name}'
  params:{
    // env: env
    // locationCodes: locationCodes
    // name: deployment.cosmosDb.name
    // keyvaultName: deployment.cosmosDb.keyvaultName
    // containers: deployment.cosmosDb.containers
    dbName: deployment.cosmosDb.dbName
    location: location
    name: deployment.cosmosDb.name
    containers: deployment.cosmosDb.containers
  }
  scope: resourceGroup(rg.name)
  // dependsOn:[
    // keyvault
  // ]
}

output appName string = webapp.outputs.appName
