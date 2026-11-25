# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Register the signed assembly with the Plugin Registration Tool first. Linking a managed identity to an assembly has no maker UI yet, so this part uses the Dataverse Web API.
$org=$ORG; $api="$org/api/data/v9.2"; $tok = az account get-access-token --resource $org --query accessToken -o tsv
$h=@{Authorization="Bearer $tok"; 'Content-Type'='application/json; charset=utf-8'; Accept='application/json'}
$asm = (Invoke-RestMethod "$api/pluginassemblies?`$select=name,isolationmode&`$filter=name eq 'ArchitectBuilds.DatabricksPrivate'" -Headers $h).value[0]; $pt = (Invoke-RestMethod "$api/plugintypes?`$select=typename&`$filter=_pluginassemblyid_value eq $($asm.pluginassemblyid)" -Headers $h).value[0]
[pscustomobject]@{ assembly=$asm.name; isolation='Sandbox'; pluginType=$pt.typename } | Format-List
# 1) Managed identity record: the Entra identity the plug-in becomes when it asks for a token. Federated, no secret anywhere.
$tenant = az account show --query tenantId -o tsv; $mi = [guid]::NewGuid().ToString()
Invoke-RestMethod "$api/managedidentities" -Method Post -Headers $h -Body (@{ managedidentityid=$mi; applicationid=$MI_CLIENT_ID; tenantid=$tenant; credentialsource=2; subjectscope=1 } | ConvertTo-Json); "managed identity record created: $mi"
# 2) Link it to the plug-in assembly
Invoke-RestMethod "$api/pluginassemblies($($asm.pluginassemblyid))" -Method Patch -Headers $h -Body (@{ 'managedidentityid@odata.bind'="/managedidentities($mi)" } | ConvertTo-Json); 'assembly linked to the managed identity'
# 3) Custom API ab_DatabricksRequest: the one door Power Apps and Power Automate call. Its plug-in type runs it, so no extra step is needed.
$hs = $h.Clone(); $hs['MSCRM.SolutionUniqueName'] = $SOLUTION
$capi = @{ uniquename='ab_DatabricksRequest'; name='ab_DatabricksRequest'; displayname='Databricks Request'; description='Calls the private Databricks workspace through the VNet plug-in'; bindingtype=0; isfunction=$false; isprivate=$false; allowedcustomprocessingsteptype=0; 'PluginTypeId@odata.bind'="/plugintypes($($pt.plugintypeid))"; CustomAPIRequestParameters=@( @{ uniquename='Operation'; name='Operation'; displayname='Operation'; description='whoAmI, listClusters, startCluster, submitJob, runStatus, dnsCheck'; type=10; isoptional=$false }, @{ uniquename='Payload'; name='Payload'; displayname='Payload'; description='Optional JSON input'; type=10; isoptional=$true } ); CustomAPIResponseProperties=@( @{ uniquename='Status'; name='Status'; displayname='Status'; type=10 }, @{ uniquename='Result'; name='Result'; displayname='Result'; type=10 } ) } | ConvertTo-Json -Depth 5
Invoke-RestMethod "$api/customapis" -Method Post -Headers $hs -Body $capi; 'custom API ab_DatabricksRequest created in your solution'
# 4) Add the plug-in assembly to the same solution, so one export carries everything
Invoke-RestMethod "$api/AddSolutionComponent" -Method Post -Headers $h -Body (@{ ComponentId=$asm.pluginassemblyid; ComponentType=91; SolutionUniqueName=$SOLUTION; AddRequiredComponents=$false; DoNotIncludeSubcomponents=$false } | ConvertTo-Json) | Out-Null; 'assembly added to the solution'
# Check: read everything back
$c = (Invoke-RestMethod "$api/customapis?`$select=uniquename,bindingtype,isfunction&`$filter=uniquename eq 'ab_DatabricksRequest'&`$expand=PluginTypeId(`$select=typename),CustomAPIRequestParameters(`$select=uniquename,isoptional),CustomAPIResponseProperties(`$select=uniquename)" -Headers $h).value[0]
[pscustomobject]@{ customApi=$c.uniquename; kind='unbound action'; runsPlugin=$c.PluginTypeId.typename; inputs=($c.CustomAPIRequestParameters.uniquename -join ', '); outputs=($c.CustomAPIResponseProperties.uniquename -join ', '); assemblyIdentity=(Invoke-RestMethod "$api/pluginassemblies($($asm.pluginassemblyid))?`$select=_managedidentityid_value" -Headers $h)._managedidentityid_value } | Format-List
