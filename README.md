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


-------------------------------------------------------------------



package test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclparse"
	"github.com/stretchr/testify/assert"
	ctyjson "github.com/zclconf/go-cty/cty/json"
)

func TestAzureWebAppDeployment(t *testing.T) {
	t.Parallel()

	logStep := func(stepNum int, message string) {
		t.Logf("✅ Step %d: %s", stepNum, message)
	}

	// Define Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		VarFiles:     []string{"../terraform.tfvars"},
	}

	// Init and apply Terraform
	// defer terraform.Destroy(t, terraformOptions)
	// terraform.InitAndApply(t, terraformOptions)

	webAppName := terraform.Output(t, terraformOptions, "webapp_name")
	resourceGroup := terraform.Output(t, terraformOptions, "resource_group")

	if assert.NotEmpty(t, webAppName, "Web App name output is empty") {
		t.Logf("✅ PASS: Web App name output is not empty")
	} else {
		t.Logf("❌ FAIL: Web App name output is empty")
	}
	if assert.NotEmpty(t, resourceGroup, "Resource group output is empty") {
		t.Logf("✅ PASS: Resource group output is not empty")
	} else {
		t.Logf("❌ FAIL: Resource group output is empty")
	}

	// Fetch web app properties dynamically using Azure CLI
	cmd := exec.Command("az", "webapp", "show", "--name", webAppName, "--resource-group", resourceGroup, "-o", "json")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		t.Fatalf("Failed to fetch web app info: %v", err)
	}
	var webApp struct {
		DefaultHostName string `json:"defaultHostName"`
		ServerFarmID    string `json:"serverFarmId"`
		Identity        struct {
			Type string `json:"type"`
		} `json:"identity"`
	}
	err = json.Unmarshal(out.Bytes(), &webApp)
	if err != nil {
		t.Fatalf("Failed to parse web app JSON: %v", err)
	}
	logStep(3, fmt.Sprintf("Fetched Web App: %+v", webApp))
	logStep(4, fmt.Sprintf("Web App Hostname: %s", webApp.DefaultHostName))
	if assert.NotEmpty(t, webApp.DefaultHostName, "Web App Hostname is empty") {
		t.Logf("✅ PASS: Web App Hostname is not empty")
	} else {
		t.Logf("❌ FAIL: Web App Hostname is empty")
	}
	webAppURL := webApp.DefaultHostName

	// Get App Service Plan ID from Terraform output
	appServicePlanID := terraform.Output(t, terraformOptions, "app_service_plan_id")
	logStep(5, fmt.Sprintf("Service Plan ID (from output): %s", appServicePlanID))
	if assert.NotEmpty(t, appServicePlanID, "App Service Plan ID should not be empty") {
		t.Logf("✅ PASS: App Service Plan ID is not empty")
	} else {
		t.Logf("❌ FAIL: App Service Plan ID is empty")
	}

	parts := strings.Split(appServicePlanID, "/")
	appServicePlanName := parts[len(parts)-1]

	cmd = exec.Command("az", "appservice", "plan", "show", "--name", appServicePlanName, "--resource-group", resourceGroup, "-o", "json")
	out.Reset()
	cmd.Stdout = &out
	err = cmd.Run()
	if err != nil {
		t.Fatalf("Failed to fetch App Service Plan info: %v", err)
	}

	var plan struct {
		Sku struct {
			Name string `json:"name"`
		} `json:"sku"`
	}
	err = json.Unmarshal(out.Bytes(), &plan)
	if err != nil {
		t.Fatalf("Failed to parse App Service Plan JSON: %v", err)
	}

	// 1. Web App existence
	cmd = exec.Command("az", "webapp", "show", "--name", webAppName, "--resource-group", resourceGroup, "-o", "json")
	output, err := cmd.CombinedOutput()
	exists := err == nil && strings.Contains(string(output), webAppName)
	if assert.True(t, exists, "Expected Web App to exist") {
		t.Logf("✅ PASS: Web App exists")
	} else {
		t.Logf("❌ FAIL: Web App does not exist")
	}
	logStep(1, "Verified Web App existence")

	// 2. HTTPS Availability Test
	url := "https://" + webAppURL
	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 10, 5*time.Second, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, "Azure") // Basic validation
	})
	logStep(2, "HTTPS availability test passed")

	// 3. Check App Settings dynamically
	cmd = exec.Command("az", "webapp", "config", "appsettings", "list", "--name", webAppName, "--resource-group", resourceGroup, "-o", "json")
	out.Reset()
	cmd.Stdout = &out
	err = cmd.Run()
	if err != nil {
		t.Fatalf("Failed to fetch app settings: %v", err)
	}

	var appSettings []map[string]interface{}
	err = json.Unmarshal(out.Bytes(), &appSettings)
	if err != nil {
		t.Fatalf("Failed to parse app settings JSON: %v", err)
	}

	found := false
	for _, kv := range appSettings {
		if name, ok := kv["name"].(string); ok && name == "WEBSITE_NODE_DEFAULT_VERSION" {
			found = true
			break
		}
	}
	if assert.True(t, found, "Expected app setting WEBSITE_NODE_DEFAULT_VERSION to exist") {
		t.Logf("✅ PASS: App setting WEBSITE_NODE_DEFAULT_VERSION exists")
	} else {
		t.Logf("❌ FAIL: App setting WEBSITE_NODE_DEFAULT_VERSION does not exist")
	}
	logStep(6, "Verified app setting WEBSITE_NODE_DEFAULT_VERSION exists")

	// 4. Validate Identity
	if assert.Equal(t, "SystemAssigned", webApp.Identity.Type, "Expected identity to be SystemAssigned") {
		t.Logf("✅ PASS: Identity is SystemAssigned")
	} else {
		t.Logf("❌ FAIL: Identity is not SystemAssigned")
	}
	logStep(7, "Validated identity is SystemAssigned")

	// 5. Confirm Plan is correctly sized
	if assert.Equal(t, "S3", plan.Sku.Name, "Expected App Service Plan SKU to be S3") {
		t.Logf("✅ PASS: App Service Plan SKU is S3")
	} else {
		t.Logf("❌ FAIL: App Service Plan SKU is not S3")
	}
	logStep(8, "Confirmed App Service Plan SKU is S3")

	// 9. Validate App Service Plan Tags
	cmd = exec.Command("az", "appservice", "plan", "show", "--name", appServicePlanName, "--resource-group", resourceGroup, "-o", "json")
	out.Reset()
	cmd.Stdout = &out
	err = cmd.Run()
	if err != nil {
		t.Fatalf("Failed to fetch App Service Plan info for tag validation: %v", err)
	}

	var planWithTags struct {
		Tags map[string]string `json:"tags"`
	}
	err = json.Unmarshal(out.Bytes(), &planWithTags)
	if err != nil {
		t.Fatalf("Failed to parse App Service Plan JSON for tags: %v", err)
	}

	// Parse HCL locals.tf to extract tags
	parser := hclparse.NewParser()
	file, diag := parser.ParseHCLFile("../locals.tf")
	if diag.HasErrors() {
		t.Fatalf("Failed to parse HCL file: %v", diag.Error())
	}

	content, _, diag := file.Body.PartialContent(&hcl.BodySchema{
		Blocks: []hcl.BlockHeaderSchema{
			{Type: "locals"},
		},
	})
	if diag.HasErrors() {
		t.Fatalf("Failed to parse 'locals' block: %v", diag.Error())
	}

	var tagExpr hcl.Expression
	for _, block := range content.Blocks {
		if block.Type == "locals" {
			bodyContent, _, diag := block.Body.PartialContent(&hcl.BodySchema{
				Attributes: []hcl.AttributeSchema{
					{Name: "tag_list_1", Required: true},
				},
			})
			if diag.HasErrors() {
				t.Fatalf("Failed to parse 'tag_list_1' from locals block: %v", diag.Error())
			}
			tagExpr = bodyContent.Attributes["tag_list_1"].Expr
			break
		}
	}
	if tagExpr == nil {
		t.Fatalf("Could not find 'tag_list_1' in locals.tf")
	}

	ctx := &hcl.EvalContext{}
	val, diag := tagExpr.Value(ctx)
	if diag.HasErrors() {
		t.Fatalf("Failed to evaluate HCL expression for tag_list_1: %v", diag.Error())
	}

	var expectedTags map[string]string
	jsonBytes, err := ctyjson.Marshal(val, val.Type())
	if err != nil {
		t.Fatalf("Failed to marshal HCL cty.Value to JSON: %v", err)
	}

	err = json.Unmarshal(jsonBytes, &expectedTags)
	if err != nil {
		t.Fatalf("Failed to unmarshal tags JSON into map: %v", err)
	}

	for key, expectedValue := range expectedTags {
		actualValue, exists := planWithTags.Tags[key]
		if assert.True(t, exists, fmt.Sprintf("Expected tag key '%s' to exist", key)) {
			if assert.Equal(t, expectedValue, actualValue, fmt.Sprintf("Expected tag value for key '%s'", key)) {
				t.Logf("✅ PASS: Tag '%s' has expected value '%s'", key, expectedValue)
			} else {
				t.Logf("❌ FAIL: Tag '%s' has unexpected value '%s'", key, actualValue)
			}
		} else {
			t.Logf("❌ FAIL: Tag '%s' does not exist", key)
		}
	}
	logStep(11, "Validated App Service Plan tags")

	// 6. Validate Deployment Source - Placeholder (requires manual API/SDK check)
	logStep(9, "Validate Deployment Source - Skipped (requires custom pipeline or API check)")

	// 7. Diagnostic Logs Check - Placeholder
	logStep(10, "Validate Diagnostic Logs - Skipped (requires Log Analytics/API validation)")
}

