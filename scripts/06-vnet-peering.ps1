# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Global VNet peering between the two regions of the geography, both directions
az network vnet peering create -g $RG -n peer-ci-to-si --vnet-name vnet-ab-ci --remote-vnet vnet-ab-si --allow-vnet-access --query "{peering:name, state:peeringState}" -o table
az network vnet peering create -g $RG -n peer-si-to-ci --vnet-name vnet-ab-si --remote-vnet vnet-ab-ci --allow-vnet-access --query "{peering:name, state:peeringState}" -o table
