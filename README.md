output "cc_rg_outputs" {
  description = <<EOT
Aggregated metadata for all Resource Groups provisioned for the enterprise application.

Each entry in this map is keyed by the logical Resource Group name and includes:
- `name`: The actual Azure Resource Group name, matching the organization's naming convention
- `location`: The Azure region where the RG is deployed (e.g., "Canada Central")
- `id`: The unique Azure Resource Manager (ARM) resource ID for referencing across modules and pipelines
- `tags`: The full, merged tag set including organization-mandated governance tags and module-supplied metadata
- lock_level : The management lock level applied to the Azure Resource Group.
  Possible values:
  - "CanNotDelete": Authorized users can read and modify the resource, but they can't delete it.
  - "ReadOnly": Authorized users can read the resource, but they can't delete or update it.
  - null or "" (empty): No lock applied to the resource group.
  Used for enforcing governance policies to protect critical infrastructure from accidental deletion or modification.

This output is designed for:
- Centralized visibility into all RGs managed by this deployment unit
- Secure and standardized downstream consumption by dependent modules (networking, policies, monitoring, etc.)
- CI/CD pipeline integration where resource IDs and metadata are needed for auditing, deployment orchestration, or security validation
- Facilitating compliance, traceability, and cost allocation across environments and business units

It supports automation at scale, especially in multi-environment (dev/qa/prod) deployments using naming standards, tag inheritance, and environment-based provisioning.
EOT
  value = {
    for name, mod in module.MF_MDI_CC_RG :
    name => {
      name     = mod.name
      location = mod.resource.location
      id       = mod.resource_id
      tags     = mod.resource.tags
    }
  }
}

output "cc_rg_locks" {
  value = {
    for k, v in azurerm_management_lock.rg_locks :
    k => v.lock_level
  }
}

data "azurerm_client_config" "current" {}

data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}

data "azurerm_role_definition" "reader" {
  name = "Reader"
}

data "azurerm_role_definition" "owner" {
  name = "Owner"
}

output "role_ids" {
  value = {
    Contributor = data.azurerm_role_definition.contributor.id
    Reader      = data.azurerm_role_definition.reader.id
    Owner       = data.azurerm_role_definition.owner.id
  }
  description = "Role definition IDs for known role names"
}

output "current_principal_id" {
  value       = data.azurerm_client_config.current.object_id
  description = "Current executor principal ID"
}

output "rg_role_assignments_principals" {
  value = {
    for rg_name, data in data.azurerm_role_assignments.rg_roles :
    rg_name => [
      for ra in data.role_assignments : {
        principal_id       = ra.principal_id
        role_definition_id = ra.role_definition_id
      }
    ]
  }
}

### Virtual Network #####

# output "cc_vnet_names" {
#   description = "Names of all deployed virtual networks"
#   value = {
#     for k, v in module.avm-res-network-virtualnetwork : k => v.name
#   }
# }

# output "cc_vnet_ids" {
#   description = "Resource IDs of all virtual networks"
#   value = {
#     for k, v in module.avm-res-network-virtualnetwork : k => v.resource_id
#   }
# }

# output "cc_vnet_locations" {
#   description = "Azure locations of all deployed VNets"
#   value = {
#     for k, v in module.avm-res-network-virtualnetwork : k => v.resource.location
#   }
# }

# output "cc_vnet_resource_group_names" {
#   description = "Resource groups of deployed virtual networks (from input)"
#   value = {
#     for k, v in var.cc_vnet : k => v.resource_group_name
#   }
# }


output "vnets_info" {
  description = "Information about all virtual networks"
  value = {
    for k, v in module.avm-res-network-virtualnetwork : k => {
      name                 = v.name
      id                   = v.resource_id
      location             = v.resource.location
      address_space        = v.resource.body.properties.addressSpace.addressPrefixes
      ddosProtectionPlan   = v.resource.body.properties.ddosProtectionPlan
      dhcpOptions          = v.resource.body.properties.dhcpOptions
      enableDdosProtection = v.resource.body.properties.enableDdosProtection
      enableVmProtection   = v.resource.body.properties.enableVmProtection
      encryption           = v.resource.body.properties.encryption
      tags                 = v.resource.tags
      #   subnets = v.subnets
      subnets = {
        for subnet_name, subnet in v.subnets : subnet_name => {
          subnet_name                       = subnet_name
          subnet_id                         = subnet.resource_id
          addressPrefix                     = subnet.resource.body.properties.addressPrefix
          defaultOutboundAccess             = subnet.resource.body.properties.defaultOutboundAccess
          delegations                       = subnet.resource.body.properties.delegations
          natGateway                        = subnet.resource.body.properties.natGateway
          networkSecurityGroup              = subnet.resource.body.properties.networkSecurityGroup
          privateEndpointNetworkPolicies    = subnet.resource.body.properties.privateEndpointNetworkPolicies
          privateLinkServiceNetworkPolicies = subnet.resource.body.properties.privateLinkServiceNetworkPolicies
          routeTable                        = subnet.resource.body.properties.routeTable
          serviceEndpointPolicies           = subnet.resource.body.properties.serviceEndpointPolicies
          serviceEndpoints                  = subnet.resource.body.properties.serviceEndpoints
          tags                              = subnet.resource.tags
        }
      }
    }
  }
}

output "cc_nsg_info" {
  description = "info for all NSGs"
  value = {
    for k, mod in module.nsg :
    k => {
      id                  = mod.resource_id
      name                = mod.name
      location            = mod.resource.location
      security_rule       = mod.resource.security_rule
      resource_group_name = mod.resource.resource_group_name
      tags                = mod.resource.tags
    }
  }
}
output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}
output "cc_route_info" {
  description = "info for all route tables info"
  value = {
    for k, mod in module.MF_MDI-rt :
    k => {
      id                  = mod.resource_id
      name                = mod.name
      location            = mod.resource.location
      routes              = mod.routes
      resource_group_name = mod.resource.resource_group_name
      tags                = mod.resource.tags
    }
  }
}

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




