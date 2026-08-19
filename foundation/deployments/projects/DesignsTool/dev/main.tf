data "azurerm_client_config" "current" {}

module "resource_group" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//resource-group?ref=v0.5.0"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.tags
}

module "container_registry" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//container-registry?ref=v0.5.0"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.tags
  registry            = var.container_registry
}

module "postgres" {
  source                 = "git::https://github.com/rimsportal/rims-infra-core-modules.git//postgresql-flexible-server?ref=v0.5.0"
  location               = var.location
  resource_group_name    = module.resource_group.resource_group_name
  tags                   = local.tags
  postgres               = var.postgres
  administrator_password = var.postgres_admin_password
}

module "storage" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//storage-account?ref=v0.5.0"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.tags
  storage             = var.storage
}

module "key_vault" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//key-vault?ref=v0.5.0"
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

  # Grant App Service system-assigned identity access to Key Vault secrets via access policy
  reader_principal_ids = compact([module.app_service.principal_id])
}

module "app_service" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//app-service?ref=v0.5.0"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.tags

  # Non-secret configuration comes in as a single object from terraform.tfvars.
  app_service = var.app_service

  # DEV runs a container image from ACR. registry_url is taken from the registry
  # module output rather than terraform.tfvars.
  container = {
    image_name   = var.container_image.image_name
    image_tag    = var.container_image.image_tag
    registry_url = "https://${module.container_registry.login_server}"
  }

  # Regional VNet integration: outbound traffic routes into the dev spoke so the
  # app can reach the Key Vault / Storage private endpoints. Inbound stays public.
  integration_subnet_id = module.spoke.subnet_ids["snet-appsvc"]

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

# Grant the web app's system-assigned managed identity permission to pull
# images from the container registry (no registry admin credentials needed).
resource "azurerm_role_assignment" "acr_pull" {
  for_each             = toset(compact([module.app_service.principal_id]))
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}
