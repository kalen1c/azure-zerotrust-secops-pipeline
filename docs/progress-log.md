# Project Progress & Troubleshooting Log

## July 4, 2026  
**Focus:** Initial infrastructure deployment and cloud environment familiarization.

**Progress made:**  
- Explored Azure dashboard and services to gain understanding.
- Created the Resource Group.
- Created Network Security Group.
- Created inbound rule to allow for remote access to VM.
- Configured and created the B-Series virtual machine.

**Issues faced & Resolutions:**
- When I first opened Azure, there was a lot of stuff that was just confusing. I had to spend some time going through all of the sections to better understand how the services operate and connect to each other.

---

## July 5, 2026 
**Focus:** Foundational security configurations and Log Analytics deployment.

**Progress made:**  
- Created Azure Key Vault.
- Granted the VM access to view secrets.
- Created Free API key through ipgeolocation.io for geolocation of attackers and put API key in secrets vault.
- Created Log Analytics Workspace to store attacker details, using the Basic Logs tier.
- Deployed Data Collection Endpoint to collect attacker logs.
- Deployed Custom Log Table to organise attacker logs.
- Created sample logs for the log table.

**Issues faced & Resolutions:**
- When I created the Key Vault I did not have any privileges to add secrets due to Zero Trust principles as I added Azure RBAC to the Key Vault, so I had to assign privileges to myself.  
- I couldn't create the DCE due to not having a subscription registered. I solved this by registering it.

---

## July 6, 2026  
**Focus:** VM security hardening and initial PowerShell development.

**Progress made:**  
- Configured Windows time to sync automatically to make sure data is accurate.
- Created a firewall rule blocking access to the IMDS IP address to prevent attackers from extracting the Key Vault access token.
- Learned how to and created the script that scrapes the attacker details, geolocates them and aggregates the data into a readable table stored in a JSONL file.
- Tested all of these features and made sure that they function.
  
**Issues faced & Resolutions:**
- The issues that I faced today were much higher complexity than the previous days, as today I started writing the PowerShell script with little base knowledge. I had to learn how PowerShell scripts operate and build the script line by line.

---

## July 7, 2026  
**Focus:** Pipeline integration, logic correction, and edge-processor debugging.

**Progress made:**  
- Changed edge processor script to scan the last 5 minutes rather than the last 10 attempts due to duplication errors.
- Updated edge processor script to track IP and username combos. It was previously adding counts for unique usernames with the same IP but not updating entries to show the specific unique username attempts.
- Updated timestamp format for better readability.
- Updated LAW sample logs to match output of edge processor.
- Matched TimeGenerated to Firstseen time through KQL to solve sample log error.
- Connected VM honeypot pipeline to LAW through Data Collection Rules.
- Created script to automate edge processor every 5 minutes.
- Fixed "edge processor already in use" issue.

**Issues faced & Resolutions:**
- Today I faced many issues with the pipeline and scripts. Initially, I was having errors with the sample logs due to not having a TimeGenerated column. I fixed this by creating one and matching the timestamp with my FirstSeen column through KQL. 
- I also was having an issue where different usernames inputted by the same IP would add a count to the output rather than creating a new entry. I solved this by creating a key that tracked the combination of IP and usernames and checking for that key to add a count rather than checking only the source IP. As well as this, I cached the geolocation to save on API calls of different usernames with the same IP.
- I faced my most difficult issue yet: when I started running the edge processor, I kept getting an error that the file was already in use. This fixed after I restarted the VM, however, it persisted each time after I added a new test login. I first thought that the reason behind this happening was because the edge-process-automator was running ghost processes holding the file, so I changed the settings in the Task Scheduler to stop the automator if it ran longer than 1 minute. However, my problem still persisted. To understand the root cause behind this issue, I installed a command line tool that found the program holding the file, and determined that it was being held by fluent-bit.exe, which is the engine behind the Azure Monitor Agent, which was reading the file when I added new entries, and attempting to send them to Azure. I tried to solve this by adding a retry loop to write the contents into the JSON file hoping that fluent-bit.exe only locked the file for a small amount of time. This resulted in no errors but the file was not being updated, so I modified the code for it to return in text on what part it was stuck on and found that fluent-bit locked the file as long as there was new data. To solve this issue I had to use C# .NET streams to only write new data and not overwrite or read anything, and while doing this grant permission for other programs to read and write the file at the same time as the new data was being written. This fixed the issue.

---

## July 8, 2026  
**Focus:** FinOps automation, SecOps hardening, and pipeline resiliency.

**Progress made:**  
- Added username sanitisation to edge processor to prevent log poisoning.
- Configured edge processor to retrieve geolocation API key from secrets vault following Zero Trust principles.
- Added error handling to edge processor for geolocation API, returning "Geo_Unavailable" if API times out or returns errors.
- Added log file archiving to edge processor, archiving file if over 50MB and deleting archives older than 1 month.
- Cleaned file name extensions and links.
- Added outbound port rules to allow for geolocation API and Azure telemetry communication while denying all internal pivoting attempts and access to other outbound ports.
- Deployed automation account and gave myself access to it.
- Created PowerShell script to sever connection of VM.
- Created and connected budget to PowerShell script, severing connection if budget is exceeded.
- Created and ran IMDS firewall command to prevent attackers from talking to IMDS service and extracting tokens.
- Added full PowerShell setup script to GitHub, including all required setup commands for VM.

**Issues faced & Resolutions:**
- I encountered an issue while testing my username sanitisation as it was not working. The issue was with my regex formatting, which I fixed, which solved the issue.
- I was having issues connecting my action group that severs the VM connection if the budget is exceeded. The reason for this was because I had the wrong scope selected, so I changed the scope to match the subscription with the VM, and connected them, solving the issue.
- I encountered issues with setting up the IMDS firewall. This was because I needed to convert the user into SDDL for the rule. Doing this fixed the issue.

---

## July 9, 2026  
**Focus:** SIEM configuration and documentation drafting.

**Progress made:**  
- Created Microsoft Sentinel Workspace.
- Created Sentinel Workbook for data visualisations.
- Heavily updated Repository name, Description, Executive Summary, Architecture & Resiliency Controls, Mermaid Architecture Topology, and Repository Navigation in the README.md to match the final project architecture.
- Added link to Global Threat Map.
- Added Core Technologies section to README.md.

**Issues faced & Resolutions:**
- I faced several minor syntax hurdles while writing the specific KQL queries for the visualization dashboard, I resolved this through iterative testing and debugging in the Log Analytics query window.

---

## July 10, 2026
**Focus:** Final data visualizations, documentation and MITRE Threat Intelligence Analysis.

**Progress made:**  
- Added hero image to README.md.
- Wrote KQL code to format threat map.
- Configured kepler.gl threat map.
- Wrote KQL for attack volume area chart, origin country pie chart, and username attempt bar chart.
- Created visualisations.md page with all visualisations.
- Created nsg-configurations.md page to show Azure VNet NSG configurations.
- Performed a MITRE T1110 analysis and created a page mitre-t1110-analysis.md to report findings.
- Polished the progress-log.md for better readability and understanding.

**Issues faced & Resolutions:**
- Initially, I was having an issue with the threat map where the same IP address with different count entries didn't accumulate and create larger accumulated counts but rather had multiple separate smaller counts. To solve this I first ordered the data by IP address and time generated and forced Azure to read the data through that order. Then I created a variable that accumulated the separated counts while creating new entries for unique IP addresses.
- Additionally, I was having an issue where when the accumulated counts joined together as it would update entries with the latest username rather than accumulating all the attempted usernames. I created a loop so that if the current IP matched the previous IP the unique usernames would merge together, and if the IP was unique the new username would be used instead.
