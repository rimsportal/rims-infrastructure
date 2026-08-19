output "hub_vnet_id" {
  description = "Resource ID of the hub VNet."
  value       = module.hub.vnet_id
}

output "hub_vnet_name" {
  description = "Name of the hub VNet."
  value       = module.hub.vnet_name
}

output "hub_resource_group_name" {
  description = "Resource group holding the hub VNet and private DNS zones."
  value       = module.resource_group.resource_group_name
}

output "hub_subnet_ids" {
  description = "Map of hub subnet name to ID."
  value       = module.hub.subnet_ids
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone name to zone ID."
  value       = module.private_dns.zone_ids
}

output "private_dns_zone_names" {
  description = "Map of private DNS zone name to zone name."
  value       = module.private_dns.zone_names
}
