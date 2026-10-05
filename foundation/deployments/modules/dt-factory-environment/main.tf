terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  prefix = "dt-factory-${var.environment}"
  tags = {
    Application = "DTFactory"
    Environment = title(var.environment)
    Owner       = "DesignsTool"
    ManagedBy   = "Terraform"
    CostCenter  = "FactoryOperations"
  }
  containers = toset([
    "drawings",
    "project-documents",
    "qc-images",
    "production-evidence",
    "handover-evidence",
    "dispatch-documents",
    "reports",
    "temporary-uploads"
  ])
}

data "azurerm_client_config" "current" {}

resource "random_password" "postgres" {
  length           = 32
  special          = true
  override_special = "!#%*-_=+"
}

module "resource_group" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//resource-group?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  resource_group_name = "rg-${local.prefix}"
  location            = var.location
  tags                = local.tags
}

module "network" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//spoke-networking?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  vnet_name           = "vnet-${local.prefix}"
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  vnet_address_space  = var.vnet_address_space
  subnets = {
    "snet-app-integration" = {
      cidr = var.subnet_prefixes.app_integration
      delegation = {
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-private-endpoints" = {
      cidr                                      = var.subnet_prefixes.private_endpoints
      private_endpoint_network_policies_enabled = false
    }
    "snet-future-integration" = { cidr = var.subnet_prefixes.future_integration }
  }
  tags = local.tags
}

module "private_dns" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-dns?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  resource_group_name = module.resource_group.resource_group_name
  zone_names = [
    "privatelink.postgres.database.azure.com",
    "privatelink.vaultcore.azure.net",
    "privatelink.blob.core.windows.net"
  ]
  vnet_links = { "${local.prefix}-link" = module.network.vnet_id }
  tags       = local.tags
}

module "key_vault" {
  source                        = "git::https://github.com/rimsportal/rims-infra-core-modules.git//key-vault?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  key_vault_name                = "kv-dtf-${var.environment}-${var.name_suffix}"
  resource_group_name           = module.resource_group.resource_group_name
  location                      = var.location
  tenant_id                     = var.entra_tenant_id
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 14
  public_network_access_enabled = var.key_vault_public_network_access_enabled
  secrets = {
    postgres-admin-username = "dtfactoryadmin"
    postgres-admin-password = random_password.postgres.result
    web-entra-client-secret = var.web_entra_client_secret
  }
  tags = local.tags
}

module "storage" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//storage-account?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  storage = {
    account_name                    = "dtf${var.environment}${var.name_suffix}"
    containers                      = local.containers
    public_network_access_enabled   = var.storage_public_network_access_enabled
    shared_access_key_enabled       = false
    versioning_enabled              = true
    delete_retention_days           = 14
    container_delete_retention_days = 14
  }
  tags = local.tags
}

module "postgresql" {
  source                 = "git::https://github.com/rimsportal/rims-infra-core-modules.git//postgresql-flexible-server?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  resource_group_name    = module.resource_group.resource_group_name
  location               = var.location
  administrator_password = random_password.postgres.result
  postgres = {
    server_name                   = "psql-${local.prefix}-${var.name_suffix}"
    database_name                 = "dt_factory_${var.environment}"
    administrator_login           = "dtfactoryadmin"
    sku_name                      = var.postgres_sku_name
    storage_mb                    = var.postgres_storage_mb
    backup_retention_days         = var.postgres_backup_retention_days
    high_availability_enabled     = var.postgres_high_availability_enabled
    zone                          = "1"
    public_network_access_enabled = false
    allow_azure_services          = false
  }
  tags = local.tags
}

module "key_vault_private_endpoint" {
  source                         = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-endpoint?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  name                           = "pe-${module.key_vault.key_vault_name}"
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  subnet_id                      = module.network.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = module.key_vault.key_vault_id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [module.private_dns.zone_ids["privatelink.vaultcore.azure.net"]]
  tags                           = local.tags
}

module "storage_private_endpoint" {
  source                         = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-endpoint?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  name                           = "pe-${module.storage.account_name}-blob"
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  subnet_id                      = module.network.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = module.storage.storage_account_id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [module.private_dns.zone_ids["privatelink.blob.core.windows.net"]]
  tags                           = local.tags
}

module "postgres_private_endpoint" {
  source                         = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-endpoint?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  name                           = "pe-${module.postgresql.server_name}"
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  subnet_id                      = module.network.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = module.postgresql.server_id
  subresource_names              = ["postgresqlServer"]
  private_dns_zone_ids           = [module.private_dns.zone_ids["privatelink.postgres.database.azure.com"]]
  tags                           = local.tags

  depends_on = [module.postgresql]
}

module "monitoring" {
  source                    = "git::https://github.com/rimsportal/rims-infra-core-modules.git//monitoring?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  workspace_name            = "log-${local.prefix}"
  application_insights_name = "appi-${local.prefix}"
  resource_group_name       = module.resource_group.resource_group_name
  location                  = var.location
  retention_days            = var.log_retention_days
  tags                      = local.tags
}

module "web_app" {
  source                = "git::https://github.com/rimsportal/rims-infra-core-modules.git//app-service?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  resource_group_name   = module.resource_group.resource_group_name
  location              = var.location
  integration_subnet_id = module.network.subnet_ids["snet-app-integration"]
  app_service = {
    app_name          = "${local.prefix}-web-${var.name_suffix}"
    service_plan_name = "asp-${local.prefix}"
    sku_name          = var.app_service_plan_sku
    always_on         = var.environment == "prod"
    health_check_path = "/health"
    app_settings = {
      APPLICATIONINSIGHTS_CONNECTION_STRING      = module.monitoring.connection_string
      ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
      API_BASE_URL                               = "https://${local.prefix}-api-${var.name_suffix}.azurewebsites.net"
      MICROSOFT_PROVIDER_AUTHENTICATION_SECRET   = "@Microsoft.KeyVault(SecretUri=${module.key_vault.vault_uri}secrets/web-entra-client-secret/)"
    }
  }
  auth_settings = {
    client_id                  = var.web_entra_client_id
    tenant_id                  = var.entra_tenant_id
    client_secret_setting_name = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
    allowed_audiences          = ["api://${var.web_entra_client_id}"]
    unauthenticated_action     = "RedirectToLoginPage"
  }
  tags = local.tags
}

module "api_app" {
  source                = "git::https://github.com/rimsportal/rims-infra-core-modules.git//app-service?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  resource_group_name   = module.resource_group.resource_group_name
  location              = var.location
  service_plan_id       = module.web_app.service_plan_id
  create_service_plan   = false
  integration_subnet_id = module.network.subnet_ids["snet-app-integration"]
  app_service = {
    app_name          = "${local.prefix}-api-${var.name_suffix}"
    service_plan_name = "asp-${local.prefix}"
    sku_name          = var.app_service_plan_sku
    always_on         = var.environment == "prod"
    health_check_path = "/health"
    app_settings = {
      APPLICATIONINSIGHTS_CONNECTION_STRING      = module.monitoring.connection_string
      ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
      AZURE_KEY_VAULT_URI                        = module.key_vault.vault_uri
      AZURE_STORAGE_ACCOUNT_NAME                 = module.storage.account_name
      DB_HOST                                    = module.postgresql.fqdn
      DB_PORT                                    = "5432"
      DB_NAME                                    = module.postgresql.database_name
      DB_USER                                    = "@Microsoft.KeyVault(SecretUri=${module.key_vault.vault_uri}secrets/postgres-admin-username/)"
      DB_PASSWORD                                = "@Microsoft.KeyVault(SecretUri=${module.key_vault.vault_uri}secrets/postgres-admin-password/)"
      DB_SSL_MODE                                = "require"
      RATE_LIMIT_ENABLED                         = "true"
      RATE_LIMIT_WINDOW_S                        = "60"
      RATE_LIMIT_MAX                             = "120"
      WEBSITES_CONTAINER_START_TIME_LIMIT        = "600"
    }
  }
  auth_settings = {
    client_id              = var.api_entra_client_id
    tenant_id              = var.entra_tenant_id
    allowed_audiences      = ["api://${var.api_entra_client_id}"]
    unauthenticated_action = "Return401"
  }
  cors = {
    allowed_origins = ["https://${local.prefix}-web-${var.name_suffix}.azurewebsites.net"]
  }
  tags = merge(local.tags, {
    "hidden-link: /app-insights-resource-id" = replace(module.monitoring.application_insights_id, "Microsoft.Insights", "microsoft.insights")
  })
}

resource "azurerm_role_assignment" "api_key_vault_secrets_user" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.api_app.principal_id
}

resource "azurerm_role_assignment" "api_blob_contributor" {
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.api_app.principal_id
}

resource "azurerm_role_assignment" "web_blob_reader" {
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.web_app.principal_id
}

locals {
  diagnostic_targets = {
    web          = module.web_app.app_service_id
    api          = module.api_app.app_service_id
    postgresql   = module.postgresql.server_id
    key_vault    = module.key_vault.key_vault_id
    storage_blob = "${module.storage.storage_account_id}/blobServices/default"
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                   = local.diagnostic_targets
  name                       = "diag-${each.key}"
  target_resource_id         = each.value
  log_analytics_workspace_id = module.monitoring.workspace_id

  enabled_log { category_group = "allLogs" }

  dynamic "enabled_metric" {
    for_each = each.key == "storage_blob" ? toset(["Capacity", "Transaction"]) : toset(["AllMetrics"])
    content { category = enabled_metric.value }
  }
}

resource "azurerm_monitor_action_group" "operations" {
  name                = "ag-${local.prefix}-operations"
  resource_group_name = module.resource_group.resource_group_name
  short_name          = substr("dtf${var.environment}ops", 0, 12)
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = var.alert_emails
    content {
      name                    = replace(email_receiver.value, "@", "-")
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

locals {
  app_alerts = {
    web_unavailable = { scope = module.web_app.app_service_id, metric = "HealthCheckStatus", aggregation = "Average", operator = "LessThan", threshold = 1, severity = 1 }
    api_unavailable = { scope = module.api_app.app_service_id, metric = "HealthCheckStatus", aggregation = "Average", operator = "LessThan", threshold = 1, severity = 1 }
    api_5xx         = { scope = module.api_app.app_service_id, metric = "Http5xx", aggregation = "Total", operator = "GreaterThan", threshold = 10, severity = 2 }
    api_response    = { scope = module.api_app.app_service_id, metric = "HttpResponseTime", aggregation = "Average", operator = "GreaterThan", threshold = 5, severity = 2 }
  }
  database_alerts = {
    db_cpu         = { metric = "cpu_percent", aggregation = "Average", operator = "GreaterThan", threshold = 80, severity = 2 }
    db_storage     = { metric = "storage_percent", aggregation = "Average", operator = "GreaterThan", threshold = 80, severity = 2 }
    db_connections = { metric = "active_connections", aggregation = "Average", operator = "GreaterThan", threshold = 80, severity = 2 }
  }
}

resource "azurerm_monitor_metric_alert" "app" {
  for_each            = local.app_alerts
  name                = "alert-${local.prefix}-${replace(each.key, "_", "-")}"
  resource_group_name = module.resource_group.resource_group_name
  scopes              = [each.value.scope]
  description         = "DT Factory ${var.environment}: ${replace(each.key, "_", " ")}"
  severity            = each.value.severity
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = each.value.metric
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }
  action { action_group_id = azurerm_monitor_action_group.operations.id }
}

resource "azurerm_monitor_metric_alert" "database" {
  for_each            = local.database_alerts
  name                = "alert-${local.prefix}-${replace(each.key, "_", "-")}"
  resource_group_name = module.resource_group.resource_group_name
  scopes              = [module.postgresql.server_id]
  description         = "DT Factory ${var.environment}: ${replace(each.key, "_", " ")}"
  severity            = each.value.severity
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = each.value.metric
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }
  action { action_group_id = azurerm_monitor_action_group.operations.id }
}

module "budget" {
  source            = "git::https://github.com/rimsportal/rims-infra-core-modules.git//budget?ref=dba214375c44ae5f4ed9ddb94f7c1b9d58e30611"
  name              = "budget-${local.prefix}"
  resource_group_id = module.resource_group.resource_group_id
  amount            = var.budget_amount
  start_date        = var.budget_start_date
  contact_emails    = var.alert_emails
}
