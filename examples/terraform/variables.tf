variable "app_name" {
  description = "Nombre corto de la aplicación (minúsculas, sin espacios)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.app_name))
    error_message = "app_name debe tener entre 3 y 12 caracteres [a-z0-9]."
  }
}

variable "environment" {
  description = "Ambiente lógico: dev, staging o prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser dev, staging o prod."
  }
}

variable "location" {
  description = "Región de Azure, p. ej. mexicocentral o eastus2."
  type        = string
}

variable "sku_name" {
  description = "SKU del App Service plan. Los slots requieren S1 o superior."
  type        = string
  default     = "P0v3"
}

variable "worker_count" {
  description = "Número de instancias del plan (>= 2 en producción)."
  type        = number
  default     = 1
}

variable "enable_staging_slot" {
  description = "Crear el slot 'staging' para despliegues sin downtime."
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Ruta de health check (warm-up del swap y smoke tests)."
  type        = string
  default     = "/healthz"
}

variable "tags" {
  description = "Etiquetas adicionales."
  type        = map(string)
  default     = {}
}
