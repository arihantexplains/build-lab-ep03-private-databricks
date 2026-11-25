# Architecture

<p align="center"><img src="images/arch-all.png" alt="The whole picture: Power Platform, Dataverse, the delegated subnet, Private Link and the private Databricks workspace" width="100%"></p>

## The pieces

| Piece | Lives in | Job |
|---|---|---|
| Canvas app and flow | Power Platform environment | Call the Custom API with an operation |
| Custom API `ab_DatabricksRequest` | Dataverse | The one door the app and the flow use. Dataverse checks the caller first |
| Plug-in `DatabricksGatewayPlugin` | Runs in the delegated subnet through VNet support | Reads the settings, gets a token, calls the Databricks REST API |
| Environment variable `ab_DatabricksConfig` | Dataverse | Workspace URL, cluster id, notebook path. No secrets |
| Enterprise policy `ep-ab-vnet` | Azure, linked to the environment | Tells Power Platform which delegated subnets to use, one per region |
| Managed identity `id-ab-plugin` + federated credential | Azure | The identity the plug-in becomes. Trusts only this signed assembly in this environment |
| Private endpoints + private DNS zone | `snet-pe` in `vnet-ab-ci` | Give the workspace a private IP inside our network |
| Databricks workspace | VNet injection in `vnet-ab-ci`, Premium | Runs the cluster and the notebook. Public network access is Disabled |
| NAT gateway | Databricks subnets | One way exit for the cluster, no public IP on any cluster machine |
| Second VNet `vnet-ab-si` + peering | Paired region | Required by the enterprise policy |

## One call, step by step

```mermaid
sequenceDiagram
  participant App as Canvas app
  participant DV as Dataverse
  participant PI as Plug-in (delegated subnet)
  participant ID as Managed identity
  participant DNS as Private DNS
  participant DBX as Databricks (private)
  App->>DV: ab_DatabricksRequest(Operation, Payload)
  DV->>DV: check the caller may use the Custom API
  DV->>PI: run the plug-in inside the VNet
  PI->>DV: read ab_DatabricksConfig
  PI->>ID: AcquireToken(AzureDatabricks)
  ID-->>PI: short-lived token (federated, no secret)
  PI->>DNS: resolve adb-<id>.azuredatabricks.net
  DNS-->>PI: 10.10.0.132 (private endpoint)
  PI->>DBX: HTTPS REST call with the token
  DBX-->>PI: JSON
  PI-->>DV: Status + Result
  DV-->>App: Status + Result
```

## Inside the code

```mermaid
flowchart TD
  E[Execute] --> R[ReadInput Operation, Payload]
  R --> C[DemoConfig.Load<br/>env variable, https + azuredatabricks.net only]
  C --> Q{Operation}
  Q -->|dnsCheck| N[DnsCheck<br/>private ranges 10/8, 172.16/12, 192.168/16]
  Q -->|others| T[GetDatabricksToken<br/>IManagedIdentityService]
  T --> K[DatabricksClient<br/>30 s per call]
  K --> W[whoAmI . listClusters . startCluster . submitJob . runStatus]
  N --> O[Status + Result]
  W --> O
```

## Design choices

- **Plug-in behind a Custom API.** The plug-in is what runs inside the delegated subnet. The Custom API gives the app and the flow one clean, permission checked door with typed inputs and outputs.
- **Submit, then poll.** A notebook run can take minutes and a cluster start even longer. The plug-in only submits or reads status, so every call finishes in seconds, far below the 2 minute sandbox limit.
- **Managed identity with a federated credential.** No client secret and no personal access token to store or rotate. The credential is bound to the certificate that signed this assembly and to one environment.
- **Settings in an environment variable.** The URL and ids can change per environment through normal solution ALM, and nothing secret lives there.
- **Front end Private Link only.** The cluster reaches the control plane through secure cluster connectivity and the NAT gateway. The two private endpoints are for the REST API and browser sign in.
- **Synthetic data in the notebook.** The demo needs no storage account and no extra permissions.

## Data stored

The plug-in stores nothing. It returns JSON to the caller. The plug-in trace log keeps the operation, the host, the HTTP status codes and the timings, never the token.
