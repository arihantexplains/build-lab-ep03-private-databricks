# Scripts in build order

PowerShell with the Azure CLI (`az`) and the Dataverse Web API. Run them one by one and check the result of each before the next, exactly as in [docs/setup.md](../docs/setup.md).

1. Copy `config.sample.ps1` to `config.ps1` (git-ignored), fill in your demo values.
2. `az login`, `pac auth create`, then `. .\scripts\config.ps1` from the repo root.
3. `00-preflight.ps1`, then `01` to `14`.

| Scripts | Layer |
|---|---|
| `00` | Checks before you start |
| `01` to `06` | Network: VNets, NAT gateway, workspace, private DNS, private endpoints, peering |
| `07`, `08` | Identity: managed identity, signing, federated credential |
| `09` to `12` | Power Platform: enterprise policy, Managed Environment, link, proof |
| `13`, `14` | Dataverse: trace log, managed identity record, Custom API |
| `tools/` | Helpers: the enterprise policy body and the federated credential subject |

The scripts are written for a demo. Read each one before you run it.
