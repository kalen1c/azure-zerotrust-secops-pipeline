$API_Key = "YOUR_API_KEY"
$LogFilePath = "C:\ProgramData\failed_rdp.json"

# Grabs logs from last 5 minutes and sorts them chronologically
$StartTime = (Get-Date).AddMinutes(-5)
$FailedLogons = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4625; StartTime = $StartTime } -ErrorAction SilentlyContinue | Sort-Object TimeCreated

if ($FailedLogons) {
   
    $AttackLedger = @{} # Tracks unique IP + Username combos
    $IPCache = @{}      # Caches GeoData to save API calls

    # Converts attempts to readable xml
    foreach ($Event in $FailedLogons) {
        $EventXML = [xml]$Event.ToXml()

        $Username  = ($EventXML.Event.EventData.Data | Where-Object {$_.Name -eq "TargetUserName"}).'#text'
        
        # Cleans username field to prevent log poisoning
        $Username = $Username -replace '[^a-zA-Z0-9._@-]', ''

        $SourceIP  = ($EventXML.Event.EventData.Data | Where-Object {$_.Name -eq "IpAddress"}).'#text'
        $Timestamp = $Event.TimeCreated.ToString("yyyy-MM-ddTHH:mm:ssZ")

        # Creates a unique key for specific IP and username combo
        $LedgerKey = "$SourceIP-$Username"
        
        # Checks if this exact IP and Username combo is already logged
        if ($AttackLedger.ContainsKey($LedgerKey)) {
            
            # If yes, adds count rather than calling API again
            $AttackLedger[$LedgerKey].Count++
            $AttackLedger[$LedgerKey].Lastseen = $Timestamp
            
        } else {
            
            # If we haven't geolocated this IP yet, call the API
            if (-not $IPCache.ContainsKey($SourceIP)) {
                $API_URL = "https://api.ipgeolocation.io/ipgeo?apiKey=$API_Key&ip=$SourceIP"
                # Checks for timout and errors to catch the block on failure
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

            # Builds all the data
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

            # Saves it to the ledger
            $AttackLedger[$LedgerKey] = $NewAttack
        }
    }
  
    # Formats the data into JSON lines in memory
    $JsonLines = $AttackLedger.Values | ForEach-Object {$_ | ConvertTo-Json -Compress}
    $PayloadString = $JsonLines -join "`r`n"
    
    # Checks if there is data to write
    if ($AttackLedger.Count -gt 0) {

        # Opens the file and gies permissions to write new data into the file while giving other programs access to read/write it simultaneously
        $Stream = [System.IO.File]::Open($LogFilePath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
        $Writer = New-Object System.IO.StreamWriter($Stream)

        # Writes data and closes data stream
        $Writer.WriteLine($PayloadString)
        $Writer.Close()
        $Stream.Close()
        }

    } else {
    Write-Host "No attacks detected in the last 5 minutes."

    }
# Exits script to prevent ghost processes
Exit
