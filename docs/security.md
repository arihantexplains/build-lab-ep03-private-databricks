# Security model

## Guardrails and where they live

| Guardrail | Where |
|---|---|
| Public network access on the workspace is **Disabled**, the internet gets 403 | Workspace networking (setup step 6) |
| The REST API is reached only through the private endpoint, the name resolves to a private IP | `scripts/04-private-dns.ps1`, `scripts/05-private-endpoints.ps1` |
| The plug-in runs inside your delegated subnet | Enterprise policy + Managed Environment (`scripts/09` to `12`) |
| No secrets: a managed identity with a federated credential, bound to the signing certificate and to one environment | `scripts/07`, `scripts/08`, `GetDatabricksToken` |
| The token is never logged, only its length | `DatabricksGatewayPlugin.GetDatabricksToken` |
| The plug-in only calls `https://<host>.azuredatabricks.net` | `DemoConfig.Load` |
| Only six known operations, anything else is refused | `DatabricksGatewayPlugin.Dispatch` |
| Payload checks: row count 1 to 1,000,000, run id must be a positive number | `ParseRows`, `ParseRunId` |
| Time limits: 30 s per HTTP call, 90 s per plug-in run, `timeout_seconds` 900 on the notebook run | `DatabricksClient`, `DatabricksGatewayPlugin` |
| The cluster has no public IP, outbound goes through a NAT gateway | `scripts/02-nat-gateway.ps1`, `03-workspace.ps1` |
| Least privilege in Databricks: Can Restart on one cluster, one notebook | [permissions.md](permissions.md) |

## Known limits (be honest about them)

- **Demo signing certificate.** `scripts/07` makes a self-signed certificate that expires after 7 days. For real use, sign with a certificate from your organisation and update the federated credential subject.
- **Host check, not an allow list.** `DemoConfig` accepts any `*.azuredatabricks.net` host. Anyone who can change the environment variable can point the plug-in at another workspace, where the managed identity would still need permissions. Protect who can edit environment variables, or pin the exact host in code.
- **`dnsCheck` checks IPv4 private ranges only.** An IPv6 answer is reported as not private.
- **Error text.** Databricks error codes are passed back to the caller in the exception message (for example `403 (PERMISSION_DENIED)`). The full details stay in the trace log.
- **Trace log set to All.** Good for a demo. In production switch it to exceptions only.
- **The NAT gateway's public IP** is the cluster's outbound address. Restrict outbound traffic with your firewall rules if your policy requires it.

## Keep your values out of Git

`scripts/config.ps1`, `key.snk`, certificates, `bin/`, `obj/` and solution zips are git-ignored. Check `git status` before every commit anyway.
