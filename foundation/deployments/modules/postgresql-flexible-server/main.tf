resource "azurerm_postgresql_flexible_server" "this" {
  name                          = var.postgres.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgres.postgres_version
  administrator_login           = var.postgres.administrator_login
  administrator_password        = var.administrator_password
  sku_name                      = var.postgres.sku_name
  storage_mb                    = var.postgres.storage_mb
  zone                          = var.postgres.zone
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.postgres.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Allow other Azure services (e.g. the App Service) to reach the server.
# The 0.0.0.0 start/end is the Azure convention for "allow Azure services".
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  count            = var.postgres.allow_azure_services ? 1 : 0
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Optional: allow a single client IP (e.g. your workstation) for db:init/seed.
resource "azurerm_postgresql_flexible_server_firewall_rule" "client_ip" {
  count            = var.postgres.client_ip != "" ? 1 : 0
  name             = "allow-client-ip"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = var.postgres.client_ip
  end_ip_address   = var.postgres.client_ip
}
