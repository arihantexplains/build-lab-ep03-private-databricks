using System;
using System.Diagnostics;
using System.Globalization;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using Microsoft.Xrm.Sdk;

namespace ArchitectBuilds.DatabricksPrivate
{
    /// <summary>
    /// Thin wrapper over the Azure Databricks workspace REST API.
    /// Every call is short (seconds). Long work (a notebook run) is SUBMIT then POLL from the caller,
    /// so the plug-in never comes near the 2-minute sandbox limit.
    /// </summary>
    internal sealed class DatabricksClient
    {
        // One HttpClient per sandbox worker (recommended for plug-ins). Per-call timeout below.
        private static readonly HttpClient Http = new HttpClient { Timeout = System.Threading.Timeout.InfiniteTimeSpan };

        private readonly Uri _baseUri;
        private readonly string _token;
        private readonly ITracingService _tracing;
        private readonly TimeSpan _perCallTimeout;

        public DatabricksClient(string workspaceUrl, string token, ITracingService tracing, TimeSpan remaining)
        {
            _baseUri = new Uri(workspaceUrl.TrimEnd('/') + "/");
            _token = token;
            _tracing = tracing;
            // 30 s per call, never more than what is left of the plug-in budget.
            _perCallTimeout = remaining < TimeSpan.FromSeconds(30) ? remaining : TimeSpan.FromSeconds(30);
        }

        /// <summary>GET /api/2.0/preview/scim/v2/Me - proves WHO Databricks thinks we are (the managed identity).</summary>
        public string WhoAmI()
        {
            var me = Json.Parse<ScimMe>(Send(HttpMethod.Get, "api/2.0/preview/scim/v2/Me", null));
            return "{\"displayName\":" + Json.Str(me.DisplayName) +
                   ",\"applicationId\":" + Json.Str(me.ApplicationId) +
                   ",\"userName\":" + Json.Str(me.UserName) + "}";
        }

        /// <summary>GET /api/2.1/clusters/list - only clusters this identity has permission on are returned.</summary>
        public string ListClusters()
        {
            var list = Json.Parse<ClusterList>(Send(HttpMethod.Get, "api/2.1/clusters/list", null));
            var sb = new StringBuilder("{\"clusters\":[");
            if (list.Clusters != null)
            {
                for (int i = 0; i < list.Clusters.Length; i++)
                {
                    var c = list.Clusters[i];
                    if (i > 0) sb.Append(',');
                    sb.Append("{\"id\":").Append(Json.Str(c.ClusterId))
                      .Append(",\"name\":").Append(Json.Str(c.ClusterName))
                      .Append(",\"state\":").Append(Json.Str(c.State)).Append('}');
                }
            }
            return sb.Append("]}").ToString();
        }

        /// <summary>POST /api/2.1/clusters/start - needs CAN_RESTART on the one demo cluster, nothing more.</summary>
        public OperationResult StartCluster(string clusterId)
        {
            try
            {
                Send(HttpMethod.Post, "api/2.1/clusters/start", "{\"cluster_id\":" + Json.Str(clusterId) + "}");
                return new OperationResult("Starting", "{\"clusterId\":" + Json.Str(clusterId) + "}");
            }
            catch (DatabricksException ex)
            {
                // Starting a cluster that is already running returns INVALID_STATE: that is fine for a demo.
                if (ex.ErrorCode == "INVALID_STATE")
                {
                    return new OperationResult("AlreadyRunning", "{\"clusterId\":" + Json.Str(clusterId) + "}");
                }
                throw;
            }
        }

        /// <summary>POST /api/2.2/jobs/runs/submit - one-time notebook run on the demo cluster. Returns at once with a run id.</summary>
        public string SubmitNotebookRun(string clusterId, string notebookPath, int rows)
        {
            string body =
                "{\"run_name\":\"ab-powerplatform-request\"," +
                "\"timeout_seconds\":900," +
                "\"tasks\":[{\"task_key\":\"summary\"," +
                "\"existing_cluster_id\":" + Json.Str(clusterId) + "," +
                "\"notebook_task\":{\"notebook_path\":" + Json.Str(notebookPath) + "," +
                "\"base_parameters\":{\"rows\":\"" + rows.ToString(CultureInfo.InvariantCulture) + "\"}}}]}";

            var submitted = Json.Parse<RunSubmitted>(Send(HttpMethod.Post, "api/2.2/jobs/runs/submit", body));
            return "{\"runId\":" + submitted.RunId.ToString(CultureInfo.InvariantCulture) + "}";
        }

        /// <summary>GET /api/2.2/jobs/runs/get (+ runs/get-output when finished) - the POLL half of submit + poll.</summary>
        public OperationResult GetRunStatus(long runId)
        {
            var run = Json.Parse<Run>(Send(HttpMethod.Get,
                "api/2.2/jobs/runs/get?run_id=" + runId.ToString(CultureInfo.InvariantCulture), null));

            string life = run.State != null ? run.State.LifeCycleState : "UNKNOWN";
            string outcome = run.State != null ? run.State.ResultState : null;
            string output = "null";

            if (life == "TERMINATED" && outcome == "SUCCESS" && run.Tasks != null && run.Tasks.Length > 0)
            {
                // Output belongs to the TASK run, not the parent run.
                var result = Json.Parse<RunOutput>(Send(HttpMethod.Get,
                    "api/2.2/jobs/runs/get-output?run_id=" + run.Tasks[0].RunId.ToString(CultureInfo.InvariantCulture), null));
                if (result.NotebookOutput != null && !string.IsNullOrEmpty(result.NotebookOutput.Result))
                {
                    output = result.NotebookOutput.Result; // the notebook returns JSON via dbutils.notebook.exit
                }
            }

            string status = life == "TERMINATED" || life == "INTERNAL_ERROR" || life == "SKIPPED" ? (outcome ?? life) : life;
            return new OperationResult(status,
                "{\"runId\":" + runId.ToString(CultureInfo.InvariantCulture) +
                ",\"lifeCycleState\":" + Json.Str(life) +
                ",\"resultState\":" + Json.Str(outcome) +
                ",\"message\":" + Json.Str(run.State != null ? run.State.StateMessage : null) +
                ",\"output\":" + output + "}");
        }

        private string Send(HttpMethod method, string relativePath, string jsonBody)
        {
            var sw = Stopwatch.StartNew();
            using (var request = new HttpRequestMessage(method, new Uri(_baseUri, relativePath)))
            using (var cts = new System.Threading.CancellationTokenSource(_perCallTimeout))
            {
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _token);
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                request.Headers.ConnectionClose = true; // no long-lived sockets inside the sandbox
                if (jsonBody != null)
                {
                    request.Content = new StringContent(jsonBody, Encoding.UTF8, "application/json");
                }

                HttpResponseMessage response;
                try
                {
                    response = Http.SendAsync(request, cts.Token).GetAwaiter().GetResult();
                }
                catch (OperationCanceledException)
                {
                    throw new InvalidPluginExecutionException(
                        "Databricks did not answer within " + _perCallTimeout.TotalSeconds + " s. Is the private endpoint and DNS in place?");
                }

                using (response)
                {
                    string text = response.Content.ReadAsStringAsync().GetAwaiter().GetResult();
                    _tracing.Trace("{0} /{1} -> {2} in {3} ms", method, relativePath.Split('?')[0], (int)response.StatusCode, sw.ElapsedMilliseconds);
                    if (!response.IsSuccessStatusCode)
                    {
                        var err = SafeParseError(text);
                        throw new DatabricksException(response.StatusCode, err.ErrorCode ?? "HTTP_" + (int)response.StatusCode, err.Message);
                    }
                    return text;
                }
            }
        }

        private static ApiError SafeParseError(string text)
        {
            try { return Json.Parse<ApiError>(text) ?? new ApiError(); }
            catch { return new ApiError(); }
        }
    }

    internal sealed class DatabricksException : Exception
    {
        public DatabricksException(HttpStatusCode statusCode, string errorCode, string message)
            : base(message ?? errorCode)
        {
            StatusCode = statusCode;
            ErrorCode = errorCode;
        }

        public HttpStatusCode StatusCode { get; private set; }
        public string ErrorCode { get; private set; }
    }
}
