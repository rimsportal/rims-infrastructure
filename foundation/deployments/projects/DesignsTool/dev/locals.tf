locals {
  resource_group_name = "${var.brand_short_name}-${var.project_short_name}-${var.environment_short_name}-${var.location_short_name}-rg"

  tags = {
    Brand       = var.brand
    Environment = var.environment
    Project     = var.project
    ManagedBy   = var.managed_by
  }
}
