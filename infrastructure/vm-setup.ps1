## This script establishes the necessary prerequisites for the honeypot VM environment

#Syncronise system clock with NTP servers
Write-Host "Synchronizing system clock with global NTP servers..."
# Stop the time service to release any locked files
Stop-Service w32time
# Configure the VM to sync with the global NTP pool
w32tm /config /manualpeerlist:"pool.ntp.org,0x8" /syncfromflags:manual /update
# Restart the service and force an immediate resync
Start-Service w32time
w32tm /resync

# Install Az.KeyVault Module
Write-Host "Installing Az.KeyVault module..."
Install-Module -Name Az.KeyVault -Force -AllowClobber -Scope AllUsers

# Block user access to IMDS IP
Write-Host "Blocking user access to IMDS IP..."
# Grab the SID of user
$UserSID = (Get-LocalUser -Name "YOUR_USER").SID.Value
# Format the SID into the required SDDL string format
$SDDL = "D:(A;;CC;;;$UserSID)"
# Apply the rule
New-NetFirewallRule -DisplayName "IMDS Lockdown"  -Direction Outbound -Action Block -RemoteAddress 169.254.169.254 -LocalUser $SDDL

Write-Host "User setup Complete!"
