using System;
using System.Diagnostics;
using System.Linq;
using System.Net;
using Microsoft.Xrm.Sdk;

namespace ArchitectBuilds.DatabricksPrivate
{
    /// <summary>
    /// Main operation of the Custom API "ab_DatabricksRequest" (unbound action).
    /// Inputs : Operation (string, required), Payload (string, optional)
    /// Outputs: Status (string), Result (string, JSON)
    ///
    /// Security story in one line: the caller never sees a secret or the Databricks URL.
    /// Dataverse checks the caller's privilege on the Custom API, the plug-in runs inside the
    /// customer VNet (Power Platform VNet support), gets a short-lived Entra token through the
    /// environment's managed identity (federated credential bound to THIS signed assembly) and
    /// reaches Databricks only through the private endpoint.
    /// </summary>
    public sealed class DatabricksGatewayPlugin : IPlugin
    {
        // Microsoft Entra application ID of the AzureDatabricks first-party resource.
        internal const string DatabricksScope = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d/.default";

        // Keep well under the 2-minute sandbox limit. Long work is submit + poll, never wait here.
        private static readonly TimeSpan Budget = TimeSpan.FromSeconds(90);

        /// <summary>Runs one Operation of the Custom API and writes Status and Result to the output parameters.</summary>
        /// <param name="serviceProvider">The Dataverse plug-in service provider.</param>
        public void Execute(IServiceProvider serviceProvider)
        {
            var tracing = (ITracingService)serviceProvider.GetService(typeof(ITracingService));
            var context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            var factory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
            var clock = Stopwatch.StartNew();

            string operation = ReadInput(context, "Operation");
            string payload = ReadInput(context, "Payload");
            tracing.Trace("ab_DatabricksRequest: operation={0}, depth={1}, user={2}", operation, context.Depth, context.InitiatingUserId);

            try
            {
                // Settings live in a Dataverse environment variable (no secrets in it: URL + ids only).
                var service = factory.CreateOrganizationService(null);
                DemoConfig config = DemoConfig.Load(service, tracing);

                OperationResult result;
                if (operation == "dnsCheck")
                {
                    // Proof step: resolve the workspace host from INSIDE the delegated subnet.
                    result = DnsCheck(config, tracing);
                }
                else
                {
                    string token = GetDatabricksToken(serviceProvider, tracing);
                    var client = new DatabricksClient(config.WorkspaceUrl, token, tracing, Budget - clock.Elapsed);
                    result = Dispatch(operation, payload, config, client);
                }

                context.OutputParameters["Status"] = result.Status;
                context.OutputParameters["Result"] = result.Json;
                tracing.Trace("ab_DatabricksRequest: done status={0} in {1} ms", result.Status, clock.ElapsedMilliseconds);
            }
            catch (DatabricksException ex)
            {
                tracing.Trace("Databricks call failed: HTTP {0} {1}", (int)ex.StatusCode, ex.ErrorCode);
                throw new InvalidPluginExecutionException(
                    "Databricks returned " + (int)ex.StatusCode + " (" + ex.ErrorCode + "). See the plug-in trace log.", ex);
            }
            catch (InvalidPluginExecutionException)
            {
                throw;
            }
            catch (Exception ex)
            {
                tracing.Trace("Unexpected error: {0}", ex.ToString());
                throw new InvalidPluginExecutionException("The Databricks request failed: " + ex.Message, ex);
            }
        }

        /// <summary>Secretless token: the platform issues it for the managed identity linked to this assembly.</summary>
        internal static string GetDatabricksToken(IServiceProvider serviceProvider, ITracingService tracing)
        {
            var identity = (IManagedIdentityService)serviceProvider.GetService(typeof(IManagedIdentityService));
            if (identity == null)
            {
                throw new InvalidPluginExecutionException(
                    "IManagedIdentityService is not available. Link a managed identity record to this plug-in assembly.");
            }

            var sw = Stopwatch.StartNew();
            string token = identity.AcquireToken(new[] { DatabricksScope });
            tracing.Trace("Token acquired for AzureDatabricks in {0} ms (length {1}; the token itself is never logged)",
                sw.ElapsedMilliseconds, token == null ? 0 : token.Length);
            return token;
        }

        private static OperationResult Dispatch(string operation, string payload, DemoConfig config, DatabricksClient client)
        {
            switch (operation)
            {
                case "whoAmI":
                    return OperationResult.Ok(client.WhoAmI());

                case "listClusters":
                    return OperationResult.Ok(client.ListClusters());

                case "startCluster":
                    return client.StartCluster(config.ClusterId);

                case "submitJob":
                    int rows = ParseRows(payload);
                    return OperationResult.Ok(client.SubmitNotebookRun(config.ClusterId, config.NotebookPath, rows));

                case "runStatus":
                    long runId = ParseRunId(payload);
                    return client.GetRunStatus(runId);

                default:
                    throw new InvalidPluginExecutionException(
                        "Unknown Operation. Allowed: whoAmI, listClusters, startCluster, submitJob, runStatus, dnsCheck.");
            }
        }

        private static OperationResult DnsCheck(DemoConfig config, ITracingService tracing)
        {
            string host = new Uri(config.WorkspaceUrl).Host;
            IPAddress[] addresses = Dns.GetHostAddresses(host);
            string list = string.Join(",", addresses.Select(a => "\"" + a + "\""));
            bool allPrivate = addresses.Length > 0 && addresses.All(IsPrivate);
            tracing.Trace("DNS {0} -> {1} (private={2})", host, list, allPrivate);
            return new OperationResult(allPrivate ? "Private" : "Public",
                "{\"host\":\"" + host + "\",\"addresses\":[" + list + "],\"private\":" + (allPrivate ? "true" : "false") + "}");
        }

        private static bool IsPrivate(IPAddress ip)
        {
            byte[] b = ip.GetAddressBytes();
            return b.Length == 4 && (b[0] == 10 || (b[0] == 172 && b[1] >= 16 && b[1] <= 31) || (b[0] == 192 && b[1] == 168));
        }

        private static string ReadInput(IPluginExecutionContext context, string name)
        {
            object value;
            return context.InputParameters.TryGetValue(name, out value) ? (value as string ?? string.Empty).Trim() : string.Empty;
        }

        private static int ParseRows(string payload)
        {
            int rows;
            if (string.IsNullOrEmpty(payload)) return 1000;
            if (!int.TryParse(payload, out rows) || rows < 1 || rows > 1000000)
            {
                throw new InvalidPluginExecutionException("Payload for submitJob must be a row count between 1 and 1000000.");
            }
            return rows;
        }

        private static long ParseRunId(string payload)
        {
            long runId;
            if (!long.TryParse(payload, out runId) || runId <= 0)
            {
                throw new InvalidPluginExecutionException("Payload for runStatus must be the numeric run id returned by submitJob.");
            }
            return runId;
        }
    }

    internal sealed class OperationResult
    {
        public OperationResult(string status, string json) { Status = status; Json = json; }
        public string Status { get; private set; }
        public string Json { get; private set; }
        public static OperationResult Ok(string json) { return new OperationResult("OK", json); }
    }
}
