variable "location" {
  description = "Azure region for the PostgreSQL flexible server."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will hold the server."
  type        = string
}

variable "tags" {
  description = "Tags applied to the server."
  type        = map(string)
  default     = {}
}

# PostgreSQL configuration supplied as one object from terraform.tfvars.
variable "postgres" {
  description = "PostgreSQL Flexible Server configuration."
  type = object({
    server_name          = string # globally unique, lowercase
    database_name        = string
    administrator_login  = string
    sku_name             = optional(string, "B_Standard_B1ms")
    storage_mb           = optional(number, 32768)
    postgres_version     = optional(string, "16")
    zone                 = optional(string, "1")
    allow_azure_services = optional(bool, true) # firewall rule for Azure-hosted services
    client_ip            = optional(string, "") # optional single IP allowed through the firewall
  })
}

# Administrator password — pass from a sensitive Terraform Cloud workspace
# variable, never from terraform.tfvars.
variable "administrator_password" {
  description = "PostgreSQL administrator password."
  type        = string
  sensitive   = true
}
