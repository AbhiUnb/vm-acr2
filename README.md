# Create an App Service Plan
# resource "azurerm_app_service_plan" "MF_MDI_CC_CORE-appSP" {
#   name                = var.MF_DM_CC_CORE-appSP_Name
#   location            = var.cc_location
#   resource_group_name = var.cc_core_resource_group_name
#   sku {
#     tier = "Standard"
#     size = "S3"
#   }
# }

resource "azurerm_service_plan" "MF_MDI_CC_CORE-appSP" {
  location            = var.cc_location
  resource_group_name = var.cc_core_resource_group_name
  name                = var.MF_DM_CC_CORE-appSP_Name
  os_type             = "Windows"
  sku_name            = "S3"
  tags                = local.tag_list_1
}
# Create a Web App
resource "azurerm_windows_web_app" "MF-MDI-CC-CORE-Webapp" {

  name                = var.MF-DM-CC-CORE-Webapp_Name
  location            = var.cc_location
  resource_group_name = var.cc_core_resource_group_name
  service_plan_id     = azurerm_service_plan.MF_MDI_CC_CORE-appSP.id
  site_config {
    always_on = true
  }
  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "14.17.0" # Example Node.js version
  }
  lifecycle {
    ignore_changes = [
      name, app_settings, site_config, tags, logs
    ]
  }

  identity {
    type = "SystemAssigned"
  }
}
resource "azapi_update_resource" "minTlsCipherSuite" {
  type        = "Microsoft.Web/sites@2023-01-01"
  resource_id = azurerm_windows_web_app.MF-MDI-CC-CORE-Webapp.id
  body = {
    properties = {
      siteConfig = {
        minTlsCipherSuite = "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
      }
    }
  }

  response_export_values = ["properties"]
}
