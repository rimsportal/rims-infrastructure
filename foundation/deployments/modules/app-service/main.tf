resource "azurerm_service_plan" "this" {
  name                = var.app_service.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_service.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.app_service.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = var.app_service.https_only
  tags                = var.tags

  site_config {
    always_on         = var.app_service.always_on
    ftps_state        = var.app_service.ftps_state
    health_check_path = var.app_service.health_check_path
    app_command_line  = var.app_service.app_command_line

    application_stack {
      node_version = var.app_service.node_version
    }
  }

  # Non-secret settings from the object, merged with sensitive settings.
  app_settings = merge(var.app_service.app_settings, var.extra_app_settings)
}
