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
