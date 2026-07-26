# 🚀 Enterprise Active Directory & Identity Management Lab (Azure)

## 📌 Executive Summary
This project documents the deployment and configuration of a cloud-based **Active Directory Domain Services (AD DS)** environment hosted on **Microsoft Azure**. The project demonstrates setting up a Domain Controller, configuring the `lab.local` domain, joining Windows Server client machines to the domain, and automating bulk user provisioning using custom PowerShell scripts.

---

## 🛠️ Infrastructure & Tech Stack
* **Cloud Platform:** Microsoft Azure (Virtual Networks, Network Security Groups)
* **Operating System:** Windows Server 2022 Datacenter (Gen 2 x64)
* **Directory Services:** Active Directory DS, DNS, Group Policy (GPO)
* **Automation:** PowerShell 5.1 (ActiveDirectory Module)
* **Domain Name:** `lab.local`

---

## 📐 Network & Lab Topology

| Device Name | Role | OS | IP Address | Subnet / VNet |
| :--- | :--- | :--- | :--- | :--- |
| **DC01** | Domain Controller / Primary DNS | Windows Server 2022 | `172.16.0.4` | `172.16.0.0/24` |
| **CLIENT01** | Member Server / Test Client | Windows Server 2022 | `10.0.0.5` | `10.0.0.0/24` |

---

## ⚙️ Key Implementation Steps

### 1. Azure Infrastructure Setup
* Provisioned an Azure Virtual Network (`VNet-Lab`) with address space `51.4.96.238/16`.
* Deployed two Windows Server 2022 VMs (`DC01` and `CLIENT01`) within the same subnet.
* Configured a **Static Private IP** (`172.16.0.4`) for `DC01` via the Azure Portal.
* Updated VNet **Custom DNS Settings** to point to `172.16.0.0` to allow domain name resolution for client VMs.

### 2. Active Directory DS & Domain Configuration
* Promoted `DC01` to a Domain Controller for the new forest `lab.local`.
* Configured a Reverse Lookup Zone on the DNS Server for the `172.16.0.x` subnet.
* Domain-joined `CLIENT01` to `lab.local` and verified network connectivity and Kerberos ticket issuance via `klist`.

### 3. Automated User & OU Provisioning via PowerShell
Created a deployment script (`Deploy-ADStructure.ps1`) to automate identity infrastructure setup:
* **Organizational Units (OUs):** `Corporate_Users`, `IT`, `HR`, `Finance`, `Operations`.
* **Security Groups:** `SG_IT_Admins`, `SG_HR_Staff`, `SG_Finance_Read`, `SG_VPN_Users`.
* **Bulk User Import:** Automated parsing of `users.csv` to create user objects, place them in targeted OUs, and set initial temporary passwords with forced password change on first logon.

---

## 🔍 Troubleshooting & Resolution Log

### Issue 1: Domain Join Failure (`DNS_ERROR_NAME_DOES_NOT_EXIST`)
* **Symptom:** `CLIENT01` failed to join `lab.local` with an error stating the domain name could not be found.
* **Root Cause:** `CLIENT01` was still using Azure Default DNS (`168.63.129.16`), preventing SRV record lookups for `_ldap._tcp.dc._msdcs.lab.local`.
* **Resolution:** 
  1. Updated the Virtual Network DNS settings in Azure Portal to custom IP `10.0.0.4`.
  2. Executed `ipconfig /flushdns` and `ipconfig /renew` on `CLIENT01`.
  3. Verified resolution via `nslookup lab.local`, returning `10.0.0.4`.

---

## 📜 How to Run the Automation Script

1. Log into **DC01** as Domain Administrator.
2. Clone or download this repository to `C:\AD-Lab\`.
3. Open PowerShell as Administrator.
4. Execute the script:
   ```powershell
   Set-ExecutionPolicy Unrestricted -Scope Process
   .\Deploy-ADStructure.ps1
