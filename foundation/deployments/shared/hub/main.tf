module "resource_group" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//resource-group?ref=v0.5.0"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.tags
}

module "hub" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//hub-networking?ref=v0.5.0"
  vnet_name           = local.vnet_name
  resource_group_name = module.resource_group.resource_group_name
  vnet_address_space  = var.hub_address_space
  location            = var.location
  subnets             = var.hub_subnets
  tags                = local.tags
}

# Private DNS zones for the private endpoints created in the spokes. Hosted
# centrally in the hub and linked to the hub VNet here; each spoke links itself
# to these zones from its own stack. ACR and App Service stay public in this
# design, so no zones are needed for them.
module "private_dns" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//private-dns?ref=v0.5.0"
  resource_group_name = module.resource_group.resource_group_name
  zone_names = [
    "privatelink.vaultcore.azure.net",
    "privatelink.blob.core.windows.net",
  ]
  vnet_links = {
    hub = module.hub.vnet_id
  }
  tags = local.tags
}
