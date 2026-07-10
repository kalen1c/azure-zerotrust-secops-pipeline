# Threat Intelligence Brief: MITRE T1110 
**Classification:** `TLP:CLEAR` (Approved for public release and portfolio inclusion)

## 1. Executive Summary
During a 48-hour exposure window, the Azure honeypot infrastructure captured **1,024 unauthorized authentication attempts** targeting the exposed RDP service (TCP 3389). Telemetry analysis indicates that the environment was targeted by both aggressive volumetric brute-force scripts and sophisticated, evasion-focused "low-and-slow" password spraying campaigns. 

This brief maps the observed attacker telemetry to the **MITRE ATT&CK framework**, specifically detailing the Tactics, Techniques, and Procedures (TTPs) of external adversaries attempting to establish initial access via **TA0006 (Credential Access)**.

---

## 2. Targeted Accounts & Reconnaissance 
Analysis of the `TargetUserName` field within the ingested Event ID 4625 (Failed Logon) logs reveals specific automated dictionary behaviors. 

| Username | Attempt Count | Threat Intelligence Notes |
| :--- | :--- | :--- |
| `Administrator` | 909 | Standard default-account targeting. Highly prevalent in automated Linux-based cracking scripts (e.g., Hydra, Ncrack). |
| `administrator` | 86 | Lowercase variation indicates attackers are likely using case-sensitive dictionary lists, unaware that Windows SAM/AD authentication is case-insensitive. |
| `desktop-b7x94q` | 20 | **Targeted Enumeration:** Attackers utilized RDP handshake scraping to enumerate the specific hostname of the virtual machine prior to brute-forcing. |
| `Test` | 9 | Secondary fallback dictionary term, often used to locate forgotten temporary or staging accounts with weak passwords. |

**Primary TTP Observed: [T1110.001 - Password Guessing]**
The overwhelming focus on the `Administrator` account demonstrates that the primary objective for these botnets is total system compromise rather than lateral movement via standard user accounts.

---

## 3. Attack Velocity & Botnet Behavior (Anomalies)
While the baseline attack velocity hovered between 1 to 5 attempts per 5-minute interval, distinct behavioral clusters were identified in the telemetry, revealing two highly contrasting attacker strategies:

### Cluster A: Aggressive Enumeration (Amsterdam)
* **Behavior:** A subset of IP addresses (notably originating from Amsterdam) generated highly aggressive, volumetric spikes (10–20 attempts per interval). 
* **Targeting:** This node systematically cycled through `Administrator`, `administrator`, and the enumerated hostname `desktop-b7x94q` in rapid succession.
* **Assessment:** Characteristic of a compromised VPS or proxy node executing a rigid, noisy brute-force script prioritizing speed over evasion. A separate IP within the same geographic cluster was observed exclusively targeting the `Test` account, suggesting a localized, multi-node deployment sharing target IP lists but splitting the dictionary workload.

### Cluster B: Global "Low-and-Slow" Evasion
* **Behavior:** Significantly, the most prevalent attack method observed was a highly coordinated, globally distributed campaign. Telemetry captured single, spaced-out attempts originating from a vast array of geographic locations including Lauterbourg, Fremont, Orange, Frankfurt, Mang Yang, Singapore, Hong Kong, Havant, Portsmouth, and São Paulo.
* **Targeting:** Rather than generating volumetric spikes, these nodes executed single login attempts spaced across the full 48-hour window. 
* **Assessment [T1110.003 - Password Spraying]:** This timing is highly deliberate and represents the primary strategy of modern brute-force botnets. By spacing attempts over hours and constantly rotating global source IPs, the adversary's infrastructure is specifically engineered to remain below the velocity detection thresholds of standard SIEM alerting rules and bypass default Windows Active Directory `AccountLockoutThreshold` policies (which typically reset after 30 minutes).

---

## 4. Strategic Defenses & Mitigations
Based on the observed telemetry, exposing native management ports (RDP/SSH) directly to the public internet presents an unacceptable business risk. To align this environment with **Zero Trust Architecture (ZTA)** principles (specifically *Assume Breach* and *Least Privilege*), the following defensive controls would be required:

1. **Eliminate Public Exposure [M1042 - Disable or Remove Feature or Program]:** Transition from static NSG Allow rules to **Azure Just-in-Time (JIT) VM Access**, which keeps RDP ports closed by default and requires Entra ID authentication and MFA to temporarily open the port for a maximum of 1-3 hours.
2. **Implement Account Lockout Policies [M1036 - Account Use Policies]:** Ensure Windows local security policies (or AD Group Policies) enforce an `Account lockout threshold` of 5 invalid attempts, paired with an `Account lockout duration` of at least 60 minutes to hinder volumetric attacks.
3. **Disable Default Accounts:** Rename the default local `Administrator` account or disable it entirely, forcing attackers to guess both the username and the password.
4. **Deploy Entra ID Conditional Access [M1032 - Multi-factor Authentication]:** Mandate MFA and block legacy authentication protocols for all remote administrative access. Configure geo-blocking to explicitly deny ingress traffic from high-risk locations with no legitimate business requirement.
5. **Detection Engineering (SIEM Alerts):** Utilize this intelligence to develop custom KQL analytic rules in Microsoft Sentinel. Specifically, create threshold alerts for "Low-and-Slow" distributed attacks by correlating failed logins across multiple distinct IPs targeting the same account within a 24-hour window. *(See the **[`/kql/`](../kql/)** directory for deployment-ready queries).*
6. **Automated Threat Intelligence (IoC Lifecycle) [M1031 - Network Intrusion Prevention]:** Export the captured malicious IP addresses as **Indicators of Compromise (IoCs)** to populate enterprise firewall blocklists and Microsoft Defender Threat Intelligence feeds, proactively shielding the wider organizational perimeter.
