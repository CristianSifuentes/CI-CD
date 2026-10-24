// Parámetros para producción. Crea un archivo por ambiente (main.dev.bicepparam, ...)
// o usa variables de entorno con readEnvironmentVariable().
using './main.bicep'

param appName = 'miapp'
param environmentName = 'prod'
param skuName = 'P0v3'
param instanceCount = 2
param enableStagingSlot = true
param tags = {
  owner: 'equipo-plataforma'
  costCenter: 'cc-001'
}
