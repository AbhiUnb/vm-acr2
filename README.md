  webapp_test.go:41: ✅ PASS: Web App name output is not empty
    webapp_test.go:46: ✅ PASS: Resource group output is not empty
    webapp_test.go:24: ✅ Step 3: Fetched Web App: {DefaultHostName:mf-mdi-cc-core-prod-webapp-terra.azurewebsites.net ServerFarmID: Identity:{Type:SystemAssigned}}
    webapp_test.go:24: ✅ Step 4: Web App Hostname: mf-mdi-cc-core-prod-webapp-terra.azurewebsites.net
    webapp_test.go:73: ✅ PASS: Web App Hostname is not empty
TestAzureWebAppDeployment 2025-06-26T16:18:43-03:00 retry.go:91: terraform [output -no-color -json app_service_plan_id]
TestAzureWebAppDeployment 2025-06-26T16:18:43-03:00 logger.go:67: Running command terraform with args [output -no-color -json app_service_plan_id]
TestAzureWebAppDeployment 2025-06-26T16:18:43-03:00 logger.go:67: "/subscriptions/5d36b86e-695f-427b-9a19-7a6cc2db39d6/resourceGroups/MF_MDIxMI_TerraTest/providers/Microsoft.Web/serverFarms/MF_DM_CC_CORE_PROD-appSP"
    webapp_test.go:24: ✅ Step 5: Service Plan ID (from output): /subscriptions/5d36b86e-695f-427b-9a19-7a6cc2db39d6/resourceGroups/MF_MDIxMI_TerraTest/providers/Microsoft.Web/serverFarms/MF_DM_CC_CORE_PROD-appSP
    webapp_test.go:83: ✅ PASS: App Service Plan ID is not empty
    webapp_test.go:114: ✅ PASS: Web App exists
    webapp_test.go:24: ✅ Step 1: Verified Web App existence
TestAzureWebAppDeployment 2025-06-26T16:18:47-03:00 retry.go:91: HTTP GET to URL https://mf-mdi-cc-core-prod-webapp-terra.azurewebsites.net
TestAzureWebAppDeployment 2025-06-26T16:18:47-03:00 http_helper.go:58: Making an HTTP GET call to URL https://mf-mdi-cc-core-prod-webapp-terra.azurewebsites.net
    webapp_test.go:24: ✅ Step 2: HTTPS availability test passed
    webapp_test.go:150: ✅ PASS: App setting WEBSITE_NODE_DEFAULT_VERSION exists
    webapp_test.go:24: ✅ Step 6: Verified app setting WEBSITE_NODE_DEFAULT_VERSION exists
    webapp_test.go:158: ✅ PASS: Identity is SystemAssigned
    webapp_test.go:24: ✅ Step 7: Validated identity is SystemAssigned
    webapp_test.go:166: ✅ PASS: App Service Plan SKU is S3
    webapp_test.go:24: ✅ Step 8: Confirmed App Service Plan SKU is S3
    webapp_test.go:245: ✅ PASS: Tag 'Onboard Date' has expected value '12/19/2024'
    webapp_test.go:245: ✅ PASS: Tag 'Organization' has expected value 'McCain Foods Limited'
    webapp_test.go:245: ✅ PASS: Tag 'Resource Owner' has expected value 'trilok.tater@mccain.ca'
    webapp_test.go:245: ✅ PASS: Tag 'Business Owner' has expected value 'trilok.tater@mccain.ca'
    webapp_test.go:245: ✅ PASS: Tag 'Environment' has expected value 'sandbox'
    webapp_test.go:245: ✅ PASS: Tag 'IT Owner' has expected value 'mccain-azurecontributor@mccain.ca'
    webapp_test.go:245: ✅ PASS: Tag 'Resource Posture' has expected value 'Private'
    webapp_test.go:245: ✅ PASS: Tag 'Resource Type' has expected value 'Terraform POC'
    webapp_test.go:245: ✅ PASS: Tag 'Application Name' has expected value 'McCain DevSecOps'
    webapp_test.go:245: ✅ PASS: Tag 'Built Using' has expected value 'Terraform'
    webapp_test.go:245: ✅ PASS: Tag 'GL Code' has expected value 'N/A'
    webapp_test.go:245: ✅ PASS: Tag 'Implemented by' has expected value 'trilok.tater@mccain.ca'
    webapp_test.go:245: ✅ PASS: Tag 'Modified Date' has expected value 'N/A'
    webapp_test.go:24: ✅ Step 11: Validated App Service Plan tags
    webapp_test.go:24: ✅ Step 9: Validate Deployment Source - Skipped (requires custom pipeline or API check)
    webapp_test.go:24: ✅ Step 10: Validate Diagnostic Logs - Skipped (requires Log Analytics/API validation)
--- PASS: TestAzureWebAppDeployment (11.30s)
PASS
ok      webapp-test     11.704s
