## Microsoft Sentinel SIEM: Live Attack Telemetry

I engineered a custom Microsoft Sentinel workbook to transform raw honeypot logs into actionable threat intelligence. This dashboard aggregates the telemetry from the edge processor, visualising the exact behavior, scale, and origin of MITRE T1110 brute-force campaigns.
### 1. Global Threat Map
*Visualises the geographic distribution of attacking botnets.*

<img width="100%" alt="Attack attempts location map" src="https://github.com/user-attachments/assets/3826a44b-5870-428f-a02e-07cf42625465" />

**[View the Live Global Threat Map Here](https://kalen1c.github.io/azure-zerotrust-secops-pipeline/visualisations/live-threat-map.html)**

### 2. Attack Velocity (48-Hour Window)
*Visualises attack frequency to highlight the sudden volumetric spikes characteristic of automated botnets.*

<img width="100%" alt="Attack Frequency over 48 hour time period" src="https://github.com/user-attachments/assets/2cb2b78e-3fef-4b92-9cef-277a9f52c999" />

### 3. Top Attempted Usernames
*Identifies exactly what default accounts and administrative privileges the attackers are attempting to compromise.*

<img width="100%" alt="Top usernames attempted" src="https://github.com/user-attachments/assets/f8c7a0b9-5b22-4835-83c9-9352dbf57627" />

### 4. Top 5 Attacker Origins
*Identifies the top attacking nations to provide direct intelligence for configuring proactive geo-blocking firewall rules.*

<img width="35%" alt="Top 5 origin countries" src="https://github.com/user-attachments/assets/4da98534-7bc9-4d5f-9f76-cb5397b5ed40" />
