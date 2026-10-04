output "deployment_report" {
  description = "Summary of the deployed DT Factory infrastructure."
  value       = module.factory.deployment_report
}

output "web_managed_identity_principal_id" {
  description = "Principal ID of the web application's managed identity."
  value       = module.factory.web_managed_identity_principal_id
}

output "api_managed_identity_principal_id" {
  description = "Principal ID of the API application's managed identity."
  value       = module.factory.api_managed_identity_principal_id
}
