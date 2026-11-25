# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Private DNS zone for the workspace, linked to both VNets, so the workspace name resolves to a private IP inside them
az network private-dns zone create -g $RG -n privatelink.azuredatabricks.net --query "{zone:name}" -o table
az network private-dns link vnet create -g $RG -z privatelink.azuredatabricks.net -n link-ab-ci -v vnet-ab-ci -e false --query "{link:name, state:provisioningState}" -o table
az network private-dns link vnet create -g $RG -z privatelink.azuredatabricks.net -n link-ab-si -v vnet-ab-si -e false --query "{link:name, state:provisioningState}" -o table
