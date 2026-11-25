using System;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;

namespace ArchitectBuilds.DatabricksPrivate
{
    /// <summary>
    /// Reads the Dataverse environment variable "ab_DatabricksConfig" (JSON, NO secrets):
    /// { "workspaceUrl": "https://adb-1234567890123456.7.azuredatabricks.net",
    ///   "clusterId": "1123-123456-abcd123", "notebookPath": "/Shared/ab-demo/summary" }
    /// The current value wins over the default value, so ALM can change it per environment.
    /// </summary>
    internal sealed class DemoConfig
    {
        public const string VariableName = "ab_DatabricksConfig";

        public string WorkspaceUrl { get; private set; }
        public string ClusterId { get; private set; }
        public string NotebookPath { get; private set; }

        public static DemoConfig Load(IOrganizationService service, ITracingService tracing)
        {
            var query = new QueryExpression("environmentvariabledefinition")
            {
                ColumnSet = new ColumnSet("defaultvalue"),
                TopCount = 1,
                Criteria = { Conditions = { new ConditionExpression("schemaname", ConditionOperator.Equal, VariableName) } }
            };
            var link = query.AddLink("environmentvariablevalue", "environmentvariabledefinitionid",
                "environmentvariabledefinitionid", JoinOperator.LeftOuter);
            link.EntityAlias = "v";
            link.Columns = new ColumnSet("value");

            var rows = service.RetrieveMultiple(query).Entities;
            if (rows.Count == 0)
            {
                throw new InvalidPluginExecutionException("Environment variable " + VariableName + " is missing.");
            }

            var row = rows[0];
            var current = row.GetAttributeValue<AliasedValue>("v.value");
            string json = current != null ? current.Value as string : row.GetAttributeValue<string>("defaultvalue");
            var parsed = Json.Parse<EnvConfigJson>(json);
            if (parsed == null || string.IsNullOrEmpty(parsed.WorkspaceUrl))
            {
                throw new InvalidPluginExecutionException("Environment variable " + VariableName + " has no workspaceUrl.");
            }

            Uri uri;
            if (!Uri.TryCreate(parsed.WorkspaceUrl, UriKind.Absolute, out uri) || uri.Scheme != Uri.UriSchemeHttps
                || !uri.Host.EndsWith(".azuredatabricks.net", StringComparison.OrdinalIgnoreCase))
            {
                // Guard rail: the plug-in only ever talks to an Azure Databricks host over HTTPS.
                throw new InvalidPluginExecutionException("workspaceUrl must be https://<workspace>.azuredatabricks.net");
            }

            tracing.Trace("Config: host={0}, cluster={1}, notebook={2}", uri.Host, parsed.ClusterId, parsed.NotebookPath);
            return new DemoConfig
            {
                WorkspaceUrl = "https://" + uri.Host,
                ClusterId = parsed.ClusterId,
                NotebookPath = parsed.NotebookPath ?? "/Shared/ab-demo/summary"
            };
        }
    }
}
