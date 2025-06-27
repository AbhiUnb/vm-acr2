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


  functionapp = {
    MF-MDI-CC-GHPROD-DDDS-AFUNC = {
      name                       = "MF-MDI-CC-GHPROD-DDDS-AFUNC"
      kind                       = "functionapp"
      storage_account_name       = "mfmdiccprodghcoresa"
      
    }
  }





#################### Azure Functions #######################

cc_core_function_apps = {
  MF-DM-CC-DDDS-AFUNC = {
    name                        = "MF-DM-CC-DDDS-AFUNC"
    location                    = "Canada Central"
    os_type                     = "Windows"
    storage_account_name        = "mfmdiccsaname"
    storage_account_rg          = "MF_MDI_CC_GH_STORAGE-PROD-RG"
    network_name                = "MF_MDI_CC_PROD_CORE-VNET"
    subnet_name                 = "MF_MDI_CC_AFUNC-SNET"
    user_assigned_identity_name = "MF_CC_CORE_PROD_APP_ACCESS-USER-IDENTITY"
    user_assigned_identity_rg   = "MF_MDIxMI_Github_PROD_RG"
    app_insights_name           = "MF-MDI-CC-CORE-APP-INSIGHTS"
    app_insights_rg             = "MF_MDIxMI_Github_PROD_RG"
    key_vault_name              = "MF-MDI-CORE-PRD-GH-KV"
    additional_app_settings = {
      DddsBatchTriggerTime            = "0 0/5 * * * *"
      FUNCTIONS_WORKER_RUNTIME        = "dotnet-isolated"
      mdiaikeyVaultName               = "MF-DM-CC-CORE-DEV-KV"
      mdiaiTenantId                   = "59fa7797-abec-4505-81e6-8ce092642190"
      WEBSITE_ENABLE_SYNC_UPDATE_SITE = "true"
      WEBSITE_RUN_FROM_PACKAGE        = "1"
    }
  }

  MF-DM-CC-EXTERNALDATA-AFUNC = {
    name                        = "MF-DM-CC-EXTERNALDATA-AFUNC"
    location                    = "Canada Central"
    os_type                     = "Windows"
    storage_account_name        = "mfmdiccsaname"
    storage_account_rg          = "MF_MDI_CC_GH_STORAGE-PROD-RG"
    network_name                = "MF_MDI_CC_PROD_CORE-VNET"
    subnet_name                 = "MF_MDI_CC_AFUNC-SNET"
    user_assigned_identity_name = "MF_CC_CORE_PROD_APP_ACCESS-USER-IDENTITY"
    user_assigned_identity_rg   = "MF_MDIxMI_Github_PROD_RG"
    app_insights_name           = "MF-MDI-CC-CORE-APP-INSIGHTS"
    app_insights_rg             = "MF_MDIxMI_Github_PROD_RG"
    key_vault_name              = "MF-MDI-CORE-PRD-GH-KV"
    additional_app_settings = {
      DddsBatchTriggerTime            = "0 0/5 * * * *"
      FUNCTIONS_WORKER_RUNTIME        = "dotnet-isolated"
      mdiaikeyVaultName               = "MF-DM-CC-CORE-DEV-KV"
      mdiaiTenantId                   = "59fa7797-abec-4505-81e6-8ce092642190"
      WEBSITE_ENABLE_SYNC_UPDATE_SITE = "true"
      WEBSITE_RUN_FROM_PACKAGE        = "1"
      WorkOrderStatusTriggerTime      = "0 0/15 * * * *"
      EquipmentStopTriggerTime        = "0 0/15 * * * *"
      SKUBatchTriggerTime             = "0 0/5 * * * *"
    }
  }

  MF-MDI-CC-LIVESKU-AFUNC = {
    name                        = "MF-MDI-CC-LIVESKU-AFUNC"
    location                    = "Canada Central"
    os_type                     = "Windows"
    storage_account_name        = "mfmdiccsaname"
    storage_account_rg          = "MF_MDI_CC_GH_STORAGE-PROD-RG"
    network_name                = "MF_MDI_CC_PROD_CORE-VNET"
    subnet_name                 = "MF_MDI_CC_AFUNC-SNET"
    user_assigned_identity_name = "MF_CC_CORE_PROD_APP_ACCESS-USER-IDENTITY"
    user_assigned_identity_rg   = "MF_MDIxMI_Github_PROD_RG"
    app_insights_name           = "MF-MDI-CC-CORE-APP-INSIGHTS"
    app_insights_rg             = "MF_MDIxMI_Github_PROD_RG"
    key_vault_name              = "MF-MDI-CORE-PRD-GH-KV"
    additional_app_settings = {
      DddsBatchTriggerTime               = "0 0/5 * * * *"
      FUNCTIONS_WORKER_RUNTIME           = "dotnet-isolated"
      mdiaikeyVaultName                  = "MF-DM-CC-CORE-DEV-KV"
      mdiaiTenantId                      = "59fa7797-abec-4505-81e6-8ce092642190"
      WEBSITE_ENABLE_SYNC_UPDATE_SITE    = "true"
      WEBSITE_RUN_FROM_PACKAGE           = "1"
      mdiaiLiveSkuEVHConnectionString    = "@Microsoft.KeyVault(SecretUri=https://MF-DM-CC-CORE-DEV-KV.vault.azure.net/secrets/mdiaiLiveSkuEVHConnectionStringCDL/)"
      mdiaiLiveSkuEVHConsumerGrp         = "ehentity-skudata-stg2-cg1"
      mdiaiLiveSkuEVHName                = "mf-mdi-cc-skudata-stg2"
      mdiaiLineStatusEVHConnectionString = "@Microsoft.KeyVault(SecretUri=https://MF-DM-CC-CORE-DEV-KV.vault.azure.net/secrets/mdiaiLineStatusEVHConnectionStringCDL/)"
      mdiaiLineStatusEVHConsumerGrp      = "ehentity-linestatus-stg2-cg1"
      mdiaiLineStatusEVHName             = "mf-mdi-cc-linestatus-stg2"
      Authority                          = "https://login.microsoftonline.com/59fa7797-abec-4505-81e6-8ce092642190"
      Scope                              = "https://piwebdev-mccaingroup.msappproxy.net/user_impersonation"
      PiApiUrl                           = "https://piwebdev-mccaingroup.msappproxy.net"
      LiveSKUTriggerTime                 = "0 * * * *"
    }
  }

  MF-MDI-CC-AUTO-SUBM-AFUNC = {
    name                        = "MF-MDI-CC-AUTO-SUBM-AFUNC"
    location                    = "Canada Central"
    os_type                     = "Windows"
    storage_account_name        = "mfmdiccsaname"
    storage_account_rg          = "MF_MDI_CC_GH_STORAGE-PROD-RG"
    network_name                = "MF_MDI_CC_PROD_CORE-VNET"
    subnet_name                 = "MF_MDI_CC_AFUNC-SNET"
    user_assigned_identity_name = "MF_CC_CORE_PROD_APP_ACCESS-USER-IDENTITY"
    user_assigned_identity_rg   = "MF_MDIxMI_Github_PROD_RG"
    app_insights_name           = "MF-MDI-CC-CORE-APP-INSIGHTS"
    app_insights_rg             = "MF_MDIxMI_Github_PROD_RG"
    key_vault_name              = "MF-MDI-CORE-PRD-GH-KV"
    additional_app_settings = {
      DddsBatchTriggerTime            = "0 0/5 * * * *"
      FUNCTIONS_WORKER_RUNTIME        = "dotnet-isolated"
      mdiaikeyVaultName               = "MF-DM-CC-CORE-DEV-KV"
      mdiaiTenantId                   = "59fa7797-abec-4505-81e6-8ce092642190"
      WEBSITE_ENABLE_SYNC_UPDATE_SITE = "true"
      WEBSITE_RUN_FROM_PACKAGE        = "1"
    }
  }
}

# kv_legacy_access_policies = {
#   "MF_MDI_CC_CORE_TF_KEY_VAULT_ACCESS_POLICY" = {
#     tenant_id               = "00000000-0000-0000-0000-000000000000"
#     object_id               = "11111111-1111-1111-1111-111111111111"
#     secret_permissions      = ["Get", "List"]
#     key_permissions         = ["Get", "List"]
#     certificate_permissions = ["Get", "List", "GetIssuers", "ListIssuers"]
#     storage_permissions     = ["Get", "List"]
#   }
#   "MF_MDI_CC_CORE_ACA_AUTH_KEY_VAULT_ACCESS_POLICY" = {
#     tenant_id               = "00000000-0000-0000-0000-000000000000"
#     object_id               = "11111111-1111-1111-1111-111111111111"
#     secret_permissions      = ["Get", "List"]
#     key_permissions         = ["Get", "List"]
#     certificate_permissions = ["Get", "List", "GetIssuers", "ListIssuers"]
#     storage_permissions     = []
#   }
#   "MF_MDI_CC_CORE_ACA_DDH_KEY_VAULT_ACCESS_POLICY" = {
#     tenant_id               = "00000000-0000-0000-0000-000000000000"
#     object_id               = "11111111-1111-1111-1111-111111111111"
#     secret_permissions      = ["Get", "List"]
#     key_permissions         = ["Get", "List"]
#     certificate_permissions = ["Get", "List", "GetIssuers", "ListIssuers"]
#     storage_permissions     = []
#   }
#   "MF_MDI_CC_CORE_KEY_VAULT_ACCESS_POLICY" = {
#     tenant_id               = "00000000-0000-0000-0000-000000000000"
#     object_id               = "11111111-1111-1111-1111-111111111111"
#     secret_permissions      = ["Get", "List"]
#     key_permissions         = ["Get", "List"]
#     certificate_permissions = ["Get", "List", "GetIssuers", "ListIssuers"]
#     storage_permissions     = []
#   }
# }

# kv_role_assignments = {
#   "MF_MDI_CC_CORE_ACA_AUTH_KEY_VAULT_ROLE_ASSGN" = {
#     role_definition_id_or_name = "Key Vault Administrator"
#     principal_id               = "33333333-3333-3333-3333-333333333333"
#   }
#   "MF_MDI_CC_CORE_ACA_DDH_KEY_VAULT_ROLE_ASSGN" = {
#     role_definition_id_or_name = "Key Vault Administrator"
#     principal_id               = "33333333-3333-3333-3333-333333333333"
#   }
#   "MF_MDI_CC_CORE_KEY_VAULT_ROLE_ASSGN" = {
#     role_definition_id_or_name = "Key Vault Administrator"
#     principal_id               = "33333333-3333-3333-3333-333333333333"
#   }
# }
