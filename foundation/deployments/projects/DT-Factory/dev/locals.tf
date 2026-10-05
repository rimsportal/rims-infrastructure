locals {
  resource_group_name = "rg-dt-factory-${var.environment_short_name}"

  tags = {
    Brand       = var.brand
    Environment = var.environment
    Project     = var.project
    ManagedBy   = var.managed_by
  }
}
