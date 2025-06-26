locals {
  tag_list_1 = {
    "Application Name" = "McCain DevSecOps"
    "GL Code"          = "N/A"
    "Environment"      = "sandbox"
    "IT Owner"         = "mccain-azurecontributor@mccain.ca"
    "Onboard Date"     = "12/19/2024"
    "Modified Date"    = "N/A"
    "Organization"     = "McCain Foods Limited"
    "Business Owner"   = "trilok.tater@mccain.ca"
    "Implemented by"   = "trilok.tater@mccain.ca"
    "Resource Owner"   = "trilok.tater@mccain.ca"
    "Resource Posture" = "Private"
    "Resource Type"    = "Terraform POC"
    "Built Using"      = "Terraform"
  }
  route_tables = {
    MF_MDI_CC_SQLMI-rt = {
      location            = "Canada Central"
      resource_group_name = "MF_MDIXMI_CC_GH_CORE_PROD_RG"
      tags = {
        env = "prod"
      }
      subnet_resource_ids = {
        subnet1 = module.avm-res-network-virtualnetwork["MF_MDI_CC_PROD_CORE-VNET"].subnets["MF_MDI_CC_PROD_SQLMI-SNET"].resource_id,
        subnet2 = module.avm-res-network-virtualnetwork["MF_MDI_CC_PROD_CORE-VNET"].subnets["MF_MDI_CC_AFUNC-SNET"].resource_id
      }
      routes = {
        "to-internet" = {
          name           = "Internet"
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "Internet"
        },
        "VDI_172.25.35.0_24" = {
          name                   = "VDI_172.25.35.0_24"
          address_prefix         = "172.25.35.0/24"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.125.251.4"
        }
        "VDI_172.16.0.0_16" = {
          name                   = "VDI_172.16.0.0_16"
          address_prefix         = "172.16.0.0/16"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.125.251.4"
        }
        "VDI_172.19.0.0_16" = {
          name                   = "VDI_172.19.0.0_16"
          address_prefix         = "172.19.0.0/16"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.125.251.4"
        }
        "VDI_172.29.0.0_16" = {
          name                   = "VDI_172.29.0.0_16"
          address_prefix         = "172.29.0.0/16"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.125.251.4"
        }

        "VnetLocal" = {
          name           = "VnetLocal"
          address_prefix = "10.125.181.192/27"
          next_hop_type  = "VnetLocal"
        }

        "AD" = {
          name           = "AD"
          address_prefix = "AzureActiveDirectory"
          next_hop_type  = "Internet"
        }

        "OneDs" = {
          name           = "OneDs"
          address_prefix = "OneDsCollector"
          next_hop_type  = "Internet"
        }

        "Storage_central" = {
          name           = "Storage_central"
          address_prefix = "Storage.canadacentral"
          next_hop_type  = "Internet"
        }

        "Storage_east" = {
          name           = "Storage_east"
          address_prefix = "Storage.canadaeast"
          next_hop_type  = "Internet"
        }

        "VDI_172.25.30.0_23" = {
          name                   = "VDI_172.25.30.0_23"
          address_prefix         = "172.25.30.0/23"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.125.251.4"
        }
      }
    }
    MF_MDI_CC_AFUNC-rt = {
      location            = "Canada Central"
      resource_group_name = "MF_MDIXMI_CC_GH_CORE_PROD_RG"
      tags = {
        env = "prod"
      }
      routes = {
        "To_Synapse" = {
          name                   = "To_Synapse"
          address_prefix         = "172.25.246.36/32"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.125.251.4"
        },
        "VDI_172.25.0.0_16" = {
          name                   = "VDI_172.25.0.0_16"
          address_prefix         = "172.25.0.0/16"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.125.251.4"
        }
      }
    }
  }
}


# locals {
#   all_role_ids = toset(flatten([
#     for k, v in data.azurerm_role_assignments.rg_roles :
#     [for r in v.role_assignments : r.role_definition_id]
#   ]))

#   role_definition_ids_map = {
#     for role_id in local.all_role_ids :
#     role_id => split("/", role_id)[length(split("/", role_id)) - 1]
#   }
# }
