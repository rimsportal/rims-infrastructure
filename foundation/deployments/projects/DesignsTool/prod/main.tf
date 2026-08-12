data "azurerm_client_config" "current" {}

module "resource_group" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//resource-group?ref=v0.3.0"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.tags
}

module "postgres" {
  source                 = "git::https://github.com/rimsportal/rims-infra-core-modules.git//postgresql-flexible-server?ref=v0.3.0"
  location               = var.location
  resource_group_name    = module.resource_group.resource_group_name
  tags                   = local.tags
  postgres               = var.postgres
  administrator_password = var.postgres_admin_password
}

module "storage" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//storage-account?ref=v0.3.0"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.tags
  storage             = var.storage
}

module "key_vault" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//key-vault?ref=v0.3.0"
  key_vault_name      = local.key_vault_name
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.tags

  # DB name, DB password, and full connection string stored securely in Key Vault
  secrets = {
    "db-name"      = module.postgres.database_name
    "db-password"  = var.postgres_admin_password
    "database-url" = "postgresql://${var.postgres.administrator_login}:${var.postgres_admin_password}@${module.postgres.fqdn}:5432/${module.postgres.database_name}?sslmode=require"
  }
}

module "app_service" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//app-service?ref=v0.3.0"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.tags

  # Non-secret configuration comes in as a single object from terraform.tfvars.
  app_service = var.app_service

  # Secret settings: DB credentials and connection string use Key Vault references
  # (@Microsoft.KeyVault(SecretUri=...)), resolved transparently at runtime by App Service
  # via its System-Assigned Managed Identity.
  extra_app_settings = merge(
    var.secret_app_settings,
    {
      DB_NAME                         = "@Microsoft.KeyVault(SecretUri=${module.key_vault.secret_versionless_ids["db-name"]})"
      DB_PASSWORD                     = "@Microsoft.KeyVault(SecretUri=${module.key_vault.secret_versionless_ids["db-password"]})"
      DATABASE_URL                    = "@Microsoft.KeyVault(SecretUri=${module.key_vault.secret_versionless_ids["database-url"]})"
      JWT_SECRET                      = var.jwt_secret
      AZURE_STORAGE_CONNECTION_STRING = module.storage.primary_connection_string
    }
  )
}

# Grant the web app's System-Assigned Managed Identity permission to read Key Vault secrets
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.app_service.principal_id
}

