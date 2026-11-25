# Copy to config.ps1 (ignored by git) and fill in YOUR demo values. Then dot-source it:  . .\scripts\config.ps1
$RG       = 'rg-ab-dbx-private'                       # resource group
$LOC      = 'centralindia'                            # main region (Databricks, endpoints, Power Platform subnet)
$PAIR     = 'southindia'                              # the other region of your Power Platform geography
$WS       = 'dbw-ab-private'                          # Databricks workspace name
$MRG      = "databricks-rg-$WS"                       # managed resource group Databricks creates
$ENVID    = '<your-power-platform-environment-id>'    # Power Platform admin center > Environments > your demo environment
$ORG      = 'https://<your-org>.crm.dynamics.com'     # the environment URL
$MI_CLIENT_ID = '<client-id-of-id-ab-plugin>'         # az identity show -g $RG -n id-ab-plugin --query clientId -o tsv
$SOLUTION = '<your-solution-unique-name>'             # the Dataverse solution that carries the Custom API and the assembly
