param([string]$Dll, [string]$EnvId)
# Builds the v2 federated credential subject for a self-signed plug-in certificate (Learn: Set up managed identity)
function B64Url([byte[]]$b) { [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
$tenant = az account show --query tenantId -o tsv
$cert = (Get-AuthenticodeSignature $Dll).SignerCertificate
$hash = -join ([Security.Cryptography.SHA256]::Create().ComputeHash($cert.RawData) | ForEach-Object { $_.ToString("x2") })   # Power Platform presents the cert SHA-256 as lowercase hex
$encTenant = B64Url ([Guid]$tenant).ToByteArray()
[pscustomobject]@{
  Issuer  = "https://login.microsoftonline.com/$tenant/v2.0"
  Subject = "/eid1/c/pub/t/$encTenant/a/qzXoWDkuqUa3l6zM5mM0Rw/n/plugin/e/$EnvId/h/$hash"
}
