terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  cloud {
    organization = "rims"

    workspaces {
      name = "rims-core-qa-HCP"
    }
  }
}

provider "azurerm" {
  features {}
}
