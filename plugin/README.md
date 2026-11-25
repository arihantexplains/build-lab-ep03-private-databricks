# The Dataverse plug-in

`DatabricksPrivatePlugin` is a C# plug-in for .NET Framework 4.6.2. It is registered on the Custom API `ab_DatabricksRequest` and runs inside your delegated subnet through Power Platform VNet support.

| File | What it does |
|---|---|
| `DatabricksGatewayPlugin.cs` | Entry point. Reads `Operation` and `Payload`, loads the settings, gets the token from the managed identity, runs one operation, writes `Status` and `Result` |
| `DatabricksClient.cs` | Small REST client for the Databricks API, 30 s per call, turns errors into clear messages |
| `DemoConfig.cs` | Reads the environment variable `ab_DatabricksConfig` and checks the workspace URL is `https://<workspace>.azuredatabricks.net` |
| `Json.cs` | Tiny JSON helpers, so the assembly needs no extra packages |

## Build

```powershell
cd plugin/DatabricksPrivatePlugin
sn -k key.snk            # once, your own strong name key (git-ignored)
dotnet build -c Release  # 0 errors, 0 warnings
```

Then sign the DLL and register it, see [docs/setup.md](../docs/setup.md) steps 2 and 4.
