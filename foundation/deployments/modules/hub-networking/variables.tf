variable "vnet_name" {
  description = "The name of the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "The address space of the virtual network."
  type        = list(string)
}

variable "location" {
  description = "The Azure region where the virtual network will be created."
  type        = string
}

variable "subnets" {
  description = "Map of subnet name to CIDR"
  type = map(object({
    cidr = string
  }))
}

variable "tags" {
  description = "A map of tags to assign to the virtual network."
  type        = map(string)
  default     = {}
}