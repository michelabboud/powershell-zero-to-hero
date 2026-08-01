# Chapter 09: Working with Files

Sam is on file 347. This chapter is for Sam.

![chapter-opener](assets/images/ch-09-opener.png)

---

## The File Operations You'll Use Every Day

PowerShell treats the filesystem like any other provider: consistent verbs,
objects all the way down, and enough cmdlets to make any sysadmin's shell
script jealous. Once you stop reaching for Windows Explorer for bulk
operations, you don't go back.

Here's the mental map you need:

![file-decision-tree](assets/images/ch-09-decision-tree.png)

---

## Reading and Writing Files

### Get-Content

`Get-Content` writes one string object per line to the pipeline. When you assign
the result, PowerShell gives you a scalar string for one line and an array for
multiple lines; wrap the command in `@(...)` when your code always needs an
array.

```powershell
# Read the whole file
Get-Content ./server.log

# Last 20 lines -- the real tail
Get-Content ./server.log -Tail 20

# Follow in real time (tail -f)
Get-Content ./server.log -Wait -Tail 5

# Read as a single string (the -Raw switch)
$text = Get-Content ./config.json -Raw

# Specify encoding explicitly when a file contract requires it
Get-Content ./data.txt -Encoding UTF8
```

The `-Raw` switch is your best friend when feeding file content to
`ConvertFrom-Json`, `[xml]`, or any cmdlet that expects a single string
rather than an array of lines.

### Set-Content vs Out-File

Two cmdlets write text to a file. They are not the same, and mixing them up
will ruin your Tuesday.

| | `Set-Content` | `Out-File` |
|---|---|---|
| Input type | Strings / objects via `.ToString()` | Anything (uses formatter) |
| Default encoding in PowerShell 7 | UTF-8 (no BOM) | UTF-8 (no BOM) |
| Use for | Data files, scripts, configs | Formatted text output |
| Overwrites? | Yes | Yes (default) |

```powershell
# Write a string to a file
Set-Content -Path ./output.txt -Value "Hello, PowerShell"

# Append a line without overwriting
Add-Content -Path ./output.txt -Value "Line two"

# Redirect formatted output (table as text)
Get-Process | Format-Table | Out-File ./process-report.txt

# Append with Out-File
Get-Process | Out-File ./process-report.txt -Append
```

Rule of thumb: use `Set-Content` when writing data you want to process again
later (CSV, JSON, config files). Use `Out-File` when writing output you want
a human to read once and never pipe through anything again.

### Add-Content

`Add-Content` appends to an existing file without reading it into memory
first. This is useful for log files and incremental writes where loading the
whole file would be wasteful.

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path ./app.log -Value "[$timestamp] Deployment complete"
```

---

## Navigating and Listing Files

### Get-ChildItem: The Swiss Army Knife

`Get-ChildItem` (alias: `ls`, `dir`, `gci`) lists directory contents and does
a lot more than that. Filters, recursion, hidden files, and attribute-based
selection are all built in.

```powershell
# List current directory
Get-ChildItem

# Include hidden and system files
Get-ChildItem -Force

# Filter by extension
Get-ChildItem -Path C:\Logs -Filter *.log

# Recursive -- descend into all subdirectories
Get-ChildItem -Path C:\Logs -Filter *.log -Recurse -ErrorAction SilentlyContinue

# Directories only
Get-ChildItem -Directory

# Files only
Get-ChildItem -File

# Files modified in the last 7 days
Get-ChildItem -File | Where-Object LastWriteTime -gt (Get-Date).AddDays(-7)
```

The `-ErrorAction SilentlyContinue` on recursive searches is not laziness --
it's pragmatism. System directories and access-protected paths will throw
permission errors that drown your output. Silence them unless you're auditing
access failures specifically.

```powershell
# Find large log files (> 100 MB)
Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object Length -gt 100MB |
    Sort-Object Length -Descending |
    Select-Object FullName, @{N='SizeMB'; E={[math]::Round($_.Length/1MB, 1)}}
```

Note: `100MB` is a PowerShell numeric literal, not a string. The runtime
converts it to bytes automatically. Same applies to `1KB`, `1GB`, `1TB`.

---

## Creating, Removing, Moving, Copying

### New-Item

Creates files, directories, symbolic links -- anything the filesystem provider
supports.

```powershell
# Create a directory
New-Item -Path ./logs -ItemType Directory

# Create a file (empty)
New-Item -Path ./logs/app.log -ItemType File

# Create with content
New-Item -Path ./config.txt -ItemType File -Value "debug=false"

# -Force creates parent directories if they don't exist and
# doesn't throw if the item already exists
New-Item -Path ./deep/nested/path -ItemType Directory -Force | Out-Null
```

Piping to `| Out-Null` suppresses the verbose object output that `New-Item`
returns. It doesn't suppress errors, just the success echo.

### Remove-Item

```powershell
# Delete a file
Remove-Item ./old-report.csv

# Delete a directory and everything in it
Remove-Item ./old-logs -Recurse -Force

# Delete all .tmp files in a directory
Get-ChildItem ./temp -Filter *.tmp | Remove-Item

# WhatIf: dry run -- shows what would be deleted without deleting
Remove-Item ./old-logs -Recurse -WhatIf
```

Always use `-WhatIf` before any `Remove-Item -Recurse` in production.
It takes two extra seconds and costs nothing. Your future self will thank you.

### Copy-Item and Move-Item

```powershell
# Copy a file
Copy-Item ./report.csv ./backup/report-backup.csv

# Copy a directory recursively
Copy-Item ./configs ./configs-backup -Recurse

# Move (rename across directories)
Move-Item ./report.csv ./archive/2026-report.csv

# Move all .log files to an archive folder
Get-ChildItem ./logs -Filter *.log |
    Move-Item -Destination ./logs/archive/
```

### Rename-Item

This is the cmdlet Sam needed on file 347.

```powershell
# Rename a single file
Rename-Item -Path ./report.csv -NewName report-final.csv

# Bulk rename: add a date prefix to every .log file
Get-ChildItem ./logs -Filter *.log |
    Rename-Item -NewName { "2026-01-$($_.Name)" }

# Replace a string in all filenames
Get-ChildItem ./reports -Filter *draft* |
    Rename-Item -NewName { $_.Name -replace 'draft', 'final' }
```

The scriptblock syntax in `-NewName { ... }` is one of PowerShell's most
useful patterns. `$_` refers to the current pipeline object, so you can
derive the new name from the old one without a loop.

---

## Path Operations

Working with paths as strings is fragile -- backslashes on Windows, forward
slashes on Linux, different roots everywhere. Use the path cmdlets and let
PowerShell handle the platform details.

### Join-Path

```powershell
# Safe cross-platform path construction
$logFile = Join-Path ([System.IO.Path]::GetTempPath()) "myapp" "run.log"
# Result: C:\Users\sam\AppData\Local\Temp\myapp\run.log

# Useful in scripts that need to run on both Windows and Linux
$config = Join-Path $PSScriptRoot "config" "settings.json"
```

### Split-Path

```powershell
# Get the directory part
Split-Path "C:\Logs\app\error.log"
# Result: C:\Logs\app

# Get the filename
Split-Path "C:\Logs\app\error.log" -Leaf
# Result: error.log

# Get the drive root
Split-Path "C:\Logs\app\error.log" -Qualifier
# Result: C:
```

### Test-Path

```powershell
# Does this path exist?
if (Test-Path ./config.json) {
    $config = Get-Content ./config.json -Raw | ConvertFrom-Json
} else {
    Write-Warning "Config file not found -- using defaults"
}

# Check for a specific type
Test-Path ./output -PathType Container   # Directory only
Test-Path ./report.csv -PathType Leaf    # File only
```

### Resolve-Path

```powershell
# Convert relative path to absolute
Resolve-Path ../configs
# Result: /home/rina/projects/configs (on Linux) or C:\Users\rina\... (Windows)

# Useful in scripts to anchor yourself
$scriptDir = Resolve-Path (Split-Path $MyInvocation.MyCommand.Path)
```

---

## Structured Data: CSV, JSON, and XML

### CSV

PowerShell's CSV support is excellent. Import gives you objects. Export gives
you CSV. The pipeline does the rest.

```powershell
# Import CSV -- each row becomes a PSCustomObject
$servers = Import-Csv ./servers.csv
$servers[0].Name       # Access a column by header name
$servers[0].CPU        # Type is always [string] -- cast if needed

# Add a calculated column
$report = $servers | Select-Object Name, CPU, Memory,
    @{
        Name       = 'MemoryGB'
        Expression = { [math]::Round([int]$_.Memory / 1024, 1) }
    }

# Export -- -NoTypeInformation suppresses the ugly #TYPE header line
$report | Export-Csv ./server-report.csv -NoTypeInformation

# Append rows to an existing CSV
$newRow | Export-Csv ./server-report.csv -NoTypeInformation -Append
```

The `@{Name='...'; Expression={...}}` pattern is a **calculated property**.
You'll use it constantly. Read it as: "create a new column called X whose
value is computed from the current object."

### JSON

```powershell
# Read JSON config
$config = Get-Content ./config.json -Raw | ConvertFrom-Json

# Access properties
$config.AppName
$config.Settings.Port

# Modify and write back
$config.Settings.Port = 9090
$config | ConvertTo-Json -Depth 10 | Set-Content ./config.json

# -Depth matters: default is 2. Deeper values are truncated and
# ConvertTo-Json emits a warning. Choose a depth that matches your schema.
```

```powershell
# Convert a hashtable to JSON (useful for API calls)
$payload = @{
    name    = "web01"
    tags    = @("production", "web")
    enabled = $true
}
$payload | ConvertTo-Json
```

### XML

```powershell
# Load an XML file -- the [xml] cast is the simplest way
[xml]$doc = Get-Content ./config.xml

# Navigate with dot-notation (the XmlDocument accelerator makes this natural)
$doc.configuration.appSettings.add

# Modify a node value
$node = $doc.SelectSingleNode("//add[@key='port']")
$node.value = "9090"

# Save back to file
$doc.Save("./config.xml")
```

XML in PowerShell is one of those things that's either delightful or maddening
depending on the schema you're dealing with. For anything more complex than
reading config nodes, reach for `Select-Xml` which gives you XPath support
without the `.Save()` foot guns.

---

## File Encoding

Encoding is the invisible source of half of all "why does this look broken"
file bugs. PowerShell 7 defaults to UTF-8 without BOM everywhere (a massive
improvement over PowerShell 5's UTF-16 defaults). Still worth knowing:

```powershell
# Specify encoding explicitly when writing
Set-Content ./output.txt -Value $data -Encoding UTF8

# Read a file that's actually Latin-1 (legacy systems)
Get-Content ./legacy-export.csv -Encoding Latin1

# UTF-8 with BOM (required by some older tools)
Set-Content ./output.txt -Value $data -Encoding UTF8BOM

# Check what encoding a file uses (heuristic -- not foolproof)
$bytes = [System.IO.File]::ReadAllBytes('./mystery.txt')
$bytes[0..3] | ForEach-Object { '{0:X2}' -f $_ }
# EF BB BF = UTF-8 BOM
# FF FE    = UTF-16 LE BOM
```

When sharing files between Windows and Linux PowerShell: always specify
`-Encoding UTF8`. The default is the same on both platforms in PS7, but
explicit beats implicit in production scripts.

---

## Practical Pattern: The Deletion Report

> <!-- tier: advanced -->
> Before deleting anything in bulk, generate a report. This pattern -- find,
> report, confirm, delete -- will save your job at least once in your career.

```powershell
$cutoff   = (Get-Date).AddDays(-30)
$target   = "C:\Logs\old"
$report   = Join-Path ([System.IO.Path]::GetTempPath()) "deletion-report-$(Get-Date -Format yyyyMMdd).csv"

# Find candidates and write report first
Get-ChildItem $target -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object LastWriteTime -lt $cutoff |
    Select-Object FullName, LastWriteTime,
        @{N='SizeMB'; E={[math]::Round($_.Length/1MB, 2)}} |
    Export-Csv $report -NoTypeInformation

Write-Host "Report written to $report"
Write-Host "Found $((Import-Csv $report).Count) files for deletion"
Write-Host "Review the CSV, then run with -Delete to proceed"
```

---

## Exercises

### [Ch-09, Ex-1] Simple: Create, Write, Read, Verify

Create a text file in your temp directory. Write a line of content to it.
Read it back and verify the content matches what you wrote. Clean up after.

### [Ch-09, Ex-2] Normal: CSV Import, Transform, Export

Given a CSV of server names with CPU and Memory columns, import it, add a
calculated `MemoryGB` column (Memory in MB divided by 1024, rounded to one
decimal), and export the result to a new file.

### [Ch-09, Ex-3] Advanced: Stale File Report

> <!-- tier: advanced -->

Recursively search a directory for files older than 30 days. Generate a CSV
deletion report including `FullName`, `LastWriteTime`, and `SizeMB`.
Do not delete anything -- report only.

### [Ch-09, Ex-4] Extreme: JSON Config Manager

> <!-- tier: extreme -->

Build a config file manager that reads a JSON file, validates that required
keys are present (`AppName`, `Version`, `Settings.Port`, `Settings.Debug`),
allows updating values, and writes the result back with proper depth. Throw a
meaningful error if a required key is missing.

---

## Key Takeaways

- `Get-Content` returns an array of lines; add `-Raw` when you need a single string.
- `Set-Content` is for data; `Out-File` is for human-readable output. Default encodings differ.
- `Add-Content` appends without reading the whole file into memory.
- `Get-ChildItem -Recurse -Filter *.ext` is how you find files at scale. Add `-ErrorAction SilentlyContinue` in production.
- `Join-Path`, `Split-Path`, and `Test-Path` make path handling portable and safe.
- `Import-Csv` / `Export-Csv` turn tabular data into objects and back. Always use `-NoTypeInformation`.
- `ConvertFrom-Json` / `ConvertTo-Json` work the same way. Use `-Depth 5+` on nested objects.
- `-WhatIf` on destructive operations is not optional in production. Use it.

---

*Next up: [Chapter 10 -- Error Handling](10-error-handling.md), where we make
file-processing failures predictable and recoverable.*
