# Changelog

All notable changes to this repo. Dates are in the format YYYY-MM-DD.

## [1.0.0] - 2026-11-25

First public release, alongside Architect's Build Lab, Episode 3 (https://youtu.be/RI6cb9neoEA).

### Added

- C# Dataverse plug-in `DatabricksGatewayPlugin` behind the Custom API `ab_DatabricksRequest`, with six operations: `whoAmI`, `dnsCheck`, `listClusters`, `startCluster`, `submitJob` and `runStatus`.
- Databricks notebook `summary.py` that builds synthetic rows and returns a JSON summary.
- Canvas app source (Power Apps YAML) with one button per operation.
- Azure CLI and Dataverse Web API scripts in build order: network, private DNS, private endpoints, peering, managed identity, signing, federated credential, enterprise policy, Managed Environment, link, trace log, Custom API.
- Docs: architecture, setup, permissions, security, a printable build checklist and a glossary.

### Security

- Managed identity with a federated credential bound to the signed assembly and the environment, no secrets anywhere.
- Host check on the workspace URL, a fixed list of operations, input checks, 30 s per call and 90 s per run.
- The token is never written to the trace log.
