<#
.SYNOPSIS
    Security Telemetry Generator - Brute Force & Password Spraying Simulation
.DESCRIPTION
    Programmatically triggers Windows Security Event ID 4625 logs via localized 
    Authentication Subsystem API calls to populate SIEM detection thresholds.
.DESIGNER
    Jordan Butler | Keystone IAM Solutions
#>

# Ensure script runs with local visibility
$ErrorActionPreference = "SilentlyContinue"

# ---------------------------------------------------------
# CONFIGURATION TARGETS
# ---------------------------------------------------------
$TargetDC      = "127.0.0.1" # Target local authentication loopback
$TargetUser    = "adm-jbutler" # Single high-value target account
$FakePassword  = "InvalidSecurePass123!"

# Simulated Active Directory User List for Password Spraying
$UserDirectory = @(
    "eexecutive1", "jdoe", "asmith", "mross", "bwayne", 
    "clent", "pparker", "dfox", "twright", "bbutler"
)

# ---------------------------------------------------------
# CORE ATTACK FUNCTIONS
# ---------------------------------------------------------

function Invoke-BruteForce {
    param (
        [string]$Username,
        [int]$Attempts
    )
    Write-Host "[!] INITIATING HIGH-VELOCITY BRUTE FORCE TARGETING: $Username" -ForegroundColor Red
    
    for ($i = 1; $i -le $Attempts; $i++) {
        # Utilize the Windows .NET NetworkCredential assembly to force a native logon failure
        $TargetConnect = New-Object System.Net.NetworkCredential($Username, ($FakePassword + $i))
        $Context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
            [System.DirectoryServices.AccountManagement.ContextType]::Machine, $TargetDC
        )
        
        # Validates credentials against local SAM, forcing Event ID 4625 Generation
        $Validate = $Context.ValidateCredentials($Username, ($FakePassword + $i))
        
        Write-Host "    [-] Execution $i/$Attempts sent for user: $Username" -ForegroundColor DarkGray
    }
    Write-Host "[SUCCESS] Brute force execution cycle complete.`n" -ForegroundColor Green
}

function Invoke-PasswordSpray {
    param (
        [array]$UserList,
        [string]$Password
    )
    Write-Host "[!] INITIATING ENTERPRISE PASSWORD SPRAY SIMULATION" -ForegroundColor Yellow
    Write-Host "[*] Spraying single password '$Password' across directory list..." -ForegroundColor Cyan
    
    foreach ($User in $UserList) {
        $Context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
            [System.DirectoryServices.AccountManagement.ContextType]::Machine, $TargetDC
        )
        $Validate = $Context.ValidateCredentials($User, $Password)
        
        Write-Host "    [-] Authentication failure dropped for: $User" -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 250 # Tiny delay to simulate automated tooling behavior
    }
    Write-Host "[SUCCESS] Password spray execution cycle complete.`n" -ForegroundColor Green
}

# ---------------------------------------------------------
# EXECUTION CONTROLLER
# ---------------------------------------------------------
Clear-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "     KEYSTONE IAM SOLUTIONS - SECURITY TELEMETRY ENGINE  " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "System Time: $(Get-Date)" -ForegroundColor Gray

# 1. Trigger High-Velocity Brute Force (25 immediate sequential failures on one account)
Invoke-BruteForce -Username $TargetUser -Attempts 25

# 2. Trigger Password Spray (1 attempt across 10 distinct accounts)
Invoke-PasswordSpray -UserList $UserDirectory -Password "Winter2026!"

Write-Host "[+] All simulation phases complete. Check local Security Event Viewer to confirm Event 4625 spikes." -ForegroundColor Green