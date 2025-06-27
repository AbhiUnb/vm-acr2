Validate Function App existence	Confirm Azure Function App is deployed	Core provisioning check	Static
Validate hosting plan and SKU	Confirm if Consumption, Premium or Dedicated plan is used	Cost and scale policy enforcement	Static
Validate deployment source	Ensure source control or package path is configured	Validates CI/CD deployment	Static
Validate App Settings	Check app settings like runtime version, timeouts, etc.	Ensure app starts with required configs	Static
Validate trigger behavior	Call HTTP or timer trigger and confirm response	Runtime check for function responsiveness	Runtime
Validate Application Insights integration	Ensure telemetry flows to AI from function logs	Monitoring integration validation	Runtime












# # resource "azurerm_app_service_plan" "MFDMCCASPAFUNC" {
# #   name                = "MFDMCCPRODASPAFUNC"
# #   resource_group_name = var.cc_core_resource_group_name
# #   location            = var.cc_location
# #   kind                = "FunctionApp"
# #   sku {
# #     tier = "PremiumV2"
# #     size = "P1v2"
# #   }
# # }


resource "azurerm_service_plan" "MFDMCCASPAFUNC" {
  resource_group_name = var.cc_core_resource_group_name
  location            = var.cc_location
  name                = "MFDMCCPRODASPAFUNC"
  os_type             = "Linux"
  sku_name            = "P1v2"
  tags                = local.tag_list_1
}

module "avm-res-web-site" {
  source              = "Azure/avm-res-web-site/azurerm"
  version             = "0.16.4"
  for_each            = local.functionapp
  name                = each.value.name
  resource_group_name = var.cc_core_resource_group_name
  location            = var.cc_location

  kind = each.value.kind

  # Uses an existing app service plan
  os_type                  = azurerm_service_plan.MFDMCCASPAFUNC.os_type
  service_plan_resource_id = azurerm_service_plan.MFDMCCASPAFUNC.id

  # Uses an existing storage account
  storage_account_name       = each.value.storage_account_name
  storage_account_access_key = each.value.storage_account_access_key
  # storage_uses_managed_identity = true

  tags = local.tag_list_1


}
