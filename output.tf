data "azurerm_client_config" "current" {}


output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_container_registry.this.resource_group_name
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.this.name
}

output "acr_login_server" {
  description = "The login server URL of the ACR"
  value       = azurerm_container_registry.this.login_server
}

output "subscription_id" {
  description = "Azure subscription ID (used in tests)"
  value       = data.azurerm_client_config.current.subscription_id
}