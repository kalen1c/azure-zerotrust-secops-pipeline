# sentinel-kql-threat-research
Azure SIEM architecture logging and analysing global MITRE T1110 threat telemetry. Built with a Microsoft Sentinel pipeline, custom PowerShell scripts querying REST APIs, modern DCR ingestion, KQL threat hunting, and GitHub Pages interactive incident mapping.

---
# Architecture & Threat Intelligence Brief: MITRE T1110 Analysis

## 1. Executive Summary
This project engineers a highly resilient, cost-optimised Azure honeypot designed to capture and analyse live MITRE T1110 (Brute Force) and T1110.003 (Password Spraying) campaigns. By utilising custom PowerShell edge-processing, Azure Data Collection Rules (DCR), and Microsoft Sentinel, this architecture reduces SIEM ingestion costs by >95%.

This architecture bridges the gap between raw Windows event logs and business risk by transforming high-volume authentication failures into structured metrics, equipping security teams to deploy targeted identity and perimeter defences based on real-time threat intelligence.

---
## 2. Architecture & Resiliency Controls

To simulate a production environment while strictly containing the blast radius of the vulnerable node, the following security, cost, and reliability controls were engineered into the pipeline:

### Cost & FinOps Controls

* **Stateful Log Aggregation (Edge Processing):** To prevent cloud ingestion billing spikes during high-velocity attacks, the PowerShell pipeline acts as an edge processor. It utilizes an in-memory hash table to batch IP addresses and count attempt frequencies, flushing deduplicated metrics to Azure at 5-minute intervals. This reduces cloud ingestion costs by >95% while maintaining volumetric fidelity.
* **FinOps Kill-Switch Automation:** As a fail-safe against volumetric DDoS campaigns generating massive log sets, an Azure Automation Account is linked to a strict $30/month budget trigger. If cloud ingestion spending exceeds this limit, a webhook automatically severs the VM's network connection to prevent financial overrun.
* **Burstable Compute (B-Series):** The honeypot runs on an affordable Azure B-Series VM. Because brute-force attacks occur in sudden spikes rather than constant streams, this setup banks CPU credits during idle periods to handle the heavy processing load when an attack hits.
* **Basic Logs Data Tiering:** Azure Log Analytics Workspace (LAW) charges premium rates for default analytics-tier ingestion. Because this project generates high-volume, low-complexity data, the destination tables are explicitly routed to Azure's "Basic Logs" tier. This drastically reduces ingestion costs while keeping the telemetry available for Sentinel dashboards.

### Security & Containment (SecOps)

* **Zero-Trust Secrets Management:** API authentication bypasses local disk storage entirely. Using a System-Assigned Managed Identity, the VM queries the Instance Metadata Service (IMDS) for an Entra ID token, dynamically retrieving the Geolocation API key from Azure Key Vault directly into volatile memory (RAM).
* **Defense-in-Depth (IMDS Firewall Block):** To prevent post-compromise credential harvesting, local Windows Defender Firewall rules block outbound access to the Azure IMDS endpoint (`169.254.169.254`) for all non-system users. This ensures that even if an attacker gains RDP access, they cannot extract the VM's managed identity tokens.
* **Egress Filtering & VNet Isolation:** A primary liability of an exposed honeypot is its potential use as a pivot point. The Virtual Network (VNet) enforces strict Network Security Group (NSG) rules, explicitly dropping all outbound traffic to internal RFC 1918 ranges and unapproved external endpoints.
* **Data Sanitization (Anti-Log Poisoning):** To prevent SIEM database corruption and parsing errors, the PowerShell edge processor utilizes Regex to strip special characters and KQL control operators from the Windows `TargetUserName` field before formatting the output, neutralizing malicious ingress attempts.

### Reliability & Data Engineering (SRE)

* **C# .NET Stream Processing:** To solve native file-locking conflicts between the edge processor and the Azure Monitor Agent (which utilizes Fluent-Bit), the script relies on custom C# .NET streams. This enables concurrent read/write access to the local JSONL log file, preventing telemetry drops during high-velocity attacks.
* **Graceful API Degradation:** The pipeline is engineered to survive third-party outages natively. If the external Geolocation API times out or throttles requests, the script applies fallback rules (e.g., a `Geo_Unavailable` placeholder) and continues processing so the SIEM never drops the underlying authentication alert.
* **Automated Log Rotation & Time Sync:** The script enforces a 50MB automated log rotation threshold on the local log file to prevent disk exhaustion. Furthermore, the VM enforces strict NTP synchronization to prevent clock drift, ensuring absolute time-series integrity for Sentinel's velocity graphs.
* **Ingestion-Time Transformation:** To optimize database query performance and lower storage overhead, the Data Collection Rule (DCR) utilizes a defined JSON schema to parse raw JSONL telemetry into discrete columns. KQL is applied strictly for lightweight ingestion-time transformations such as normalizing custom timestamp fields prior to Log Analytics Workspace commit.
---
## 3. Architecture Topology & Data Flow
```mermaid 
flowchart TD
    %% Define Nodes
    Attacker["Attacker / Internet"]
    NSG["Azure NSG Rules:<br>Allow RDP, deny<br>egress & internal pivoting"]
    NTP["NTP Time Server"]
    VM["Azure Virtual Machine<br>(B-Series)"]
    TaskSched["Windows Task Scheduler"]
    EdgeProc["PowerShell Edge Processor"]
    KV["Azure Key Vault<br>(Zero trust API retrieval)"]
    GeoAPI["IPGeolocation.io API<br>(Geolocation data)"]
    LogFile["Failed_RDP log file"]
    AMA["Azure Monitor Agent"]
    DCR["Data Collection Rules"]
    DCE["Data Collection Endpoint"]
    LAW["Log Analytics Workspace"]
    Sentinel["Microsoft Sentinel SIEM"]
    Workbook["Sentinel Workbook<br>(Threat Map & Visualisations)"]
    FinOps["FinOps VM Kill-Switch Script"]
    AutoAcc["Automation Account: Budget"]
    EntraID["Azure managed zero-trust identity<br>(Microsoft Entra ID)"]
    IMDS["Windows IMDS service firewall"]

    %% Define Connections and Data Flow
    Attacker -->|"RDP Brute force traffic (Port 3389)"| NSG
    NSG -->|"Inbound RDP attempt"| VM
    VM <-->|"Clock sync"| NTP
    VM -->|"Read Event ID 4625 & Geo API Key"| EdgeProc
    KV -->|"Return API Key into VM's memory"| VM
    TaskSched -->|"Trigger script every 5 Minutes"| EdgeProc
    EdgeProc -->|"Authenticate via<br>Managed Identity"| KV
    EdgeProc -->|"Send IP"| GeoAPI
    GeoAPI -->|"Return Geo-Data<br>(Timeout/Fail: Fallback rules apply)"| EdgeProc
    EdgeProc -->|"Sanitize via Regex & Rotate File (>50MB)"| LogFile
    LogFile -->|"Ingest updated logs"| AMA
    DCR -->|"Apply KQL & Parsing Schema"| AMA
    AMA -->|"Forward telemetry"| DCE
    DCE -->|"Send telemetry to LAW"| LAW
    LAW -->|"Filter via KQL"| Sentinel
    Sentinel -->|"Export JSON"| Workbook
    
    %% Identity and Automation Routing
    VM <-->|"Token Request & Response (Blocked for non-system users)"| IMDS
    IMDS <--->|"Auth Request & Token Response"| EntraID
    DCE <-->|"Authenticate via<br>Managed Identity"| EntraID
    AutoAcc -->|"Budget exceeds $30/month"| FinOps
    FinOps -->|"Sever VM connection"| VM
    FinOps <-->|"Authenticate via Managed Identity"| EntraID

```
---
## 4. Repository Navigation (COMING SOON)
* `/planning/`
* `/visualisations/`
* `/incident-response/`
* `/infrastructure/`
* [`/scripts/`](Scripts.md)
* `/dashboards/`




---
**Disclaimer:** *This project was conducted in a strictly controlled, isolated cloud environment for educational and threat intelligence gathering purposes. The infrastructure was hardened to prevent lateral movement and explicitly denied outbound traffic to prevent its use as a pivot point. All captured data (such as attacker IPs) has been anonymized or hashed where appropriate to adhere to ethical sharing standards.*


---
Project Methodology: To push my cloud security skills beyond standard tutorials, I used AI to help establish the initial project parameters and map out the target architecture. Everything beyond that initial blueprint, the coding, cloud infrastructure configuration, troubleshooting, and learning is entirely my own hands-on work. The following commits document my journey of actively building this complex system from the ground up.

You can view my technical hurdles, bug fixes, planning and build progress in the
[`/Troubleshooting & Progress Log/`](Troubleshooting-and-Progress-Log.md)
