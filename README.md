
@startuml
title **Azure VM Stop/Start Automation Roadmap with Challenges**

skinparam note {
  BackgroundColor #FDF6E3
  BorderColor #586E75
}

skinparam title {
  BackgroundColor #268BD2
  FontColor white
}

start

:🔷 Phase 0: Goal Clarification;
note right
🎯 Objective: Automate Excel reports recommending VM stop/start times
✅ Design: Azure Monitor + Azure Function (no Log Analytics)
end note

:🔷 Phase 1: Environment Setup;
note right
📝 Tasks:
- Create test VM (B1S x64)
- Enable guest diagnostics

⚠️ Challenges:
- ARM64 image incompatibility
- Free tier regional quota limits
end note

:🔷 Phase 2: Metric Verification;
note right
📝 Tasks:
- Verify metrics in Azure Monitor
  • CPU
  • Memory (guest agent)
  • Disk IO
  • Network

⚠️ Challenges:
- Metrics delayed 5-10 mins post-deployment
- Missing guest agent blocks memory/disk metrics
end note

:🔷 Phase 3: Azure Function Setup;
note right
📝 Tasks:
- Deploy Python Function App
- Enable managed identity
- Assign Monitoring Reader role

⚠️ Challenges:
- VNet integration issues
- RBAC permission propagation delays
end note

:🔷 Phase 4: Develop Function Logic;
note right
📝 Tasks:
- MVP: Query CPU metric, return JSON
- Full: Process all metrics, apply thresholds
- Generate Excel report with pandas/openpyxl

⚠️ Challenges:
- API rate limits with many VMs
- Function timeout on large datasets
end note

:🔷 Phase 5: Testing;
note right
📝 Tasks:
- Unit tests (metric queries)
- End-to-end tests (Excel output)

⚠️ Challenges:
- Data gaps if metrics missing
- Timezone consistency (UTC vs local business hours)
end note

:🔷 Phase 6: Optimization & Security;
note right
📝 Tasks:
- Optimize API calls
- Secure HTTP trigger endpoint

⚠️ Challenges:
- Managed identity secret rotation (if used)
- Key Vault integration if secrets introduced
end note

:🔷 Phase 7: Production Scaling;
note right
📝 Tasks:
- Scale to multiple VMs dynamically
- Integrate email delivery (SendGrid/Graph API)
- Document and seek governance approvals

⚠️ Challenges:
- API call limits at scale
- Approvals for automated stop/start actions
end note

stop

@enduml
-----------------------------
locals {
  # Custom Policy Definitions
  vm_custom_policies = {
    "mf-dt-vm-tags-01" = {
      definition = {
        name         = "mf-dt-vm-tags-01-deny-vm-missing-parking-tags"
        mode         = "Indexed"
        display_name = "mf-dt-vm-tags-01-Deny Azure VMs without required parking tags or invalid Parking Category"
        description  = "Ensure Azure VMs have 'Parking start time', 'Parking end time', and a valid 'Parking Category' tag that is not 'NotParked'."
        category     = "Tags"
        version      = "1.1.0"
        parameters = {
          effect = {
            type = "String"
            metadata = {
              displayName = "Effect",
              description = "The effect determines what happens when the policy rule is evaluated to match"
            },
            allowedValues = [
              "Audit",
              "Deny",
              "Disabled"
            ],
            defaultValue = "Deny"
          }
        }
        policy_rule = {
          if = {
            allOf = [
              {
                field  = "type"
                equals = "Microsoft.Compute/virtualMachines"
              },
              {
                anyOf = [
                  {
                    anyOf = [
                      { field = "tags['Parking start time']", exists = false },
                      { field = "tags['Parking start time']", equals = "" }
                    ]
                  },
                  {
                    anyOf = [
                      { field = "tags['Parking end time']", exists = false },
                      { field = "tags['Parking end time']", equals = "" }
                    ]
                  },
                  {
                    anyOf = [
                      { field = "tags['Parking Category']", exists = false },
                      { field = "tags['Parking Category']", equals = "" },
                      { field = "tags['Parking Category']", equals = "NotParked" }
                    ]
                  }
                ]
              }
            ]
          }
          then = {
            effect = "[parameters('effect')]"
          }
        }
      }
      assignments = {
        "default" = {
          parameters             = {}
          non_compliance_message = "VMs must have Parking start time, Parking end time, and a valid value for Parking Category tag. Also, Parking Category should not bet set to NotParked. Please visit the following link for more information: https://mccainfoodslimited.atlassian.net/wiki/spaces/CC/pages/145621219/Virtual+Machine-Service+Specification#mf-dt-vm-tags-01"
          create_remediation     = contains(var.policies_to_be_remediated, "mf-dt-vm-tags-01")
        }
      }
      audit_assignments = {
        "default" = {
          parameters = {
            effect = "Audit"
          }
          non_compliance_message = "VMs must have Parking start time, Parking end time, and a valid value for Parking Category tag. Also, Parking Category should not bet set to NotParked. Please visit the following link for more information: https://mccainfoodslimited.atlassian.net/wiki/spaces/CC/pages/145621219/Virtual+Machine-Service+Specification#mf-dt-vm-tags-01"
          create_remediation     = false
        }
      }
    }
    "mf-dt-vm-tags-02" = {
      definition = {
        name         = "mf-dt-vm-tags-02-set-default-parking-category-vm"
        mode         = "Indexed"
        display_name = "mf-dt-vm-tags-02-Set default Parking Category tag to 'ParkedDaily' on VMs if missing or incorrect"
        description  = "Ensure that the 'Parking Category' tag on virtual machines is always set to 'ParkedDaily', if it does not exist, or is blank."
        category     = "Tags"
        version      = "1.1.0"
        parameters = {
          tagName = {
            type         = "String"
            defaultValue = "Parking Category"
            metadata = {
              displayName = "Tag Name"
              description = "Name of the tag to add a default value for"
            }
          }
          tagValue = {
            type         = "String"
            defaultValue = "ParkedDaily"
            metadata = {
              displayName = "Tag Value"
              description = "Expected default tag value"
            }
          }
          effect = {
            type = "String"
            metadata = {
              displayName = "Effect",
              description = "The effect determines what happens when the policy rule is evaluated to match"
            },
            allowedValues = [
              "Audit",
              "Modify",
              "Disabled"
            ],
            defaultValue = "Modify"
          }
        }
        policy_rule = {
          if = {
            allOf = [
              {
                field  = "type"
                equals = "Microsoft.Compute/virtualMachines"
              },
              {
                anyOf = [
                  {
                    field  = "[concat('tags[', parameters('tagName'), ']')]"
                    exists = false
                  },
                  {
                    field  = "[concat('tags[', parameters('tagName'), ']')]"
                    equals = ""
                  }
                ]
              }
            ]
          }
          then = {
            effect = "[parameters('effect')]"
            details = {
              roleDefinitionIds = [
                "/providers/microsoft.authorization/roleDefinitions/28608",
                "/providers/microsoft.authorization/roleDefinitions/3f"
              ]
              operations = [
                {
                  operation = "addOrReplace"
                  field     = "[concat('tags[', parameters('tagName'), ']')]"
                  value     = "[parameters('tagValue')]"
                }
              ]
            }
          }
        }
      }
      assignments = {
        "default" = {
          parameters = {
            tagName  = "Parking Category"
            tagValue = "ParkedDaily"
          }
          non_compliance_message = "Parking Category should be set to 'ParkedDaily' by default on all VMs. Please visit the following link for more information: https://mccainfoodslimited.atlassian.net/wiki/spaces/CC/pages/145621219/Virtual+Machine-Service+Specification#mf-dt-vm-tags-02"
          create_remediation     = contains(var.policies_to_be_remediated, "mf-dt-vm-tags-02")
        }
      }
      audit_assignments = {
        "default" = {
          parameters = {
            tagName  = "Parking Category"
            tagValue = "ParkedDaily"
            effect   = "Audit"
          }
          non_compliance_message = "Parking Category should be set to 'ParkedDaily' by default on all VMs. Please visit the following link for more information: https://mccainfoodslimited.atlassian.net/wiki/spaces/CC/pages/145621219/Virtual+Machine-Service+Specification#mf-dt-vm-tags-02"
          create_remediation     = false
        }
      }
    }
    "mf-dt-vm-finops-01" = {
      definition = {
        name         = "mf-dt-vm-finops-01-Ensure AHUB are enabled for VMs"
        mode         = "Indexed"
        display_name = "mf-dt-vm-finops-01-Ensure hybrid benefits are enabled for virtual machines"
        description  = "This policy ensures that hybrid benefits are enabled for virtual machines."
        category     = "Virtual Machines"
        version      = "1.0.0"
        parameters = {
          effect = {
            type = "String"
            metadata = {
              displayName = "Effect",
              description = "The effect determines what happens when the policy rule is evaluated to match"
            },
            allowedValues = [
              "Audit",
              "Modify",
              "Disabled"
            ],
            defaultValue = "Modify"
          }
        },
        policy_rule = {
          if = {
            allOf = [
              {
                field  = "type",
                equals = "Microsoft.Compute/virtualMachines"
              },
              {
                field  = "Microsoft.Compute/imagePublisher",
                equals = "MicrosoftWindowsServer"
              },
              {
                field     = "Microsoft.Compute/virtualMachines/licenseType",
                notEquals = "Windows_Server"
              }
            ]
          },
          then = {
            effect = "[parameters('effect')]",
            details = {
              roleDefinitionIds = [
                "/providers/microsoft.authorization/roleDefinitions/9980e02c-
                c"
              ],
              operations = [
                {
                  operation = "addOrReplace",
                  field     = "Microsoft.Compute/virtualMachines/licenseType",
                  value     = "Windows_Server"
                }
              ]
            }
          }
        }
      }
      assignments = {
        "default" = {
          parameters             = {}
          non_compliance_message = "This policy ensures that hybrid benefits are enabled for Windows virtual machines. Please refer the following link for information regarding this policy: https://mccainfoodslimited.atlassian.net/wiki/spaces/CC/pages/145621219/Virtual+Machine-Service+Specification#mf-dt-vm-finops-01"
          create_remediation     = contains(var.policies_to_be_remediated, "mf-dt-vm-finops-01")
        }
      }
      audit_assignments = {
        "default" = {
          parameters = {
            effect = "Audit"
          }
          non_compliance_message = "This policy ensures that hybrid benefits are enabled for Windows virtual machines. Please refer the following link for information regarding this policy: https://mccainfoodslimited.atlassian.net/wiki/spaces/CC/pages/145621219/Virtual+Machine-Service+Specification#mf-dt-vm-finops-01"
          create_remediation     = false
        }
      }
    }
    "mf-dt-vm-finops-02" : {
      definition = {
        name         = "mf-dt-vm-finops-02-Allow only A,B,D, and E VM SKUs up to 4C 16GB"
        mode         = "All"
        display_name = "mf-dt-vm-finops-02-Allow only A, B, D and E series VM SKUs up to 4 vCPUs and 16 GB memory"
        description  = "Only allows creation of virtual machines in A, B, D and E-series SKU where VM has ≤ 4 vCPUs and ≤ 16 GB memory"
        category     = "Compute"
        version      = "1.0.0"
        parameters = {
          allowedSkus = {
            type = "Array"
            metadata = {
              displayName = "Allowed VM SKUs"
              description = "List of allowed VM SKUs (ABDE series only with ≤4 vCPUs and ≤16 GB RAM)"
            }
            defaultValue = [
              "Standard_A1_v2", "Standard_A2_v2", "Standard_A4_v2", "Standard_A2m_v2",
              "Standard_B2ts_v2", "Standard_B2ls_v2", "Standard_B2s_v2", "Standard_B4ls_v2", "Standard_B4s_v2", "Standard_B2ats_v2", "Standard_B2als_v2", "Standard_B2as_v2", "Standard_B4als_v2", "Standard_B4as_v2",
              "Standard_D2s_v6", "Standard_D4s_v6", "Standard_D2ds_v6", "Standard_D4ds_v6", "Standard_D2ls_v6", "Standard_D4ls_v6", "Standard_D2lds_v6", "Standard_D4lds_v6", "Standard_D2as_v6", "Standard_D4as_v6", "Standard_D2ads_v6", "Standard_D4ads_v6", "Standard_D2als_v6", "Standard_D4als_v6", "Standard_D2alds_v6", "Standard_D4alds_v6",
              "Standard_D2_v5", "Standard_D4_v5", "Standard_D2s_v5", "Standard_D4s_v5", "Standard_D2d_v5", "Standard_D4d_v5", "Standard_D2ds_v5", "Standard_D4ds_v5", "Standard_D2as_v5", "Standard_D4as_v5", "Standard_D2ads_v5", "Standard_D4ads_v5", "Standard_D2ls_v5", "Standard_D4ls_v5", "Standard_D2lds_v5", "Standard_D4lds_v5",
              "Standard_DC2as_v5", "Standard_DC4as_v5", "Standard_DC2ads_v5", "Standard_DC4ads_v5",
              "Standard_D2_v4", "Standard_D4_v4", "Standard_D2s_v4", "Standard_D4s_v4", "Standard_D2a_v41", "Standard_D4a_v4", "Standard_D2as_v42", "Standard_D4as_v4", "Standard_D2d_v4", "Standard_D4d_v4", "Standard_D2ds_v4", "Standard_D4ds_v4",
              "Standard_DC1s_v3", "Standard_DC2s_v3", "Standard_DC1ds_v3", "Standard_DC2ds_v3",
              "Standard_DC1s_v2", "Standard_DC2s_v2", "Standard_DC4s_v2",
              "Standard_E2s_v6", "Standard_E2ds_v6", "Standard_E2as_v6", "Standard_E2ads_v6",
              "Standard_E2_v5", "Standard_E2s_v5", "Standard_E2d_v5", "Standard_E2ds_v5", "Standard_E2as_v5", "Standard_E2ads_v5", "Standard_E2ns_v6", "Standard_E2nds_v6",
              "Standard_E2d_v4", "Standard_E2ds_v4", "Standard_E2a_v4", "Standard_E2as_v4", "Standard_E2_v4", "Standard_E2s_v4",
              "Standard_E2bds_v5", "Standard_E2bds_v5", "Standard_E2bs_v5", "Standard_E2bs_v5",
              "Standard_EC2as_v5", "Standard_EC2ads_v5"
            ]
          }
          effect = {
            type = "String"
            metadata = {
              displayName = "Effect",
              description = "The effect determines what happens when the policy rule is evaluated to match"
            },
            allowedValues = [
              "Audit",
              "Deny",
              "Disabled"
            ],
            defaultValue = "Deny"
          }
        }
        policy_rule = {
          if = {
            allOf = [
              {
                field  = "type"
                equals = "Microsoft.Compute/virtualMachines"
              },
              {
                not = {
                  field = "Microsoft.Compute/virtualMachines/sku.name"
                  in    = "[parameters('allowedSkus')]"
                }
              }
            ]
          }
          then = {
            effect = "[parameters('effect')]"
          }
        }
      }
      assignments = {
        default = {
          parameters = {
            allowedSkus = [
              "Standard_A1_v2", "Standard_A2_v2", "Standard_A4_v2", "Standard_A2m_v2",
              "Standard_B2ts_v2", "Standard_B2ls_v2", "Standard_B2s_v2", "Standard_B4ls_v2", "Standard_B4s_v2", "Standard_B2ats_v2", "Standard_B2als_v2", "Standard_B2as_v2", "Standard_B4als_v2", "Standard_B4as_v2",
              "Standard_D2s_v6", "Standard_D4s_v6", "Standard_D2ds_v6", "Standard_D4ds_v6", "Standard_D2ls_v6", "Standard_D4ls_v6", "Standard_D2lds_v6", "Standard_D4lds_v6", "Standard_D2as_v6", "Standard_D4as_v6", "Standard_D2ads_v6", "Standard_D4ads_v6", "Standard_D2als_v6", "Standard_D4als_v6", "Standard_D2alds_v6", "Standard_D4alds_v6",
              "Standard_D2_v5", "Standard_D4_v5", "Standard_D2s_v5", "Standard_D4s_v5", "Standard_D2d_v5", "Standard_D4d_v5", "Standard_D2ds_v5", "Standard_D4ds_v5", "Standard_D2as_v5", "Standard_D4as_v5", "Standard_D2ads_v5", "Standard_D4ads_v5", "Standard_D2ls_v5", "Standard_D4ls_v5", "Standard_D2lds_v5", "Standard_D4lds_v5",
              "Standard_DC2as_v5", "Standard_DC4as_v5", "Standard_DC2ads_v5", "Standard_DC4ads_v5",
              "Standard_D2_v4", "Standard_D4_v4", "Standard_D2s_v4", "Standard_D4s_v4", "Standard_D2a_v41", "Standard_D4a_v4", "Standard_D2as_v42", "Standard_D4as_v4", "Standard_D2d_v4", "Standard_D4d_v4", "Standard_D2ds_v4", "Standard_D4ds_v4",
              "Standard_DC1s_v3", "Standard_DC2s_v3", "Standard_DC1ds_v3", "Standard_DC2ds_v3",
              "Standard_DC1s_v2", "Standard_DC2s_v2", "Standard_DC4s_v2",
              "Standard_E2s_v6", "Standard_E2ds_v6", "Standard_E2as_v6", "Standard_E2ads_v6",
              "Standard_E2_v5", "Standard_E2s_v5", "Standard_E2d_v5", "Standard_E2ds_v5", "Standard_E2as_v5", "Standard_E2ads_v5", "Standard_E2ns_v6", "Standard_E2nds_v6",
              "Standard_E2d_v4", "Standard_E2ds_v4", "Standard_E2a_v4", "Standard_E2as_v4", "Standard_E2_v4", "Standard_E2s_v4",
              "Standard_E2bds_v5", "Standard_E2bds_v5", "Standard_E2bs_v5", "Standard_E2bs_v5",
              "Standard_EC2as_v5", "Standard_EC2ads_v5"
            ]
            effect = "Deny"
          }
          non_compliance_message = "VM SKU must be from A, B, D or E series with ≤4 vCPUs and ≤16 GB RAM in non-production environments. Please refer the following link for information regarding this policy: https://mccainfoodslimited.atlassian.net/wiki/spaces/CC/pages/145621219/Virtual+Machine-Service+Specification#mf-dt-vm-finops-02"
          create_remediation     = contains(var.policies_to_be_remediated, "mf-dt-vm-finops-02")
        }
      }
      audit_assignments = {
        default = {
          parameters = {
            allowedSkus = [
              "Standard_A1_v2", "Standard_A2_v2", "Standard_A4_v2", "Standard_A2m_v2",
              "Standard_B2ts_v2", "Standard_B2ls_v2", "Standard_B2s_v2", "Standard_B4ls_v2", "Standard_B4s_v2", "Standard_B2ats_v2", "Standard_B2als_v2", "Standard_B2as_v2", "Standard_B4als_v2", "Standard_B4as_v2",
              "Standard_D2s_v6", "Standard_D4s_v6", "Standard_D2ds_v6", "Standard_D4ds_v6", "Standard_D2ls_v6", "Standard_D4ls_v6", "Standard_D2lds_v6", "Standard_D4lds_v6", "Standard_D2as_v6", "Standard_D4as_v6", "Standard_D2ads_v6", "Standard_D4ads_v6", "Standard_D2als_v6", "Standard_D4als_v6", "Standard_D2alds_v6", "Standard_D4alds_v6",
              "Standard_D2_v5", "Standard_D4_v5", "Standard_D2s_v5", "Standard_D4s_v5", "Standard_D2d_v5", "Standard_D4d_v5", "Standard_D2ds_v5", "Standard_D4ds_v5", "Standard_D2as_v5", "Standard_D4as_v5", "Standard_D2ads_v5", "Standard_D4ads_v5", "Standard_D2ls_v5", "Standard_D4ls_v5", "Standard_D2lds_v5", "Standard_D4lds_v5",
              "Standard_DC2as_v5", "Standard_DC4as_v5", "Standard_DC2ads_v5", "Standard_DC4ads_v5",
              "Standard_D2_v4", "Standard_D4_v4", "Standard_D2s_v4", "Standard_D4s_v4", "Standard_D2a_v41", "Standard_D4a_v4", "Standard_D2as_v42", "Standard_D4as_v4", "Standard_D2d_v4", "Standard_D4d_v4", "Standard_D2ds_v4", "Standard_D4ds_v4",
              "Standard_DC1s_v3", "Standard_DC2s_v3", "Standard_DC1ds_v3", "Standard_DC2ds_v3",
              "Standard_DC1s_v2", "Standard_DC2s_v2", "Standard_DC4s_v2",
              "Standard_E2s_v6", "Standard_E2ds_v6", "Standard_E2as_v6", "Standard_E2ads_v6",
              "Standard_E2_v5", "Standard_E2s_v5", "Standard_E2d_v5", "Standard_E2ds_v5", "Standard_E2as_v5", "Standard_E2ads_v5", "Standard_E2ns_v6", "Standard_E2nds_v6",
              "Standard_E2d_v4", "Standard_E2ds_v4", "Standard_E2a_v4", "Standard_E2as_v4", "Standard_E2_v4", "Standard_E2s_v4",
              "Standard_E2bds_v5", "Standard_E2bds_v5", "Standard_E2bs_v5", "Standard_E2bs_v5",
              "Standard_EC2as_v5", "Standard_EC2ads_v5"
            ]
            effect = "Audit"
          }
          non_compliance_message = "VM SKU must be from A, B, D or E series with ≤4 vCPUs and ≤16 GB RAM in non-production environments. Please refer the following link for information regarding this policy: https://mccainfoodslimited.atlassian.net/wiki/spaces/CC/pages/145621219/Virtual+Machine-Service+Specification#mf-dt-vm-finops-02"
          create_remediation     = false
        }
      }
