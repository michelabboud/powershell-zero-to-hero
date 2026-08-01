# Chapter 09 -- Answers

---

## Ch-09, Ex-1 (Simple)

**Task:** Create a text file in your temp directory. Write content to it,
read it back, verify the content matches, then clean up.

### Solution

```powershell
# Build a safe temp path
$file = Join-Path ([System.IO.Path]::GetTempPath()) "ps-ch09-ex1.txt"

# Write content
'Hello PowerShell' | Set-Content $file

# Verify the file exists
Test-Path $file   # Should be True

# Read it back
$content = Get-Content $file
$content          # Hello PowerShell

# Verify content matches
$content | Should -Be 'Hello PowerShell'   # Pester assertion
# Or without Pester:
if ($content -ne 'Hello PowerShell') { throw "Content mismatch!" }

# Clean up
Remove-Item $file
```

### Expected Output

```
True
Hello PowerShell
```

### What to notice

`Set-Content` with a pipeline input string writes that string as one line.
When `Get-Content` reads a one-line file, assignment produces a scalar string;
multiple lines produce an array. Wrap the read in `@(...)` when later code must
always use array indexing. `Test-Path` returns `$true`/`$false`, making it
naturally usable in `if` conditions without any comparison operator.

---

## Ch-09, Ex-2 (Normal)

**Task:** Import a CSV of servers (Name, CPU, Memory), add a calculated
`MemoryGB` column (Memory in MB / 1024, rounded to 1 decimal place), export
to a new file with `-NoTypeInformation`.

### Solution

```powershell
# Sample input file (create it if you don't have one)
@"
Name,CPU,Memory
web01,45,2048
db01,80,8192
app01,30,4096
"@ | Set-Content (Join-Path ([System.IO.Path]::GetTempPath()) 'servers.csv')

$csvIn  = Join-Path ([System.IO.Path]::GetTempPath()) 'servers.csv'
$csvOut = Join-Path ([System.IO.Path]::GetTempPath()) 'servers-report.csv'

Import-Csv $csvIn |
    Select-Object Name, CPU, Memory, @{
        Name       = 'MemoryGB'
        Expression = { [math]::Round([int]$_.Memory / 1024, 1) }
    } |
    Export-Csv $csvOut -NoTypeInformation

# Verify
$result = Import-Csv $csvOut
$result | Format-Table
```

### Expected Output

```
Name  CPU Memory MemoryGB
----  --- ------ --------
web01 45  2048   2
db01  80  8192   8
app01 30  4096   4
```

### What to notice

Three things are worth studying here:

1. **Calculated property syntax** -- `@{Name='MemoryGB'; Expression={...}}`
   is a hashtable that `Select-Object` interprets as "add a virtual column."
   The `Expression` scriptblock runs once per object with `$_` bound to the
   current pipeline item. This pattern appears everywhere in real scripts.

2. **Type casting** -- CSV imports all values as strings. `[int]$_.Memory`
   documents the expected type and makes malformed input fail clearly before
   the calculation. PowerShell can coerce a numeric-looking string during
   arithmetic, but relying on implicit conversion hides data-quality errors.

3. **-NoTypeInformation** -- PowerShell 6 and later omit the `#TYPE` line by
   default. Keeping this switch is harmless and makes the intent explicit when
   the example is copied to Windows PowerShell 5.1. Use
   `-IncludeTypeInformation` only when a consumer explicitly requires it.

---

## Ch-09, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Recursively search a directory for files whose `LastWriteTime` is
older than 30 days. Generate a CSV deletion report with `FullName`,
`LastWriteTime`, and `SizeMB`. Do not delete anything.

### Solution

```powershell
$targetDir = [System.IO.Path]::GetTempPath()   # or any directory you want to audit
$cutoff    = (Get-Date).AddDays(-30)
$report    = Join-Path ([System.IO.Path]::GetTempPath()) "stale-files-$(Get-Date -Format yyyyMMdd-HHmmss).csv"

$stale = Get-ChildItem -Path $targetDir -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff }

if ($stale.Count -eq 0) {
    Write-Host "No files older than 30 days found in $targetDir"
} else {
    $stale |
        Select-Object FullName, LastWriteTime,
            @{
                Name       = 'SizeMB'
                Expression = { [math]::Round($_.Length / 1MB, 2) }
            } |
        Export-Csv $report -NoTypeInformation

    Write-Host "Report: $report"
    Write-Host "Files found: $($stale.Count)"
    Write-Host "Total size:  $([math]::Round(($stale | Measure-Object Length -Sum).Sum / 1MB, 1)) MB"
}
```

To test with synthetic data (as the Pester test does):

```powershell
# Create a file and backdate its LastWriteTime
$old = New-Item (Join-Path ([System.IO.Path]::GetTempPath()) 'old-test.log') -ItemType File -Force
Set-Content $old 'stale content'
(Get-Item $old).LastWriteTime = (Get-Date).AddDays(-60)

# Verify it shows up in the stale search
$found = Get-ChildItem ([System.IO.Path]::GetTempPath()) -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
$found.Name   # old-test.log
```

### Expected Output

```
Report: C:\Users\sam\AppData\Local\Temp\stale-files-20260317-143022.csv
Files found: 14
Total size:  237.4 MB
```

### What to notice

1. **LastWriteTime is a real DateTime object** -- you compare it with
   `-lt` against another `DateTime` (the result of `(Get-Date).AddDays(-30)`).
   No string parsing, no epoch math, no `strftime`. This is the object
   pipeline paying dividends.

2. **Backdating LastWriteTime** -- `(Get-Item $path).LastWriteTime = $date`
   works because `LastWriteTime` is a settable property on `FileInfo`.
   This is only useful in tests and tooling; never do this to production
   files unless you're trying to confuse your future self.

3. **Generate before you delete** -- the report-first pattern is a
   professional habit. Even if you're certain the files are safe to remove,
   the CSV gives you an undo list: you know what was there, when it was
   last touched, and how big it was. A two-second export has prevented many
   a midnight-pager-alert.

4. **-ErrorAction SilentlyContinue scope** -- it applies only to
   `Get-ChildItem`, not to the pipeline stages after it. If `Export-Csv`
   fails (disk full, permissions), you'll still see that error. That's
   correct behavior.

---

## Ch-09, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Build a JSON config manager that reads a file, validates required
keys (`AppName`, `Version`, `Settings.Port`, `Settings.Debug`), allows
updating values, and writes back with proper depth.

### Solution

```powershell
function Read-AppConfig {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Config file not found: $Path"
    }

    $json = Get-Content $Path -Raw
    try {
        $config = $json | ConvertFrom-Json
    } catch {
        throw "Failed to parse JSON: $_"
    }

    # Validate required top-level keys
    foreach ($key in @('AppName', 'Version', 'Settings')) {
        if ($null -eq $config.$key) {
            throw "Missing required config key: '$key'"
        }
    }

    # Validate nested keys under Settings
    foreach ($key in @('Port', 'Debug')) {
        if ($null -eq $config.Settings.$key) {
            throw "Missing required config key: 'Settings.$key'"
        }
    }

    return $config
}

function Write-AppConfig {
    param(
        [Parameter(Mandatory)][object]$Config,
        [Parameter(Mandatory)][string]$Path
    )

    $Config | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
    Write-Verbose "Config saved to $Path"
}

# --- Example usage ---

$configPath = Join-Path ([System.IO.Path]::GetTempPath()) 'appconfig.json'

# Create an initial config
@{
    AppName  = 'MyApp'
    Version  = '1.0.0'
    Settings = @{
        Port  = 8080
        Debug = $false
    }
} | ConvertTo-Json -Depth 5 | Set-Content $configPath

# Read and validate
$config = Read-AppConfig -Path $configPath
Write-Host "Loaded: $($config.AppName) v$($config.Version)"
Write-Host "Port: $($config.Settings.Port)"

# Modify a value
$config.Settings.Port = 9090

# Write back
Write-AppConfig -Config $config -Path $configPath

# Verify round-trip
$reloaded = Read-AppConfig -Path $configPath
$reloaded.Settings.Port   # 9090
```

### Testing the validation

```powershell
# This should throw because 'AppName' is missing
$bad = @{
    Version  = '1.0.0'
    Settings = @{ Port = 8080; Debug = $false }
} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path ([System.IO.Path]::GetTempPath()) 'bad.json')

try {
    Read-AppConfig -Path (Join-Path ([System.IO.Path]::GetTempPath()) 'bad.json')
} catch {
    Write-Host "Caught expected error: $_"
    # Output: Caught expected error: Missing required config key: 'AppName'
}
```

### Expected Output

```
Loaded: MyApp v1.0.0
Port: 8080
9090
```

### What to notice

1. **-Depth 10 on ConvertTo-Json** -- the default depth is 2. Values deeper
   than the selected depth are truncated and current PowerShell versions emit
   a warning. Choose a depth from the configuration schema instead of blindly
   using an arbitrarily large value.

2. **ConvertFrom-Json returns PSCustomObject by default** -- this is the source
   of the `$config.$key` property access syntax. When a hashtable is more
   appropriate, PowerShell 7 provides `ConvertFrom-Json -AsHashtable`, which
   recursively produces ordered hashtables.

3. **Null-check pattern for nested keys** -- `$config.Settings.$key`
   navigates the object graph with dot notation. If `Settings` itself is
   null, this would throw a NullReferenceException instead of your
   meaningful error. The solution checks `Settings` exists first, then
   checks nested keys. The order of validation matters.

4. **Set-Content -Encoding UTF8** -- JSON files should be UTF-8. PowerShell 7
   already defaults to UTF-8 without a BOM, but the explicit parameter records
   the file contract and protects copied examples from Windows PowerShell 5.1
   defaults.

5. **This is a foundation, not production code** -- a real config manager
   would add file locking for concurrent writes, schema versioning,
   migration support for old config formats, and a default-value merge
   for missing optional keys. The pattern here gives you the skeleton;
   your specific application provides the flesh.
