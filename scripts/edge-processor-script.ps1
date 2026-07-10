# Authenticate to Azure using VM's assigned identity
Connect-AzAccount -Identity

# Retrieve API key from Vault into memory
$VaultName = "YOUR_VAULT_NAME"
$API_Key = (Get-AzKeyVaultSecret -VaultName $VaultName -Name "GeoAPIKey" -AsPlainText)

$LogFilePath = "C:\ProgramData\failed_rdp.json"
$MaxSize = 50MB

# Archive the file if it gets larger than 50MB
if(Test-Path $LogFilePath){
    $File = Get-Item $LogFilePath
        if($File.Length -gt $MaxSize){
            $Timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
            $ArchiveName = "failed_rdp_archive_$Timestamp.json"
            Rename-Item -Path $LogFilePath -NewName $ArchiveName

            # Automatically deletes archives over 1 month old
            $ArchiveFolder = "C:\ProgramData\"
            Get-ChildItem -Path $ArchiveFolder -Filter "failed_rdp_archive_*.json" | Where-Object {$_.CreationTime -lt (Get-Date).AddMonths(-1)} | Remove-Item -Force
        }
    }

# Create new log file if none already exist
if(-not (Test-Path $LogFilePath)){
    New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
}


# Grab logs from last 5 minutes and sorts them chronologically
$StartTime = (Get-Date).AddMinutes(-5)
$FailedLogons = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4625; StartTime = $StartTime } -ErrorAction SilentlyContinue | Sort-Object TimeCreated

if ($FailedLogons) {
   
    $AttackLedger = @{} # Track unique IP + Username combos
    $IPCache = @{}      # Cache GeoData to save API calls

    # Convert attempts to readable xml
    foreach ($Event in $FailedLogons) {
        $EventXML = [xml]$Event.ToXml()

        $Username  = ($EventXML.Event.EventData.Data | Where-Object {$_.Name -eq "TargetUserName"}).'#text'
        
        # Clean username field to prevent log poisoning
        $Username = $Username -replace '[^a-zA-Z0-9._@-]', ''

        $SourceIP  = ($EventXML.Event.EventData.Data | Where-Object {$_.Name -eq "IpAddress"}).'#text'
        $Timestamp = $Event.TimeCreated.ToString("yyyy-MM-ddTHH:mm:ssZ")

        # Create a unique key for specific IP and username combo
        $LedgerKey = "$SourceIP-$Username"
        
        # Checksif this exact IP and Username combo is already logged
        if ($AttackLedger.ContainsKey($LedgerKey)) {
            
            # If yes, add count rather than calling API again
            $AttackLedger[$LedgerKey].Count++
            $AttackLedger[$LedgerKey].Lastseen = $Timestamp
            
        } else {
            
            # If we haven't geolocated this IP yet, call the API
            if (-not $IPCache.ContainsKey($SourceIP)) {
                $API_URL = "https://api.ipgeolocation.io/ipgeo?apiKey=$API_Key&ip=$SourceIP"
                # Check for timeout and errors to catch the block on failure
                try{
                    $IPCache[$SourceIP] = Invoke-RestMethod -Uri $API_URL -Method Get -TimeoutSec 10 -ErrorAction Stop
                }
                catch{
                    $IPCache[$SourceIP] = [PSCustomObject]@{
                        city         = "Geo_Unavailable"
                        country_name = "Geo_Unavailable"
                        latitude     = "0.0000"
                        longitude    = "0.0000"
                    }
                }
            }

            # Pull the location from geo cache
            $GeoData = $IPCache[$SourceIP]

            # Build all the data
            $NewAttack = [PSCustomObject]@{
                IPAddress = $SourceIP
                Username  = $Username
                City      = $GeoData.city
                Country   = $GeoData.country_name
                Latitude  = $GeoData.latitude
                Longitude = $GeoData.longitude
                Firstseen = $Timestamp
                Lastseen  = $Timestamp
                Count     = 1
            }

            # Save it to the ledger
            $AttackLedger[$LedgerKey] = $NewAttack
        }
    }
  
    # Format the data into JSON lines in memory
    $JsonLines = $AttackLedger.Values | ForEach-Object {$_ | ConvertTo-Json -Compress}
    $PayloadString = $JsonLines -join "`r`n"
    
    # Check if there is data to write
    if ($AttackLedger.Count -gt 0) {

        # Open the file and gies permissions to write new data into the file while giving other programs access to read/write it simultaneously
        $Stream = [System.IO.File]::Open($LogFilePath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
        $Writer = New-Object System.IO.StreamWriter($Stream)

        # Write data and closes data stream
        $Writer.WriteLine($PayloadString)
        $Writer.Close()
        $Stream.Close()
        }

    } else {
    Write-Host "No attacks detected in the last 5 minutes."

    }
#Exit script to prevent ghost processes
Exit
