location               = "centralindia"
brand                  = "RIMS"
environment            = "Production"
project                = "Designstool"
managed_by             = "Terraform"
brand_short_name       = "rims"
environment_short_name = "prod"
project_short_name     = "dtool"
location_short_name    = "cin"

# App Service configuration passed to the app-service module as one object.
# NON-SECRET values only. Put secrets (DATABASE_URL, JWT_SECRET, storage
# connection string) in the sensitive `secret_app_settings` Terraform Cloud
# workspace variable instead.
app_service = {
  app_name          = "rims-designstool-prod-api"
  service_plan_name = "rims-designstool-prod-plan"
  sku_name          = "B1"
  node_version      = "20-lts"
  always_on         = true
  https_only        = true
  ftps_state        = "Disabled"
  health_check_path = "/api/health"
  app_command_line  = "node src/server.js"

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION"   = "~20"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "PORT"                           = "8080"
    "NODE_ENV"                       = "production"
    "JWT_EXPIRES_IN"                 = "12h"
    "JWT_ISSUER"                     = "rims-auth"
    "AZURE_IMAGES_CONTAINER"         = "inspection-images"
    "AZURE_PDFS_CONTAINER"           = "generated-pdfs"
  }
}

# PostgreSQL Flexible Server (managed). NON-SECRET values only — the admin
# password goes in the sensitive `postgres_admin_password` TFC variable.
# Set `client_ip` to your workstation's public IP so you can run db:init/seed.
postgres = {
  server_name          = "rims-designstool-prod-pg"
  database_name        = "rims"
  administrator_login  = "rimsadmin"
  sku_name             = "B_Standard_B1ms"
  storage_mb           = 32768
  postgres_version     = "16"
  zone                 = "1"
  allow_azure_services = true
  client_ip            = ""
}

# Azure Storage account for inspection images and generated PDFs.
# account_name must be globally unique, 3-24 lowercase alphanumeric chars.
storage = {
  account_name     = "rimsdtoolprodsa"
  account_tier     = "Standard"
  replication_type = "LRS"
  min_tls_version  = "TLS1_2"
  containers       = ["inspection-images", "generated-pdfs"]
}
