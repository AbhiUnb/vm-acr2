import azure.functions as func
import json
import logging
from datetime import datetime
import pyodbc

# Azure SDK imports
from azure.identity import ManagedIdentityCredential
from azure.mgmt.managementgroups import ManagementGroupsAPI
from azure.mgmt.resource import SubscriptionClient
from azure.mgmt.compute import ComputeManagementClient

# Configuration for DB connection
DB_SERVER = "hjshjdfhsdjfhjhj.database.windows.net"
DB_NAME = "metadata"
DB_USERNAME = "rdsjkdataadmin"
DB_PASSWORD = "ejhjhsrhjdhfjh"

# User Assigned Managed Identity Client ID
USER_ASSIGNED_CLIENT_ID = "YOUR-USER-ASSIGNED-MSI-CLIENT-ID"

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Starting VM discovery via Management Groups")

    try:
        # Connect to Azure SQL DB using username/password
        conn_str = (
            "Driver={ODBC Driver 17 for SQL Server};"
            f"Server={DB_SERVER};"
            f"Database={DB_NAME};"
            f"Uid={DB_USERNAME};"
            f"Pwd={DB_PASSWORD};"
            "Encrypt=yes;"
            "TrustServerCertificate=no;"
            "Connection Timeout=30;"
        )

        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        cursor.execute("SELECT mg_id FROM Managment_Groups WHERE env_type = 'lower'")
        rows = cursor.fetchall()
        mg_ids = [row.mg_id for row in rows]

        logging.info(f"Fetched {len(mg_ids)} management groups from DB")

        # Authenticate with UAMI
        credential = ManagedIdentityCredential(client_id=USER_ASSIGNED_CLIENT_ID)
        mg_client = ManagementGroupsAPI(credential)
        subscription_client = SubscriptionClient(credential)

        all_results = []

        for mg_id in mg_ids:
            try:
                mg_details = mg_client.management_groups.get(group_id=mg_id, expand="children", recurse=True)
                subscriptions = []

                def extract_subscriptions(entity):
                    if entity.type == "/subscriptions":
                        subscriptions.append(entity.name)
                    elif hasattr(entity, 'children'):
                        for child in entity.children:
                            extract_subscriptions(child)

                if hasattr(mg_details, 'children'):
                    for child in mg_details.children:
                        extract_subscriptions(child)

                logging.info(f"MG {mg_id} has {len(subscriptions)} subscriptions")

                for sub_id in subscriptions:
                    compute_client = ComputeManagementClient(credential, sub_id)
                    vms = compute_client.virtual_machines.list_all()
                    for vm in vms:
                        all_results.append({
                            "mg_id": mg_id,
                            "subscription_id": sub_id,
                            "vm_name": vm.name,
                            "resource_group": vm.id.split("/")[4],
                            "location": vm.location
                        })
            except Exception as e:
                logging.error(f"Failed to fetch VMs for MG {mg_id}: {str(e)}")

        return func.HttpResponse(
            json.dumps(all_results, indent=2),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logging.error(f"Error in function: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )
