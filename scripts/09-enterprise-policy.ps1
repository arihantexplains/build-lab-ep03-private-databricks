# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Power Platform enterprise policy (NetworkInjection): tells Power Platform which delegated subnets to use
# Rule: one VNet in EACH region of the environment's geography (India = Central India + South India)
$f = & .\scripts\tools\ep-body.ps1 -RG $RG
Get-Content $f
az resource create -g $RG -n ep-ab-vnet --resource-type Microsoft.PowerPlatform/enterprisePolicies --api-version 2020-10-30 --is-full-object --properties "@$f" --query "{policy:name, kind:kind, location:location, state:properties.provisioningState}" -o table
az resource show -g $RG -n ep-ab-vnet --resource-type Microsoft.PowerPlatform/enterprisePolicies --query "properties.networkInjection.virtualNetworks[].{vnet:id, subnet:subnet.name}" -o table
