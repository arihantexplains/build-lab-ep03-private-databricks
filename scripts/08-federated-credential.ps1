# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Federated credential: trust tokens that Power Platform issues for THIS signed plug-in in THIS environment only
$dll = ".\plugin\DatabricksPrivatePlugin\bin\Release\net462\ArchitectBuilds.DatabricksPrivate.dll"
Get-AuthenticodeSignature $dll | Select-Object @{n='Signer';e={$_.SignerCertificate.Subject}}, @{n='SignedWith';e={'SHA256'}} | Format-List
$fic = & .\scripts\tools\fic-subject.ps1 -Dll $dll -EnvId $ENVID
$fic | Format-List
az identity federated-credential create -g $RG --identity-name id-ab-plugin -n fic-ab-plugin --issuer $fic.Issuer --subject $fic.Subject --audiences api://AzureADTokenExchange --query "{credential:name, audience:audiences[0]}" -o table
az identity show -g $RG -n id-ab-plugin --query "{identity:name, clientId:clientId}" -o table
