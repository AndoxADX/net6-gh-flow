param location string
param staticSiteslocation string
param webappName string
param skuName string
param skuTier string

// var isReserved = (functionPlanOS == 'Linux') ? true : false

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: toLower('hplan-${webappName}')
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'linux'
}

resource website 'Microsoft.Web/sites@2021-03-01' = {
  name: toLower(webappName)
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: insights.properties.InstrumentationKey
        }
      ]
    }
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: appServicePlan.name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource staticWebApp 'Microsoft.Web/staticSites@2021-01-01' = {
  name: 'static-${webappName}'
  location: staticSiteslocation
  tags: {
    tagName1: 'init-static-site'
  }
  properties: {}
  sku: {
    name: skuTier
  }
}

output appName string = website.name
