variable "cc_core_acr_name" {
  type = string
  validation {
    condition     = can(regex("^acr[a-z0-9-]+$", var.cc_core_acr_name))
    error_message = "ACR name must follow convention: acr-<app>-<env>"
  }
}

variable "cc_core_resource_group_name" {
  type = string
}

variable "cc_location" {
  type    = string
  default = "eastus"
}

variable "cc_core_acr_sku" {
  type    = string
  default = "Standard"
}

#variable "retention_days" {
# type    = number
#  default = 14
#}

variable "environment" {
  type = string
}

variable "owner" {
  type = string
}

variable "created" {
  type = string
}