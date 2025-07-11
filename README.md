
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
