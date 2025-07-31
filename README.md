
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


-----------------------------------------------------



import azure.functions as func
import json
import logging
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
from azure.identity import AzureCliCredential, DefaultAzureCredential
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.resource import ResourceManagementClient
from typing import Dict, List, Tuple, Optional

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Simple GET endpoint for VM optimization analysis
    
    No parameters required - all settings are hardcoded:
    - days_back: 10 days
    - cpu_weight: 0.6
    - disk_weight: 0.4
    - Fetches management groups from database automatically
    
    Usage: Just hit GET https://your-function-url/api/vm-optimization
    """
    
    try:
        # Step 1: Initialize Azure credentials
        logging.info("Initializing Azure credentials...")
        credential = AzureCliCredential()
        
        # Step 2: Hardcoded configuration
        logging.info("Using hardcoded configuration...")
        DAYS_BACK = 10          # Analyze last 10 days
        CPU_WEIGHT = 0.6        # CPU weight in combined score
        DISK_WEIGHT = 0.4       # Disk weight in combined score
        
        logging.info(f"Configuration: {DAYS_BACK} days, CPU weight: {CPU_WEIGHT}, Disk weight: {DISK_WEIGHT}")
        
        # Step 3: Get management groups from database
        logging.info("Fetching management groups from database...")
        management_groups = get_management_groups_from_database()
        logging.info(f"Found {len(management_groups)} management groups to analyze")
        
        # Step 4: Initialize Enterprise VM Optimizer
        logging.info("Initializing Enterprise VM Optimizer...")
        optimizer = EnterpriseVMOptimizer(
            credential=credential,
            cpu_weight=CPU_WEIGHT,
            disk_weight=DISK_WEIGHT
        )
        
        # Step 5: Execute hierarchical analysis
        logging.info(f"Starting hierarchical analysis for {len(management_groups)} management groups...")
        results = optimizer.analyze_management_groups(management_groups, DAYS_BACK)
        
        # Step 6: Return JSON results
        logging.info("Analysis completed successfully")
        return func.HttpResponse(
            json.dumps(results, indent=2, default=str),
            status_code=200,
            mimetype="application/json"
        )
        
    except Exception as e:
        logging.error(f"Error in VM optimization analysis: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e), "timestamp": datetime.utcnow().isoformat()}),
            status_code=500,
            mimetype="application/json"
        )


def get_management_groups_from_database() -> List[Dict]:
    """
    Fetch management groups from your database
    
    TODO: Replace this with your actual database connection logic
    
    Returns:
        List of management group dictionaries
    """
    # Example database connection logic - replace with your actual implementation
    try:
        # Option 1: Direct database connection
        import pyodbc  # or your preferred database library
        
        # Replace with your database connection string
        conn_string = "your_database_connection_string"
        
        with pyodbc.connect(conn_string) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT mg_id, mg_name FROM management_groups WHERE active = 1")
            
            management_groups = []
            for row in cursor.fetchall():
                management_groups.append({
                    "mg_id": row.mg_id,
                    "name": row.mg_name
                })
            
            return management_groups
    
    except Exception as e:
        logging.error(f"Error fetching management groups from database: {str(e)}")
        # Fallback to hardcoded list or raise exception
        raise Exception(f"Database connection failed: {str(e)}")


class EnterpriseVMOptimizer:
    """
    Enterprise-level VM optimizer that handles management group hierarchies
    """
    
    def __init__(self, credential, cpu_weight: float = 0.6, disk_weight: float = 0.4):
        """
        Initialize the Enterprise VM Optimizer
        
        Args:
            credential: Azure credential object
            cpu_weight: Weight for CPU usage in combined score
            disk_weight: Weight for disk usage in combined score
        """
        self.credential = credential
        self.cpu_weight = cpu_weight
        self.disk_weight = disk_weight
        
        # Initialize management client for management groups
        from azure.mgmt.managementgroups import ManagementGroupsAPI
        self.mg_client = ManagementGroupsAPI(credential)
        
        logging.info("Enterprise VM Optimizer initialized successfully")
    
    def analyze_management_groups(self, management_groups: List[Dict], days_back: int) -> Dict:
        """
        Analyze VMs across multiple management groups
        
        Args:
            management_groups: List of management group information
            days_back: Number of days to analyze
            
        Returns:
            Comprehensive analysis results across all management groups
        """
        try:
            results = {
                "analysis_summary": {
                    "analysis_date": datetime.utcnow().isoformat(),
                    "days_analyzed": days_back,
                    "management_groups_analyzed": len(management_groups),
                    "cpu_weight": self.cpu_weight,
                    "disk_weight": self.disk_weight
                },
                "management_group_results": {}
            }
            
            total_vms_analyzed = 0
            total_subscriptions = 0
            
            # Analyze each management group
            for mg in management_groups:
                logging.info(f"Analyzing Management Group: {mg['name']} ({mg['mg_id']})")
                
                try:
                    # Step 1: Get all subscriptions in this management group
                    subscriptions = self._get_subscriptions_in_mg(mg['mg_id'])
                    logging.info(f"Found {len(subscriptions)} subscriptions in MG: {mg['name']}")
                    
                    # Step 2: Analyze all subscriptions in this MG
                    mg_results = self.analyze_subscriptions(
                        [sub['subscription_id'] for sub in subscriptions], 
                        days_back
                    )
                    
                    # Step 3: Add MG-specific metadata
                    mg_results["management_group_info"] = {
                        "mg_id": mg['mg_id'],
                        "mg_name": mg['name'],
                        "subscriptions_count": len(subscriptions)
                    }
                    
                    results["management_group_results"][mg['mg_id']] = mg_results
                    
                    # Update totals
                    total_subscriptions += len(subscriptions)
                    total_vms_analyzed += mg_results["analysis_summary"]["total_vms_analyzed"]
                    
                except Exception as mg_error:
                    logging.error(f"Error analyzing MG {mg['mg_id']}: {str(mg_error)}")
                    results["management_group_results"][mg['mg_id']] = {
                        "error": f"Management group analysis failed: {str(mg_error)}"
                    }
            
            # Update overall summary
            results["analysis_summary"]["total_subscriptions"] = total_subscriptions
            results["analysis_summary"]["total_vms_analyzed"] = total_vms_analyzed
            
            return results
            
        except Exception as e:
            logging.error(f"Error in analyze_management_groups: {str(e)}")
            raise
    
    def analyze_subscriptions(self, subscription_ids: List[str], days_back: int) -> Dict:
        """
        Analyze VMs across multiple subscriptions
        
        Args:
            subscription_ids: List of subscription IDs to analyze
            days_back: Number of days to analyze
            
        Returns:
            Analysis results across all subscriptions
        """
        try:
            results = {
                "analysis_summary": {
                    "analysis_date": datetime.utcnow().isoformat(),
                    "days_analyzed": days_back,
                    "subscriptions_analyzed": len(subscription_ids),
                    "total_vms_analyzed": 0,
                    "cpu_weight": self.cpu_weight,
                    "disk_weight": self.disk_weight
                },
                "subscription_results": {}
            }
            
            # Analyze each subscription
            for subscription_id in subscription_ids:
                logging.info(f"Analyzing Subscription: {subscription_id}")
                
                try:
                    # Create VM optimizer for this subscription
                    vm_optimizer = VMOptimizer(
                        subscription_id=subscription_id,
                        credential=self.credential,
                        cpu_weight=self.cpu_weight,
                        disk_weight=self.disk_weight
                    )
                    
                    # Analyze VMs in this subscription
                    subscription_results = vm_optimizer.analyze_vms(days_back)
                    
                    results["subscription_results"][subscription_id] = subscription_results
                    results["analysis_summary"]["total_vms_analyzed"] += \
                        subscription_results["analysis_summary"]["eligible_vms_analyzed"]
                        
                except Exception as sub_error:
                    logging.error(f"Error analyzing subscription {subscription_id}: {str(sub_error)}")
                    results["subscription_results"][subscription_id] = {
                        "error": f"Subscription analysis failed: {str(sub_error)}"
                    }
            
            return results
            
        except Exception as e:
            logging.error(f"Error in analyze_subscriptions: {str(e)}")
            raise
    
    def _get_subscriptions_in_mg(self, mg_id: str) -> List[Dict]:
        """
        Get all subscriptions in a management group
        
        Args:
            mg_id: Management group ID
            
        Returns:
            List of subscription information
        """
        try:
            subscriptions = []
            
            # Get management group details including subscriptions
            mg_details = self.mg_client.management_groups.get(
                group_id=mg_id,
                expand="children",
                recurse=True
            )
            
            # Extract subscriptions from the management group hierarchy
            def extract_subscriptions(entity):
                if entity.type == "/subscriptions":
                    subscriptions.append({
                        "subscription_id": entity.name,
                        "display_name": entity.display_name,
                        "management_group_id": mg_id
                    })
                elif hasattr(entity, 'children') and entity.children:
                    for child in entity.children:
                        extract_subscriptions(child)
            
            # Process the management group hierarchy
            if hasattr(mg_details, 'children') and mg_details.children:
                for child in mg_details.children:
                    extract_subscriptions(child)
            
            logging.info(f"Found {len(subscriptions)} subscriptions in MG {mg_id}")
            return subscriptions
            
        except Exception as e:
            logging.error(f"Error fetching subscriptions for MG {mg_id}: {str(e)}")
            return []


class VMOptimizer:
    """
    Core class for VM optimization analysis
    """
    
    def __init__(self, subscription_id: str, credential, cpu_weight: float = 0.6, disk_weight: float = 0.4):
        """
        Initialize the VM Optimizer with Azure clients
        
        Args:
            subscription_id: Azure subscription ID
            credential: Azure credential object
            cpu_weight: Weight for CPU usage in combined score
            disk_weight: Weight for disk usage in combined score
        """
        self.subscription_id = subscription_id
        self.credential = credential
        self.cpu_weight = cpu_weight
        self.disk_weight = disk_weight
        
        # Initialize Azure management clients
        self.monitor_client = MonitorManagementClient(credential, subscription_id)
        self.compute_client = ComputeManagementClient(credential, subscription_id)
        self.resource_client = ResourceManagementClient(credential, subscription_id)
        
        logging.info("VM Optimizer initialized successfully")
    
    def analyze_vms(self, days_back: int = 10) -> Dict:
        """
        Main analysis function - analyzes all eligible VMs
        
        Args:
            days_back: Number of days to analyze
            
        Returns:
            Dictionary containing analysis results for all VMs
        """
        try:
            # Step 1: Get all VMs in subscription
            logging.info("Fetching all VMs in subscription...")
            all_vms = self._get_all_vms()
            logging.info(f"Found {len(all_vms)} total VMs")
            
            # Step 2: Filter out AKS and Databricks VMs
            logging.info("Filtering out managed service VMs...")
            eligible_vms = self._filter_eligible_vms(all_vms)
            logging.info(f"Found {len(eligible_vms)} eligible VMs for analysis")
            
            # Step 3: Analyze each VM
            results = {
                "analysis_summary": {
                    "subscription_id": self.subscription_id,
                    "analysis_date": datetime.utcnow().isoformat(),
                    "days_analyzed": days_back,
                    "total_vms_found": len(all_vms),
                    "eligible_vms_analyzed": len(eligible_vms),
                    "cpu_weight": self.cpu_weight,
                    "disk_weight": self.disk_weight
                },
                "vm_recommendations": {}
            }
            
            for vm in eligible_vms:
                logging.info(f"Analyzing VM: {vm['name']}")
                try:
                    vm_analysis = self._analyze_single_vm(vm, days_back)
                    results["vm_recommendations"][vm['name']] = vm_analysis
                except Exception as vm_error:
                    logging.error(f"Error analyzing VM {vm['name']}: {str(vm_error)}")
                    results["vm_recommendations"][vm['name']] = {
                        "error": f"Analysis failed: {str(vm_error)}"
                    }
            
            return results
            
        except Exception as e:
            logging.error(f"Error in analyze_vms: {str(e)}")
            raise
    
    def _get_all_vms(self) -> List[Dict]:
        """
        Get all VMs in the subscription
        
        Returns:
            List of VM information dictionaries
        """
        vms = []
        try:
            for vm in self.compute_client.virtual_machines.list_all():
                vm_info = {
                    'name': vm.name,
                    'resource_group': vm.id.split('/')[4],
                    'location': vm.location,
                    'vm_size': vm.hardware_profile.vm_size,
                    'resource_id': vm.id,
                    'tags': vm.tags or {}
                }
                vms.append(vm_info)
            
            return vms
            
        except Exception as e:
            logging.error(f"Error fetching VMs: {str(e)}")
            raise
    
    def _filter_eligible_vms(self, all_vms: List[Dict]) -> List[Dict]:
        """
        Filter out AKS and Databricks VMs
        
        Args:
            all_vms: List of all VMs
            
        Returns:
            List of eligible VMs for optimization
        """
        eligible_vms = []
        
        for vm in all_vms:
            # Skip AKS VMs
            if self._is_aks_vm(vm):
                logging.info(f"Skipping AKS VM: {vm['name']}")
                continue
            
            # Skip Databricks VMs
            if self._is_databricks_vm(vm):
                logging.info(f"Skipping Databricks VM: {vm['name']}")
                continue
            
            # VM is eligible for analysis
            eligible_vms.append(vm)
        
        return eligible_vms
    
    def _is_aks_vm(self, vm: Dict) -> bool:
        """
        Check if VM is part of AKS cluster
        
        Args:
            vm: VM information dictionary
            
        Returns:
            True if VM is AKS-managed
        """
        # Check resource group name (AKS creates RGs with MC_ prefix)
        if vm['resource_group'].startswith('MC_'):
            return True
        
        # Check tags for Kubernetes-related tags
        tags = vm.get('tags', {})
        aks_indicators = ['kubernetes.io', 'k8s.io', 'aks-managed']
        
        for tag_key in tags.keys():
            if any(indicator in tag_key.lower() for indicator in aks_indicators):
                return True
        
        return False
    
    def _is_databricks_vm(self, vm: Dict) -> bool:
        """
        Check if VM is part of Databricks cluster
        
        Args:
            vm: VM information dictionary
            
        Returns:
            True if VM is Databricks-managed
        """
        # Check resource group name
        if 'databricks' in vm['resource_group'].lower():
            return True
        
        # Check VM name
        if 'databricks' in vm['name'].lower():
            return True
        
        # Check tags
        tags = vm.get('tags', {})
        for tag_key, tag_value in tags.items():
            if 'databricks' in tag_key.lower() or 'databricks' in str(tag_value).lower():
                return True
        
        return False
    
    def _analyze_single_vm(self, vm: Dict, days_back: int) -> Dict:
        """
        Analyze a single VM for optimization opportunities
        
        Args:
            vm: VM information dictionary
            days_back: Number of days to analyze
            
        Returns:
            Dictionary containing VM analysis results
        """
        try:
            # Step 1: Get VM metrics for the specified period
            logging.info(f"Fetching metrics for VM: {vm['name']}")
            metrics_data = self._get_vm_metrics(vm['resource_id'], days_back)
            
            if not metrics_data:
                return {"error": "No metrics data available for this VM"}
            
            # Step 2: Process daily recommendations
            daily_recommendations = []
            
            # Group data by day and analyze each day
            for day_data in self._group_by_days(metrics_data):
                day_analysis = self._analyze_single_day(day_data)
                daily_recommendations.append(day_analysis)
            
            # Step 3: Calculate summary statistics
            total_potential_savings = sum(
                day['hours_saved'] for day in daily_recommendations 
                if day['recommendation'] != 'Keep Running'
            )
            
            savings_opportunities = len([
                day for day in daily_recommendations 
                if day['recommendation'] != 'Keep Running'
            ])
            
            # Step 4: Return comprehensive analysis
            return {
                "vm_info": {
                    "name": vm['name'],
                    "resource_group": vm['resource_group'],
                    "vm_size": vm['vm_size'],
                    "location": vm['location']
                },
                "analysis_period": {
                    "days_analyzed": days_back,
                    "weekdays_only": True
                },
                "summary": {
                    "total_potential_hours_saved": total_potential_savings,
                    "days_with_savings_opportunity": savings_opportunities,
                    "total_days_analyzed": len(daily_recommendations)
                },
                "daily_recommendations": daily_recommendations
            }
            
        except Exception as e:
            logging.error(f"Error analyzing VM {vm['name']}: {str(e)}")
            raise
    
    def _get_vm_metrics(self, resource_id: str, days_back: int) -> List[Dict]:
        """
        Get VM metrics from Azure Monitor
        
        Args:
            resource_id: VM resource ID
            days_back: Number of days to fetch
            
        Returns:
            List of metric data points
        """
        try:
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=days_back)
            
            # Define metrics to collect
            metrics_to_collect = [
                'Percentage CPU',
                'Disk Read Bytes/sec',
                'Disk Write Bytes/sec',
                'Network In Total',
                'Network Out Total'
            ]
            
            all_metrics_data = []
            
            for metric_name in metrics_to_collect:
                try:
                    # Get metric data from Azure Monitor
                    metrics = self.monitor_client.metrics.list(
                        resource_uri=resource_id,
                        timespan=f"{start_time.isoformat()}/{end_time.isoformat()}",
                        interval='PT1H',  # 1-hour intervals
                        metricnames=metric_name,
                        aggregation='Average'
                    )
                    
                    # Process metric data
                    for metric in metrics.value:
                        for timeseries in metric.timeseries:
                            for data_point in timeseries.data:
                                if data_point.average is not None:
                                    metric_entry = {
                                        'timestamp': data_point.time_stamp,
                                        'metric_name': metric_name,
                                        'value': data_point.average
                                    }
                                    all_metrics_data.append(metric_entry)
                
                except Exception as metric_error:
                    logging.warning(f"Could not fetch {metric_name}: {str(metric_error)}")
                    continue
            
            return all_metrics_data
            
        except Exception as e:
            logging.error(f"Error fetching VM metrics: {str(e)}")
            return []
    
    def _group_by_days(self, metrics_data: List[Dict]) -> List[Dict]:
        """
        Group metrics data by day
        
        Args:
            metrics_data: List of metric data points
            
        Returns:
            List of daily metric summaries
        """
        # Convert to DataFrame for easier processing
        df = pd.DataFrame(metrics_data)
        
        if df.empty:
            return []
        
        # Group by date
        df['date'] = pd.to_datetime(df['timestamp']).dt.date
        df['hour'] = pd.to_datetime(df['timestamp']).dt.hour
        
        daily_data = []
        
        for date, day_group in df.groupby('date'):
            # Skip weekends
            if pd.to_datetime(date).weekday() >= 5:  # 5=Saturday, 6=Sunday
                continue
            
            # Create hourly summary for this day
            hourly_data = {}
            
            for hour in range(24):
                hour_data = day_group[day_group['hour'] == hour]
                
                # Calculate combined score for this hour
                cpu_val = hour_data[hour_data['metric_name'] == 'Percentage CPU']['value']
                disk_read = hour_data[hour_data['metric_name'] == 'Disk Read Bytes/sec']['value'] 
                disk_write = hour_data[hour_data['metric_name'] == 'Disk Write Bytes/sec']['value']
                
                # Handle missing data
                cpu_pct = cpu_val.iloc[0] if len(cpu_val) > 0 else 0
                disk_total = (disk_read.iloc[0] if len(disk_read) > 0 else 0) + \
                           (disk_write.iloc[0] if len(disk_write) > 0 else 0)
                
                # Convert disk bytes/sec to percentage (normalize to 0-100 range)
                # This is a simplified conversion - adjust based on your VM's disk capacity
                disk_pct = min(disk_total / 1000000, 100)  # Rough conversion
                
                combined_score = (cpu_pct * self.cpu_weight) + (disk_pct * self.disk_weight)
                
                hourly_data[hour] = {
                    'cpu_percent': cpu_pct,
                    'disk_percent': disk_pct,
                    'combined_score': combined_score
                }
            
            daily_data.append({
                'date': date,
                'hourly_data': hourly_data
            })
        
        return daily_data
    
    def _analyze_single_day(self, day_data: Dict) -> Dict:
        """
        Analyze a single day and provide start/stop recommendations
        
        Args:
            day_data: Dictionary containing hourly data for one day
            
        Returns:
            Dictionary with daily analysis results
        """
        hourly_scores = [hour_info['combined_score'] for hour_info in day_data['hourly_data'].values()]
        
        if not hourly_scores:
            return {
                "date": str(day_data['date']),
                "recommendation": "Keep Running",
                "reason": "No data available"
            }
        
        # Calculate daily statistics
        daily_stats = {
            'min': min(hourly_scores),
            'max': max(hourly_scores),
            'avg': np.mean(hourly_scores),
            'std': np.std(hourly_scores)
        }
        
        # Calculate dynamic threshold for this day
        if daily_stats['max'] <= 20:
            # Low usage day - use relative threshold
            threshold = daily_stats['avg'] * 0.5
        else:
            # Normal usage day - use range-based threshold
            threshold = daily_stats['min'] + (daily_stats['max'] - daily_stats['min']) * 0.3
        
        # Find idle hours (below threshold)
        idle_hours = []
        for hour, hour_data in day_data['hourly_data'].items():
            if hour_data['combined_score'] < threshold:
                idle_hours.append(hour)
        
        # Find consecutive idle periods
        consecutive_periods = self._find_consecutive_periods(idle_hours)
        
        # Find longest period >= 2 hours
        valid_periods = [period for period in consecutive_periods if len(period) >= 2]
        
        if not valid_periods:
            return {
                "date": str(day_data['date']),
                "daily_stats": daily_stats,
                "threshold_used": threshold,
                "recommendation": "Keep Running",
                "reason": "No consecutive idle period >= 2 hours found",
                "hours_saved": 0
            }
        
        # Get the longest valid period
        longest_period = max(valid_periods, key=len)
        stop_time = f"{longest_period[0]:02d}:00"
        start_time = f"{longest_period[-1] + 1:02d}:00"  # +1 to start after idle period
        hours_saved = len(longest_period)
        
        return {
            "date": str(day_data['date']),
            "daily_stats": daily_stats,
            "threshold_used": threshold,
            "recommendation": f"Stop {stop_time}, Start {start_time}",
            "hours_saved": hours_saved,
            "idle_period": {
                "start_hour": longest_period[0],
                "end_hour": longest_period[-1],
                "duration_hours": hours_saved
            }
        }
    
    def _find_consecutive_periods(self, hours_list: List[int]) -> List[List[int]]:
        """
        Find consecutive periods in a list of hours
        
        Args:
            hours_list: List of hours (0-23)
            
        Returns:
            List of consecutive hour periods
        """
        if not hours_list:
            return []
        
        sorted_hours = sorted(hours_list)
        consecutive_periods = []
        current_period = [sorted_hours[0]]
        
        for i in range(1, len(sorted_hours)):
            if sorted_hours[i] == sorted_hours[i-1] + 1:
                current_period.append(sorted_hours[i])
            else:
                consecutive_periods.append(current_period)
                current_period = [sorted_hours[i]]
        
        consecutive_periods.append(current_period)
        return consecutive_periods
