# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Azure Databricks workspace: PREMIUM tier (Private Link needs Premium; the Trial tier is refused), VNet injection, Secure Cluster Connectivity (no public IP)
# Public network access stays ENABLED for now: we finish workspace setup first, then switch it off
az databricks workspace create -g $RG -n $WS -l $LOC --sku premium --vnet vnet-ab-ci --public-subnet snet-dbx-host --private-subnet snet-dbx-container --enable-no-public-ip true --public-network-access Enabled --required-nsg-rules AllRules --managed-resource-group $MRG --tags purpose=architect-builds-demo --no-wait
# Provisioning takes a few minutes 
do { Start-Sleep 30; $s = az databricks workspace show -g $RG -n $WS --query provisioningState -o tsv; Write-Host "$(Get-Date -Format HH:mm:ss)  $s" } while ($s -notin 'Succeeded','Failed')
az databricks workspace show -g $RG -n $WS --query "{name:name, tier:sku.name, url:workspaceUrl, noPublicIp:parameters.enableNoPublicIp.value, publicAccess:publicNetworkAccess, nsgRules:requiredNsgRules}" -o json
az group show -n $MRG --query "{managedRG:name, region:location}" -o table
