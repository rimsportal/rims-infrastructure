output "resource_group_id" {
  description = "ID of the environment resource group."
  value       = module.resource_group.resource_group_id
}

output "resource_group_name" {
  description = "Name of the environment resource group."
  value       = module.resource_group.resource_group_name
}

output "app_service_name" {
  description = "Name of the deployed Linux web app."
  value       = module.app_service.app_service_name
}

output "app_service_default_hostname" {
  description = "Default hostname of the deployed web app."
  value       = module.app_service.default_hostname
}

output "postgres_fqdn" {
  description = "FQDN of the PostgreSQL flexible server."
  value       = module.postgres.fqdn
}

output "postgres_database_name" {
  description = "Application database name."
  value       = module.postgres.database_name
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = module.storage.account_name
}

output "storage_blob_endpoint" {
  description = "Primary blob endpoint."
  value       = module.storage.primary_blob_endpoint
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry."
  value       = module.container_registry.name
}

output "container_registry_login_server" {
  description = "Login server for the Azure Container Registry (docker push/pull target)."
  value       = module.container_registry.login_server
}

output "key_vault_name" {
  description = "Name of the deployed Key Vault."
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the deployed Key Vault."
  value       = module.key_vault.vault_uri
}

# ----- Networking (Phase 1) -----

output "spoke_vnet_id" {
  description = "Resource ID of the dev spoke VNet."
  value       = module.spoke.vnet_id
}

output "spoke_subnet_ids" {
  description = "Map of dev spoke subnet name to ID."
  value       = module.spoke.subnet_ids
}

output "key_vault_private_endpoint_ip" {
  description = "Private IP of the Key Vault private endpoint."
  value       = module.kv_private_endpoint.private_ip_address
}

output "storage_private_endpoint_ip" {
  description = "Private IP of the Storage (blob) private endpoint."
  value       = module.storage_private_endpoint.private_ip_address
}
