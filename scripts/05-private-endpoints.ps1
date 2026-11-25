# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Private Link (Premium workspace): the workspace front end gets private IPs inside our VNet. Run 04-private-dns.ps1 first.
$WSID = az databricks workspace show -g $RG -n $WS --query id -o tsv
# Endpoint 1: databricks_ui_api = REST API + UI (this is what the Dataverse plug-in calls)
az network private-endpoint create -g $RG -n pe-ab-dbx-uiapi -l $LOC --vnet-name vnet-ab-ci --subnet snet-pe --private-connection-resource-id $WSID --group-id databricks_ui_api --connection-name pec-uiapi --query "{endpoint:name, state:provisioningState, ip:customDnsConfigs[0].ipAddresses[0]}" -o table
# Endpoint 2: browser_authentication = SSO callback for the web UI over Private Link
az network private-endpoint create -g $RG -n pe-ab-dbx-auth -l $LOC --vnet-name vnet-ab-ci --subnet snet-pe --private-connection-resource-id $WSID --group-id browser_authentication --connection-name pec-auth --query "{endpoint:name, state:provisioningState, ip:customDnsConfigs[0].ipAddresses[0]}" -o table
# DNS zone groups write the A records automatically
az network private-endpoint dns-zone-group create -g $RG --endpoint-name pe-ab-dbx-uiapi -n zg -z privatelink.azuredatabricks.net --private-dns-zone privatelink.azuredatabricks.net --query "{group:name, state:provisioningState}" -o table
az network private-endpoint dns-zone-group create -g $RG --endpoint-name pe-ab-dbx-auth -n zg -z privatelink.azuredatabricks.net --private-dns-zone privatelink.azuredatabricks.net --query "{group:name, state:provisioningState}" -o table
# Result: A records in the private zone
az network private-dns record-set a list -g $RG -z privatelink.azuredatabricks.net --query "[].{record:name, ip:aRecords[0].ipv4Address}" -o table
