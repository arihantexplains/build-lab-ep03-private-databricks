# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Explicit outbound for the cluster subnets: new VNets have no default outbound internet access
az network public-ip create -g $RG -n pip-ab-nat -l $LOC --sku Standard --allocation-method Static --query "publicIp.{name:name,sku:sku.name}" -o table
az network nat gateway create -g $RG -n nat-ab-dbx -l $LOC --public-ip-addresses pip-ab-nat --idle-timeout 4 --query "{name:name,sku:sku.name,state:provisioningState}" -o table
az network vnet subnet update -g $RG --vnet-name vnet-ab-ci -n snet-dbx-host --nat-gateway nat-ab-dbx --query "{subnet:name,nat:natGateway.id!=null}" -o table
az network vnet subnet update -g $RG --vnet-name vnet-ab-ci -n snet-dbx-container --nat-gateway nat-ab-dbx --query "{subnet:name,nat:natGateway.id!=null}" -o table
