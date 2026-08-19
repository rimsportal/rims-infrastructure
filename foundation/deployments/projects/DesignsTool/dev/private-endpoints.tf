# Private endpoints for Key Vault and Storage, placed in the dev spoke's
# privatelink subnet and registered in the hub-hosted private DNS zones.

module "kv_private_endpoint" {
  source                         = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-endpoint?ref=v0.5.0"
  name                           = "${local.key_vault_name}-pe"
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  subnet_id                      = module.spoke.subnet_ids["snet-pe-keyvault"]
  private_connection_resource_id = module.key_vault.key_vault_id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.vaultcore.azure.net"]]
  tags                           = local.tags
}

module "storage_private_endpoint" {
  source                         = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-endpoint?ref=v0.5.0"
  name                           = "${var.storage.account_name}-blob-pe"
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  subnet_id                      = module.spoke.subnet_ids["snet-pe-storage"]
  private_connection_resource_id = module.storage.storage_account_id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.blob.core.windows.net"]]
  tags                           = local.tags
}

module "app_service_private_endpoint" {
  source                         = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-endpoint?ref=v0.5.0"
  name                           = "${var.app_service.app_name}-pe"
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  subnet_id                      = module.spoke.subnet_ids["snet-pe-appservice"]
  private_connection_resource_id = module.app_service.app_service_id
  subresource_names              = ["sites"]
  private_dns_zone_ids           = [data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.azurewebsites.net"]]
  tags                           = local.tags
}

module "postgres_private_endpoint" {
  source                         = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-endpoint?ref=v0.5.0"
  name                           = "${var.postgres.server_name}-pe"
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  subnet_id                      = module.spoke.subnet_ids["snet-postgres"]
  private_connection_resource_id = module.postgres.server_id
  subresource_names              = ["postgresqlServer"]
  private_dns_zone_ids           = [data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.postgres.database.azure.com"]]
  tags                           = local.tags
}
