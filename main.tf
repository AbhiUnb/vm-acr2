provider "azurerm" {
  features {}
}

resource "azurerm_container_registry" "this" {
  name                = var.cc_core_acr_name
  resource_group_name = var.cc_core_resource_group_name
  location            = var.cc_location
  sku                 = var.cc_core_acr_sku
  admin_enabled       = true 
  tags = local.tag_list_1
}