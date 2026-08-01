# Chapter 16: Automation Recipes

Sam has been doing this manually for six months. This chapter ends that.

![chapter-opener](assets/images/ch-16-opener.png)

---

## Why Automation Recipes?

Theory is how you learn to drive. Recipes are how you survive rush hour.

This chapter is a collection of real-world automation patterns that show up
in nearly every IT environment: cleaning up old files, backing up directories,
generating system reports, scheduling tasks, and watching for problems before
they become incidents. Each recipe is a self-contained script you can adapt
and deploy.

The goal is not to teach new syntax -- you have all the tools from earlier
chapters. The goal is to show how those tools combine into scripts that are
reliable, observable, and maintainable by someone other than you at 2 AM.

![recipe-map](assets/images/ch-16-recipe-map.png)

---

## Recipe 1: Log Rotation and Cleanup

The most common sysadmin automation task. Logs grow until they eat the disk,
then someone pages you at midnight. Prevention is a script.

### The Pattern

```powershell
<#
.SYNOPSIS
    Remove log files older than a specified number of days.
.PARAMETER LogDir
    Directory to clean.
.PARAMETER DaysOld
    Files older than this many days are deleted. Default: 30.
.PARAMETER WhatIf
    Inherited from CmdletBinding -- shows what would be deleted without deleting.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$LogDir,
    [int]$DaysOld = 30
)

$cutoff = (Get-Date).AddDays(-$DaysOld)
$candidates = @(Get-ChildItem -Path $LogDir -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff })

if ($candidates.Count -eq 0) {
    Write-Host "No files older than $DaysOld days found in $LogDir"
    return
}

$totalMB = [math]::Round(($candidates | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Host "Found $($candidates.Count) files ($totalMB MB) eligible for removal"

foreach ($file in $candidates) {
    if ($PSCmdlet.ShouldProcess($file.FullName, 'Remove-Item')) {
        Remove-Item $file.FullName -Force -ErrorAction Continue
        Write-Verbose "Deleted: $($file.FullName)"
    }
}
```

### Key Points

`SupportsShouldProcess` wires up `-WhatIf` and `-Confirm` automatically.
When you call your script with `-WhatIf`, nothing gets deleted -- you see
exactly what *would* happen. Run with `-WhatIf` first. Always.

`-ErrorAction Continue` on `Remove-Item` means a locked file won't abort
the whole cleanup. You lose that one file, but the rest of the run completes.
Log the failures separately if they matter.

### Running It

```powershell
# Dry run -- see what would be deleted
.\Invoke-LogCleanup.ps1 -LogDir C:\IIS\Logs -DaysOld 7 -WhatIf

# Real run with verbose output
.\Invoke-LogCleanup.ps1 -LogDir C:\IIS\Logs -DaysOld 7 -Verbose
```

---

## Recipe 2: File Backup with Retention

Backup without retention is just slow disk death. The pattern: copy to a
date-stamped folder, then prune backups older than your retention window.

```powershell
<#
.SYNOPSIS
    Back up a source directory to a date-stamped folder, then prune old backups.
.PARAMETER SourceDir
    The directory to back up.
.PARAMETER BackupRoot
    Root folder where dated backup folders are created.
.PARAMETER RetainDays
    Delete backup folders older than this many days. Default: 14.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$SourceDir,
    [Parameter(Mandatory)][string]$BackupRoot,
    [int]$RetainDays = 14
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Create the backup ---
$stamp     = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupDir = Join-Path $BackupRoot $stamp

Write-Host "Backing up '$SourceDir' -> '$backupDir'"
if ($PSCmdlet.ShouldProcess($backupDir, "Copy '$SourceDir'")) {
    New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
    Copy-Item -Path $SourceDir -Destination $backupDir -Recurse -Force
    Write-Host "Backup complete."
}

# --- Prune old backups ---
$cutoff = (Get-Date).AddDays(-$RetainDays)
$old = @(Get-ChildItem -Path $BackupRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff })

if ($old.Count -gt 0) {
    Write-Host "Pruning $($old.Count) backup(s) older than $RetainDays days..."
    foreach ($dir in $old) {
        if ($PSCmdlet.ShouldProcess($dir.FullName, 'Remove backup')) {
            Remove-Item $dir.FullName -Recurse -Force
            Write-Verbose "Pruned: $($dir.FullName)"
        }
    }
} else {
    Write-Host "No backups to prune."
}
```

### Self-Documenting with Comment-Based Help

Notice the `<# .SYNOPSIS ... #>` block. This is **comment-based help**. Run
`Get-Help .\Invoke-Backup.ps1` and PowerShell renders it as a proper help
page -- parameters, synopsis, everything. It costs you thirty seconds to
write and saves ten minutes of "what does this script do again?" every time
someone else touches it.

```powershell
# What you get for free:
Get-Help .\Invoke-Backup.ps1 -Full
Get-Help .\Invoke-Backup.ps1 -Examples
```

`Set-StrictMode -Version Latest` catches use of uninitialized variables and
other sloppy habits at script start. Pairing it with
`$ErrorActionPreference = 'Stop'` is a strong default for automation because
cmdlet failures become terminating errors. Native executables still report
failure through `$LASTEXITCODE` unless you deliberately enable
`$PSNativeCommandUseErrorActionPreference`; choose and test that policy for
each script.

---

## Recipe 3: System Inventory Report

One of the most-requested scripts in any IT team: "give me a snapshot of
what's running on this box." Useful for baseline documentation, incident
response, and compliance audits.

This recipe is **Windows-only**: the `Win32_*` CIM classes and `Get-Service`
calls shown here rely on Windows management providers. The exercises later in
the chapter show how to keep the basic inventory object portable.

![inventory-report](assets/images/ch-16-inventory-report.png)

```powershell
<#
.SYNOPSIS
    Generate an HTML system inventory report.
.PARAMETER OutputPath
    Where to write the HTML file. Defaults to the current directory.
#>
param(
    [string]$OutputPath = (Join-Path (Get-Location)
        "inventory-$([Environment]::MachineName)-$(Get-Date -Format yyyyMMdd).html")
)

$ErrorActionPreference = 'Stop'

# --- Gather data ---
$os       = Get-CimInstance Win32_OperatingSystem
$cpu      = Get-CimInstance Win32_Processor | Select-Object -First 1
$disks    = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$services = Get-Service | Where-Object Status -eq 'Running' |
                Sort-Object DisplayName
$topProcs = Get-Process | Sort-Object WorkingSet64 -Descending |
                Select-Object -First 15 Name,
                    @{N='MemMB';  E={[math]::Round($_.WorkingSet64/1MB,1)}},
                    @{N='CPU';    E={[math]::Round($_.CPU,1)}},
                    Id

$inventory = [PSCustomObject]@{
    Hostname    = [Environment]::MachineName
    OS          = $os.Caption
    OSBuild     = $os.BuildNumber
    Architecture= $os.OSArchitecture
    CPU         = $cpu.Name
    TotalMemGB  = [math]::Round($os.TotalVisibleMemorySizeKB / 1MB, 1)
    FreeMemGB   = [math]::Round($os.FreePhysicalMemoryKB / 1MB, 1)
    Uptime      = [math]::Round((New-TimeSpan $os.LastBootUpTime (Get-Date)).TotalHours, 1)
    PSVersion   = $PSVersionTable.PSVersion.ToString()
    ReportTime  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

# --- Build HTML ---
$cssStyle = @"
<style>
  body { font-family: Segoe UI, sans-serif; background: #f0f2f5; color: #1a1a2e; }
  h1   { background: #012456; color: white; padding: 16px 24px; margin: 0; }
  h2   { color: #012456; border-bottom: 2px solid #012456; padding-bottom: 4px; }
  .container { max-width: 1100px; margin: 24px auto; padding: 0 16px; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 24px; }
  th    { background: #012456; color: white; padding: 8px 12px; text-align: left; }
  td    { padding: 8px 12px; border-bottom: 1px solid #d0d0d0; }
  tr:nth-child(even) td { background: #eef0f4; }
</style>
"@

$sysInfoHtml = $inventory.PSObject.Properties |
    Select-Object Name, Value |
    ConvertTo-Html -Fragment -As List

$topProcsHtml  = $topProcs  | ConvertTo-Html -Fragment
$servicesHtml  = $services  | Select-Object DisplayName, Status, StartType |
                              ConvertTo-Html -Fragment

$html = ConvertTo-Html -Title "Inventory: $($inventory.Hostname)" `
    -Head $cssStyle `
    -PreContent "<h1>System Inventory -- $($inventory.Hostname)</h1>
                 <div class='container'>
                 <h2>System Information</h2>$sysInfoHtml
                 <h2>Top 15 Processes by Memory</h2>$topProcsHtml
                 <h2>Running Services ($($services.Count))</h2>$servicesHtml
                 </div>" `
    -PostContent "<p style='color:#888;font-size:0.8em;padding:0 24px'>
                  Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') by
                  PowerShell Automation Guide Ch. 16</p>" |
    Out-String

Set-Content -Path $OutputPath -Value $html -Encoding UTF8
Write-Host "Report written to: $OutputPath"
# Optional on an interactive desktop: Invoke-Item $OutputPath
```

`ConvertTo-Html -Fragment` is the workhorse here: it renders any object
collection as an HTML table snippet without full `<html>` boilerplate. Combine
multiple fragments with `ConvertTo-Html -PreContent` for full reports. This
pattern requires zero HTML knowledge and produces something a manager will
actually read.

---

## Recipe 4: Scheduled Tasks

A script that runs manually is a ceremony. A script in a scheduled task is
infrastructure.

This recipe is **Windows-only**. On Linux, use a systemd timer or cron; on
macOS, use `launchd`. Their scheduling and security models are different, so
translate the intent rather than copying these cmdlets.

```powershell
# Register a daily cleanup task (run as current user)
$action  = New-ScheduledTaskAction `
    -Execute 'pwsh.exe' `
    -Argument '-NonInteractive -NoProfile -File "C:\Scripts\Invoke-LogCleanup.ps1" -LogDir "C:\IIS\Logs" -DaysOld 7'

$trigger = New-ScheduledTaskTrigger -Daily -At '02:00'

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false

Register-ScheduledTask `
    -TaskName   'PS-LogCleanup-Daily' `
    -TaskPath   '\PowerShellGuide\' `
    -Action     $action `
    -Trigger    $trigger `
    -Settings   $settings `
    -RunLevel   Highest `
    -Description 'Daily IIS log cleanup, managed by PowerShell automation scripts' `
    -Force
```

### Useful Task Management Commands

```powershell
# List your tasks
Get-ScheduledTask -TaskPath '\PowerShellGuide\*'

# Run immediately (don't wait for the trigger)
Start-ScheduledTask -TaskName 'PS-LogCleanup-Daily' -TaskPath '\PowerShellGuide\'

# Check the last run result
Get-ScheduledTaskInfo -TaskName 'PS-LogCleanup-Daily' -TaskPath '\PowerShellGuide\' |
    Select-Object LastRunTime, LastTaskResult, NextRunTime

# LastTaskResult 0 = success. Anything else: check Event Viewer -> Task Scheduler.

# Remove a task
Unregister-ScheduledTask -TaskName 'PS-LogCleanup-Daily' -TaskPath '\PowerShellGuide\' -Confirm:$false
```

The `-TaskPath` parameter organises tasks in a virtual folder. Using `\PowerShellGuide\`
(or your company prefix) keeps your tasks separate from Windows built-in tasks
in Task Scheduler's tree view. It costs nothing and saves confusion during audits.

---

## Recipe 5: Alert Transport Adapter

Sending an alert turns reactive monitoring into proactive alerting. Keep the
monitor independent of the delivery provider by passing a transport adapter.
That makes the core behavior testable and lets one environment use Microsoft
Graph while another uses a ticketing or webhook API.

```powershell
function Send-Alert {
    <#
    .SYNOPSIS
        Build an alert and pass it to a caller-supplied transport.
    #>
    param(
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][scriptblock]$Transport,
        [string]$To = 'ops-alerts@company.com'
    )

    $alert = [PSCustomObject]@{
        To        = $To
        Subject   = "[ALERT] $Subject"
        Body      = $Body
        CreatedAt = Get-Date
    }

    try {
        & $Transport $alert
        Write-Verbose "Alert sent: $Subject"
    } catch {
        Write-Warning "Failed to send alert '$Subject': $_"
        # Log but don't rethrow -- alert failure shouldn't abort the monitoring script
    }
}

# Example Microsoft Graph adapter. Connect-MgGraph must already be configured
# with the least privilege your identity needs (normally Mail.Send). Prefer a
# managed identity or certificate-based app identity over a stored secret.
$graphTransport = {
    param($Alert)

    $request = @{
        message = @{
            subject = $Alert.Subject
            body = @{ contentType = 'Text'; content = $Alert.Body }
            toRecipients = @(
                @{ emailAddress = @{ address = $Alert.To } }
            )
        }
        saveToSentItems = $false
    }

    Send-MgUserMail -UserId 'monitoring@company.com' -BodyParameter $request
}

# Windows-only usage example: disk space check with alert
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freePercent = [math]::Round($disk.FreeSpace / $disk.Size * 100, 1)

if ($freePercent -lt 15) {
    $body = @"
WARNING: Low disk space on $([Environment]::MachineName)

Drive:      C:\
Free Space: $([math]::Round($disk.FreeSpace/1GB, 1)) GB
Total:      $([math]::Round($disk.Size/1GB, 1)) GB
Free:       $freePercent%

This alert was generated by: $PSCommandPath
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    Send-Alert -Subject "Low disk on $([Environment]::MachineName) (C: $freePercent% free)" `
        -Body $body -Transport $graphTransport
}
```

Do not build new automation around `Send-MailMessage`: Microsoft marks it
obsolete and says it does not guarantee secure SMTP connections. Microsoft
365 automation can use the supported Microsoft Graph
`Send-MgUserMail` cmdlet. Other providers need their own supported SDK or
HTTPS API adapter. Authentication belongs outside the script in the platform's
secret or workload-identity system.

---

## Recipe 6: Service Monitor with Drift Detection

Alerts are reactive. Drift detection is proactive: you define what "healthy"
looks like (the baseline), and your monitor flags deviations automatically.

This concrete implementation is **Windows-only** because `Get-Service` is
currently supported only on Windows. The baseline-comparison function in the
answer section is platform-neutral when supplied with ordinary objects.

```powershell
<#
.SYNOPSIS
    Compare current service state against a saved baseline.
    Save a new baseline with -SaveBaseline.
.PARAMETER BaselinePath
    Path to the baseline JSON file.
.PARAMETER SaveBaseline
    Capture current state as the new baseline.
.PARAMETER AlertThreshold
    Number of drifted services before sending an alert. Default: 1.
#>
[CmdletBinding()]
param(
    [string]$BaselinePath    = (Join-Path $PSScriptRoot 'service-baseline.json'),
    [switch]$SaveBaseline,
    [int]   $AlertThreshold  = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Services we care about -- adjust to your environment
$watchList = @(
    'wuauserv',   # Windows Update
    'WinRM',      # Windows Remote Management
    'EventLog',   # Windows Event Log
    'Spooler',    # Print Spooler
    'BITS'        # Background Intelligent Transfer
)

function Get-ServiceSnapshot {
    Get-Service -Name $watchList -ErrorAction SilentlyContinue |
        Select-Object Name,
            @{N='Status'; E={$_.Status.ToString()}},
            @{N='StartType'; E={$_.StartType.ToString()}}
}

# --- Save baseline ---
if ($SaveBaseline) {
    $snapshot = Get-ServiceSnapshot
    $snapshot | ConvertTo-Json -Depth 5 | Set-Content $BaselinePath -Encoding UTF8
    Write-Host "Baseline saved to: $BaselinePath ($($snapshot.Count) services)"
    return
}

# --- Load baseline ---
if (-not (Test-Path $BaselinePath)) {
    Write-Warning "No baseline found at $BaselinePath. Run with -SaveBaseline first."
    return
}

$baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
$current  = Get-ServiceSnapshot

# --- Detect drift ---
$drift = @(foreach ($expected in $baseline) {
    $actual = $current | Where-Object Name -eq $expected.Name
    if (-not $actual) {
        [PSCustomObject]@{
            Name      = $expected.Name
            Type      = 'Missing'
            Expected  = $expected.Status
            Actual    = 'NOT FOUND'
        }
    } elseif ($actual.Status -ne $expected.Status) {
        [PSCustomObject]@{
            Name      = $expected.Name
            Type      = 'StatusDrift'
            Expected  = $expected.Status
            Actual    = $actual.Status
        }
    }
})

if ($drift.Count -eq 0) {
    Write-Host "[OK] All $($baseline.Count) monitored services match baseline."
    return
}

Write-Warning "Drift detected: $($drift.Count) service(s) out of expected state"
$drift | Format-Table -AutoSize

if ($drift.Count -ge $AlertThreshold) {
    $alertBody = $drift |
        ForEach-Object { "  $($_.Name): expected=$($_.Expected), actual=$($_.Actual)" } |
        Out-String

    # Send-Alert -Subject "Service drift on $([Environment]::MachineName)" `
    #     -Body $alertBody -Transport $configuredTransport
    Write-Host "Alert body (would be emailed):`n$alertBody"
}
```

### Saving and Running

```powershell
# One-time: save today's state as the baseline
.\Invoke-ServiceMonitor.ps1 -SaveBaseline

# Daily (scheduled task or manual): check for drift
.\Invoke-ServiceMonitor.ps1

# Output when everything is fine:
# [OK] All 5 monitored services match baseline.

# Output when something drifted:
# WARNING: Drift detected: 1 service(s) out of expected state
# Name     Type        Expected  Actual
# ----     ----        --------  ------
# Spooler  StatusDrift Running   Stopped
```

---

## Self-Documenting Scripts: The Minimum Standard

A script that works is useful. A script that documents itself is an asset.

![self-documenting](assets/images/ch-16-self-documenting.png)

```powershell
<#
.SYNOPSIS
    One sentence. What does this script do?

.DESCRIPTION
    A paragraph. Why does it exist, what problem does it solve?

.PARAMETER ParameterName
    What does this parameter control? Required? Default?

.EXAMPLE
    .\Script.ps1 -Param Value
    What does this example do?

.NOTES
    Author:  Sam Chen
    Version: 1.0.0
    Updated: 2026-03-17
    Requires: PowerShell 7.4+, Windows Server 2019+
#>
```

Beyond the help block, apply these three rules to every script you write:

1. **Name things for what they are, not what they are made of.** `$cutoff`
   tells you the intent. `$datetime1` tells you the type. One of these is
   useful at 2 AM.

2. **Log what you do.** `Write-Verbose` for normal operations, `Write-Warning`
   for recoverable problems, `Write-Error` for failures. Users who need detail
   run with `-Verbose`. Users who don't, get clean output.

3. **Leave breadcrumbs.** At the start of every script run, log: who ran it,
   from where, with what parameters. At the end, log: what changed, what was
   skipped, how long it took. Operational logs are your alibi.

```powershell
# Standard script preamble (add to every production script)
$scriptStart = Get-Date
Write-Verbose "[$($MyInvocation.MyCommand.Name)] Started by $([Environment]::UserName) on $([Environment]::MachineName)"
Write-Verbose "[$($MyInvocation.MyCommand.Name)] Parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"

# ... script body ...

$elapsed = [math]::Round((New-TimeSpan $scriptStart (Get-Date)).TotalSeconds, 1)
Write-Verbose "[$($MyInvocation.MyCommand.Name)] Completed in ${elapsed}s"
```

---

## Exercises

### [Ch-16, Ex-1] Simple: Temp File Cleanup

Write a script that finds all files in a given directory whose
`LastWriteTime` is older than 7 days and removes them. Test it by
creating a file, backdating its timestamp to 10 days ago, and verifying
it gets removed while a fresh file in the same directory is left alone.

### [Ch-16, Ex-2] Normal: Backup with Date-Stamped Folder and Retention

Write a backup script that:
- Copies a source directory into a date-stamped subfolder under a backup root
  (folder name format: `yyyy-MM-dd_HHmmss`)
- After copying, prunes date-stamped backup folders whose age, according to
  the script's documented retention timestamp, exceeds a configurable period
  (default: 14 days). The recipe uses `LastWriteTime`; a production backup
  system can instead parse the timestamp in its controlled folder names.

Verify that the backup folder is created and that the files it contains
match the source.

### [Ch-16, Ex-3] Advanced: System Inventory HTML Report

Build a script that collects the following inventory data and produces a
structured `PSCustomObject`:
- Hostname, OS, PowerShell version
- Total running process count
- Total running service count on Windows; use `$null` where `Get-Service` is
  unavailable
- System uptime in hours (rounded to 1 decimal)
- Total working set of all processes in MB

The object must have at least 5 properties and `Processes` must be greater
than 0.

### [Ch-16, Ex-4] Extreme: Service Monitor with Drift Detection

Build a service drift detector. Given a **baseline** list of services with
expected statuses, and a **current snapshot** of the same services, produce
a list of services whose current status differs from the baseline. Verify
that when `ServiceB` is `Running` in the baseline but `Stopped` in the
current state, your drift list contains exactly one entry for `ServiceB`
with the correct expected and actual values.

---

## Key Takeaways

- State-changing advanced functions and scripts should implement
  `SupportsShouldProcess` and gate **every** mutation with `ShouldProcess`.
- `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` are
  strong automation defaults, but native command exit handling and intentional
  recovery paths require an explicit, tested policy.
- Date-stamp your backup folders (`yyyy-MM-dd_HHmmss`). Prune with
  a timestamp whose semantics you control. Retention policy is not optional.
- `ConvertTo-Html -Fragment` turns any object collection into an HTML table.
  Combine fragments for full reports with zero HTML knowledge required.
- On Windows, `Get-Service` + `ConvertTo-Json` gives you a baseline. Compare against it
  with `Where-Object` to detect drift. This pattern scales to disks, firewall
  rules, installed software, registry keys -- anything you can enumerate.
- Comment-based help is not documentation overhead. It is the minimum viable
  act of respect for whoever runs your script at 2 AM. Which might be you.

---

*Next up: [Chapter 17 -- DevOps and CI/CD](17-devops-and-cicd.md), where we put
automation recipes into repeatable delivery pipelines.*
