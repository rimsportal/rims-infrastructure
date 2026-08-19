variable "location" {
  description = "Azure region for the hub."
  type        = string
}

variable "location_short_name" {
  description = "Short location name used in resource naming."
  type        = string
}

variable "brand" {
  description = "Brand name."
  type        = string
}

variable "brand_short_name" {
  description = "Short brand name used in resource naming."
  type        = string
}

variable "managed_by" {
  description = "Tool managing these resources."
  type        = string
  default     = "Terraform"
}

variable "hub_address_space" {
  description = "Address space for the hub VNet."
  type        = list(string)
}

variable "hub_subnets" {
  description = "Map of hub subnet name to CIDR."
  type = map(object({
    cidr = string
  }))
}
