import azure.functions as func
import logging
import json
import pyodbc
from azure.identity import ManagedIdentityCredential
from azure.mgmt.managementgroups import ManagementGroupsAPI
from azure.mgmt.resource import SubscriptionClient
from azure.mgmt.compute import ComputeManagementClient


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Starting Azure Function to fetch VMs by MG -> Subs -> VMs using UAMI")

    try:
        # Step 1: Authenticate using User Assigned Managed Identity
        USER_ASSIGNED_CLIENT_ID = "<your-user-assigned-client-id>"  # replace with your UAMI client ID
        credential = ManagedIdentityCredential(client_id=USER_ASSIGNED_CLIENT_ID)

        # Step 2: Connect to SQL DB and fetch Management Group IDs
        conn_str = (
            "Driver={ODBC Driver 17 for SQL Server};"
            "Server=tcp:hjshjdfhsdjfhjhj.database.windows.net,1433;"
            "Database=metadata;"
            "Uid=rdsjkdataadmin;"
            "Pwd=ejhjhsrhjdhfjh;"
            "Encrypt=yes;"
            "TrustServerCertificate=no;"
            "Connection Timeout=30;"
        )

        mg_ids = []
        with pyodbc.connect(conn_str) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT mg_id FROM Management_Groups WHERE env_type = 'lower';")
            for row in cursor.fetchall():
                mg_ids.append(row.mg_id)

        # Step 3: Initialize clients
        mgmt_group_client = ManagementGroupsAPI(credential)
        subscription_client = SubscriptionClient(credential)

        vm_details = []

        for mg_id in mg_ids:
            try:
                mg_details = mgmt_group_client.management_groups.get(group_id=mg_id, expand="children", recurse=True)
                subscriptions = []

                def extract_subscriptions(entity):
                    if entity.type == "/subscriptions":
                        subscriptions.append(entity.name)
                    elif hasattr(entity, 'children') and entity.children:
                        for child in entity.children:
                            extract_subscriptions(child)

                if hasattr(mg_details, 'children') and mg_details.children:
                    for child in mg_details.children:
                        extract_subscriptions(child)

                # Step 4: For each subscription, get VMs
                for sub_id in subscriptions:
                    compute_client = ComputeManagementClient(credential, sub_id)
                    for vm in compute_client.virtual_machines.list_all():
                        vm_details.append({
                            "mg_id": mg_id,
                            "subscription_id": sub_id,
                            "vm_name": vm.name,
                            "resource_group": vm.id.split("/")[4],
                            "location": vm.location,
                            "vm_size": vm.hardware_profile.vm_size
                        })

            except Exception as ex:
                logging.warning(f"Skipping MG {mg_id} due to error: {str(ex)}")
                continue

        return func.HttpResponse(json.dumps(vm_details, indent=2), mimetype="application/json", status_code=200)

    except Exception as e:
        logging.error(f"Function error: {str(e)}")
        return func.HttpResponse(f"Error: {str(e)}", status_code=500)
