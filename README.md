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



        -------------
import azure.functions as func
import logging
import json
import pymssql
import os
from azure.identity import ManagedIdentityCredential
from azure.mgmt.managementgroups import ManagementGroupsAPI

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Azure Function triggered – starting MG fetch with UAMI + DB.")

    try:
        # Step 1: Get UAMI client ID from environment and authenticate
        uami_client_id = os.environ.get("UAMI_CLIENT_ID")
        if not uami_client_id:
            raise ValueError("UAMI_CLIENT_ID environment variable is not set")

        credential = ManagedIdentityCredential(client_id=uami_client_id)
        mgmt_client = ManagementGroupsAPI(credential)

        # Step 2: Connect to Azure SQL using pymssql
        conn_str = os.environ.get("SQL_CONN_STR")
        if not conn_str:
            raise ValueError("SQL_CONN_STR environment variable is not set")

        # Parse connection string format: Server=...;Database=...;Uid=...;Pwd=...
        parts = dict(item.split("=", 1) for item in conn_str.split(";") if item)
        server = parts["Server"].replace("tcp:", "").replace(",", "")
        database = parts["Database"]
        user = parts["Uid"]
        password = parts["Pwd"]

        # Step 3: Fetch management groups from database
        with pymssql.connect(server, user, password, database) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT mg_id FROM Management_Groups WHERE env_type = 'lower'")
            rows = cursor.fetchall()

        mg_ids = [row[0] for row in rows]
        logging.info(f"Retrieved {len(mg_ids)} management groups from DB")

        # Step 4: Validate access to each MG using UAMI
        all_mgs = []
        for mg_id in mg_ids:
            try:
                mg = mgmt_client.management_groups.get(group_id=mg_id)
                all_mgs.append({"mg_id": mg_id, "display_name": mg.display_name})
            except Exception as e:
                logging.warning(f"Cannot access MG {mg_id}: {e}")

        return func.HttpResponse(
            json.dumps({"status": "success", "mg_data": all_mgs}, indent=2),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logging.error(f"Error occurred: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )

--sd-s-s--s-s-----

import azure.functions as func
import logging
import json
import pymssql
from azure.identity import ManagedIdentityCredential
from azure.mgmt.managementgroups import ManagementGroupsAPI

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Starting VM analyzer with UAMI + DB string")

    try:
        # Step 1: Auth with User Assigned Managed Identity (UAMI)
        uami_client_id = "your-uami-client-id"  # <<--- put your UAMI client_id here
        credential = ManagedIdentityCredential(client_id=uami_client_id)
        mgmt_client = ManagementGroupsAPI(credential)

        # Step 2: Read and parse SQL connection string
        conn_str = "Server=tcp:your-server.database.windows.net,1433;Database=metadata;Uid=your-username;Pwd=your-password;"

        def get_conn_value(key, source):
            for part in source.split(";"):
                if part.strip().lower().startswith(f"{key.lower()}="):
                    return part.split("=", 1)[1].strip()
            raise ValueError(f"Missing '{key}' in SQL connection string")

        try:
            server = get_conn_value("Server", conn_str).replace("tcp:", "").split(",")[0]
            database = get_conn_value("Database", conn_str)
            username = get_conn_value("Uid", conn_str)
            password = get_conn_value("Pwd", conn_str)
        except ValueError as parse_error:
            logging.error(str(parse_error))
            return func.HttpResponse(
                json.dumps({"error": str(parse_error)}),
                status_code=400
            )

        # Step 3: Connect to SQL DB using pymssql
        with pymssql.connect(server=server, user=username, password=password, database=database) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT mg_id FROM Management_Groups WHERE env_type = 'lower'")
            rows = cursor.fetchall()

        mg_ids = [row[0] for row in rows]
        logging.info(f"✅ Retrieved {len(mg_ids)} management groups from DB")

        # Step 4: Use UAMI to check access to MGs
        valid_mgs = []
        for mg_id in mg_ids:
            try:
                mg = mgmt_client.management_groups.get(group_id=mg_id)
                valid_mgs.append({"mg_id": mg_id, "display_name": mg.display_name})
            except Exception as e:
                logging.warning(f"⛔ Cannot access MG '{mg_id}': {str(e)}")

        return func.HttpResponse(
            json.dumps({"status": "success", "mg_data": valid_mgs}, indent=2),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logging.error(f"Unhandled error: {e}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500
        )
