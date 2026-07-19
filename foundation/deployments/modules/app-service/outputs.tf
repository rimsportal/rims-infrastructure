output "app_service_id" {
  description = "Resource ID of the Linux web app."
  value       = azurerm_linux_web_app.this.id
}

output "app_service_name" {
  description = "Name of the Linux web app."
  value       = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  description = "Default hostname of the web app (e.g. app.azurewebsites.net)."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "service_plan_id" {
  description = "Resource ID of the App Service Plan."
  value       = azurerm_service_plan.this.id
}
