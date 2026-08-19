# Dev spoke network + hub wiring (Phase 1).
# Public network access on Key Vault / Storage / Postgres stays ON in this phase
# so GitHub-hosted runners keep working; lock-down happens in Phase 2.

data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-rims-tfstate-dev"
    storage_account_name = "rimstfstatedev"
    container_name       = "tfstate-hub"
    key                  = "shared/hub.terraform.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}

module "spoke" {
  source              = "git::https://github.com/rimsportal/rims-infra-core-modules.git//spoke-networking?ref=v0.5.0"
  vnet_name           = "${var.brand_short_name}-${var.project_short_name}-${var.environment_short_name}-${var.location_short_name}-vnet"
  resource_group_name = module.resource_group.resource_group_name
  vnet_address_space  = var.spoke_address_space
  location            = var.location
  tags                = local.tags
  subnets             = var.spoke_subnets

  hub_vnet_id             = data.terraform_remote_state.hub.outputs.hub_vnet_id
  hub_vnet_name           = data.terraform_remote_state.hub.outputs.hub_vnet_name
  hub_resource_group_name = data.terraform_remote_state.hub.outputs.hub_resource_group_name
}

# Link the hub-hosted private DNS zones to the dev spoke so the app resolves the
# Key Vault / Storage private endpoints to their private IPs from inside the VNet.
resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "${var.environment_short_name}-spoke"
  resource_group_name   = data.terraform_remote_state.hub.outputs.hub_resource_group_name
  private_dns_zone_name = data.terraform_remote_state.hub.outputs.private_dns_zone_names["privatelink.vaultcore.azure.net"]
  virtual_network_id    = module.spoke.vnet_id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "${var.environment_short_name}-spoke"
  resource_group_name   = data.terraform_remote_state.hub.outputs.hub_resource_group_name
  private_dns_zone_name = data.terraform_remote_state.hub.outputs.private_dns_zone_names["privatelink.blob.core.windows.net"]
  virtual_network_id    = module.spoke.vnet_id
  registration_enabled  = false
  tags                  = local.tags
}
