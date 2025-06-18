run "acr_name_convention" {
  command = plan

  #variables {
   # cc_core_acr_name = "acrmyappdev"
  #}
  

  assert {
    condition     = can(regex("^acr[a-z0-9-]+$", resource.azurerm_container_registry.this.name))
    error_message = "ACR name must follow convention: acr-<app>-<env>"
  }
}

run "admin_access_enabled" {
  command = plan

  assert {
    condition     = resource.azurerm_container_registry.this.admin_enabled == true
    error_message = "Admin access should be enabled for dev testing"
  }
}

run "tag_owner_present" {
  command = plan

  assert {
    condition     = contains(keys(resource.azurerm_container_registry.this.tags), "owner")
    error_message = "Missing required tag: owner"
  }
}

run "tag_environment_present" {
  command = plan

  assert {
    condition     = contains(keys(resource.azurerm_container_registry.this.tags), "environment")
    error_message = "Missing required tag: environment"
  }
}

run "tag_created_present" {
  command = plan

  assert {
    condition     = contains(keys(resource.azurerm_container_registry.this.tags), "created")
    error_message = "Missing required tag: created"
  }
}

run "sku_is_basic_or_standard" {
  command = plan

  assert {
    condition     = contains(["Basic", "Standard"], resource.azurerm_container_registry.this.sku)
    error_message = "Dev ACR SKU must be Basic or Standard"
  }
}

run "region_is_approved" {
  command = plan

  assert {
    condition     = contains(["eastus", "centralus", "westeurope"], lower(resource.azurerm_container_registry.this.location))
    error_message = "Dev ACR must be deployed in an approved dev region"
  }
}
