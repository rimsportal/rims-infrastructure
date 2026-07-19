variable "vnet_name" {
  description = "Name of the spoke virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy spoke resources into"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the spoke VNet — from IP plan"
  type        = list(string)
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "Map of subnet name to CIDR"
  type = map(object({
    cidr = string
  }))
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet — from hub remote state"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet — from hub remote state"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group of the hub VNet — needed to create hub-side peering"
  type        = string
}