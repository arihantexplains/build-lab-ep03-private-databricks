# Permissions (least privilege)

## Databricks

| Principal | Permission | Why |
|---|---|---|
| Managed identity `id-ab-plugin`, added to the workspace as a service principal | **Can Restart** on the one demo cluster | `startCluster` and running the notebook on it |
| Same | Read and run on `/Shared/ab-demo/summary` | `submitJob` runs this notebook |

Left out on purpose: workspace admin, Can Manage on the cluster, cluster creation rights, any access to other notebooks, and any personal access token.
`listClusters` only returns the clusters this identity has permission on, so the app never sees the rest of the workspace.

## Azure

| Who | Role | Scope | Why |
|---|---|---|---|
| The person building the demo | Contributor (or Network Contributor + Databricks + Managed Identity rights) | The demo resource group | Create the network, the workspace and the identity |
| Power Platform admin | Power Platform administrator | Tenant | Create and link the enterprise policy, turn on a Managed Environment |

The managed identity itself needs **no Azure role**. It only needs to exist in the workspace as a service principal.

## Dataverse

| Who | Gets | Why |
|---|---|---|
| App users | A security role that can call the Custom API `ab_DatabricksRequest` | Dataverse checks this before the plug-in runs |
| The plug-in | Reads the environment variable definition and value | Settings, no secrets |

## Federated credential

| Field | Value |
|---|---|
| Issuer | `https://login.microsoftonline.com/<tenant-id>/v2.0` |
| Subject | Built by `scripts/tools/fic-subject.ps1` from the tenant, the environment id and the SHA-256 of the signing certificate (lowercase hex) |
| Audience | `api://AzureADTokenExchange` |

If you sign the assembly with a new certificate, update the subject. That is a feature: an assembly signed by someone else cannot get the token.
