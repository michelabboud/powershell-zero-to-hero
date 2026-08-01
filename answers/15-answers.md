# Chapter 15 -- Answers

---

## Ch-15, Ex-1 (Simple)

**Task:** List all enabled users in `OU=Users,DC=corp,DC=local` and display
their `Name` and `SamAccountName`. Use a mock in tests — no real AD required.

### Solution

```powershell
$searchBase = 'OU=Users,DC=corp,DC=local'

$users = Get-ADUser -Filter { Enabled -eq $true } -SearchBase $searchBase

foreach ($user in $users) {
    [PSCustomObject]@{
        Name           = $user.Name
        SamAccountName = $user.SamAccountName
    }
}
```

### Expected Output

```
Name        SamAccountName
----        --------------
John Smith  jsmith
Jane Doe    jdoe
```

### What to notice

`Get-ADUser -Filter { Enabled -eq $true }` pushes the enabled-state predicate
to the directory server. Omitting `-SearchBase` would scan the entire domain.
Adding `-SearchBase` scopes the LDAP query server-side before any results
travel over the wire — much faster in large environments. The mock in the
test file returns a fixed two-element array so the test never touches a
Domain Controller; the script itself is identical to what you'd run against
real AD. `[PSCustomObject]` shapes the output for consistent column display
whether you pipe to `Format-Table`, `Export-Csv`, or just print to the host.

---

## Ch-15, Ex-2 (Normal)

**Task:** Query all users, filter to those with `Enabled -eq $false`, output
the count and a list of their SAM account names. Handle zero results
gracefully.

### Solution

```powershell
$allUsers    = Get-ADUser -Filter *
$disabled    = @($allUsers | Where-Object { -not $_.Enabled })
$count       = $disabled.Count

if ($count -eq 0) {
    Write-Host 'No disabled accounts found.' -ForegroundColor Green
} else {
    Write-Host "Disabled accounts: $count" -ForegroundColor Yellow
    $disabled | Select-Object Name, SamAccountName
}
```

### Expected Output (with sample data)

```
Disabled accounts: 1

Name      SamAccountName
----      --------------
Old User  ouser
```

### What to notice

`Get-ADUser -Filter { Enabled -eq $false }` is a valid alternative that
pushes the filter server-side and is faster at scale. The `Where-Object`
approach in this exercise is intentional — it demonstrates the client-side
pipeline pattern and allows the mock to return a mixed array that you then
filter yourself. In production with tens of thousands of accounts, prefer
the server-side `-Filter { Enabled -eq $false }` form. Note that
Wrapping the pipeline in `@(...)` guarantees an array for zero, one, or many
results, so `$disabled.Count` is unambiguous.

---

## Ch-15, Ex-3 (Advanced)

**Task:** Given an in-memory CSV-like array, bulk-create AD users with
`New-ADUser`. Derive SAM as first-initial + lowercase surname. Return a
summary object per user. Wrap each call in `try/catch`.

### Solution

```powershell
$csvData = @(
    [PSCustomObject]@{ FirstName = 'Alice'; LastName = 'Brown'; Department = 'IT' },
    [PSCustomObject]@{ FirstName = 'Bob';   LastName = 'Green'; Department = 'HR' }
)

$results = foreach ($user in $csvData) {
    $sam  = "$($user.FirstName.Substring(0,1).ToLower())$($user.LastName.ToLower())"
    $name = "$($user.FirstName) $($user.LastName)"

    try {
        New-ADUser -Name $name -SamAccountName $sam
        [PSCustomObject]@{ Name = $name; SAM = $sam; Status = 'Created' }
    }
    catch {
        Write-Warning "Failed to create $sam : $_"
        [PSCustomObject]@{ Name = $name; SAM = $sam; Status = 'Failed' }
    }
}

$results
```

### Expected Output

```
Name         SAM     Status
----         ---     ------
Alice Brown  abrown  Created
Bob Green    bgreen  Created
```

### What to notice

`foreach` as an expression (assigned to `$results`) is idiomatic PowerShell.
Each loop iteration can emit one or more objects; they all accumulate into
`$results` automatically — no `[System.Collections.Generic.List[object]]`
required. The `try/catch` means a single account that already exists (or
any other `New-ADUser` error) won't abort the entire batch; the loop
continues and logs a `Failed` status row instead. In tests, `New-ADUser` is
mocked to do nothing, so `Should -Invoke New-ADUser -Times 2` verifies the
loop executed both calls without any real AD dependency.

---

## Ch-15, Ex-4 (Extreme)

**Task:** Write `New-UserOnboarding` — a function that creates an AD user,
sets their attributes, and adds them to two groups. It must preview safely,
stop on AD errors, and return a structured staged result on every path.

### Solution

```powershell
function New-UserOnboarding {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $FirstName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $LastName,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Department,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Title,
        [Parameter(Mandatory)] [SecureString] $TemporaryPassword,
        [switch] $RemovePartialUserOnFailure
    )

    $sam = "$($FirstName.Substring(0,1).ToLower())$($LastName.ToLower())"
    $upn = "$sam@corp.local"

    $state = [ordered]@{
        SAM              = $sam
        UPN              = $upn
        Status           = 'Planned'
        Stage            = 'Plan'
        CompletedStages  = [System.Collections.Generic.List[string]]::new()
        GroupsAdded      = [System.Collections.Generic.List[string]]::new()
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
            -SamAccountName    $sam `
            -UserPrincipalName $upn `
            -AccountPassword   $TemporaryPassword `
            -Enabled           $true `
            -ErrorAction       Stop
        $userCreated = $true
        $state.CompletedStages.Add('CreateUser')

        $state.Stage = 'SetAttributes'
        Set-ADUser -Identity $sam -Department $Department -Title $Title `
            -ErrorAction Stop
        $state.CompletedStages.Add('SetAttributes')

        foreach ($group in @('AllEmployees', $Department)) {
            $state.Stage = "AddGroup:$group"
            Add-ADGroupMember -Identity $group -Members $sam -ErrorAction Stop
            $state.GroupsAdded.Add($group)
            $state.CompletedStages.Add("AddGroup:$group")
        }

        $state.Stage = 'Complete'
        $state.Status = 'Complete'
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
```

### Expected Output

```powershell
$temporaryPassword = Read-Host 'Temporary password for Charlie Davis' -AsSecureString
$result = New-UserOnboarding -FirstName 'Charlie' -LastName 'Davis' `
    -Department 'Engineering' -Title 'Developer' `
    -TemporaryPassword $temporaryPassword

$result.SAM         # cdavis
$result.UPN         # cdavis@corp.local
$result.Status      # Complete
$result.GroupsAdded # AllEmployees, Engineering
```

### What to notice

`ShouldProcess` gates the workflow before the first write, so `-WhatIf` returns
a `WhatIf` result and invokes no AD cmdlet. `-ErrorAction Stop` makes each AD
failure terminating; `catch` then returns the failed stage, completed stages,
groups that were actually added, and the error. `Complete` is assigned only
after all four mutations succeed, so a group failure cannot produce a false
success result.

The sequence is **not a transaction**. A newly created but partially configured
user remains in AD by default for investigation. The caller may explicitly add
`-RemovePartialUserOnFailure` to request a separately confirmed compensating
delete. That cleanup is limited to a user created by this invocation, and even
when it succeeds the result says `FailedCleanupCompleted`, not "rolled back,"
because directory replication, audit records, and other observed side effects
can remain. The Pester suite verifies success, `-WhatIf` with zero mutations,
and a second-group failure that reports only the first group as completed.
