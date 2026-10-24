output "resource_group_name" {
  description = "Resource group de la aplicación."
  value       = azurerm_resource_group.this.name
}

output "web_app_name" {
  description = "Nombre de la Web App."
  value       = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  description = "Host por defecto de producción."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "principal_id" {
  description = "Object ID de la identidad administrada (para asignarle roles RBAC)."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}
