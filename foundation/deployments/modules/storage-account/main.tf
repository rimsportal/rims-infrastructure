resource "azurerm_storage_account" "this" {
  name                     = var.storage.account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage.account_tier
  account_replication_type = var.storage.replication_type
  min_tls_version          = var.storage.min_tls_version
  tags                     = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each              = toset(var.storage.containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}
