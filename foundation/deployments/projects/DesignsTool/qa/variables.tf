variable "location" {
  description = "Azure region for deployed resources."
  type        = string
}

variable "brand" {
  description = "Brand name."
  type        = string
}

variable "environment" {
  description = "Environment full name."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "managed_by" {
  description = "Tool managing these resources."
  type        = string
  default     = "Terraform"
}

variable "brand_short_name" {
  description = "Short brand name used in resource naming."
  type        = string
}

variable "environment_short_name" {
  description = "Short environment name used in resource naming."
  type        = string
}

variable "project_short_name" {
  description = "Short project name used in resource naming."
  type        = string
}

variable "location_short_name" {
  description = "Short location name used in resource naming."
  type        = string
}

# App Service configuration, supplied as one object from terraform.tfvars.
variable "app_service" {
  description = "App Service (Linux, Node.js) configuration object."
  type = object({
    app_name          = string
    service_plan_name = string
    sku_name          = string
    node_version      = optional(string, "20-lts")
    always_on         = optional(bool, true)
    https_only        = optional(bool, true)
    ftps_state        = optional(string, "Disabled")
    health_check_path = optional(string, "/")
    app_command_line  = optional(string, "")
    app_settings      = optional(map(string), {})
  })
}

# Secret app settings (extra key/values). Set as sensitive Terraform Cloud
# workspace variables — never in terraform.tfvars.
variable "secret_app_settings" {
  description = "Sensitive app settings merged into the web app's app_settings."
  type        = map(string)
  default     = {}
  sensitive   = true
}

# PostgreSQL Flexible Server configuration (non-secret), from terraform.tfvars.
variable "postgres" {
  description = "PostgreSQL Flexible Server configuration object."
  type = object({
    server_name          = string
    database_name        = string
    administrator_login  = string
    sku_name             = optional(string, "B_Standard_B1ms")
    storage_mb           = optional(number, 32768)
    postgres_version     = optional(string, "16")
    zone                 = optional(string, "1")
    allow_azure_services = optional(bool, true)
    client_ip            = optional(string, "")
  })
}

# PostgreSQL admin password — set as a sensitive Terraform Cloud workspace
# variable, never in terraform.tfvars.
variable "postgres_admin_password" {
  description = "PostgreSQL administrator password."
  type        = string
  sensitive   = true
}

# JWT signing secret for the backend — sensitive TFC workspace variable.
variable "jwt_secret" {
  description = "JWT signing secret injected into the web app."
  type        = string
  sensitive   = true
}

# Storage account configuration (non-secret), from terraform.tfvars.
variable "storage" {
  description = "Storage account configuration object."
  type = object({
    account_name     = string
    account_tier     = optional(string, "Standard")
    replication_type = optional(string, "LRS")
    min_tls_version  = optional(string, "TLS1_2")
    containers       = optional(list(string), ["inspection-images", "generated-pdfs"])
  })
}
