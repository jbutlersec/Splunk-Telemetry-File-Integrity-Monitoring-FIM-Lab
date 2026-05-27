# =========================================================================
#   KEYSTONE IAM SOLUTIONS - HYBRID ENTRA ID ORCHESTRATION ENGINE
# =========================================================================

# 1. Connect securely to Microsoft Graph Cloud API
Write-Host "[*] Requesting secure authentication token from Entra ID..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All"

$GroupName = "SG-Cloud-MFA-Enforced"
$TargetUsers = @("asmith", "bwayne", "pparker", "adm-jbutler")

# 2. Check if the Cloud Security Group already exists
Write-Host "[*] Verifying cloud security group status..." -ForegroundColor Cyan
$ExistingGroup = Get-MgGroup -Filter "DisplayName eq '$GroupName'"

if (-not $ExistingGroup) {
    Write-Host "[+] Creating new cloud-native group: $GroupName" -ForegroundColor Green
    $GroupParams = @{
        DisplayName     = $GroupName
        MailEnabled     = $false
        MailNickname    = "CloudMFAEnforced"
        SecurityEnabled = $true
    }
    $CloudGroup = New-MgGroup @GroupParams
} else {
    Write-Host "[!] Group '$GroupName' already exists in tenant." -ForegroundColor Yellow
    $CloudGroup = $ExistingGroup
}

# 3. Loop through and programmatically assign synced identities
Write-Host "`n[*] Initiating programmatic cloud assignments..." -ForegroundColor Cyan
foreach ($UserSAM in $TargetUsers) {
    # Query Entra ID for the user's unique cloud Object ID using their UPN prefix
    $EntraUser = Get-MgUser -Filter "startsWith(UserPrincipalName, '$UserSAM')"
    
    if ($EntraUser) {
        try {
            # Bind the user's identity to the security group via the API graph path
            New-MgGroupMemberByRef -GroupId $CloudGroup.Id -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$($EntraUser.Id)"
            Write-Host "    [-] Successfully added User: $UserSAM ($($EntraUser.UserPrincipalName)) to cloud security boundary." -ForegroundColor Green
        } catch {
            Write-Host "    [!] User $UserSAM is already a member of this cloud boundary." -ForegroundColor Yellow
        }
    } else {
        Write-Host "    [X] ERROR: Could not locate synced identity for prefix: $UserSAM" -ForegroundColor Red
    }
}

# 4. Disconnect session cleanly
Disconnect-MgGraph | Out-Null
Write-Host "`n[+] Cloud provisioning cycle finished cleanly." -ForegroundColor Cyan