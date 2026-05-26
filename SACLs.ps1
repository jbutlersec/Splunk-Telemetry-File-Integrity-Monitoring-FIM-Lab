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