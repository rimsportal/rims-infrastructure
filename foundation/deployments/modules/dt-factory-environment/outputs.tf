output "deployment_report" {
  value = {
    subscription_id         = data.azurerm_client_config.current.subscription_id
    resource_group          = module.resource_group.resource_group_name
    region                  = var.location
    vnet                    = module.network.vnet_name
    app_integration_subnet  = module.network.subnet_ids["snet-app-integration"]
    private_endpoint_subnet = module.network.subnet_ids["snet-private-endpoints"]
    future_subnet           = module.network.subnet_ids["snet-future-integration"]
    web_app                 = module.web_app.app_service_name
    web_url                 = "https://${module.web_app.default_hostname}"
    api_app                 = module.api_app.app_service_name
    api_url                 = "https://${module.api_app.default_hostname}"
    app_service_plan        = module.web_app.service_plan_id
    postgres_server         = module.postgresql.server_name
    postgres_fqdn           = module.postgresql.fqdn
    postgres_database       = module.postgresql.database_name
    storage_account         = module.storage.account_name
    blob_endpoint           = module.storage.primary_blob_endpoint
    key_vault               = module.key_vault.key_vault_name
    key_vault_uri           = module.key_vault.vault_uri
    application_insights    = module.monitoring.application_insights_name
    log_analytics           = module.monitoring.workspace_name
    private_endpoints = {
      postgresql = module.postgres_private_endpoint.private_ip_address
      key_vault  = module.key_vault_private_endpoint.private_ip_address
      blob       = module.storage_private_endpoint.private_ip_address
    }
    private_dns_zones = keys(module.private_dns.zone_names)
    monitoring_alerts = concat(keys(azurerm_monitor_metric_alert.app), keys(azurerm_monitor_metric_alert.database))
  }
}

output "web_managed_identity_principal_id" { value = module.web_app.principal_id }
output "api_managed_identity_principal_id" { value = module.api_app.principal_id }
