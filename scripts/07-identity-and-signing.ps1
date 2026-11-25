# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Secretless identity: a user-assigned managed identity the plug-in will use (no client secret, no PAT)
az identity create -g $RG -n id-ab-plugin -l $LOC --query "{identity:name, region:location}" -o table
# Sign the plug-in assembly with a short-lived self-signed code-signing certificate (demo only, 7 days)
$cert = New-SelfSignedCertificate -Subject "CN=ArchitectBuilds Plugin Demo" -Type CodeSigningCert -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddDays(7)
dotnet build ".\plugin\DatabricksPrivatePlugin" -c Release -nologo -v q
Set-AuthenticodeSignature -FilePath ".\plugin\DatabricksPrivatePlugin\bin\Release\net462\ArchitectBuilds.DatabricksPrivate.dll" -Certificate $cert -HashAlgorithm SHA256 | Select-Object Status, StatusMessage | Format-List
$cert | Select-Object Subject, NotAfter, Thumbprint | Format-List
