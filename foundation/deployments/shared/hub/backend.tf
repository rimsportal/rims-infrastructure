terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # Shared non-prod hub state. Reuses the existing dev state storage account
  # with a dedicated container (tfstate-hub must be created once — see the
  # phase-1 runbook). Relocate to a dedicated shared state account later if
  # desired.
  backend "azurerm" {
    resource_group_name  = "rg-rims-tfstate-dev"
    storage_account_name = "rimstfstatedev"
    container_name       = "tfstate-hub"
    key                  = "shared/hub.terraform.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}
