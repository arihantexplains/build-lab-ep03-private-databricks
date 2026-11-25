# Setup in a demo environment

Build it bottom up and test each layer before the next one. The portal version of every network step, with a check after each one, is in [checklist.md](checklist.md). The same steps as scripts are in [`scripts/`](../scripts). Use a demo or developer environment and a test subscription.

## 0. Values and tools

1. Copy `scripts/config.sample.ps1` to `scripts/config.ps1` (git-ignored) and fill in your values.
2. Open PowerShell in the repo root, sign in with `az login` and `pac auth create`, then run `. .\scripts\config.ps1`.
3. Run `scripts/00-preflight.ps1`. It shows the subscription, the environment, the resource providers and your vCPU quota.

## 1. Network (Azure)

| Script | What it creates | Check |
|---|---|---|
| `01-vnets.ps1` | `vnet-ab-ci` with the Databricks host and container subnets (delegated, NSG attached), the private endpoint subnet and the Power Platform subnet delegated to `Microsoft.PowerPlatform/enterprisePolicies`, plus `vnet-ab-si` in the paired region | The subnet list shows each delegation |
| `02-nat-gateway.ps1` | NAT gateway + public IP on the two Databricks subnets, a one way exit for the cluster | Both subnets show the NAT gateway |
| `03-workspace.ps1` | Premium workspace with VNet injection and no public IP for the cluster. Public access stays ON for now, to finish the setup | `provisioningState` is `Succeeded` |
| `04-private-dns.ps1` | Private DNS zone `privatelink.azuredatabricks.net`, linked to both VNets | Two links in the zone |
| `05-private-endpoints.ps1` | Private endpoints `databricks_ui_api` and `browser_authentication` with DNS zone groups | Two A records with private IPs |
| `06-vnet-peering.ps1` | Peering in both directions between the two VNets | Both peerings `Connected` |

## 2. Identity

| Script | What it does |
|---|---|
| `07-identity-and-signing.ps1` | Creates the user assigned managed identity `id-ab-plugin`, builds the plug-in and signs it with a short lived self-signed code signing certificate (demo only) |
| `08-federated-credential.ps1` | Adds a federated credential that trusts tokens Power Platform issues for **this signed assembly** in **this environment** only |

Before you build, create your own strong name key once: `cd plugin/DatabricksPrivatePlugin` then `sn -k key.snk`. The key is git-ignored.

## 3. Power Platform VNet support

| Script | What it does |
|---|---|
| `09-enterprise-policy.ps1` | Creates the `NetworkInjection` enterprise policy with one delegated subnet in each region of the geography |
| `10-managed-environment.ps1` | Turns the environment into a Managed Environment (VNet support needs it) |
| `11-link-environment.ps1` | Links the policy to the environment and waits for `Linked` |
| `12-linked-proof.ps1` | Shows the environment, the policy and the link status |

## 4. Dataverse

1. Register the signed assembly with the Plugin Registration Tool.
2. Run `13-trace-log-on.ps1` so every call leaves a row in the plug-in trace log.
3. Put the managed identity client id in `config.ps1` and run `14-managed-identity-and-custom-api.ps1`. It creates the managed identity record, links it to the assembly, creates the Custom API `ab_DatabricksRequest` (inputs `Operation`, `Payload`, outputs `Status`, `Result`) and adds the assembly to your solution.
4. Create the environment variable `ab_DatabricksConfig` (type JSON or text) with the value from [`config/environment-variable.sample.json`](../config/environment-variable.sample.json). It holds the workspace URL, the cluster id and the notebook path. No secrets.

## 5. Databricks

While public access is still on:

1. Import `databricks/summary.py` to `/Shared/ab-demo/summary`.
2. Add the managed identity to the workspace as a service principal (its client id).
3. Create a small single node cluster with auto termination.
4. Give the service principal **Can Restart** on that cluster and access to the notebook.

## 6. Close the door

1. In the workspace, open **Networking** and set **Public network access** to **Disabled**. Save.
2. Proof from outside: open the workspace URL from a normal internet connection. It answers 403.

## 7. The app and the proof

1. Import the canvas app source from [`app/`](../app) (or build your own) and add the Custom API as a data source.
2. Run the buttons in order: **Who am I?** (the managed identity), **DNS check** (`private: true`), **List clusters**, **Start cluster**, **Submit job**, then **Run status** until it shows `SUCCESS` and the summary.
3. Open the plug-in trace log to see every step and the time it took.

When you are done with the demo, delete the resource group so nothing keeps running.
