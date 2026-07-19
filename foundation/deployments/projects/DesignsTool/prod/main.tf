data "azurerm_client_config" "current" {}

module "resource_group" {
  source              = "../../../modules/resource-group"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.tags
}
