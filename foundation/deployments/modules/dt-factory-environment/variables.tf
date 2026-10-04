variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "location" {
  description = "Azure region used by the DT Factory resources."
  type        = string
}

variable "name_suffix" {
  description = "Short suffix used to keep globally unique Azure resource names stable."
  type        = string
}

variable "vnet_address_space" {
  description = "Address spaces assigned to the DT Factory virtual network."
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "CIDR prefixes for the application, private endpoint, and future integration subnets."
  type = object({
    app_integration    = string
    private_endpoints  = string
    future_integration = string
  })
}

variable "app_service_plan_sku" {
  description = "SKU for the shared App Service plan."
  type        = string
}

variable "postgres_sku_name" {
  description = "Azure Database for PostgreSQL Flexible Server SKU."
  type        = string
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage allocation in megabytes."
  type        = number
}

variable "postgres_backup_retention_days" {
  description = "Number of days PostgreSQL backups are retained."
  type        = number
}

variable "postgres_high_availability_enabled" {
  description = "Whether zone-redundant PostgreSQL high availability is enabled."
  type        = bool
}

variable "log_retention_days" {
  description = "Log Analytics retention period in days."
  type        = number
}

variable "budget_amount" {
  description = "Monthly Azure budget amount for this environment."
  type        = number
}

variable "budget_start_date" {
  description = "Budget start date in RFC 3339 format."
  type        = string
}

variable "alert_emails" {
  description = "Email addresses that receive budget and operational alerts."
  type        = set(string)
}

variable "entra_tenant_id" {
  description = "Microsoft Entra tenant ID used by App Service authentication."
  type        = string
}

variable "web_entra_client_id" {
  description = "Application client ID for the DT Factory web application."
  type        = string
}

variable "web_entra_client_secret" {
  description = "Application client secret for the DT Factory web application."
  type        = string
  sensitive   = true
}

variable "api_entra_client_id" {
  description = "Application client ID for the DT Factory API."
  type        = string
}

variable "key_vault_public_network_access_enabled" {
  description = "Whether public network access remains enabled for Key Vault."
  type        = bool
}

variable "storage_public_network_access_enabled" {
  description = "Whether public network access remains enabled for the storage account."
  type        = bool
}
