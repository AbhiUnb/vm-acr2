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





output "webapp_url" {
  value       = azurerm_windows_web_app.MF-MDI-CC-CORE-Webapp.default_hostname
  description = "The default URL of the deployed Azure Web App"
}

output "webapp_id" {
  value       = azurerm_windows_web_app.MF-MDI-CC-CORE-Webapp.id
  description = "The ID of the Azure Web App resource"
}

output "app_service_plan_id" {
  value       = azurerm_service_plan.MF_MDI_CC_CORE-appSP.id
  description = "The ID of the App Service Plan"
}



output "webapp_name" {
  value = azurerm_windows_web_app.MF-MDI-CC-CORE-Webapp.name
}

output "resource_group" {
  value = var.cc_core_resource_group_name
}
-------------------------------------------
provider "azurerm" {

  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "5d36b86e-695f-427b-9a19-7a6cc2db39d6"
  use_cli=true
}
-------------------------------
cc_location                    = "Canada Central"
cc_core_resource_group_name    = "MF_MDIxMI_TerraTest"
# cc_storage_resource_group_name = "MF_MDI_CC_GH_STORAGE-PROD-RG"




###########################LOG Analytics###########################################

# cc_core_law_name = "MF-MDI-CC-CORE-PROD-LAW"
# cc_core_law_sku  = "PerGB2018"


############################Web App###########################################
MF_DM_CC_CORE-appSP_Name  = "MF_DM_CC_CORE_PROD-appSP"
MF-DM-CC-CORE-Webapp_Name = "MF-MDI-CC-CORE-PROD-Webapp-Terra"


# ############################ACR############################
# cc_core_acr_name = "MFMDICCCOREPRODACRTerra"
# cc_core_acr_sku  = "Basic"








#   "MF_MDI_CC_CORE_KEY_VAULT_ROLE_ASSGN" = {
#     role_definition_id_or_name = "Key Vault Administrator"
#     principal_id               = "33333333-3333-3333-3333-333333333333"
#   }
# }
------------------------------------------




variable "cc_location" {
  type        = string
  description = "Canada Central Region"
}

variable "cc_core_resource_group_name" {
  type        = string
  description = "Resource Group Name for McCain Foods Manufacturing Digital Shared Azure Components in Canada Central"
}

# variable "cc_storage_resource_group_name" {
#   type        = string
#   default     = "MF_MDI_CC_GH_STORAGE-PROD-RG"
#   description = "Resource Group Name for McCain Foods Manufacturing Digital Shared Azure Components in Canada Central"
# }

# variable "cc_resource_groups" {
#   type = map(object({
#     location = string
#     tags     = optional(map(string), {})
#     lock = optional(object({
#       level = string
#       notes = optional(string)
#     }), null)
#   }))
#   description = "Resource Groups for McCain Foods Manufacturing Digital Shared Azure Components in Canada Central Region with Tags"

#   validation {
#     condition = alltrue([
#       for key in keys(var.cc_resource_groups) :
#       can(regex("^MF_[A-Z0-9]+_CC_[A-Z]+_[A-Z]+_(DEV|QA|PROD)_RG$", key))
#     ])
#     error_message = "RG names must match: MF_<APP>_CC_<TEAM>_<TYPE>_<ENV>_RG"
#   }


#   validation {
#     condition = alltrue([
#       for rg in values(var.cc_resource_groups) :
#       contains(["canadacentral", "East US", "West Europe"], rg.location)
#     ])
#     error_message = "Resource Group locations must be one of: Canada Central, East US, West Europe"
#   }

#   validation {
#     condition = alltrue([
#       for rg in values(var.cc_resource_groups) :
#       alltrue([
#         for tag in ["CodeOwner", "Environment"] :
#         contains(keys(rg.tags), tag)
#       ])
#     ])
#     error_message = "Each RG must include 'CodeOwner' and 'Environment' tags if tags are defined"
#   }
# }

# variable "cc_vnet" {
#   type = map(object({
#     name                = string
#     resource_group_name = string
#     location            = string
#     address_space       = list(string)
#     subnets = map(object({
#       name                              = string
#       address_prefixes                  = list(string)
#       service_endpoints                 = list(string)
#       private_endpoint_network_policies = string
#       delegation = list(object({
#         name = string
#         service_delegation = object({
#           name = string
#         actions = list(string) })
#       }))
#     }))
#   }))
#   description = "Map of virtual networks"
# }

# variable "nsgs" {
#   description = "Map of NSGs to create"
#   type = map(object({
#     location            = string
#     resource_group_name = string
#     security_rules = map(object({
#       name                         = string
#       priority                     = number
#       direction                    = string
#       access                       = string
#       protocol                     = string
#       source_address_prefix        = string
#       source_port_range            = string
#       destination_address_prefix   = optional(string)
#       destination_address_prefixes = optional(list(string))
#       destination_port_range       = optional(string)
#       destination_port_ranges      = optional(list(string))
#     }))
#   }))
# }


# variable "public_ips" {
#   description = "Map of public IPs to create"
#   type = map(object({
#     sku               = string
#     allocation_method = string
#     domain_name_label = optional(string)
#   }))
# }

# variable "cc_core_acr_name" {
#   type        = string
#   description = "container registry for McCain Food Manufacturing Digital Shared Azure Components in Canada Central"
# }

# variable "cc_core_acr_sku" {
#   type        = string
#   description = "Container Registry SKU for McCain Foods Manufacturing Digital Shared Azure Components in Canada Central"
# }


variable "MF_DM_CC_CORE-appSP_Name" {
    type = string
    description = "webapp service plan for mccain food MF digital canada central"
}


variable "MF-DM-CC-CORE-Webapp_Name" {
    type = string
    description = "webapp for mccain food MF digital canada central"
}
