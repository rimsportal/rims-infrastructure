terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # Remote state in Azure Storage, authenticated via Azure AD + GitHub OIDC
  # (no storage account key / client secret stored anywhere).
  backend "azurerm" {
    resource_group_name  = "rg-rims-tfstate-qa"
    storage_account_name = "rimstfstateqa"
    container_name       = "tfstate-qa"
    key                  = "designstool/qa.terraform.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}
