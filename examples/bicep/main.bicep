// =============================================================================
// Infraestructura de referencia para una API en Azure App Service (Linux)
//   - Log Analytics + Application Insights (basado en workspace)
//   - App Service plan Linux + Web App + slot "staging" (swap sin downtime)
//   - Identidad administrada, HTTPS obligatorio, TLS >= 1.2, FTP deshabilitado
//   - Autenticación básica (SCM/FTP) deshabilitada: los despliegues usan Entra ID
//
// Despliegue recomendado (deployment stack con protección contra borrado):
//   az stack group create --name miapp-prod --resource-group rg-miapp-prod \
//     --template-file main.bicep --parameters main.bicepparam \
//     --action-on-unmanage detachAll --deny-settings-mode denyDelete --yes
// =============================================================================

targetScope = 'resourceGroup'

@description('Nombre corto de la aplicación (minúsculas, sin espacios).')
@minLength(3)
@maxLength(12)
param appName string

@description('Ambiente lógico.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentName string

@description('Región. Por defecto, la del resource group.')
param location string = resourceGroup().location

@description('SKU del plan. Los slots requieren Standard (S1) o superior; P0v3 es el Premium más económico.')
param skuName string = 'P0v3'

@description('Número de instancias del plan (usa >= 2 en producción).')
@minValue(1)
param instanceCount int = 1

@description('Crear el slot "staging" para despliegues sin downtime.')
param enableStagingSlot bool = true

@description('Ruta del health check que usan App Service, el warm-up del swap y los smoke tests.')
param healthCheckPath string = '/healthz'

@description('Etiquetas adicionales.')
param tags object = {}

var name = '${appName}-${environmentName}'
var allTags = union(tags, {
  environment: environmentName
  'managed-by': 'bicep'
})

resource logs 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: 'log-${name}'
  location: location
  tags: allTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${name}'
  location: location
  tags: allTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logs.id
  }
}

resource plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: 'asp-${name}'
  location: location
  tags: allTags
  kind: 'linux'
  sku: {
    name: skuName
    capacity: instanceCount
  }
  properties: {
    reserved: true // requerido para planes Linux
  }
}

// Configuración compartida por producción y staging: el swap es seguro sólo si
// ambos slots son idénticos salvo en lo que marques como "slot setting".
var siteConfig = {
  linuxFxVersion: 'DOTNETCORE|10.0'
  alwaysOn: true
  ftpsState: 'Disabled'
  http20Enabled: true
  minTlsVersion: '1.2'
  scmMinTlsVersion: '1.2'
  healthCheckPath: healthCheckPath
  appSettings: [
    {
      name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
      value: appInsights.properties.ConnectionString
    }
    {
      // El swap espera a que esta ruta responda 200 en todas las instancias.
      name: 'WEBSITE_SWAP_WARMUP_PING_PATH'
      value: healthCheckPath
    }
    {
      name: 'WEBSITE_SWAP_WARMUP_PING_STATUSES'
      value: '200'
    }
  ]
}

resource app 'Microsoft.Web/sites@2024-11-01' = {
  name: 'app-${name}'
  location: location
  tags: allTags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: siteConfig
  }
}

// Deshabilita usuario/contraseña para SCM (Kudu) y FTP.
resource appScmBasicAuth 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: app
  name: 'scm'
  properties: {
    allow: false
  }
}

resource appFtpBasicAuth 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: app
  name: 'ftp'
  properties: {
    allow: false
  }
}

resource stagingSlot 'Microsoft.Web/sites/slots@2024-11-01' = if (enableStagingSlot) {
  parent: app
  name: 'staging'
  location: location
  tags: allTags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: siteConfig
  }
}

resource slotScmBasicAuth 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2024-11-01' = if (enableStagingSlot) {
  parent: stagingSlot
  name: 'scm'
  properties: {
    allow: false
  }
}

resource slotFtpBasicAuth 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2024-11-01' = if (enableStagingSlot) {
  parent: stagingSlot
  name: 'ftp'
  properties: {
    allow: false
  }
}

@description('Nombre de la Web App.')
output webAppName string = app.name

@description('Host por defecto de producción.')
output defaultHostName string = app.properties.defaultHostName

@description('Object ID de la identidad administrada (para asignarle roles RBAC).')
output principalId string = app.identity.principalId
