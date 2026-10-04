terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10"
    }
  }
}

data "azuread_client_config" "current" {}

data "azuread_application" "api" {
  client_id = var.api_client_id
}

locals {
  applications = {
    supervisor = "${var.application_name_prefix}-SUPERVISOR-MOBILE-${upper(var.environment)}"
    worker     = "${var.application_name_prefix}-WORKER-MOBILE-${upper(var.environment)}"
  }
}

resource "azuread_application" "mobile" {
  for_each = local.applications

  display_name                   = each.value
  description                    = "DT Factory ${title(each.key)} mobile application (${upper(var.environment)})."
  fallback_public_client_enabled = true
  owners                         = [data.azuread_client_config.current.object_id]
  sign_in_audience               = "AzureADMyOrg"

  public_client {
    redirect_uris = var.public_redirect_uris
  }

  required_resource_access {
    resource_app_id = var.api_client_id

    resource_access {
      id   = var.api_access_scope_id
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "mobile" {
  for_each = azuread_application.mobile

  client_id                    = each.value.client_id
  app_role_assignment_required = false
  description                  = each.value.description
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_pre_authorized" "mobile" {
  for_each = azuread_application.mobile

  application_id       = data.azuread_application.api.id
  authorized_client_id = each.value.client_id
  permission_ids       = [var.api_access_scope_id]
}
