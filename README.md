# Splunk Telemetry & File Integrity Monitoring (FIM) Lab
**Architect:** Jordan Butler  
**Company:** Keystone IAM Solutions  
**Environment:** Proxmox VE (Enterprise Hybrid Lab)  
**Target Hosts:** `KIAM-DC01` (Windows Server 2019 Domain Controller) & `SIEM` (Hardened Ubuntu Server Splunk Indexer)

---

## 1. Executive Summary
This technical deployment log documents the engineering of an end-to-end security telemetry pipeline configured to achieve comprehensive **File Integrity Monitoring (FIM)** and **Object Access Auditing** across a critical Active Directory infrastructure plane. 

By integrating Windows Advanced Security Auditing policies, explicit Directory System Access Control Lists (SACLs), and the Splunk Universal Forwarder, this architecture captures, parses, and streams real-time data modification events over a secure transport layer to a Linux-based SIEM platform. The design filters platform-level background noise, resolves raw operating system SIDs into human-readable corporate identities, and builds an analytical foundation for malicious threat and automated ransomware detection.

---

## 2. Telemetry Architecture & Data Flow
The data processing loop spans three distinct layers across the virtualized lab network:

1. **OS/Kernel Generation Layer (`KIAM-DC01`):** The local Windows Server kernel tracks file handle interactions and dropped operations on the physical disk via granular SACLs applied to the root filesystem (`C:\CompanyData`).
2. **Endpoint Forwarding Layer (Splunk UF):** A lightweight agent captures raw entries out of the `Security.evtx` channel, filters unnecessary Event IDs to manage network bandwidth/license ingestion overhead, and forwards logs across port `9997`.
3. **Ingestion & Parsing Layer (`SIEM` / Ubuntu):** The remote centralized Splunk indexer captures the telemetry stream into the `main` index database, executing Search Processing Language (SPL) queries to normalize logs on the fly.

---

## 3. Implementation Steps

### Step 3.1: Enable OS-Level Advanced Security Auditing
To prime the Windows kernel subsystem to record local object access, Advanced Audit configuration policies were enforced via Group Policy.

1. Launch the local or linked GPO Editor via `gpmc.msc`.
2. Navigate to: **Computer Configuration** > **Policies** > **Windows Settings** > **Security Settings** > **Advanced Audit Policy Configuration** > **Audit Policies** > **Object Access**.
3. Locate **Audit File System**, open its properties, and toggle tracking on for both **Success** and **Failure** events.
4. Execute an immediate policy refresh and verify operational state using an administrative PowerShell console:

```powershell
gpupdate /force
auditpol /get /category:"Object Access"

---

### Step 3.2: Establish System Access Control Lists (SACLs)
Activating the kernel engine is a global primer; individual folder target paths must be tagged to generate logs. The following automated PowerShell script was executed to recursively bind auditing rules to the central organizational data repository:

```powershell
# Specify storage root path
$PathToAudit = "C:\CompanyData"

# Retrieve existing ACL parameters 
$Acl = Get-Acl -Path $PathToAudit -Audit

# Define auditing parameters (Watch everyone who attempts to write, alter, or delete files)
$AuditUser = New-Object System.Security.Principal.NTAccount("Everyone")
$AuditRights = "Modify, Delete, Write"
$AuditInheritance = "ContainerInherit, ObjectInherit"
$AuditPropagation = "None"
$AuditAuditFlags = "Success, Failure"

# Instantiate the SACL Rule Object
$AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(`
    $AuditUser, $AuditRights, $AuditInheritance, $AuditPropagation, $AuditAuditFlags)

# Append the rule and re-apply the ACL back to the physical folder system
$Acl.AddAuditRule($AuditRule)
Set-Acl -Path $PathToAudit -AclObject $Acl
Write-Host "[SUCCESS] SACL successfully bound to $PathToAudit." -ForegroundColor Green

---

### Step 3.3: Configure the Forwarder Log Pipeline
To direct data to the SIEM, the host-level Universal Forwarder collection configuration file was adjusted to capture the security log stream.

* **Configuration File Path:** `C:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf`

```ini
[WinEventLog://Security]
disabled = 0
start_from = oldest
current_only = 0
evt_resolve_id = 1
# Strict event ID whitelist limits data intake to core Object Access actions
whitelist = 4656,4663,4658,4660
index = main
sourcetype = WinEventLog:Security

# Commit the configuration changes and restart the endpoint agent daemon via PowerShell:
Restart-Service -Name SplunkForwarder

---

## 4. SIEM Verification & Event Logging Procedure

### Step 4.1: Accessing the Centralized Splunk Web UI
To verify that data transmission is active across the virtualized network plane, connect to your hardened Ubuntu Splunk Instance through a web browser on your management workspace:

1. Open a web browser on a machine with network visibility to your SIEM host.
2. Navigate to your Splunk Indexer’s web console address over the standard management port `8000`: http://<YOUR_UBUNTU_SIEM_IP>:8000
3. Enter your administrative credentials at the Splunk login screen to enter the management dashboard environment.

### Step 4.2: Running the Analytics Verification Query
Once authenticated, access the primary analytics workspace to extract and parse the incoming Windows Event ID `4663` FIM telemetry strings:

1. Click on the **Search & Reporting** application icon on the left app panel.
2. In the central search bar console, input the following production-refined Search Processing Language (SPL) query to parse out raw system noise and extract human user identities:

```spl
index=main EventCode=4663 "CompanyData"
| eval User_Name=coalesce(Account_Name, SubjectUserName, Security_ID)
| search NOT User_Name="*$" AND NOT User_Name="SYSTEM"
| table _time, User_Name, Object_Name, Process_Name, Accesses
| rename _time as "Timestamp", User_Name as "User Account", Object_Name as "Target File", Process_Name as "Application Used", Accesses as "Action"

3. Adjust the time-frame dropdown menu (located to the right of the search bar) from the default Last 24 Hours to Presets > Real-time > All time (real-time) or a strict historical window matching your file-touch execution.
4. Click the search magnifying glass icon to run the query pipeline.

### Step 4.3: Validating Captured Telemetry Logs
Analyze the resulting structured data table to confirm that the telemetry matches your workstation actions:
1. Verify that the User Account column populates with clean human IDs (e.g., eexecutive1) instead of raw cryptographic SIDs or system background tasks.
2. Confirm that the Target File path matches the exact nested directory structure inside C:\CompanyData.
3. Inspect the Application Used and Action columns to validate that explicit modifications (WriteData) or deletions executed on the workstation are recorded chronologically.