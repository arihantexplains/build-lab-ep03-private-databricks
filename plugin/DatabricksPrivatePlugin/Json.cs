using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;

namespace ArchitectBuilds.DatabricksPrivate
{
    /// <summary>Tiny JSON helpers on DataContractJsonSerializer (in the .NET Framework, allowed in the sandbox, no extra DLLs).</summary>
    internal static class Json
    {
        public static T Parse<T>(string json) where T : class
        {
            if (string.IsNullOrWhiteSpace(json)) return null;
            var serializer = new DataContractJsonSerializer(typeof(T), new DataContractJsonSerializerSettings { UseSimpleDictionaryFormat = true });
            using (var ms = new MemoryStream(Encoding.UTF8.GetBytes(json)))
            {
                return (T)serializer.ReadObject(ms);
            }
        }

        /// <summary>Writes a JSON string literal (or null) with the escapes JSON needs.</summary>
        public static string Str(string value)
        {
            if (value == null) return "null";
            var sb = new StringBuilder("\"");
            foreach (char c in value)
            {
                switch (c)
                {
                    case '"': sb.Append("\\\""); break;
                    case '\\': sb.Append("\\\\"); break;
                    case '\n': sb.Append("\\n"); break;
                    case '\r': sb.Append("\\r"); break;
                    case '\t': sb.Append("\\t"); break;
                    default:
                        if (c < ' ') sb.Append("\\u").Append(((int)c).ToString("x4"));
                        else sb.Append(c);
                        break;
                }
            }
            return sb.Append('"').ToString();
        }
    }

    // Only the fields the demo reads. Unknown fields are ignored by the serializer.

    [DataContract] internal sealed class ApiError
    {
        [DataMember(Name = "error_code")] public string ErrorCode { get; set; }
        [DataMember(Name = "message")] public string Message { get; set; }
    }

    [DataContract] internal sealed class ScimMe
    {
        [DataMember(Name = "displayName")] public string DisplayName { get; set; }
        [DataMember(Name = "userName")] public string UserName { get; set; }
        [DataMember(Name = "applicationId")] public string ApplicationId { get; set; }
    }

    [DataContract] internal sealed class ClusterList
    {
        [DataMember(Name = "clusters")] public ClusterInfo[] Clusters { get; set; }
    }

    [DataContract] internal sealed class ClusterInfo
    {
        [DataMember(Name = "cluster_id")] public string ClusterId { get; set; }
        [DataMember(Name = "cluster_name")] public string ClusterName { get; set; }
        [DataMember(Name = "state")] public string State { get; set; }
    }

    [DataContract] internal sealed class RunSubmitted
    {
        [DataMember(Name = "run_id")] public long RunId { get; set; }
    }

    [DataContract] internal sealed class Run
    {
        [DataMember(Name = "run_id")] public long RunId { get; set; }
        [DataMember(Name = "state")] public RunState State { get; set; }
        [DataMember(Name = "tasks")] public TaskRun[] Tasks { get; set; }
    }

    [DataContract] internal sealed class RunState
    {
        [DataMember(Name = "life_cycle_state")] public string LifeCycleState { get; set; }
        [DataMember(Name = "result_state")] public string ResultState { get; set; }
        [DataMember(Name = "state_message")] public string StateMessage { get; set; }
    }

    [DataContract] internal sealed class TaskRun
    {
        [DataMember(Name = "run_id")] public long RunId { get; set; }
        [DataMember(Name = "task_key")] public string TaskKey { get; set; }
    }

    [DataContract] internal sealed class RunOutput
    {
        [DataMember(Name = "notebook_output")] public NotebookOutput NotebookOutput { get; set; }
    }

    [DataContract] internal sealed class NotebookOutput
    {
        [DataMember(Name = "result")] public string Result { get; set; }
        [DataMember(Name = "truncated")] public bool Truncated { get; set; }
    }

    [DataContract] internal sealed class EnvConfigJson
    {
        [DataMember(Name = "workspaceUrl")] public string WorkspaceUrl { get; set; }
        [DataMember(Name = "clusterId")] public string ClusterId { get; set; }
        [DataMember(Name = "notebookPath")] public string NotebookPath { get; set; }
    }
}
