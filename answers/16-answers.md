# Chapter 16 -- Answers

---

## Ch-16, Ex-1 (Simple)

**Task:** Find all files in a directory whose `LastWriteTime` is older than
7 days and remove them. A freshly-created file in the same directory must
survive.

### Solution

```powershell
param(
    [string]$TargetDir = $env:TEMP,
    [int]   $DaysOld   = 7
)

$cutoff = (Get-Date).AddDays(-$DaysOld)

$stale = Get-ChildItem -Path $TargetDir -File |
    Where-Object { $_.LastWriteTime -lt $cutoff }

if ($stale.Count -eq 0) {
    Write-Host "Nothing to clean in $TargetDir (threshold: $DaysOld days)"
    return
}

Write-Host "Removing $($stale.Count) file(s) older than $DaysOld days..."
$stale | Remove-Item -Force -ErrorAction Continue
Write-Host "Done."
```

### Testing it manually

```powershell
# Setup
$dir = Join-Path $env:TEMP 'ch16-ex1-test'
New-Item $dir -ItemType Directory -Force | Out-Null

$old = Join-Path $dir 'old-temp.log'
$new = Join-Path $dir 'new-temp.log'
Set-Content $old 'stale'
Set-Content $new 'fresh'
(Get-Item $old).LastWriteTime = (Get-Date).AddDays(-10)   # backdate

# Run
Get-ChildItem $dir -File | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-7)
} | Remove-Item -Force

# Verify
Test-Path $old   # False -- deleted
Test-Path $new   # True  -- survived

# Cleanup
Remove-Item $dir -Recurse -Force
```

### Expected Output

```
False
True
```

### What to notice

**Backdating `LastWriteTime`** is done by assigning to the `FileInfo`
property directly: `(Get-Item $path).LastWriteTime = $date`. This works
because `LastWriteTime` has a public setter on `System.IO.FileInfo`. It
is only meaningful in tests and tooling -- never backdate files in
production, or you will confuse every retention script and every human
who comes after you.

**`-ErrorAction Continue`** on `Remove-Item` means a locked file (opened
by another process) does not abort the loop. You lose that one file in
this run but clean everything else. Log locked files separately if they
matter for auditing.

**The `$cutoff` variable** captures `(Get-Date).AddDays(-7)` once, before
the loop. If you inline `(Get-Date).AddDays(-7)` inside `Where-Object`,
PowerShell evaluates it for every file, which introduces tiny time drift
on large directories. Capture once, compare many. This is a good habit.

---

## Ch-16, Ex-2 (Normal)

**Task:** Copy a source directory into a date-stamped subfolder under a
backup root. Prune backup folders older than a configurable retention
window (default: 14 days). Verify the copy succeeded.

### Solution

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$SourceDir,
    [Parameter(Mandatory)][string]$BackupRoot,
    [int]$RetainDays = 14
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 1. Create date-stamped backup
$stamp     = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupDir = Join-Path $BackupRoot $stamp

Write-Host "Creating backup: $backupDir"
New-Item $BackupRoot -ItemType Directory -Force | Out-Null
Copy-Item -Path $SourceDir -Destination $backupDir -Recurse -Force

$fileCount = (Get-ChildItem $backupDir -File -Recurse).Count
Write-Host "Backup complete. $fileCount file(s) copied."

# 2. Prune old backups
$cutoff = (Get-Date).AddDays(-$RetainDays)
$old    = Get-ChildItem $BackupRoot -Directory |
    Where-Object { $_.CreationTime -lt $cutoff }

if ($old.Count -gt 0) {
    Write-Host "Pruning $($old.Count) backup(s) older than $RetainDays days..."
    foreach ($dir in $old) {
        if ($PSCmdlet.ShouldProcess($dir.FullName, 'Remove old backup')) {
            Remove-Item $dir.FullName -Recurse -Force
            Write-Verbose "Pruned: $($dir.Name)"
        }
    }
} else {
    Write-Host "No backups eligible for pruning."
}
```

### Testing it manually

```powershell
$base   = Join-Path $env:TEMP 'ch16-ex2-test'
$src    = Join-Path $base 'source'
$bkRoot = Join-Path $base 'backups'
New-Item $src -ItemType Directory -Force | Out-Null
Set-Content (Join-Path $src 'data.txt') 'important data'
Set-Content (Join-Path $src 'config.json') '{"key":"value"}'

$stamp     = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupDir = Join-Path $bkRoot $stamp
Copy-Item $src $backupDir -Recurse -Force

Test-Path $backupDir                           # True
Test-Path (Join-Path $backupDir 'data.txt')    # True
(Get-ChildItem $backupDir -File).Count         # 2

Remove-Item $base -Recurse -Force
```

### Expected Output

```
Creating backup: C:\...\backups\2026-03-17_143022
Backup complete. 2 file(s) copied.
No backups eligible for pruning.
```

### What to notice

**`Copy-Item -Recurse`** copies the *contents* of the source directory when
the destination does not yet exist. After the copy, `$backupDir` contains
`data.txt` and `config.json` directly -- not a nested `source\data.txt`.
If the destination directory already existed before the copy, PowerShell
would nest the source directory inside it. This is the "create before copy"
subtlety: the behaviour differs based on whether the destination path exists
at copy time. When in doubt, let `Copy-Item` create the destination.

**Retention uses `CreationTime`, not `LastWriteTime`** for backup folders.
You want to measure when the backup was *made*, not when a file inside it
was last modified. Using `LastWriteTime` on a directory returns the time
its *directory entry* was last updated, which can be misleading. `CreationTime`
is unambiguous for this purpose.

**`SupportsShouldProcess` on a backup script** might seem surprising, but
the prune step is a bulk destructive operation. Running the script with
`-WhatIf` lets you verify which old backups would be removed before
committing. Attach `-WhatIf` to every script that deletes anything, even
if deletion is not the primary purpose.

---

## Ch-16, Ex-3 (Advanced)

**Task:** Collect system inventory data into a `PSCustomObject` with at
least 5 properties. Hostname must be populated. Process count must be > 0.

### Solution

```powershell
$inventory = [PSCustomObject]@{
    Hostname  = $env:COMPUTERNAME
    OS        = $PSVersionTable.OS
    PSVersion = $PSVersionTable.PSVersion.ToString()
    Processes = (Get-Process).Count
    Services  = (Get-Service).Count
    Uptime    = [math]::Round((Get-Uptime).TotalHours, 1)
    MemoryMB  = [math]::Round(
        (Get-Process | Measure-Object WorkingSet64 -Sum).Sum / 1MB
    )
    ReportTime = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

$inventory | Format-List
```

### For a full HTML report (production version)

```powershell
# Extend the object with CIM data for richer output
$os    = Get-CimInstance Win32_OperatingSystem
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

$inventory = [PSCustomObject]@{
    Hostname   = $env:COMPUTERNAME
    OS         = $os.Caption
    OSBuild    = $os.BuildNumber
    PSVersion  = $PSVersionTable.PSVersion.ToString()
    TotalMemGB = [math]::Round($os.TotalVisibleMemorySizeKB / 1MB, 1)
    FreeMemGB  = [math]::Round($os.FreePhysicalMemoryKB / 1MB, 1)
    Processes  = (Get-Process).Count
    Services   = (Get-Service | Where-Object Status -eq 'Running').Count
    UptimeHrs  = [math]::Round((New-TimeSpan $os.LastBootUpTime (Get-Date)).TotalHours, 1)
    ReportTime = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

# Convert to HTML
$html = $inventory.PSObject.Properties |
    Select-Object Name, Value |
    ConvertTo-Html -Title "Inventory: $($inventory.Hostname)" -Fragment |
    Out-String

Set-Content (Join-Path $env:TEMP 'inventory.html') $html -Encoding UTF8
Write-Host "Report: $(Join-Path $env:TEMP 'inventory.html')"
```

### Expected Output

```
Hostname   : WEB01
OS         : Microsoft Windows 11 Pro
PSVersion  : 7.4.6
Processes  : 187
Services   : 243
Uptime     : 48.3
MemoryMB   : 4821
ReportTime : 2026-03-17 14:30:22
```

### What to notice

**`[PSCustomObject]@{}`** with a hashtable literal is the idiomatic way to
build structured output objects in PowerShell. The order of properties in
the hashtable is preserved in the output, which matters when you pipe to
`Format-Table` or `ConvertTo-Html`. Regular `[hashtable]` does not preserve
order; `[PSCustomObject]` does. Use `[PSCustomObject]` when property order
matters to you or your downstream consumers.

**`$PSVersionTable`** is a built-in automatic variable available in every
session. It requires no cmdlet call and no CIM query. Use it for quick
PS/OS version data. For deeper OS details (total memory, build number,
last boot), `Get-CimInstance Win32_OperatingSystem` is the right tool.
The two complement each other.

**`Get-Uptime`** (PS7+) is a clean one-liner. On Windows PowerShell 5.1,
you need `(Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime`. Know
which version your environment runs before deploying scripts that use PS7+
cmdlets.

**`Measure-Object WorkingSet64 -Sum`** sums a property across all pipeline
objects. The same pattern works for file sizes, CPU times, error counts --
any numeric property on any object collection. Learn this pattern and use
it constantly.

---

## Ch-16, Ex-4 (Extreme)

**Task:** Given a baseline list of services with expected statuses and a
current snapshot, produce a drift report listing services whose actual
status differs from the baseline. Verify that a single changed service
produces exactly one drift entry with correct `Name`, `Expected`, and
`Actual` values.

### Solution

```powershell
function Compare-ServiceBaseline {
    <#
    .SYNOPSIS
        Detect drift between a service baseline and current state.
    .PARAMETER Baseline
        Array of PSCustomObjects with Name and Status properties.
    .PARAMETER Current
        Array of PSCustomObjects with Name and Status properties.
    .OUTPUTS
        PSCustomObjects with Name, Expected, and Actual properties for each
        service that has drifted. Empty array if no drift detected.
    #>
    param(
        [Parameter(Mandatory)][object[]]$Baseline,
        [Parameter(Mandatory)][object[]]$Current
    )

    foreach ($expected in $Baseline) {
        $actual = $Current | Where-Object Name -eq $expected.Name

        if (-not $actual) {
            [PSCustomObject]@{
                Name     = $expected.Name
                Expected = $expected.Status
                Actual   = 'NOT FOUND'
            }
            continue
        }

        if ($actual.Status -ne $expected.Status) {
            [PSCustomObject]@{
                Name     = $expected.Name
                Expected = $expected.Status
                Actual   = $actual.Status
            }
        }
    }
}

# --- Example usage ---

$baseline = @(
    [PSCustomObject]@{ Name = 'WinRM';   Status = 'Running' },
    [PSCustomObject]@{ Name = 'Spooler'; Status = 'Running' },
    [PSCustomObject]@{ Name = 'BITS';    Status = 'Running' }
)

# Simulate a stopped spooler
$current = @(
    [PSCustomObject]@{ Name = 'WinRM';   Status = 'Running' },
    [PSCustomObject]@{ Name = 'Spooler'; Status = 'Stopped' },
    [PSCustomObject]@{ Name = 'BITS';    Status = 'Running' }
)

$drift = Compare-ServiceBaseline -Baseline $baseline -Current $current

if ($drift.Count -eq 0) {
    Write-Host '[OK] All services match baseline.'
} else {
    Write-Warning "Drift detected: $($drift.Count) service(s) out of expected state"
    $drift | Format-Table -AutoSize
}
```

### With real services (production usage)

```powershell
$watchList = @('WinRM', 'EventLog', 'Spooler', 'BITS', 'wuauserv')
$baselinePath = Join-Path $PSScriptRoot 'service-baseline.json'

# Save baseline (run once)
Get-Service -Name $watchList -ErrorAction SilentlyContinue |
    Select-Object Name, @{N='Status'; E={$_.Status.ToString()}} |
    ConvertTo-Json -Depth 3 |
    Set-Content $baselinePath -Encoding UTF8

# Check drift (run on schedule)
$baseline = Get-Content $baselinePath -Raw | ConvertFrom-Json
$current  = Get-Service -Name $watchList -ErrorAction SilentlyContinue |
    Select-Object Name, @{N='Status'; E={$_.Status.ToString()}}

$drift = Compare-ServiceBaseline -Baseline $baseline -Current $current
$drift | Format-Table -AutoSize
```

### Expected Output (with one drifted service)

```
WARNING: Drift detected: 1 service(s) out of expected state

Name    Expected Actual
----    -------- ------
Spooler Running  Stopped
```

### What to notice

**The `foreach ... Where-Object` inner lookup** is an O(n*m) operation --
fine for a watchlist of 10-50 services, not fine for thousands. For large
baselines, convert the current state to a hashtable keyed by `Name` first:
`$currentMap = @{}; $current | ForEach-Object { $currentMap[$_.Name] = $_ }`.
Then each lookup is O(1). Know when your data size makes the naive approach
unacceptable.

**Output objects, not strings.** `Compare-ServiceBaseline` returns
`PSCustomObject` instances, not formatted text. The *caller* decides how to
present them: `Format-Table` for terminal display, `ConvertTo-Json` for
logging, `ConvertTo-Html` for reports, `Send-Alert` for email. Functions
that return objects are composable; functions that return strings are
terminal. Write the former.

**The `NOT FOUND` sentinel** handles services that disappeared entirely from
the system -- not just stopped, but uninstalled. This is a distinct failure
mode from a status change and worth surfacing separately in alerts. A
service going missing is often more alarming than one stopping.

**This pattern generalises.** Swap services for firewall rules, installed
software, registry keys, local users, or any enumerable system state. The
function signature is identical; only the data source changes. Baseline
comparison is one of the most powerful and reusable patterns in operational
PowerShell.
