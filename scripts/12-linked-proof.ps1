# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Proof: Demo is a Managed Environment and the VNet enterprise policy is Linked
$t = az account get-access-token --resource https://service.powerapps.com/ --query accessToken -o tsv
$e = Invoke-RestMethod -Uri "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments/$($ENVID)?api-version=2021-04-01&`$expand=properties.governanceConfiguration" -Headers @{Authorization="Bearer $t"}
[pscustomobject]@{ environment=$e.properties.displayName; managed=$e.properties.governanceConfiguration.protectionLevel; policy=($e.properties.enterprisePolicies.Vnets.id -split '/')[-1]; linkStatus=$e.properties.enterprisePolicies.Vnets.linkStatus } | Format-List
