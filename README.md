# 🚀 Enterprise Active Directory & Identity Management Lab (Azure)

## 📌 Executive Summary
Proyek ini mendokumentasikan penyiapan infrastruktur **Active Directory Domain Services (AD DS)** berbasis cloud di **Microsoft Azure**. Proyek ini mencakup konfigurasi Domain Controller, pembuatan infrastruktur domain `lab.local`, join domain pada Windows Server client, serta otomatisasi manajemen pengguna (*bulk user provisioning*) menggunakan skrip PowerShell.

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
| **DC01** | Domain Controller / Primary DNS | Windows Server 2022 | `10.0.0.4` | `10.0.0.0/24` |
| **CLIENT01** | Member Server / Test Client | Windows Server 2022 | `10.0.0.5` | `10.0.0.0/24` |

---

## ⚙️ Key Implementation Steps

### 1. Azure Infrastructure Setup
* Buat Virtual Network (`VNet-Lab`) dengan address space `10.0.0.0/16`.
* Deploy dua VM Windows Server 2022 (DC01 dan CLIENT01) pada subnet yang sama.
* Konfigurasi **Static Private IP** untuk DC01 di Azure Portal.
* Ubah **DNS Server Settings** pada VNet ke Custom DNS (`10.0.0.4`) agar CLIENT01 dapat melakukan resolusi nama domain `lab.local`.

### 2. Active Directory DS Domain Installation
* Promosi `DC01` menjadi Domain Controller untuk forest baru: `lab.local`.
* Konfigurasi Reverse Lookup Zone pada DNS Server untuk cakupan jaringan `10.0.0.x`.
* Lakukan Join Domain pada `CLIENT01` ke `lab.local` dan verifikasi konektivitas jaringan serta tiket Kerberos via `klist`.

### 3. Automated User & OU Provisioning via PowerShell
Menggunakan skrip khusus (`Deploy-ADStructure.ps1`), infrastruktur berikut berhasil dibuat secara otomatis:
* **Organizational Units:** `Corporate_Users`, `IT`, `HR`, `Finance`, `Operations`.
* **Security Groups:** `SG_IT_Admins`, `SG_HR_Staff`, `SG_Finance_Read`, `SG_VPN_Users`.
* **Bulk User Import:** Mengimpor data pengguna dari `users.csv` ke dalam OU masing-masing dengan pengaturan *Force Password Change on First Logon*.

---

## 🔍 Troubleshooting & Resolution Log

### Issue 1: Domain Join Failure (`DNS_ERROR_NAME_DOES_NOT_EXIST`)
* **Symptom:** CLIENT01 gagal join ke domain `lab.local` dengan pesan kesalahan nama domain tidak ditemukan.
* **Root Cause:** CLIENT01 masih menggunakan Azure Default DNS (`168.63.129.16`) sehingga tidak bisa menyelesaikan kueri SRV record `_ldap._tcp.dc._msdcs.lab.local`.
* **Resolution:** 
  1. Mengubah setting DNS pada Virtual Network interface CLIENT01 di Azure Portal menjadi `10.0.0.4`.
  2. Menjalankan `ipconfig /flushdns` dan `ipconfig /renew` pada CLIENT01.
  3. Uji resolusi domain via `nslookup lab.local` sampai mengembalikan IP `10.0.0.4`.

---

## 📜 How to Run the Automation Script

1. Login ke **DC01** sebagai Domain Administrator.
2. Clone atau download repositori ini ke folder `C:\AD-Lab\`.
3. Buka PowerShell sebagai Administrator.
4. Jalankan perintah berikut:
   ```powershell
   Set-ExecutionPolicy Unrestricted -Scope Process
   .\Deploy-ADStructure.ps1
