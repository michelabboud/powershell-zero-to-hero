# Chapter 15 -- Answers

---

## Ch-15, Ex-1 (Simple)

**Task:** List all enabled users in `OU=Users,DC=corp,DC=local` and display
their `Name` and `SamAccountName`. Use a mock in tests — no real AD required.

### Solution

```powershell
$searchBase = 'OU=Users,DC=corp,DC=local'

$users = Get-ADUser -Filter * -SearchBase $searchBase

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

`Get-ADUser -Filter *` without `-SearchBase` would scan the entire domain.
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
$disabled    = $allUsers | Where-Object { -not $_.Enabled }
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
`$disabled.Count` safely returns `0` when the pipeline yields nothing,
because PowerShell always returns an array from `Where-Object`, never `$null`.

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
sets their attributes, and adds them to two groups, returning a structured
summary object.

### Solution

```powershell
function New-UserOnboarding {
    param(
        [Parameter(Mandatory)] [string] $FirstName,
        [Parameter(Mandatory)] [string] $LastName,
        [Parameter(Mandatory)] [string] $Department,
        [Parameter(Mandatory)] [string] $Title
    )

    $sam = "$($FirstName.Substring(0,1).ToLower())$($LastName.ToLower())"
    $upn = "$sam@corp.local"

    New-ADUser `
        -Name              "$FirstName $LastName" `
        -SamAccountName    $sam `
        -UserPrincipalName $upn `
        -Enabled           $true

    Set-ADUser -Identity $sam -Department $Department -Title $Title

    Add-ADGroupMember -Identity 'AllEmployees' -Members $sam
    Add-ADGroupMember -Identity $Department    -Members $sam

    [PSCustomObject]@{
        SAM    = $sam
        UPN    = $upn
        Groups = @('AllEmployees', $Department)
    }
}
```

### Expected Output

```powershell
$result = New-UserOnboarding -FirstName 'Charlie' -LastName 'Davis' `
                              -Department 'Engineering' -Title 'Developer'

$result.SAM    # cdavis
$result.UPN    # cdavis@corp.local
$result.Groups # AllEmployees, Engineering
```

### What to notice

The function follows the **single-responsibility by layer** pattern: one
block creates, one modifies attributes, two lines handle group membership.
Each concern is a distinct AD call rather than one massive `New-ADUser`
parameter list — this makes it easier to wrap individual calls in
`try/catch` later. `Groups` is stored as an array literal `@('AllEmployees',
$Department)`, which means `$result.Groups | Should -Contain 'Engineering'`
works cleanly in Pester via the `-Contain` operator. `Should -Invoke
Add-ADGroupMember -Times 2` in the test verifies both group calls fired
without needing a real domain — a good example of behaviour verification
(did we attempt the right operations?) rather than state verification (is
the user actually in the group?). In a real onboarding script you'd add
`SupportsShouldProcess` and `-WhatIf` support; see the chapter's
`New-UserOnboarding` listing for the full production version.
