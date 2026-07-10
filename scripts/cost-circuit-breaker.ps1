# Connect azure account using assigned zero-trust identity
Connect-AzAccount -Identity

$ResourceGroup = "rg-sentinel-threat-honeypot"
$VMName = "vm-win-honeypot"

#Force stop of VM
Stop-AzVM  -ResourceGroupName $ResourceGroup -Name $VMName -Force
