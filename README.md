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


try {
    Connect-AzAccount -Identity -AccountId $uamiClientId | Out-Null
    Write-Output "Logged in with User Assigned Managed Identity (ClientId: ${uamiClientId})"
} catch {
    Write-Error "Failed to login with User Assigned Managed Identity: $_"
    return
}

# --- FETCH MANAGEMENT GROUP IDS FROM AZURE SQL DATABASE ---
$connectionString = ${env:SQL_CONNECTION_STRING}
$query = 'SELECT mg_id FROM Management_Groups WHERE env_type = ''lower'';'

try {
    Add-Type -AssemblyName "System.Data"

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $reader = $command.ExecuteReader()
    $managementGroupIds = @()
    while ($reader.Read()) {
        $managementGroupIds += $reader["mg_id"]
    }

    $reader.Close()
    $connection.Close()

    Write-Output "Fetched Management Group IDs from DB: $($managementGroupIds -join ', ')"
} catch {
    Write-Error "Failed to fetch Management Group IDs from DB: $_"
    return
}

# --- GET ALL SUBSCRIPTIONS UNDER NON-PROD MGs ---
# Ensure $managementGroupIds is an array of MG IDs (strings)
$allSubscriptions = @()

foreach ($mgId in $managementGroupIds) {
    try {
        Write-Output "Getting subscriptions under Management Group: ${mgId}"
        $subs = Get-AzManagementGroupSubscription -GroupName $mgId
        if ($subs) {
            $allSubscriptions += $subs
            Write-Output "Found $($subs.Count) subscriptions under MG ${mgId}"
        } else {
            Write-Output "No subscriptions found under MG ${mgId}"
        }
    } catch {
        Write-Error "Failed to get subscriptions for MG ${mgId}: $_"
    }
}

# After collecting all subscriptions from MGs

# Remove duplicates based on Subscription ID (not just object uniqueness)
$uniqueSubs = @{}
$filteredSubscriptions = @()

foreach ($sub in $allSubscriptions) {
    if ($sub.Id -match "/subscriptions/([0-9a-fA-F-]+)$") {
        $subId = $matches[1]

        if (-not $uniqueSubs.ContainsKey($subId)) {
            $uniqueSubs[$subId] = $true
            $filteredSubscriptions += $sub
        }
    } else {
        Write-Warning "Cannot extract subscription ID from $($sub.Id)"
    }
}

$allSubscriptions = $filteredSubscriptions
Write-Output "Total unique subscriptions to process: $($allSubscriptions.Count)"


# --- FOR EACH SUBSCRIPTION, FIND VMs AND APPLY PARKING LOGIC ---
foreach ($sub in $allSubscriptions) {
    Write-Output "Subscription object: $sub"
    $fullSubId = $sub.Id
    $subName = $sub.Name
    Write-Output "Full Subscription Id: $fullSubId"

    # Extract only subscription GUID from the full resource ID string
    # Subscription GUID is always the last segment after 'subscriptions/'
    if ($fullSubId -match "/subscriptions/([0-9a-fA-F-]+)$") {
        $subId = $matches[1]
    } else {
        Write-Error "Cannot extract subscription ID from $fullSubId"
        continue
    }

    Write-Output "Processing subscription: ${subName} (${subId})"

    try {
        $subDetails = Get-AzSubscription -SubscriptionId $subId
        $tenantId = $subDetails.TenantId
    } catch {
        Write-Error "Failed to get subscription details for $subId : $_"
        continue
    }

    try {
        Set-AzContext -SubscriptionId $subId -TenantId $tenantId | Out-Null
        Write-Output "Context set for Subscription: ${subName} with TenantId: $tenantId"
    } catch {
        Write-Error "Failed to set context for ${subName} (${subId}) with TenantId: $tenantId : $_"
        continue
    }
    
    try {
    $vms = Get-AzVM
    Write-Output "Found $($vms.Count) VMs in subscription ${subName}"
    foreach ($vm in $vms) {
        # Write-Output "VM found: $($vm.Name), Tags: $($vm.Tags | Out-String)"
        $tags = $vm.Tags
        $vmName = $vm.Name



-----------
import azure.functions as func
import logging
import json
from azure.identity import AzureCliCredential
from azure.monitor.query import MetricsQueryClient
from datetime import datetime, timedelta
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.resource import SubscriptionClient
import calendar
from statistics import median
from collections import defaultdict

IDLE_HOURS = 4
WINDOW_SIZE = int((IDLE_HOURS * 60) / 15)  # 4 hours = 16 samples

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Analyzing VM CPU usage for start/stop recommendations.')

    try:
        subscription_id = req.params.get('subscription_id')
        days = int(req.params.get('days', 10))
        if not subscription_id:
            return func.HttpResponse("Missing 'subscription_id' query parameter", status_code=400)

        credential = AzureCliCredential()
        client = MetricsQueryClient(credential)
        compute_client = ComputeManagementClient(credential, subscription_id)

        vm_results = []

        for vm in compute_client.virtual_machines.list_all():
            if "aks" in vm.name.lower() or "databricks" in vm.name.lower():
                continue

            vm_resource_id = vm.id
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=days)

            response = client.query_resource(
                resource_uri=vm_resource_id,
                metric_names=["Percentage CPU"],
                timespan=(start_time, end_time),
                granularity=timedelta(minutes=15)
            )

            cpu_values, timestamps = [], []

            for metric in response.metrics:
                if metric.name == "Percentage CPU":
                    for ts in metric.timeseries:
                        for point in ts.data:
                            if point.average is not None:
                                timestamps.append(point.timestamp.isoformat())
                                cpu_values.append(point.average)

            daily_data = defaultdict(list)
            for i, cpu_val in enumerate(cpu_values):
                date_key = timestamps[i][:10]
                date_obj = datetime.strptime(date_key, "%Y-%m-%d")
                if date_obj.weekday() < 5:
                    daily_data[date_key].append({
                        "timestamp": timestamps[i],
                        "value": cpu_val
                    })

            daily_results = []
            sorted_dates = sorted(daily_data.keys())

            for date in sorted_dates:
                date_obj = datetime.strptime(date, "%Y-%m-%d")
                entries = daily_data[date]
                values = [e["value"] for e in entries]
                times = [e["timestamp"] for e in entries]

                if not values:
                    continue

                day_min_cpu = min(values)
                day_max_cpu = max(values)
                day_avg_cpu = sum(values) / len(values)

                threshold = day_avg_cpu * 0.75  # dynamic threshold per day

                spike_indexes = [i for i, val in enumerate(values) if val >= threshold]
                if not spike_indexes:
                    continue

                first_spike = spike_indexes[0]
                last_spike = spike_indexes[-1]

                start_index = max(0, first_spike - 4)
                stop_index = min(len(times) - 1, last_spike + 4)

                daily_results.append({
                    "date": date,
                    "day": date_obj.strftime("%A"),
                    "week": f"Week {(date_obj.day - 1) // 7 + 1} of {calendar.month_name[date_obj.month]}",
                    "start_time": times[start_index],
                    "stop_time": times[stop_index],
                    "avg_cpu": round(day_avg_cpu, 2),
                    "min_cpu": day_min_cpu,
                    "max_cpu": day_max_cpu,
                    "decision": "Safe to stop after last spike"
                })

            vm_results.append({
                "name": vm.name,
                "daily_recommendations": daily_results
            })

        return func.HttpResponse(
            json.dumps(vm_results, indent=2),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error: {e}")
        return func.HttpResponse(f"Error: {str(e)}", status_code=500)


 -------------
 import azure.functions as func
import logging
import json
from azure.identity import AzureCliCredential
from azure.monitor.query import MetricsQueryClient
from datetime import datetime, timedelta
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.resource import SubscriptionClient
import calendar

IDLE_HOURS = 4
WINDOW_SIZE = int((IDLE_HOURS * 60) / 15)


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Analyzing VM CPU usage for start/stop recommendations.')

    try:
        credential = AzureCliCredential()
        sub_client = SubscriptionClient(credential)
        client = MetricsQueryClient(credential)

        subscription_id = req.params.get("subscription_id")
        days = int(req.params.get("days", 7))

        if not subscription_id:
            return func.HttpResponse("Missing subscription_id in query parameters", status_code=400)

        compute_client = ComputeManagementClient(credential, subscription_id)
        vm_results = []

        for vm in compute_client.virtual_machines.list_all():
            if "aks" in vm.name.lower() or "databricks" in vm.name.lower():
                continue

            vm_resource_id = vm.id
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=days)
            response = client.query_resource(
                resource_uri=vm_resource_id,
                metric_names=["Percentage CPU", "OS Disk Read Bytes/sec", "OS Disk Write Bytes/sec"],
                timespan=(start_time, end_time + timedelta(hours=1)),  # Include buffer for spike-after-last logic
                granularity=timedelta(minutes=15)
            )

            cpu_values, disk_values, timestamps = [], [], []
            disk_reads, disk_writes = {}, {}

            for metric in response.metrics:
                for ts in metric.timeseries:
                    for point in ts.data:
                        if point.average is None:
                            continue
                        ts_str = point.timestamp.isoformat()
                        if metric.name == "Percentage CPU":
                            timestamps.append(ts_str)
                            cpu_values.append(point.average)
                        elif metric.name == "OS Disk Read Bytes/sec":
                            disk_reads[ts_str] = point.average
                        elif metric.name == "OS Disk Write Bytes/sec":
                            disk_writes[ts_str] = point.average

            for ts in timestamps:
                read_val = disk_reads.get(ts, 0)
                write_val = disk_writes.get(ts, 0)
                disk_values.append(read_val + write_val)

            from collections import defaultdict
            daily_data = defaultdict(list)
            for i, ts in enumerate(timestamps):
                date_key = ts[:10]
                date_obj = datetime.strptime(date_key, "%Y-%m-%d")
                if date_obj.weekday() < 5:
                    daily_data[date_key].append({
                        "timestamp": ts,
                        "value": cpu_values[i],
                        "disk": disk_values[i] if i < len(disk_values) else 0
                    })

            daily_results = []
            for date in sorted(daily_data):
                entries = daily_data[date]
                if not entries:
                    continue
                date_obj = datetime.strptime(date, "%Y-%m-%d")
                if date_obj.weekday() >= 5:
                    continue

                values = [e["value"] for e in entries]
                disks = [e["disk"] for e in entries]
                ts_vals = [e["timestamp"] for e in entries]

                busy_indexes = [i for i, v in enumerate(values) if v > 10.0]
                if busy_indexes:
                    first_idx = max(0, busy_indexes[0] - 4)
                    last_idx = min(len(values) - 1, busy_indexes[-1] + 4)
                    start_time = ts_vals[first_idx]
                    stop_time = ts_vals[last_idx]
                    start_cpu_avg = sum(values[first_idx:first_idx + 4]) / 4
                    stop_cpu_avg = sum(values[max(0, last_idx - 4):last_idx]) / 4
                    start_disk_avg = sum(disks[first_idx:first_idx + 4]) / 4
                    stop_disk_avg = sum(disks[max(0, last_idx - 4):last_idx]) / 4
                    decision = "Active VM. Consider scheduling around busy hours."
                else:
                    start_time = "No busy workload detected"
                    stop_time = "No busy workload detected"
                    start_cpu_avg = None
                    stop_cpu_avg = None
                    start_disk_avg = None
                    stop_disk_avg = None
                    decision = "Idle VM. Safe to stop."

                daily_results.append({
                    "date": date,
                    "day": date_obj.strftime("%A"),
                    "week": f"Week {(date_obj.day - 1) // 7 + 1} of {calendar.month_name[date_obj.month]}",
                    "start_time": start_time,
                    "stop_time": stop_time,
                    "start_window_cpu_usage": start_cpu_avg,
                    "stop_window_cpu_usage": stop_cpu_avg,
                    "start_window_disk_usage": start_disk_avg,
                    "stop_window_disk_usage": stop_disk_avg,
                    "decision": decision
                })

            vm_results.append({
                "name": vm.name,
                "daily_recommendations": daily_results
            })

        return func.HttpResponse(
            json.dumps(vm_results, indent=2),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error: {e}")
        return func.HttpResponse(
            f"Error: {str(e)}",
            status_code=500
        )



--------
from azure.identity import AzureCliCredential
from azure.monitor.query import MetricsQueryClient
from azure.mgmt.compute import ComputeManagementClient
from datetime import datetime, timedelta

credential = AzureCliCredential()
metrics_client = MetricsQueryClient(credential)
compute_client = ComputeManagementClient(credential, "<subscription_id>")  # replace with your sub ID

end_time = datetime.utcnow()
start_time = end_time - timedelta(days=30)

# Thresholds
CPU_THRESHOLD = 15.0
MEMORY_THRESHOLD = 80.0  # Available memory in %
NETWORK_THRESHOLD_MB = 10.0  # MB
IOPS_THRESHOLD = 10.0  # %

matching_vms = []

for vm in compute_client.virtual_machines.list_all():
    if "aks" in vm.name.lower() or "databricks" in vm.name.lower():
        continue

    resource_id = vm.id
    response = metrics_client.query_resource(
        resource_uri=resource_id,
        metric_names=[
            "Percentage CPU",
            "Available Memory Bytes",
            "Network In Total",
            "Network Out Total",
            "Used OS Disk IOPS",
            "Used Data Disk IOPS"
        ],
        timespan=(start_time, end_time),
        granularity=timedelta(hours=1),
        aggregations=["Average"]
    )

    cpu_vals, mem_vals, net_vals, os_iops_vals, data_iops_vals = [], [], [], [], []

    for metric in response.metrics:
        for ts in metric.timeseries:
            for point in ts.data:
                if point.average is None:
                    continue
                if metric.name == "Percentage CPU":
                    cpu_vals.append(point.average)
                elif metric.name == "Available Memory Bytes":
                    # Convert to percentage of 16 GB total (example, adjust to actual if known)
                    mem_vals.append((point.average / (16 * 1024**3)) * 100)
                elif metric.name in ["Network In Total", "Network Out Total"]:
                    net_vals.append(point.average / (1024**2))  # Convert to MB
                elif metric.name == "Used OS Disk IOPS":
                    os_iops_vals.append(point.average)
                elif metric.name == "Used Data Disk IOPS":
                    data_iops_vals.append(point.average)

    if not cpu_vals:
        continue

    avg_cpu = sum(cpu_vals) / len(cpu_vals)
    avg_mem = sum(mem_vals) / len(mem_vals) if mem_vals else 0
    avg_net = sum(net_vals) / len(net_vals) if net_vals else 0
    avg_os_iops = sum(os_iops_vals) / len(os_iops_vals) if os_iops_vals else 0
    avg_data_iops = sum(data_iops_vals) / len(data_iops_vals) if data_iops_vals else 0

    if (
        avg_cpu <= CPU_THRESHOLD and
        avg_mem >= MEMORY_THRESHOLD and
        avg_net < NETWORK_THRESHOLD_MB and
        avg_os_iops < IOPS_THRESHOLD and
        avg_data_iops < IOPS_THRESHOLD
    ):
        matching_vms.append({
            "vm_name": vm.name,
            "avg_cpu": round(avg_cpu, 2),
            "avg_mem_percent": round(avg_mem, 2),
            "avg_network_MB": round(avg_net, 2),
            "avg_os_iops": round(avg_os_iops, 2),
            "avg_data_iops": round(avg_data_iops, 2)
        })

print("Matching VMs:", matching_vms)


------------

import azure.functions as func
import logging
import json
from azure.identity import AzureCliCredential
from azure.monitor.query import MetricsQueryClient
from datetime import datetime, timedelta
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.resource import SubscriptionClient
import calendar

IDLE_HOURS = 4
WINDOW_SIZE = int((IDLE_HOURS * 60) / 15)


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Analyzing VM utilization for start/stop recommendations.')

    try:
        credential = AzureCliCredential()
        sub_client = SubscriptionClient(credential)
        client = MetricsQueryClient(credential)

        subscription_id = req.params.get("subscription_id")
        days = int(req.params.get("days", 7))

        if not subscription_id:
            return func.HttpResponse("Missing subscription_id in query parameters", status_code=400)

        compute_client = ComputeManagementClient(credential, subscription_id)
        vm_results = []

        for vm in compute_client.virtual_machines.list_all():
            if "aks" in vm.name.lower() or "databricks" in vm.name.lower():
                continue

            vm_resource_id = vm.id
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=days)

            response = client.query_resource(
                resource_uri=vm_resource_id,
                metric_names=[
                    "Percentage CPU",
                    "Available Memory Bytes",
                    "Network In Total",
                    "Network Out Total",
                    "OS Disk Read Bytes/sec",
                    "OS Disk Write Bytes/sec"
                ],
                timespan=(start_time, end_time + timedelta(hours=1)),
                granularity=timedelta(minutes=15)
            )

            cpu_values, disk_values, mem_values, net_values, timestamps = [], [], [], [], []
            disk_reads, disk_writes = {}, {}
            net_in, net_out = {}, {}
            mem_avail = {}

            for metric in response.metrics:
                for ts in metric.timeseries:
                    for point in ts.data:
                        if point.average is None:
                            continue
                        ts_str = point.timestamp.isoformat()
                        if metric.name == "Percentage CPU":
                            timestamps.append(ts_str)
                            cpu_values.append(point.average)
                        elif metric.name == "Available Memory Bytes":
                            mem_avail[ts_str] = point.average
                        elif metric.name == "Network In Total":
                            net_in[ts_str] = point.average
                        elif metric.name == "Network Out Total":
                            net_out[ts_str] = point.average
                        elif metric.name == "OS Disk Read Bytes/sec":
                            disk_reads[ts_str] = point.average
                        elif metric.name == "OS Disk Write Bytes/sec":
                            disk_writes[ts_str] = point.average

            for ts in timestamps:
                read_val = disk_reads.get(ts, 0)
                write_val = disk_writes.get(ts, 0)
                disk_values.append((read_val + write_val) / (1024 * 1024))  # MB

                mem_val = mem_avail.get(ts, 0)
                mem_values.append(mem_val / (1024 ** 3))  # GB

                net_val = (net_in.get(ts, 0) + net_out.get(ts, 0)) / (1024 * 1024)  # MB
                net_values.append(net_val)

            from collections import defaultdict
            daily_data = defaultdict(list)
            for i, ts in enumerate(timestamps):
                date_key = ts[:10]
                date_obj = datetime.strptime(date_key, "%Y-%m-%d")
                if date_obj.weekday() < 5:
                    daily_data[date_key].append({
                        "timestamp": ts,
                        "cpu": cpu_values[i],
                        "disk": disk_values[i] if i < len(disk_values) else 0,
                        "mem": mem_values[i] if i < len(mem_values) else 0,
                        "net": net_values[i] if i < len(net_values) else 0
                    })

            daily_results = []
            for date in sorted(daily_data):
                entries = daily_data[date]
                if not entries:
                    continue

                date_obj = datetime.strptime(date, "%Y-%m-%d")
                if date_obj.weekday() >= 5:
                    continue

                values_cpu = [e["cpu"] for e in entries]
                values_disk = [e["disk"] for e in entries]
                values_mem = [e["mem"] for e in entries]
                values_net = [e["net"] for e in entries]
                ts_vals = [e["timestamp"] for e in entries]

                busy_indexes = [
                    i for i in range(len(entries))
                    if values_cpu[i] > 15 or values_mem[i] < 1 or values_net[i] > 10 or values_disk[i] > 1
                ]

                if busy_indexes:
                    first_idx = max(0, busy_indexes[0] - 4)
                    last_idx = min(len(ts_vals) - 1, busy_indexes[-1] + 4)
                    start_time = ts_vals[first_idx]
                    stop_time = ts_vals[last_idx]
                    decision = "Active VM. Consider scheduling around busy hours."
                else:
                    start_time = "No busy workload detected"
                    stop_time = "No busy workload detected"
                    decision = "Idle VM. Safe to stop."

                daily_results.append({
                    "date": date,
                    "day": date_obj.strftime("%A"),
                    "week": f"Week {(date_obj.day - 1) // 7 + 1} of {calendar.month_name[date_obj.month]}",
                    "start_time": start_time,
                    "stop_time": stop_time,
                    "decision": decision
                })

            vm_results.append({
                "name": vm.name,
                "daily_recommendations": daily_results
            })

        return func.HttpResponse(
            json.dumps(vm_results, indent=2),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error: {e}")
        return func.HttpResponse(
            f"Error: {str(e)}",
            status_code=500
        )



-------
import azure.functions as func
import logging
import json
from azure.identity import AzureCliCredential
from azure.monitor.query import MetricsQueryClient
from datetime import datetime, timedelta
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.resource import SubscriptionClient
import calendar

IDLE_HOURS = 4
WINDOW_SIZE = int((IDLE_HOURS * 60) / 15)


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Analyzing VM usage across CPU, Memory, Disk, and Network.')

    try:
        credential = AzureCliCredential()
        sub_client = SubscriptionClient(credential)
        client = MetricsQueryClient(credential)

        subscription_id = req.params.get("subscription_id")
        days = int(req.params.get("days", 7))

        if not subscription_id:
            return func.HttpResponse("Missing subscription_id in query parameters", status_code=400)

        compute_client = ComputeManagementClient(credential, subscription_id)
        vm_results = []

        for vm in compute_client.virtual_machines.list_all():
            if "aks" in vm.name.lower() or "databricks" in vm.name.lower():
                continue

            vm_resource_id = vm.id
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=days)
            response = client.query_resource(
                resource_uri=vm_resource_id,
                metric_names=[
                    "Percentage CPU",
                    "Available Memory Bytes",
                    "Network In Total",
                    "Network Out Total",
                    "OS Disk Read Bytes/sec",
                    "OS Disk Write Bytes/sec",
                    "OS Disk IOPS Consumed Percentage",
                    "Data Disk IOPS Consumed Percentage"
                ],
                timespan=(start_time, end_time + timedelta(hours=1)),
                granularity=timedelta(minutes=15)
            )

            cpu_values, disk_values, timestamps = [], [], []
            disk_reads, disk_writes = {}, {}
            mem_values, net_in, net_out = {}, {}, {}
            os_disk_iops, data_disk_iops = {}, {}

            for metric in response.metrics:
                for ts in metric.timeseries:
                    for point in ts.data:
                        if point.average is None:
                            continue
                        ts_str = point.timestamp.isoformat()
                        if metric.name == "Percentage CPU":
                            timestamps.append(ts_str)
                            cpu_values.append(point.average)
                        elif metric.name == "OS Disk Read Bytes/sec":
                            disk_reads[ts_str] = point.average
                        elif metric.name == "OS Disk Write Bytes/sec":
                            disk_writes[ts_str] = point.average
                        elif metric.name == "Available Memory Bytes":
                            mem_values[ts_str] = point.average
                        elif metric.name == "Network In Total":
                            net_in[ts_str] = point.average
                        elif metric.name == "Network Out Total":
                            net_out[ts_str] = point.average
                        elif metric.name == "OS Disk IOPS Consumed Percentage":
                            os_disk_iops[ts_str] = point.average
                        elif metric.name == "Data Disk IOPS Consumed Percentage":
                            data_disk_iops[ts_str] = point.average

            for ts in timestamps:
                read_val = disk_reads.get(ts, 0)
                write_val = disk_writes.get(ts, 0)
                disk_values.append(read_val + write_val)

            from collections import defaultdict
            daily_data = defaultdict(list)
            for i, ts in enumerate(timestamps):
                date_key = ts[:10]
                date_obj = datetime.strptime(date_key, "%Y-%m-%d")
                if date_obj.weekday() < 5:
                    daily_data[date_key].append({
                        "timestamp": ts,
                        "value": cpu_values[i],
                        "disk": disk_values[i] if i < len(disk_values) else 0,
                        "memory": mem_values.get(ts),
                        "net": (net_in.get(ts, 0) + net_out.get(ts, 0)),
                        "os_iops": os_disk_iops.get(ts),
                        "data_iops": data_disk_iops.get(ts)
                    })

            daily_results = []
            for date in sorted(daily_data):
                entries = daily_data[date]
                if not entries:
                    continue
                date_obj = datetime.strptime(date, "%Y-%m-%d")
                if date_obj.weekday() >= 5:
                    continue

                values = [e["value"] for e in entries]
                disks = [e["disk"] for e in entries]
                ts_vals = [e["timestamp"] for e in entries]
                mem_vals = [e["memory"] for e in entries if e["memory"] is not None]
                net_vals = [e["net"] for e in entries]
                os_vals = [e["os_iops"] for e in entries if e["os_iops"] is not None]
                data_vals = [e["data_iops"] for e in entries if e["data_iops"] is not None]

                busy_indexes = [i for i, v in enumerate(values) if v > 10.0]
                if busy_indexes:
                    first_idx = max(0, busy_indexes[0] - 4)
                    last_idx = min(len(values) - 1, busy_indexes[-1] + 4)
                    start_time = ts_vals[first_idx]
                    stop_time = ts_vals[last_idx]
                    start_cpu_avg = sum(values[first_idx:first_idx + 4]) / 4
                    stop_cpu_avg = sum(values[max(0, last_idx - 4):last_idx]) / 4
                    start_disk_avg = sum(disks[first_idx:first_idx + 4]) / 4
                    stop_disk_avg = sum(disks[max(0, last_idx - 4):last_idx]) / 4
                    decision = "Active VM. Consider scheduling around busy hours."
                else:
                    start_time = "No busy workload detected"
                    stop_time = "No busy workload detected"
                    start_cpu_avg = stop_cpu_avg = start_disk_avg = stop_disk_avg = None
                    decision = "Idle VM. Safe to stop."

                avg_mem_percent = round(sum(mem_vals)/len(mem_vals)/1024/1024/1024 if mem_vals else 0, 2)
                avg_net_mb = round(sum(net_vals)/len(net_vals)/1024/1024 if net_vals else 0, 2)
                avg_os_iops = round(sum(os_vals)/len(os_vals) if os_vals else 0, 2)
                avg_data_iops = round(sum(data_vals)/len(data_vals) if data_vals else 0, 2)

                daily_results.append({
                    "date": date,
                    "day": date_obj.strftime("%A"),
                    "week": f"Week {(date_obj.day - 1) // 7 + 1} of {calendar.month_name[date_obj.month]}",
                    "start_time": start_time,
                    "stop_time": stop_time,
                    "start_window_cpu_usage": start_cpu_avg,
                    "stop_window_cpu_usage": stop_cpu_avg,
                    "start_window_disk_usage": start_disk_avg,
                    "stop_window_disk_usage": stop_disk_avg,
                    "avg_memory_available_gb": avg_mem_percent,
                    "avg_network_throughput_MB": avg_net_mb,
                    "avg_os_disk_iops_percent": avg_os_iops,
                    "avg_data_disk_iops_percent": avg_data_iops,
                    "decision": decision
                })

            vm_results.append({
                "name": vm.name,
                "daily_recommendations": daily_results
            })

        return func.HttpResponse(
            json.dumps(vm_results, indent=2),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error: {e}")
        return func.HttpResponse(
            f"Error: {str(e)}",
            status_code=500
        )
		
