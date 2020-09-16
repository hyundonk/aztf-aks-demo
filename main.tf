provider "azurerm" {
    version = "2.25.0"
    features {}
}

provider "azuread" {
    version = "0.11.0"
}

terraform {
    backend "azurerm" {}
}
