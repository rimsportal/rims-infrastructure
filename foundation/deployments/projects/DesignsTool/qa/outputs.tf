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
