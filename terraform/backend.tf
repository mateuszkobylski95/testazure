terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatee1c19c4c"
    container_name       = "tfstate"
    key                  = "testazure.tfstate"
  }
}
