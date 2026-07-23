data "azurerm_client_config" "current" {}

module "resource_group" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//resource-group?ref=v0.1.0"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.tags
}

module "postgres" {
  source                 = "git::https://github.com/rimsportal/rims-infra-core-modules.git//postgresql-flexible-server?ref=v0.1.0"
  location               = var.location
  resource_group_name    = module.resource_group.resource_group_name
  tags                   = local.tags
  postgres               = var.postgres
  administrator_password = var.postgres_admin_password
}

module "storage" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//storage-account?ref=v0.1.0"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.tags
  storage             = var.storage
}

module "app_service" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//app-service?ref=v0.1.0"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.tags

  # Non-secret configuration comes in as a single object from terraform.tfvars.
  app_service = var.app_service

  # Secret settings: the DB connection string and storage connection string are
  # composed from module outputs + sensitive TFC variables, then merged into the
  # web app's app_settings by the module.
  extra_app_settings = merge(
    var.secret_app_settings,
    {
      DATABASE_URL                    = "postgresql://${var.postgres.administrator_login}:${var.postgres_admin_password}@${module.postgres.fqdn}:5432/${module.postgres.database_name}?sslmode=require"
      JWT_SECRET                      = var.jwt_secret
      AZURE_STORAGE_CONNECTION_STRING = module.storage.primary_connection_string
    }
  )
}
