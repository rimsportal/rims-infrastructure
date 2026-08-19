locals {
  resource_group_name = "${var.brand_short_name}-qa-hub-${var.location_short_name}-rg"
  vnet_name           = "${var.brand_short_name}-qa-hub-${var.location_short_name}-vnet"

  tags = {
    Brand       = var.brand
    Environment = "QA"
    Scope       = "Hub"
    ManagedBy   = var.managed_by
  }
}
