# Chapter 15: Active Directory

Sam has 200 users to create. Max has a CSV template. ADUC has a mouse.

![chapter-opener](assets/images/ch-15-opener.png)

---

## The ActiveDirectory Module

Before you can do anything, you need the Windows-only `ActiveDirectory`
module. It ships with **Remote Server Administration Tools (RSAT)** on Windows
client systems and is available on a Domain Controller after the relevant AD
DS management tools are installed. These cmdlets aren't supported natively on
Linux or macOS.

```powershell
# Check if it's available
Get-Module -ListAvailable -Name ActiveDirectory

# Import it (usually auto-imported on first use)
Import-Module ActiveDirectory

# Confirm the cmdlets are there
Get-Command -Module ActiveDirectory | Measure-Object
```

If `Get-Module` returns nothing, install RSAT:

```powershell
# Windows 10/11 — as admin
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

Once imported, you have about 150 cmdlets. The ones you'll use 90% of the
time:

| Cmdlet | Purpose |
|--------|---------|
| `Get-ADUser` | Query user accounts |
| `Get-ADGroup` | Query security and distribution groups |
| `Get-ADComputer` | Query computer accounts |
| `New-ADUser` | Create a user account |
| `Set-ADUser` | Modify a user account |
| `Add-ADGroupMember` | Add objects to a group |
| `Remove-ADGroupMember` | Remove objects from a group |
| `Move-ADObject` | Move an object to a different OU |
| `Disable-ADAccount` | Disable a user or computer account |

![module-overview](assets/images/ch-15-module-overview.png)

---

## Querying Users

### The -Filter Parameter

`Get-ADUser` requires either `-Filter` or `-Identity`. `-Identity` is for
when you know exactly who you want. `-Filter` is for everything else.

```powershell
# Get a specific user by SAM account name
Get-ADUser -Identity jsmith

# Get all users (use carefully in large domains)
Get-ADUser -Filter *

# Filter by department
Get-ADUser -Filter { Department -eq 'Engineering' }

# Filter by enabled state
Get-ADUser -Filter { Enabled -eq $true }

# Combine conditions
Get-ADUser -Filter { Department -eq 'HR' -and Enabled -eq $true }
```

The filter syntax is the Active Directory module's PowerShell Expression
Language, not an ordinary scriptblock evaluated locally. It is translated to
a server-side directory query. The golden rule: if the
property is an AD attribute, use `-Filter`. If you need complex logic that
AD can't handle, pipe to `Where-Object`.

```powershell
# AD handles this (fast, server-side)
Get-ADUser -Filter { Department -eq 'IT' }

# Where-Object handles this (slow, client-side -- fetches everything first)
Get-ADUser -Filter * | Where-Object { $_.Description -match 'temp' }
```

### The -Properties Parameter

By default, `Get-ADUser` returns a small set of attributes. To get more,
you must ask explicitly:

```powershell
# Default properties only (Name, SamAccountName, Enabled, DistinguishedName, etc.)
Get-ADUser -Identity jsmith

# Request additional properties
Get-ADUser -Identity jsmith -Properties Department, Title, Manager, EmailAddress

# Request everything (use sparingly -- slow and noisy)
Get-ADUser -Identity jsmith -Properties *
```

This is intentional. Fetching all properties for 50,000 users would be
painful. Ask for what you need.

```powershell
# Practical pattern: filter + select specific properties
Get-ADUser -Filter { Enabled -eq $true } -Properties Department, Title |
    Select-Object Name, SamAccountName, Department, Title |
    Sort-Object Department, Name
```

### The -SearchBase Parameter

Scoping your query to an Organisational Unit (OU) makes it faster and
more predictable:

```powershell
# Search only in the London OU
Get-ADUser -Filter * -SearchBase 'OU=London,OU=Users,DC=corp,DC=local'

# The SearchScope controls depth: Base, OneLevel, Subtree (default)
Get-ADUser -Filter * -SearchBase 'OU=Users,DC=corp,DC=local' -SearchScope OneLevel
```

`Subtree` (the default) searches the OU and all child OUs. `OneLevel`
searches only the immediate OU. `Base` searches a single object — mostly
useful for confirming existence.

![ldap-searchbase](assets/images/ch-15-ldap-searchbase.png)

---

## LDAP Filters vs -Filter

For power users, the raw LDAP filter syntax is available via
`-LDAPFilter`. It's more expressive and sometimes faster:

```powershell
# -Filter syntax
Get-ADUser -Filter { Department -eq 'IT' -and Enabled -eq $true }

# Equivalent LDAP filter
Get-ADUser -LDAPFilter '(&(department=IT)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'
```

Stick with `-Filter` until you hit its limits. You'll know when: either it
throws an error or the query is so nested that only raw LDAP can express it.

---

## Modifying Users

`Set-ADUser` takes an `-Identity` (SAM, DN, GUID, or UPN) and any number
of attribute parameters:

```powershell
# Update a single attribute
Set-ADUser -Identity jsmith -Department 'Platform Engineering'

# Update multiple attributes at once
Set-ADUser -Identity jsmith `
    -Department 'Platform Engineering' `
    -Title 'Senior Engineer' `
    -Office 'London'

# Clear an attribute explicitly
Set-ADUser -Identity jsmith -Clear 'description'

# Use -Replace for multi-valued attributes or raw LDAP attribute names
Set-ADUser -Identity jsmith -Replace @{ telephoneNumber = '+44 20 1234 5678' }
```

Pipeline pattern for bulk updates:

```powershell
# Preview disabling all users in the Contractors OU; remove -WhatIf only after review
Get-ADUser -Filter * -SearchBase 'OU=Contractors,DC=corp,DC=local' |
    Disable-ADAccount -WhatIf
```

---

## Creating Users

`New-ADUser` has a lot of parameters. The important ones:

```powershell
$temporaryPassword = Read-Host 'Temporary password for Jane Smith' -AsSecureString

New-ADUser `
    -Name           'Jane Smith' `
    -GivenName      'Jane' `
    -Surname        'Smith' `
    -SamAccountName 'jsmith' `
    -UserPrincipalName 'jsmith@corp.local' `
    -Path           'OU=Users,DC=corp,DC=local' `
    -AccountPassword $temporaryPassword `
    -Enabled        $true `
    -Department     'Engineering' `
    -Title          'Software Engineer'
```

A few things worth knowing:

- `-Path` is the DN of the **parent OU**, not the user itself.
- `-AccountPassword` requires a `SecureString`. Obtain it from a secret manager
  or an interactive `Read-Host -AsSecureString`; don't embed plaintext and
  convert it in source code.
- `-Enabled $false` is the default. Forgetting `-Enabled $true` means the
  account is created but locked out. You will do this once. Everyone does.
- The `-PassThru` switch returns the new AD object, useful for piping
  immediately to `Add-ADGroupMember`.

```powershell
# Create and immediately add to a group
$bobPassword = Read-Host 'Temporary password for Bob Jones' -AsSecureString
$bob = New-ADUser -Name 'Bob Jones' -SamAccountName 'bjones' `
    -Path 'OU=Users,DC=corp,DC=local' `
    -AccountPassword $bobPassword `
    -Enabled $true -PassThru
Add-ADGroupMember -Identity 'AllEmployees' -Members $bob
```

---

## Group Membership

```powershell
# Add a single user to a group
Add-ADGroupMember -Identity 'VPN-Users' -Members 'jsmith'

# Add multiple users
Add-ADGroupMember -Identity 'VPN-Users' -Members 'jsmith', 'bjones', 'adavis'

# Add all users from a pipeline
Get-ADUser -Filter { Department -eq 'Engineering' } |
    ForEach-Object { Add-ADGroupMember -Identity 'Engineering-All' -Members $_ }

# Check current membership
Get-ADGroupMember -Identity 'VPN-Users' | Select-Object Name, SamAccountName

# Remove a member
Remove-ADGroupMember -Identity 'VPN-Users' -Members 'jsmith' -Confirm:$false
```

---

## Bulk Operations with CSV Import

This is what Max had in mind when Sam started clicking.

```powershell
# users.csv:
# FirstName,LastName,Department,Title,OU
# Alice,Brown,IT,Analyst,OU=IT,OU=Users,DC=corp,DC=local
# Bob,Green,HR,Coordinator,OU=HR,OU=Users,DC=corp,DC=local

$users = Import-Csv './users.csv'

foreach ($user in $users) {
    $sam  = "$($user.FirstName.Substring(0,1).ToLower())$($user.LastName.ToLower())"
    $upn  = "$sam@corp.local"
    $pass = Read-Host "Temporary password for $sam" -AsSecureString

    $params = @{
        Name               = "$($user.FirstName) $($user.LastName)"
        GivenName          = $user.FirstName
        Surname            = $user.LastName
        SamAccountName     = $sam
        UserPrincipalName  = $upn
        Path               = $user.OU
        AccountPassword    = $pass
        Department         = $user.Department
        Title              = $user.Title
        Enabled            = $true
    }

    try {
        New-ADUser @params
        Write-Host "Created: $sam" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to create $sam : $_"
    }
}
```

Splatting (`@params`) keeps the loop body readable. The interactive password
prompt keeps credentials out of the CSV and source, but a production bulk
workflow should retrieve a unique password or provisioning token from an
approved identity/secret system instead of pausing for input. Always wrap `New-ADUser`
in a `try/catch` in bulk scripts — one duplicate SAM account name would
otherwise abort the entire run.

![bulk-create-flow](assets/images/ch-15-bulk-create-flow.png)

---

## OU Management

```powershell
# List all OUs
Get-ADOrganizationalUnit -Filter *

# Create a new OU
New-ADOrganizationalUnit -Name 'Contractors' -Path 'OU=Users,DC=corp,DC=local'

# Move a user to a different OU
Move-ADObject -Identity 'CN=Jane Smith,OU=NewHires,DC=corp,DC=local' `
              -TargetPath 'OU=Engineering,OU=Users,DC=corp,DC=local'

# Get the DN of an object (useful for Move-ADObject targeting)
(Get-ADUser -Identity jsmith).DistinguishedName
```

---

## Automated Onboarding: Putting It Together

Real onboarding scripts combine everything: create user, set attributes,
assign groups, maybe trigger an email. The following resilient pattern reports
exactly how far it got and makes compensating cleanup an explicit choice:

```powershell
function New-UserOnboarding {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $FirstName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $LastName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Department,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Title,
        [Parameter(Mandatory)] [SecureString] $TemporaryPassword,
        [string] $Manager,
        [string] $BasePath = 'OU=Users,DC=corp,DC=local',
        [switch] $RemovePartialUserOnFailure
    )

    $sam  = "$($FirstName.Substring(0,1).ToLower())$($LastName.ToLower())"
    $upn  = "$sam@corp.local"
    $ouPath = "OU=$Department,$BasePath"

    $state = [ordered]@{
        SAM             = $sam
        UPN             = $upn
        Status          = 'Planned'
        Stage           = 'Plan'
        CompletedStages = [System.Collections.Generic.List[string]]::new()
        GroupsAdded     = [System.Collections.Generic.List[string]]::new()
        CleanupAttempted = $false
        CleanupSucceeded = $null
        Error            = $null
        CleanupError     = $null
    }

    if (-not $PSCmdlet.ShouldProcess($sam, 'Create and configure AD user')) {
        $state.Status = 'WhatIf'
        return [PSCustomObject] $state
    }

    $userCreated = $false
    try {
        $state.Stage = 'CreateUser'
        New-ADUser `
            -Name              "$FirstName $LastName" `
            -GivenName         $FirstName `
            -Surname           $LastName `
            -SamAccountName    $sam `
            -UserPrincipalName $upn `
            -Path              $ouPath `
            -AccountPassword   $TemporaryPassword `
            -Department        $Department `
            -Title             $Title `
            -Enabled           $true `
            -ErrorAction       Stop
        $userCreated = $true
        $state.CompletedStages.Add('CreateUser')

        foreach ($group in @('AllEmployees', $Department)) {
            $state.Stage = "AddGroup:$group"
            Add-ADGroupMember -Identity $group -Members $sam -ErrorAction Stop
            $state.GroupsAdded.Add($group)
            $state.CompletedStages.Add("AddGroup:$group")
        }

        if ($Manager) {
            $state.Stage = 'ResolveManager'
            $managerDN = (Get-ADUser -Identity $Manager `
                -Properties DistinguishedName -ErrorAction Stop).DistinguishedName
            if (-not $managerDN) {
                throw "Manager '$Manager' has no DistinguishedName."
            }
            $state.CompletedStages.Add('ResolveManager')

            $state.Stage = 'AssignManager'
            Set-ADUser -Identity $sam -Manager $managerDN -ErrorAction Stop
            $state.CompletedStages.Add('AssignManager')
        }

        $state.Stage = 'Complete'
        $state.Status = 'Complete'
        Write-Verbose "Onboarding complete for $sam ($upn)"
    }
    catch {
        $state.Error = $_.Exception.Message
        if ($userCreated) {
            $state.Status = 'PartialFailure'
        }
        else {
            $state.Status = 'Failed'
        }

        if ($userCreated -and $RemovePartialUserOnFailure -and
            $PSCmdlet.ShouldProcess($sam, 'Remove partially provisioned AD user')) {
            $state.CleanupAttempted = $true
            $state.CleanupSucceeded = $false
            try {
                Remove-ADUser -Identity $sam -Confirm:$false -ErrorAction Stop
                $state.CleanupSucceeded = $true
                $state.Status = 'FailedCleanupCompleted'
                $state.CompletedStages.Add('CleanupUser')
            }
            catch {
                $state.CleanupError = $_.Exception.Message
            }
        }
    }

    [PSCustomObject] $state
}

# Usage
$temporaryPassword = Read-Host 'Temporary password for Charlie Davis' -AsSecureString
New-UserOnboarding -FirstName 'Charlie' -LastName 'Davis' `
                   -Department 'Engineering' -Title 'Developer' `
                   -Manager 'rina' -TemporaryPassword $temporaryPassword -WhatIf
```

`SupportsShouldProcess` adds `-WhatIf` and `-Confirm`, but only because the
function gates the mutation before the first AD write. `-WhatIf` returns a
structured `WhatIf` result and calls no AD cmdlets. Every AD call uses
`-ErrorAction Stop`, so a failure enters `catch`; the returned `Stage`,
`CompletedStages`, and `GroupsAdded` fields distinguish a failed create from a
partially configured account. `Complete` is assigned only after every requested
operation succeeds.

This sequence is **not a transaction**. By default, a partially created user is
retained for investigation, and the result reports `PartialFailure`. The
`-RemovePartialUserOnFailure` switch opts into a separate, confirmed
compensating action only for a user created by this invocation. Even successful
cleanup does not erase directory replication, audit logs, or other observed
side effects, so the function reports `FailedCleanupCompleted`, never
"rolled back." Run with `-WhatIf` first and inspect the result in every
environment you value.

---

## Quick Reference

Use these commands as a starting point, then narrow their scope and add
environment-appropriate error handling before automating changes.

```powershell
# Find all users in an OU
Get-ADUser -Filter * -SearchBase 'OU=Users,DC=corp,DC=local' -Properties *

# Find disabled accounts
Get-ADUser -Filter { Enabled -eq $false } -Properties LastLogonDate |
    Select-Object Name, SamAccountName, LastLogonDate | Sort-Object LastLogonDate

# Find users not logged in for 90 days
$cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter { LastLogonDate -lt $cutoff -and Enabled -eq $true } `
           -Properties LastLogonDate

# List members of a group
Get-ADGroupMember -Identity 'VPN-Users' -Recursive

# Find a user's group memberships
(Get-ADUser -Identity jsmith -Properties MemberOf).MemberOf
```

---

## Exercises

### [Ch-15, Ex-1] List Users in an OU (Simple)

Write a script that retrieves all enabled users from
`OU=Users,DC=corp,DC=local` and displays their `Name` and `SamAccountName`.
Use a mock in your test so no AD connection is required.

**Constraints:**
- Use `Get-ADUser -Filter { Enabled -eq $true }` (not `-Identity`)
- Use `-SearchBase` to scope the query
- Output must include at least two users

---

### [Ch-15, Ex-2] Find Disabled Accounts (Normal)

Query all users (no SearchBase restriction) and return only those where
`Enabled -eq $false`. Your script should output the count of disabled
accounts and list their SAM account names.

**Constraints:**
- Use `Get-ADUser -Filter *` then `Where-Object`
- Return a count and a list
- Handle the case where zero disabled accounts exist gracefully

---

### [Ch-15, Ex-3] Bulk Create Users from CSV (Advanced)

Given an in-memory array of user data (simulating `Import-Csv`), write a
loop that creates each user with `New-ADUser`. Build the `SamAccountName`
as first initial + lowercase surname. Return a summary object per user.

**Constraints:**
- SAM format: `"$($user.FirstName[0].ToString().ToLower())$($user.LastName.ToLower())"`
- Wrap each `New-ADUser` call in `try/catch`
- Return `[PSCustomObject]` with `Name` and `SAM` properties per user
- All `New-ADUser` calls must be mocked in tests

---

### [Ch-15, Ex-4] Automated Onboarding Script (Extreme)

Write a `New-UserOnboarding` function that:
1. Accepts `FirstName`, `LastName`, `Department`, `Title`, and a caller-provided
   `SecureString` temporary password as mandatory parameters
2. Derives `SamAccountName` and `UserPrincipalName` from the name
3. Calls `New-ADUser` to create the account enabled with that temporary password
4. Calls `Set-ADUser` to set `Department` and `Title`
5. Calls `Add-ADGroupMember` twice: once for `'AllEmployees'` and once for the department group
6. Uses terminating errors and returns a staged `[PSCustomObject]` that reports
   `Status`, `Stage`, completed stages, groups added, and any failure
7. Supports `-WhatIf` without invoking any AD cmdlet
8. Retains a partially created user by default and offers explicitly requested,
   separately confirmed compensating cleanup

**Constraints:**
- All AD cmdlets mocked in Pester
- No plaintext password literals in the function or test fixture
- Do not describe the multi-call workflow as transactional or rolled back
- `Should -Invoke` assertions on all three AD cmdlets
- Test the success, `-WhatIf`, and partial-failure paths
