# Security

This is a teaching sample from a YouTube episode, not a supported product. It changes real network settings in Azure and runs code inside your Power Platform environment, so please read this before you run it anywhere.

## Use a demo environment first

- Build it in a demo or developer environment and a test subscription, never straight in production.
- The demo signs the plug-in with a self-signed certificate that expires after 7 days. For real use, sign with a certificate your organisation issues.
- When you finish the demo, delete the resource group so the workspace, the NAT gateway and the endpoints stop costing money.

## Keep your settings out of Git

The repo contains placeholders only. Your tenant, subscription and environment IDs, the environment URL, the workspace URL, the managed identity client id and the cluster id belong in `scripts/config.ps1` (git-ignored) and in the Dataverse environment variable, never in code, commits or issues. The `.gitignore` blocks `config.ps1`, signing keys, certificates and solution exports, but check `git status` before every commit anyway.

If you open an issue, remove IDs, URLs, IP addresses and names from logs and screenshots first.

## What the sample does to stay safe

The guardrails are described in [docs/security.md](docs/security.md): public network access off on the workspace, the REST API reached through a private endpoint only, the plug-in running inside your delegated subnet, a managed identity with a federated credential instead of a secret, a host check on the workspace URL, a fixed list of operations with input checks, time limits on every call, and least privilege in Databricks. The same page lists the known limits.

## Reporting a problem

If you find a security problem in the code, please don't open a public issue with exploit details. Use GitHub's **Report a vulnerability** button on the Security tab of this repository (private vulnerability reporting), or open an issue that just says you found something and would like a private way to share it.

There is no bug bounty and no guaranteed response time, but I read every report and will fix real problems in the sample.
