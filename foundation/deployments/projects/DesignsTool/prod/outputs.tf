output "resource_group_id" {
  description = "ID of the environment resource group."
  value       = module.resource_group.resource_group_id
}

output "resource_group_name" {
  description = "Name of the environment resource group."
  value       = module.resource_group.resource_group_name
}
