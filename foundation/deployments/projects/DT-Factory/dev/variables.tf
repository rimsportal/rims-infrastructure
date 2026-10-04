variable "location" {
  description = "Azure region used by the DT Factory resources."
  type        = string
}

variable "brand" {
  description = "Brand name used in standard resource tags."
  type        = string
}

variable "environment" {
  description = "Long environment name used in standard resource tags."
  type        = string
}

variable "project" {
  description = "Project name used in standard resource tags."
  type        = string
}

variable "managed_by" {
  description = "Management system used in standard resource tags."
  type        = string
  default     = "Terraform"
}

variable "brand_short_name" {
  description = "Short brand name reserved for repository naming conventions."
  type        = string
}

variable "environment_short_name" {
  description = "Short environment name used by the deployed resources."
  type        = string
}

variable "project_short_name" {
  description = "Short project name reserved for repository naming conventions."
  type        = string
}

variable "location_short_name" {
  description = "Short Azure region name reserved for repository naming conventions."
  type        = string
}

variable "name_suffix" {
  description = "Stable suffix for globally unique resource names."
  type        = string
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

variable "api_access_scope_id" {
  description = "ID of the access_as_user delegated permission exposed by the DT Factory API."
  type        = string
}

variable "api_entra_application_object_id" {
  description = "Object ID of the existing DT Factory API application registration."
  type        = string
}

variable "mobile_public_redirect_uris" {
  description = "Public-client redirect URIs shared by the mobile registrations until platform-specific package metadata is available."
  type        = set(string)
}

variable "alert_emails" {
  description = "Email addresses that receive budget and operational alerts."
  type        = set(string)
}

variable "budget_start_date" {
  description = "Budget start date in RFC 3339 format."
  type        = string
}
