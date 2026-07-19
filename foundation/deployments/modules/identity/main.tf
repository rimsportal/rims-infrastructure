# ─────────────────────────────────────────────────────────────────────────────
# User Assigned Managed Identity
# Scoped to resource group — never subscription level
# ─────────────────────────────────────────────────────────────────────────────
resource "azurerm_user_assigned_identity" "uami" {
  name                = var.uami_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}


# ─────────────────────────────────────────────────────────────────────────────
# Key Vault
# RBAC mode — no access policies
# Public access disabled — private endpoint only
# Purge protection — prevents accidental permanent deletion
# Test
# ─────────────────────────────────────────────────────────────────────────────
resource "azurerm_key_vault" "kv" {
  name                          = var.key_vault_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = false
  tags                          = var.tags
}


# ─────────────────────────────────────────────────────────────────────────────
# Private DNS Zone
# One zone per workload environment
# Links to spoke VNet so DNS resolves internally
# ─────────────────────────────────────────────────────────────────────────────
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}