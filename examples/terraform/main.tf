locals {
  name = "${var.app_name}-${var.environment}"
  tags = merge(var.tags, {
    environment = var.environment
    managed-by  = "terraform"
  })

  # Settings idénticos en producción y staging: el swap mueve código + settings.
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this.connection_string
    WEBSITE_SWAP_WARMUP_PING_PATH         = var.health_check_path
    WEBSITE_SWAP_WARMUP_PING_STATUSES     = "200"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.tags
}

resource "azurerm_service_plan" "this" {
  name                = "asp-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = var.sku_name
  worker_count        = var.worker_count
  tags                = local.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = "app-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  # Sin usuario/contraseña de publicación: se despliega con Entra ID.
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                         = true
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = 5

    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = local.app_settings
  tags         = local.tags
}

resource "azurerm_linux_web_app_slot" "staging" {
  count = var.enable_staging_slot ? 1 : 0

  name           = "staging"
  app_service_id = azurerm_linux_web_app.this.id
  https_only     = true

  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                         = true
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = 5

    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = local.app_settings
  tags         = local.tags
}
