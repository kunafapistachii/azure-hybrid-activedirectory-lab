Import-Module ActiveDirectory

$DomainDN = "DC=lab,DC=local"
$CSVPath = "C:\users.csv"
$TempPassword = ConvertTo-SecureString "P@ssw0rd2026!" -AsPlainText -Force

# 1. Create Top-Level & Sub OUs
Write-Host "[+] Creating Custom OU Structure..." -ForegroundColor Green

# Top Level OUs
$TopOUs = @("_Branches", "_Groups")
foreach ($OU in $TopOUs) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OU'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $OU -Path $DomainDN -ProtectedFromAccidentalDeletion $true
        Write-Host "    Created Top OU: $OU" -ForegroundColor Cyan
    }
}

# Branch & Sub OUs
$JeddahPath = "OU=Jeddah,OU=_Branches,$DomainDN"
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Jeddah'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Jeddah" -Path "OU=_Branches,$DomainDN" -ProtectedFromAccidentalDeletion $true
}

$JeddahSubOUs = @("Users", "Workstations", "Laptops")
foreach ($SubOU in $JeddahSubOUs) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$SubOU'" -SearchBase $JeddahPath -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $SubOU -Path $JeddahPath -ProtectedFromAccidentalDeletion $true
        Write-Host "    Created Sub-OU: _Branches/Jeddah/$SubOU" -ForegroundColor Cyan
    }
}

# 2. Create Security Groups in _Groups OU
Write-Host "`n[+] Creating Security Groups in _Groups..." -ForegroundColor Green
$Groups = @("ITSupport", "Accounting", "Helpdesk")
$GroupsOUPath = "OU=_Groups,$DomainDN"

foreach ($Group in $Groups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$Group'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $Group -GroupScope Global -GroupCategory Security -Path $GroupsOUPath
        Write-Host "    Created Group: $Group" -ForegroundColor Cyan
    }
}

# 3. Import Users into _Branches/Jeddah/Users
Write-Host "`n[+] Importing Users to _Branches/Jeddah/Users..." -ForegroundColor Green
$UserTargetOU = "OU=Users,OU=Jeddah,OU=_Branches,$DomainDN"

if (Test-Path $CSVPath) {
    $Users = Import-Csv -Path $CSVPath
    foreach ($User in $Users) {
        $UserParams = @{
            SamAccountName        = $User.Username
            UserPrincipalName     = "$($User.Username)@lab.local"
            GivenName             = $User.FirstName
            Surname               = $User.LastName
            DisplayName           = "$($User.FirstName) $($User.LastName)"
            Department            = $User.Department
            Title                 = $User.JobTitle
            Path                  = $UserTargetOU
            AccountPassword       = $TempPassword
            Enabled               = $true
            ChangePasswordAtLogon = $true
        }

        if (-not (Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'" -ErrorAction SilentlyContinue)) {
            New-ADUser @UserParams
            Write-Host "    User created: $($User.Username)" -ForegroundColor Green
            
            # Auto-assign to group based on department if matching
            if ($User.Department -eq "IT" -or $User.Department -eq "Helpdesk") {
                Add-ADGroupMember -Identity "ITSupport" -Members $User.Username -ErrorAction SilentlyContinue
                Write-Host "      -> Added $($User.Username) to ITSupport group" -ForegroundColor Yellow
            } elseif ($User.Department -eq "Finance" -or $User.Department -eq "Accounting") {
                Add-ADGroupMember -Identity "Accounting" -Members $User.Username -ErrorAction SilentlyContinue
                Write-Host "      -> Added $($User.Username) to Accounting group" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "`n[✓] Active Directory custom structure deployed successfully!" -ForegroundColor Yellow