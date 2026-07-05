# Progress Log

## July 4 2026

Started the project today.  
Initial set up and exploration of Azure features

**Progress made:**
- Explored Azure dashboard and services to gain understanding
- Created the research group 
- Created Network security Group
- Created inbound/outbound rules to allow for remote access to VM and blocking external ports, internal traffic while allowing azure monitoring.
- Configured and created the virtual machine

**Issues faced:**  
When I first opened Azure there was a lot of stuff that was just confusing, I had to spend a some time just going through all of the sections to better understand them.

## July 5 2026 

Set up more foundational infrastructure for the project

**Progress made:**
- Created Azure key vault
- Created Free API key through ipgeolocation.io for Geolocation of attackers
- Granted the VM access to view secrets
- Created Log analytics workspace to store attacker details
- Deployed Data Collection Endpoint to collect attacker logs
- Deployed Custom Log Table to orgainse attacker logs
- Created Sample Logs for the log table 

**Issues faced:**  
When I created the key vault I did not have any priveledges to add secrets due to zero trust principles as I added Azure RBAC to the key vault, so I had to assign priveledges to myself.  
Couldn't create DCE due to not registering a subscription, sovled this by registering it 

## July 6 2026

Today I started configuring the VM to ensure data is accurate, solve security risks and verify that the solutions work.
I also started learning how to write powershell scripts and wrote the scraper, geolocator and aggregator script.

**Progress made:**
- Made windows time sync automatically to make sure data is accurate
- Created a firewall rule to blocking access to the IMDS IP address to prevent attackers from extracting the key vault access token
- Learned how to and created the script that scrapes the attacker details, geolocates them and aggregates the data into a readable table stored in a JSONL file
- Tested all of these features and made sure that the function
  
**Issues Faced:**  
The issues that I faced today were much higher complexity than the previous days, as today I started writing the powershell script with little base knowledge, I had to learn how powershell scripts operate and build the script line by line.







