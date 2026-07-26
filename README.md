# 🚀 Enterprise Active Directory & Identity Management Lab (Azure)

## 📌 Executive Summary
This project demonstrates the design, deployment, and automation of a cloud-hosted **Active Directory Domain Services (AD DS)** environment built on **Microsoft Azure**. The lab highlights enterprise identity management, custom Organizational Unit (OU) architecture following multi-site best practices, domain integration of client workstations, and automated bulk user provisioning using PowerShell.

---

## 🛠️ Infrastructure & Tech Stack
* **Cloud Infrastructure:** Microsoft Azure (Virtual Networks, Static IP Allocation, NSGs)
* **Operating Systems:** Windows Server 2022 Datacenter (Gen 2 x64)
* **Directory Services:** Active Directory DS, DNS, Group Policy (GPO)
* **Automation:** PowerShell 5.1 (ActiveDirectory Module)
* **Domain Name:** `lab.local`

---

## 📐 Network & Lab Topology

| Device Name | Role | OS | Private IP | Subnet / VNet |
| :--- | :--- | :--- | :--- | :--- |
| **DC01** | Domain Controller / Primary DNS | Windows Server 2022 | `172.16.0.4` | `172.16.0.4/24` |
| **CLIENT01** | Member Workstation / Client | Windows Server 2022 | `172.16.0.5` | `172.16.0.4/24` |

---

## 🏛️ Custom Active Directory Architecture (RBAC & OU Design)

To reflect real-world enterprise standards, a location-based and role-based access control (RBAC) structure was designed using top-level underscores (`_`) for administrative organization:

```text
lab.local
 ├── _Branches
 │    └── Jeddah
 │         ├── Users          <-- Domain Users imported via script
 │         ├── Workstations   <-- Workstation accounts
 │         └── Laptops        <-- Mobile devices / Remote assets
 └── _Groups
      ├── ITSupport           <-- Administrative / Helpdesk scope
      ├── Accounting          <-- Departmental access scope
      └── Helpdesk           <-- Tier-1 Ticket Handlers
```
# ⚙️ Key Implementation Steps

## 1. Azure Networking & DNS Alignment

- Provisioned `DC01` and `CLIENT01` within a shared Azure Virtual Network (`VNet-Lab`).
- Configured static private IP binding for `DC01` (`10.0.0.4`).
- Updated Azure VNet Custom DNS Settings to direct all name queries to `10.0.0.4`, enabling proper Kerberos and LDAP resolution.

## 2. Active Directory DS Promotion & Workstation Join

- Promoted `DC01` to a Domain Controller for the `lab.local` forest.
- Successfully joined `CLIENT01` to `lab.local` after verifying SRV record resolution via `nslookup lab.local`.
- Moved `CLIENT01` out of the default `CN=Computers` container into its designated Organizational Unit: `OU=Workstations,OU=Jeddah,OU=_Branches,DC=lab,DC=local` for granular GPO management.

## 3. Automated Provisioning via PowerShell (`Deploy-ADStructure.ps1`)

Designed an idempotent PowerShell script to automate directory deployment:

- **OU & Sub-OU Creation:** Provisions `_Branches/Jeddah/(Users, Workstations, Laptops)` and `_Groups`.
- **Security Group Creation:** Generates RBAC groups (`ITSupport`, `Accounting`, `Helpdesk`).
- **Bulk User Ingestion:** Parses `users.csv`, automatically creates account objects with populated attributes (Title, Department, UPN), targets destination OUs, assigns temporary credentials, enforces mandatory password changes on first logon, and maps users to corresponding security groups.

# 🔒 Security Policies & Administrative Delegation

## 1. Domain-Wide Password Policy

Enforced strong credential protection across the domain via Group Policy:

- **Minimum Password Length:** 12 Characters.
- **Password Complexity:** Enabled (Upper/Lowercase, Numbers, Symbols).
- **Account Lockout Threshold:** 5 Failed Login Attempts.
- **Lockout Duration:** 15 Minutes (prevents brute-force attack vectors).

## 2. Helpdesk Administrative Delegation (Least Privilege)

To maintain the Principle of Least Privilege (PoLP) without granting full Domain Admin rights:

- Delegated "Reset User Passwords and Force Password Change at Next Logon" permissions explicitly to the `Helpdesk` security group over the `OU=Users,OU=Jeddah,OU=_Branches,DC=lab,DC=local` scope.
- Verified that Tier-1 Helpdesk staff can maintain user access without elevated domain control.

# 🔍 Verification & Troubleshooting Log

**DNS Resolution Issue (`DNS_ERROR_NAME_DOES_NOT_EXIST`):**

- **Issue:** Client VM failed initial domain join.
- **Root Cause:** Client retained default Azure internal DNS (`168.63.129.16`).
- **Resolution:** Updated VNet DNS to point to `10.0.0.4`, executed `ipconfig /flushdns` on `CLIENT01`, and verified lookup via `nslookup lab.local`.

**Domain Authentication Verification:**

- Successfully authenticated on `CLIENT01` using newly created credentials (`lab\ahmad.alghamdi`).
- Confirmed initial logon forced password reset prompt.
- Executed `whoami` and `net config workstation` confirming active session under `LAB.LOCAL`.

# 📜 Repository Structure
 
```
├── Deploy-ADStructure.ps1   # PowerShell automation script for OUs, Groups, and Users
├── users.csv                # Sample CSV dataset for bulk user ingestion
├── README.md                # Project documentation
└── docs/
    └── images/              # Screenshots (ADUC console, script execution, client logon)
```
