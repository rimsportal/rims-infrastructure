# Private endpoints for Key Vault and Storage, placed in the dev spoke's
# privatelink subnet and registered in the hub-hosted private DNS zones.
# (Postgres goes private via VNet injection in Phase 2; ACR stays public.)

module "kv_private_endpoint" {
  source                         = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-endpoint?ref=v0.5.0"
  name                           = "${local.key_vault_name}-pe"
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  subnet_id                      = module.spoke.subnet_ids["snet-privatelink"]
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
  subnet_id                      = module.spoke.subnet_ids["snet-privatelink"]
  private_connection_resource_id = module.storage.storage_account_id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.blob.core.windows.net"]]
  tags                           = local.tags
}
