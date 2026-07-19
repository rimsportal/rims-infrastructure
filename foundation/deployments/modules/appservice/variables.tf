variable "location" {}
variable "resource_group_name" {}
variable "app_service_plan_name" {}
variable "appservice_name" {}

variable "os_type" {
  default = "Linux"
}

variable "sku_name" {
  default = "B1"
}

variable "always_on" {
  default = true
}

variable "ftps_state" {
  default = "Disabled"
}

variable "health_check_path" {
  default = "/api/health"
}

variable "scm_type" {
  default = "LocalGit"
}

variable "node_version" {
  default = "20-lts"
}

variable "app_command_line" {
  default = "node src/server.js"
}

variable "website_node_default_version" {
  default = "~20"
}

variable "scm_do_build_during_deployment" {
  default = "true"
}

variable "port" {
  default = "8080"
}

variable "node_env" {
  default = "production"
}

variable "database_url" {
  sensitive = true
}

variable "jwt_secret" {
  sensitive = true
}

variable "jwt_expires_in" {
  default = "12h"
}

variable "jwt_issuer" {
  default = "rims-auth"
}

variable "storage_connection_string" {
  sensitive = true
}

variable "images_container" {
  default = "inspection-images"
}

variable "pdfs_container" {
  default = "generated-pdfs"
}

variable "tags" {
  type = map(string)
}