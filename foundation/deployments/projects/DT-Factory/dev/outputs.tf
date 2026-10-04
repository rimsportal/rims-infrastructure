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

output "supervisor_mobile_client_id" {
  description = "Microsoft Entra client ID used by the Supervisor mobile application."
  value       = module.mobile_identities.supervisor_client_id
}

output "worker_mobile_client_id" {
  description = "Microsoft Entra client ID used by the Worker mobile application."
  value       = module.mobile_identities.worker_client_id
}

output "mobile_authentication" {
  description = "Non-secret authentication settings consumed by both mobile applications."
  value       = module.mobile_identities.authentication
}
