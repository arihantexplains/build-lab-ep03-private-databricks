# Run from the repo root after:  . .\scripts\config.ps1   (copy config.sample.ps1 to config.ps1 first)
# Preflight: who am I, which subscription, which Power Platform environment
az account show --query "{subscription:name, user:user.type}" -o table
pac org who | Select-String 'Environment|Org Url|Friendly|Version'
# Resource providers (registering is free)
az provider list --query "[?namespace=='Microsoft.Databricks' || namespace=='Microsoft.PowerPlatform' || namespace=='Microsoft.Network' || namespace=='Microsoft.ManagedIdentity'].{provider:namespace, state:registrationState}" -o table
# vCPU quota in Central India for the cluster and jump VM families
az vm list-usage -l centralindia --query "[?contains(name.value,'DSv2') || contains(name.value,'BS') || name.value=='cores'].{family:localName, used:currentValue, limit:limit}" -o table
