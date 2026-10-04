data "azurerm_client_config" "current" {}

module "factory" {
  source = "../../../modules/dt-factory-environment"

  environment        = var.environment_short_name
  location           = var.location
  name_suffix        = var.name_suffix
  vnet_address_space = ["10.20.0.0/16"]
  subnet_prefixes = {
    app_integration    = "10.20.1.0/24"
    private_endpoints  = "10.20.2.0/24"
    future_integration = "10.20.3.0/24"
  }

  app_service_plan_sku                    = "B1"
  postgres_sku_name                       = "B_Standard_B1ms"
  postgres_storage_mb                     = 32768
  postgres_backup_retention_days          = 7
  postgres_high_availability_enabled      = false
  log_retention_days                      = 30
  budget_amount                           = 150
  budget_start_date                       = var.budget_start_date
  alert_emails                            = var.alert_emails
  entra_tenant_id                         = var.entra_tenant_id
  web_entra_client_id                     = var.web_entra_client_id
  web_entra_client_secret                 = var.web_entra_client_secret
  api_entra_client_id                     = var.api_entra_client_id
  key_vault_public_network_access_enabled = true
  storage_public_network_access_enabled   = true
}
