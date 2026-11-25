# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Plug-in trace log = All, so every call to the plug-in leaves a trace row. The modern admin center has no switch for this yet (only the classic System Settings dialog), so one Web API call.
$org=$ORG; $api="$org/api/data/v9.2"; $h=@{Authorization="Bearer $(az account get-access-token --resource $org --query accessToken -o tsv)"; 'Content-Type'='application/json'; Accept='application/json'}
$o = (Invoke-RestMethod "$api/organizations?`$select=plugintracelogsetting" -Headers $h).value[0]; "before: $($o.plugintracelogsetting)  (0 off, 1 exceptions, 2 all)"
Invoke-RestMethod "$api/organizations($($o.organizationid))" -Method Patch -Headers $h -Body '{"plugintracelogsetting":2}'; "after: $((Invoke-RestMethod "$api/organizations?`$select=plugintracelogsetting" -Headers $h).value[0].plugintracelogsetting)  = All"
