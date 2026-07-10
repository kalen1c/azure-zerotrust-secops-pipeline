# Virtual Network (VNet) & NSG Architecture

To ensure the honeypot could safely capture live MITRE T1110 brute-force telemetry without posing a risk to the wider cloud environment, strict network isolation controls were implemented via Azure Network Security Groups (NSGs). 

The architecture follows a **Zero-Trust containment model**: the perimeter is intentionally vulnerable to ingest threat data, but egress and lateral movement are restricted.

## Inbound Security Rules
To simulate a vulnerable internet-facing server, RDP (TCP 3389) is explicitly exposed. All other ingress ports are blocked to reduce unwanted noise and ensure pure credential-stuffing telemetry.

| Priority | Name | Port | Protocol | Source | Destination | Action | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **100** | `AllowRDP` | 3389 | TCP | Any | Any | **Allow** | Exposes the honeypot to the public internet to capture brute-force authentication attempts. |
| **65000** | `AllowVnetInBound` | Any | Any | VirtualNetwork | VirtualNetwork | **Allow** | Default Azure rule permitting internal VNet communication. |
| **65001** | `AllowAzureLoadBalancerInBound` | Any | Any | AzureLoadBalancer | Any | **Allow** | Default Azure rule for internal load balancer health probes. |
| **65500** | `DenyAllInBound` | Any | Any | Any | Any | **Deny** | Default Azure rule to drop all unauthorized ingress traffic. |

---

## Outbound Security Rules
The primary liability of deploying an exposed honeypot is its potential to be compromised and used as a pivot point. The egress rules are heavily restricted to prevent lateral movement and outbound DDoS participation.

| Priority | Name | Port | Protocol | Source | Destination | Action | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **100** | `DenyInternalPivoting` | Any | Any | Any | `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | **Deny** | Drops all traffic to internal RFC1918 IP spaces to prevent lateral movement if the VM is breached. |
| **110** | `AllowAzureTelemetry` | 443 | TCP | Any | AzureMonitor | **Allow** | Permits the Azure Monitor Agent (AMA) to push logs securely to the Log Analytics Workspace. |
| **120** | `AllowAPIandDNS` | 443, 53 | Any | Any | Internet | **Allow** | Permits DNS resolution and outbound HTTPS strictly for the PowerShell edge-processor to query the IPGeolocation API. |
| **130** | `DenyAllOtherOutbound` | Any | Any | Any | Internet | **Deny** | **Containment:** Blocks all other outbound internet traffic, overriding the default Azure 65001 rule. This prevents the VM from downloading secondary malware payloads or participating in botnets. |
| **65000** | `AllowVnetOutBound` | Any | Any | VirtualNetwork | VirtualNetwork | **Allow** | Default Azure rule (Superseded by Priority 100). |
| **65001** | `AllowInternetOutBound` | Any | Any | Any | Internet | **Allow** | Default Azure rule (Overridden by Priority 130). |
| **65500** | `DenyAllOutBound` | Any | Any | Any | Any | **Deny** | Default Azure rule dropping all other egress traffic. |
