# Progress Log

## July 4 2026  
Started the project today.  
Initial set up and exploration of Azure features.

**Progress made:**
- Explored Azure dashboard and services to gain understanding
- Created the research group 
- Created Network security Group
- Created inbound rule to allow for remote access to VM.
- Configured and created the B-Series virtual machine

**Issues faced:**  
- When I first opened Azure there was a lot of stuff that was just confusing, I had to spend a some time just going through all of the sections to better understand them.

## July 5 2026 
Set up more foundational infrastructure for the project.

**Progress made:**
- Created Azure key vault
- Granted the VM access to view secrets
- Created Free API key through ipgeolocation.io for Geolocation of attackers and put API key in secrets vault
- Created Log analytics workspace to store attacker details, using basic logs tier
- Deployed Data Collection Endpoint to collect attacker logs
- Deployed Custom Log Table to orgainse attacker logs
- Created Sample Logs for the log table 

**Issues faced:**  
- When I created the key vault I did not have any priveledges to add secrets due to zero trust principles as I added Azure RBAC to the key vault, so I had to assign priveledges to myself.  
- I Couldn't create DCE due to not having a subscription regististered, I sovled this by registering it 

## July 6 2026  
Started configuring the VM to ensure data is accurate, solve security risks and verify that the solutions work.  
Started learning how to write powershell scripts and wrote the scraper, geolocator and aggregator script.

**Progress made:**  
- Made windows time sync automatically to make sure data is accurate
- Created a firewall rule to blocking access to the IMDS IP address to prevent attackers from extracting the key vault access token
- Learned how to and created the script that scrapes the attacker details, geolocates them and aggregates the data into a readable table stored in a JSONL file
- Tested all of these features and made sure that they function
  
**Issues Faced:**  
- The issues that I faced today were much higher complexity than the previous days, as today I started writing the powershell script with little base knowledge, I had to learn how powershell scripts operate and build the script line by line.

## July 6 2026  
Built the pipeline and configured the components that run through it.  
Updated and fixed issues with edge processor.

**Progress made:**  
- Changed edge processor script to scan last 5 minutes rather than last 10 attempts due to duplication errors
- Updated edge processor script to track IP and username combos as was previously adding counts for unique usernames with same IP and not updating entries to show unique username attempts
- Updated Timestamp format for better readability
- Updated LAW sample logs to match output of edge processor
- Matched TimeGenerated to Firstseen time through KQL to solve sample log error
- Connected VM honeypot pipeline to LAW through Data Collection Rules
- Created script to automate edge processor every 5 minutes
- Fixed edge processor already in use issue

**Issues Faced**  
- Today I faced many issuse with the pipeline and scripts, initially I was having errors with the sample logs due to not having a TimeGenerated column, I fixed this by creating one and matching the timestamp with my FirstSeen column through KQL. 
- I also was having an issue where different usernames inputted by the same IP would add a count to the output rather than creating a new entry. I solved this by creating a key that tracked the combination of IP and usernames and checking for that key to add a count rather than checking only the source IP. As well this I cached the geolocation to save on API calls of different usernames with the same IP.
- I faced my most difficult issue yet, when I started running the edge processor, I kept getting an error that the file was already in use, this fixed after I restarted the VM however persisted each time after I added a new test login. I first thought that the reason behind this happening was because the edge-process-automator was running ghost processes holding the file, so I changed the settings in the task scheduler to stop the automator if it ran longer than 1 minute. However, my problem still persisted, to understand the root cause behind this issue I installed a command line tool that found the program holding the file, and determined that it was being held by fluent-bit.exe, which is the engine behind the Azure monitoring agent, which was reading the file when I added new entries, and attempting to send them to Azure. I tried to solve this by adding a retry loop to write the contents into the json file hoping that fluent-bit.exe only locked the file for a small amount of time. This resulted in no errors but the file was not being updated, so I modified the code for it to return in text on what part it was stuck on and found that fluent-bit locked the file as long as there was new data. To solve this issue I had to use C# .NET streams to only write new data and not overwrite or read anything, and while doing this grant permission for other programs to read and write the file at the same time as the new data was being written. This fixed the issue.

## July 7 2026  
Today I focused heavily on FinOps and SecOps hardening across the Azure environment and local scripts.  
This officially marks the completion of the projects architecture, with all the planned infrastructure, security, and pipeline features sucessfully deployed and tested.  

**Progress made**  
- Added username sanitisation to edge processor to prevent log poisoning
- Configured edge processor to retrieve geolocation API key from secrets vault following zero-trust principles
- Added error handling to edge processor for geolocation API, returning "Geo_Unavailable" if API times out or returns errors
- Added log file archiving to edge processor, archiving file if over 50mb and deleting archives older than 1 month
- Cleaned file name extensions and links
- Added outbound port rules to allow for geolocation API and Azure telemetry communication while denying all internal pivoting attempts and access to other outbound ports
- Deployed automation account and gave myself acess to it
- Created powershell script to sever connection of VM
- Created and connected budget to powershell script, severing connection if budget is exceeded
- Created and ran IMDS firewall command to prevent attackers from talking to IMDS service and extracting tokens
- Added full powershell setup script to github, including all required setup commands for VM

**Issues Faced**
- I encountered an issue while testing my username sanitisation as it was not working, the issue was my with regex formatting, which I fixed, which solved the issue.
- I was having issues connecting my action group that severs VM connection if budget is exceeded, the reason for this was because I had the wrong scope selected, so I changed the scope to match the subscription with the VM, and connected them, solving the issue.
- I encountered issues with setting up IMDS firewall, this was because I needed to convert the user into SDDL for the rule, doing this fixed the issue.




