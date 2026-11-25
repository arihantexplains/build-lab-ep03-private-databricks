param([string]$RG)
$ci = az network vnet show -g $RG -n vnet-ab-ci --query id -o tsv
$si = az network vnet show -g $RG -n vnet-ab-si --query id -o tsv
$body = @{ location='india'; kind='NetworkInjection'; properties=@{ networkInjection=@{ virtualNetworks=@(
  @{ id=$ci; subnet=@{ name='snet-pp-ci' } }, @{ id=$si; subnet=@{ name='snet-pp-si' } } ) } } } | ConvertTo-Json -Depth 8
$f = Join-Path $env:TEMP 'ep-ab-vnet.json'; [IO.File]::WriteAllText($f, $body); $f
