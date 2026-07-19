resource "azurerm_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type  = var.os_type
  sku_name = var.sku_name

  tags = var.tags
}

resource "azurerm_linux_web_app" "linux_web_app" {
  name                = var.appservice_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {

    always_on         = var.always_on
    ftps_state        = var.ftps_state
    health_check_path = var.health_check_path
    scm_type          = var.scm_type

    application_stack {
      node_version = var.node_version
    }

    app_command_line = var.app_command_line
  }

  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION   = var.website_node_default_version
    SCM_DO_BUILD_DURING_DEPLOYMENT = var.scm_do_build_during_deployment
    PORT                           = var.port
    NODE_ENV                       = var.node_env

    DATABASE_URL   = var.database_url
    JWT_SECRET     = var.jwt_secret
    JWT_EXPIRES_IN = var.jwt_expires_in
    JWT_ISSUER     = var.jwt_issuer

    AZURE_STORAGE_CONNECTION_STRING = var.storage_connection_string
    AZURE_IMAGES_CONTAINER          = var.images_container
    AZURE_PDFS_CONTAINER            = var.pdfs_container
  }

  tags = var.tags
}