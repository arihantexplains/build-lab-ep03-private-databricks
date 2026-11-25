# Build order checklist

Architect's Build Lab, Episode 3. Power Apps, Power Automate and Dataverse reaching a private Azure Databricks workspace through Power Platform virtual network support.

Build the parts in this order. After each step, run the check before you move on. Each check takes a minute and catches the mistake while it is still easy to fix.

Names and addresses are the ones used in the video. Change them to fit your own naming and address plan.

## Address plan

| Item | Value |
|---|---|
| vnet-ab-ci (Central India) | 10.10.0.0/22 |
| snet-dbx-host | 10.10.0.0/26 |
| snet-dbx-container | 10.10.0.64/26 |
| snet-pe | 10.10.0.128/27 |
| snet-pp-ci | 10.10.0.160/27 |
| snet-jump | 10.10.0.192/28 |
| vnet-ab-si (South India) | 10.20.0.0/24 |
| snet-pp-si | 10.20.0.0/27 |
| Private endpoint, UI and API | 10.10.0.132 |
| Private endpoint, browser sign in | 10.10.0.133 |
| Private DNS zone | privatelink.azuredatabricks.net |

## 1. Resource group

Create rg-ab-dbx-private in Central India. Everything in this build goes inside it.

Check it worked: the resource group opens in the Azure portal and shows Central India as its location.

## 2. Virtual network and address space

Create vnet-ab-ci in Central India with the address space 10.10.0.0/22. Pick a range that does not overlap with any other network you may connect later.

Check it worked: the Address space page of vnet-ab-ci shows 10.10.0.0/22 and nothing else.

## 3. Subnets

Add the five subnets from the address plan: snet-dbx-host, snet-dbx-container, snet-pe, snet-pp-ci and snet-jump.

Check it worked: the Subnets page lists all five with the ranges above, and none of them overlap.

## 4. Subnet delegation

Delegate snet-pp-ci to Microsoft.PowerPlatform/enterprisePolicies. Leave the other subnets without this delegation.

Check it worked: the Subnets page shows Microsoft.PowerPlatform/enterprisePolicies in the Delegated to column for snet-pp-ci.

## 5. NAT gateway and public IP

Create the public IP pip-ab-nat and the NAT gateway nat-ab-dbx. Attach the NAT gateway to snet-dbx-host and snet-dbx-container. This is the cluster's way out to the internet. Nothing comes in through it.

Check it worked: both Databricks subnets show nat-ab-dbx as their NAT gateway, and nat-ab-dbx shows pip-ab-nat as its public IP.

## 6. Databricks workspace

Create dbw-ab-private on the Premium tier. Deploy it into vnet-ab-ci with snet-dbx-host and snet-dbx-container (VNet injection), and turn on No Public IP for the cluster nodes. Both Databricks subnets end up delegated to Microsoft.Databricks/workspaces. Private Link needs the Premium tier.

Check it worked: the workspace overview shows Premium, and its networking settings show vnet-ab-ci, the two Databricks subnets and No Public IP enabled.

## 7. Private endpoints, then public access off

In snet-pe, add the private endpoint pe-ab-dbx-uiapi for the UI and API, and pe-ab-dbx-auth for browser sign in. When both are in place, set public network access on the workspace to Disabled.

Check it worked: both endpoints show the connection state Approved, with 10.10.0.132 and 10.10.0.133. From a laptop on the internet, the workspace address now answers 403.

## 8. Private DNS zone and links

Create the private DNS zone privatelink.azuredatabricks.net with the workspace records that point to the private endpoint addresses. Add a virtual network link from the zone to vnet-ab-ci and to vnet-ab-si.

Check it worked: from the jump machine on snet-jump, nslookup of the workspace name returns 10.10.0.132. If it returns a public address, the link is missing.

## 9. Second VNet and peering

Create vnet-ab-si in South India with the address space 10.20.0.0/24, and the subnet snet-pp-si at 10.20.0.0/27, delegated to Microsoft.PowerPlatform/enterprisePolicies. Peer vnet-ab-ci and vnet-ab-si in both directions. Power Platform needs one delegated subnet in each region of the environment's geo pair. For India, that is Central India and South India.

Check it worked: both peerings show Connected, one on each VNet.

## 10. Enterprise policy

Create the enterprise policy ep-ab-vnet for virtual network support. Point it at snet-pp-ci and snet-pp-si.

Check it worked: ep-ab-vnet lists both delegated subnets.

## 11. Link the environment

In the Power Platform admin center, link the demo environment to ep-ab-vnet. The environment needs to be a Managed Environment.

Check it worked: the environment's virtual network settings show ep-ab-vnet. The plug-in's dnsCheck operation then returns 10.10.0.132, which proves the code runs inside the delegated subnet.

## 12. Managed identity and federated credential

Create the user assigned managed identity id-ab-plugin. Add a federated credential that trusts Power Platform for this plug-in in this environment. The subject has to match exactly. Add id-ab-plugin to the Databricks workspace as a service principal, using its Entra ID application ID. In Dataverse, create the managed identity record and link it to the signed plug-in assembly.

Check it worked: the whoAmI operation of ab_DatabricksRequest returns OK with the identity's name. If you see AADSTS700213, compare the federated credential subject character by character.

## Final proof

Press the button in the app, or run the flow. It calls ab_DatabricksRequest, the plug-in reaches Databricks over the private endpoint, and the notebook run comes back as SUCCESS. No secret is stored anywhere.
