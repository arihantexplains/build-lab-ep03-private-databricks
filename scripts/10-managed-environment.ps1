# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Managed Environment: Power Platform VNet support only works on a MANAGED environment
# Free to turn on (no Azure charge). Users who run apps/flows there need a premium licence (enforced from Feb 2027).
pac env list
pac admin set-governance-config --environment $ENVID --protection-level Standard
$t = az account get-access-token --resource https://service.powerapps.com/ --query accessToken -o tsv
$e = Invoke-RestMethod -Uri "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments/$($ENVID)?api-version=2021-04-01&`$expand=properties.governanceConfiguration" -Headers @{Authorization="Bearer $t"}
[pscustomobject]@{ environment=$e.properties.displayName; type=$e.properties.environmentSku; geo=$e.location; protectionLevel=$e.properties.governanceConfiguration.protectionLevel } | Format-List
