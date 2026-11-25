# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Two VNets: Central India (Databricks + endpoints + Power Platform) and South India (the geo pair for the policy)
az network vnet create -g $RG -n vnet-ab-ci -l $LOC --address-prefixes 10.10.0.0/22 --query "newVNet.{name:name,region:location,space:addressSpace.addressPrefixes[0]}" -o table
az network nsg create -g $RG -n nsg-ab-dbx -l $LOC --query "NewNSG.{name:name,state:provisioningState}" -o table
# Databricks host + container subnets: delegated to Databricks, NSG attached
az network vnet subnet create -g $RG --vnet-name vnet-ab-ci -n snet-dbx-host --address-prefixes 10.10.0.0/26 --delegations Microsoft.Databricks/workspaces --network-security-group nsg-ab-dbx --default-outbound false --query "{subnet:name,prefix:addressPrefix,delegation:delegations[0].serviceName}" -o table
az network vnet subnet create -g $RG --vnet-name vnet-ab-ci -n snet-dbx-container --address-prefixes 10.10.0.64/26 --delegations Microsoft.Databricks/workspaces --network-security-group nsg-ab-dbx --default-outbound false --query "{subnet:name,prefix:addressPrefix,delegation:delegations[0].serviceName}" -o table
# Private endpoint subnet (no delegation)
az network vnet subnet create -g $RG --vnet-name vnet-ab-ci -n snet-pe --address-prefixes 10.10.0.128/27 --query "{subnet:name,prefix:addressPrefix}" -o table
# Power Platform subnets: delegated to Microsoft.PowerPlatform/enterprisePolicies, one per region of the geo pair
az network vnet subnet create -g $RG --vnet-name vnet-ab-ci -n snet-pp-ci --address-prefixes 10.10.0.160/27 --delegations Microsoft.PowerPlatform/enterprisePolicies --query "{subnet:name,prefix:addressPrefix,delegation:delegations[0].serviceName}" -o table
az network vnet subnet create -g $RG --vnet-name vnet-ab-ci -n snet-jump --address-prefixes 10.10.0.192/28 --query "{subnet:name,prefix:addressPrefix}" -o table
az network vnet create -g $RG -n vnet-ab-si -l $PAIR --address-prefixes 10.20.0.0/24 --query "newVNet.{name:name,region:location,space:addressSpace.addressPrefixes[0]}" -o table
az network vnet subnet create -g $RG --vnet-name vnet-ab-si -n snet-pp-si --address-prefixes 10.20.0.0/27 --delegations Microsoft.PowerPlatform/enterprisePolicies --query "{subnet:name,prefix:addressPrefix,delegation:delegations[0].serviceName}" -o table
# Result
az network vnet subnet list -g $RG --vnet-name vnet-ab-ci --query "[].{subnet:name,prefix:addressPrefix,delegatedTo:delegations[0].serviceName,nsg:networkSecurityGroup.id!=null}" -o table
