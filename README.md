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

variable "cc_resource_groups" {
  type = map(object({
    location = string
    tags     = optional(map(string), {})
    lock = optional(object({
      level = string
      notes = optional(string)
    }), null)
  }))
  description = "Resource Groups for McCain Foods Manufacturing Digital Shared Azure Components in Canada Central Region with Tags"

  validation {
    condition = alltrue([
      for key in keys(var.cc_resource_groups) :
      can(regex("^MF_[A-Z0-9]+_CC_[A-Z]+_[A-Z]+_(DEV|QA|PROD)_RG$", key))
    ])
    error_message = "RG names must match: MF_<APP>_CC_<TEAM>_<TYPE>_<ENV>_RG"
  }


  validation {
    condition = alltrue([
      for rg in values(var.cc_resource_groups) :
      contains(["canadacentral", "East US", "West Europe"], rg.location)
    ])
    error_message = "Resource Group locations must be one of: Canada Central, East US, West Europe"
  }

  validation {
    condition = alltrue([
      for rg in values(var.cc_resource_groups) :
      alltrue([
        for tag in ["CodeOwner", "Environment"] :
        contains(keys(rg.tags), tag)
      ])
    ])
    error_message = "Each RG must include 'CodeOwner' and 'Environment' tags if tags are defined"
  }
}

variable "cc_vnet" {
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    address_space       = list(string)
    subnets = map(object({
      name                              = string
      address_prefixes                  = list(string)
      service_endpoints                 = list(string)
      private_endpoint_network_policies = string
      delegation = list(object({
        name = string
        service_delegation = object({
          name = string
        actions = list(string) })
      }))
    }))
  }))
  description = "Map of virtual networks"
}

variable "nsgs" {
  description = "Map of NSGs to create"
  type = map(object({
    location            = string
    resource_group_name = string
    security_rules = map(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_address_prefix        = string
      source_port_range            = string
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(list(string))
      destination_port_range       = optional(string)
      destination_port_ranges      = optional(list(string))
    }))
  }))
}


variable "public_ips" {
  description = "Map of public IPs to create"
  type = map(object({
    sku               = string
    allocation_method = string
    domain_name_label = optional(string)
  }))
}

variable "cc_core_acr_name" {
  type        = string
  description = "container registry for McCain Food Manufacturing Digital Shared Azure Components in Canada Central"
}

variable "cc_core_acr_sku" {
  type        = string
  description = "Container Registry SKU for McCain Foods Manufacturing Digital Shared Azure Components in Canada Central"
}
