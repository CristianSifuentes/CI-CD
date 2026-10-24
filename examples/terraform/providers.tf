# La autenticación NO va en el código: el provider la toma de variables de
# entorno (ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_USE_OIDC=true
# y el token OIDC que inyecta GitHub Actions / Azure Pipelines).
provider "azurerm" {
  features {}

  # Usa Entra ID (RBAC) en lugar de shared keys para Storage.
  storage_use_azuread = true

  # AzureRM 5.x ya no registra resource providers por defecto
  # (resource_provider_registrations = "none"). Regístralos una vez por
  # suscripción con una identidad de plataforma, no desde el pipeline:
  #   az provider register --namespace Microsoft.Web
}
