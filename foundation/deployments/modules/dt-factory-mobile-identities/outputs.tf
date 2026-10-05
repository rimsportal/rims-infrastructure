output "supervisor_client_id" {
  description = "Client ID of the Supervisor mobile application registration."
  value       = azuread_application.mobile["supervisor"].client_id
}

output "worker_client_id" {
  description = "Client ID of the Worker mobile application registration."
  value       = azuread_application.mobile["worker"].client_id
}

output "authentication" {
  description = "Non-secret authentication configuration for the DT Factory mobile applications."
  value = {
    tenant_id            = data.azuread_client_config.current.tenant_id
    authority            = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}"
    api_audience         = "api://${var.api_client_id}"
    api_scope            = "api://${var.api_client_id}/access_as_user"
    public_redirect_uris = sort(tolist(var.public_redirect_uris))
    supervisor_client_id = azuread_application.mobile["supervisor"].client_id
    worker_client_id     = azuread_application.mobile["worker"].client_id
  }
}
