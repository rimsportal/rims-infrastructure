variable "resource_group_name" {
  description = "Resource group to deploy identity resources into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "uami_name" {
  description = "Name of the User Assigned Managed Identity"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault — globally unique, max 24 chars"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID — required for Key Vault"
  type        = string
}

variable "pe_subnet_id" {
  description = "Subnet ID for Key Vault private endpoint — use snet-pe from spoke state"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID — for private DNS zone VNet link"
  type        = string
}

variable "soft_delete_retention_days" {
  description = "Key Vault soft delete retention in days — minimum 7"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}