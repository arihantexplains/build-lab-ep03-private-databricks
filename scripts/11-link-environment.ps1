# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Link the NetworkInjection enterprise policy to the (now Managed) Demo environment
# Same call the Power Platform admin center / Enable-SubnetInjection makes. Free. Undo = .../unlink with the same body.
$sys = az resource show -g $RG -n ep-ab-vnet --resource-type Microsoft.PowerPlatform/enterprisePolicies --query properties.systemId -o tsv
"policy systemId: $sys"
$t = az account get-access-token --resource https://service.powerapps.com/ --query accessToken -o tsv
$h = @{Authorization="Bearer $t"}
$base = "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform"
$r = Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$base/environments/$ENVID/enterprisePolicies/NetworkInjection/link?api-version=2019-10-01" -Headers $h -ContentType 'application/json' -Body (@{SystemId=$sys} | ConvertTo-Json)
"link request: HTTP $($r.StatusCode)"
for ($i=0; $i -lt 40; $i++) {
  $e = Invoke-RestMethod -Uri "$base/scopes/admin/environments/$($ENVID)?api-version=2021-04-01" -Headers $h
  $vn = $e.properties.enterprisePolicies.Vnets
  if ($vn -and $vn.linkStatus -eq 'Linked') { break }
  "waiting... $($vn.linkStatus)"; Start-Sleep 15
}
[pscustomobject]@{ environment=$e.properties.displayName; policy=($vn.id -split '/')[-1]; linkStatus=$vn.linkStatus; location=$vn.location } | Format-List
