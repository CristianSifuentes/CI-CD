terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.11" # AzureRM 5.x (jul-2026). Fija y actualiza con PRs de Dependabot/Renovate.
    }
  }

  # Estado remoto en Azure Storage con autenticación Entra ID (sin access keys).
  # Los valores se pasan con: terraform init -backend-config=backend.hcl
  backend "azurerm" {}
}
