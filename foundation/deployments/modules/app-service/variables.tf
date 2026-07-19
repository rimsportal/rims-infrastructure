variable "location" {
  description = "Azure region for the app service."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will hold the app service and plan."
  type        = string
}

variable "tags" {
  description = "Tags applied to the app service and plan."
  type        = map(string)
  default     = {}
}

# Single object carrying the App Service configuration. Each environment
# supplies this object from its terraform.tfvars.
variable "app_service" {
  description = "App Service (Linux, Node.js) configuration."
  type = object({
    app_name          = string # globally unique web app name
    service_plan_name = string # name of the App Service Plan
    sku_name          = string # e.g. B1, P1v3
    node_version      = optional(string, "20-lts")
    always_on         = optional(bool, true)
    https_only        = optional(bool, true)
    ftps_state        = optional(string, "Disabled")
    health_check_path = optional(string, "/")
    app_command_line  = optional(string, "")
    app_settings      = optional(map(string), {}) # non-secret settings only
  })
}

# Secret app settings are passed separately (marked sensitive) and merged into
# app_settings inside the module, keeping secrets out of terraform.tfvars.
variable "extra_app_settings" {
  description = "Additional (sensitive) app settings merged into app_settings."
  type        = map(string)
  default     = {}
  sensitive   = true
}
