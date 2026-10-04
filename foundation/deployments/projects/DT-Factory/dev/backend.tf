terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-dt-factory-tfstate"
    storage_account_name = "dtfactorytfstate001"
    container_name       = "tfstate"
    key                  = "factory-dev.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  use_oidc            = true
  storage_use_azuread = true
}

provider "azuread" {
  tenant_id = var.entra_tenant_id
  use_oidc  = true
}
