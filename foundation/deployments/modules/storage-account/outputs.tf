output "account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account."
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "container_names" {
  description = "Names of the created blob containers."
  value       = [for c in azurerm_storage_container.this : c.name]
}
