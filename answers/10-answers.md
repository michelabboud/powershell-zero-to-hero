# Chapter 10 -- Answers

---

## Ch-10, Ex-1 (Simple)

**Task:** Write a basic `try`/`catch` that handles a divide-by-zero error.
Assign the result of the expression to `$result` and print it -- the value should be `'caught'`.

### Solution

```powershell
$result = try {
    1 / 0
} catch {
    'caught'
}

$result    # caught
```

### Expected Output

```
caught
```

### What to notice

`try`/`catch` is an **expression** in PowerShell, not just a statement. You can assign the
return value of the entire `try`/`catch` construct to a variable. The value of the block is
the last expression evaluated inside whichever branch ran -- the `try` body on success, the
`catch` body on error.

Dividing by zero in PowerShell throws a `System.DivideByZeroException`, which is a
terminating error. That's why `catch` fires here without needing `-ErrorAction Stop`. Integer
division by zero always terminates; it's the cmdlet-style errors (like `Get-Item` failing on a
missing path) that default to non-terminating and require the explicit promotion.

---

## Ch-10, Ex-2 (Normal)

**Task:** Handle specific exception types differently. Write a function
`Test-SpecificCatch` that accepts a `[string]$Path`, tries `Get-Content $Path -ErrorAction Stop`,
catches `[System.Management.Automation.ItemNotFoundException]` to return `'NotFound'`,
and catches everything else to return `'OtherError'`.

### Solution

```powershell
function Test-SpecificCatch {
    param([string]$Path)
    try {
        Get-Content $Path -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        'NotFound'
    }
    catch {
        'OtherError'
    }
}

# Test with a non-existent path
Test-SpecificCatch -Path '/nonexistent/path/file.txt'   # NotFound

# Test with an access-denied scenario (example -- adjust path to a restricted file on your system)
# Test-SpecificCatch -Path 'C:\Windows\System32\config\SAM'   # OtherError (UnauthorizedAccess)
```

### Expected Output

```
NotFound
```

### What to notice

Two things make this work correctly:

1. **`-ErrorAction Stop` is mandatory.** `Get-Content` on a missing file generates a
   non-terminating error by default. Without `-ErrorAction Stop`, the `catch` blocks
   would never run and the function would return nothing -- silently. This is the most
   common `try`/`catch` bug in beginner PowerShell scripts.

2. **Exception type matching.** PowerShell walks `catch` blocks in order and runs the
   first one whose bracketed type matches the exception. To discover the type name of
   any exception, run the failing code, then check `$Error[0].Exception.GetType().FullName`
   in the console. Copy that string into your `catch [...]` clause. It works every time.

The unqualified `catch` at the end is the catch-all safety net. Always put it last -- if it
were first, the specific `ItemNotFoundException` handler would never be reached.

---

## Ch-10, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Build a function `Get-SafeContent` with `[CmdletBinding()]` that:
- Takes a mandatory `[string]$Path` parameter
- Uses `Write-Error` (not `throw`) to signal a missing file
- Returns `$null` on error
- Returns `Get-Content $Path` on success
- Correctly supports `-ErrorAction SilentlyContinue` and `-ErrorVariable` from the caller

### Solution

```powershell
function Get-SafeContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return $null
    }

    Get-Content $Path
}

# --- Usage ---

# Default behavior: error is displayed
Get-SafeContent -Path '/nonexistent/file.txt'

# Suppress the error
$content = Get-SafeContent -Path '/nonexistent/file.txt' -ErrorAction SilentlyContinue
Write-Host "Result: $content"    # Result:

# Capture the error into a variable
$content = Get-SafeContent -Path '/nonexistent/file.txt' `
    -ErrorAction SilentlyContinue `
    -ErrorVariable ev

Write-Host "Errors caught: $($ev.Count)"
Write-Host "Error message: $($ev[0].Exception.Message)"
```

### Expected Output

```
Get-SafeContent: File not found: /nonexistent/file.txt
Result:
Errors caught: 1
Error message: File not found: /nonexistent/file.txt
```

### What to notice

Three design decisions in this function are worth studying:

1. **`[CmdletBinding()]` enables `-ErrorAction` and `-ErrorVariable`.** Without this
   attribute, your function does not inherit the common parameters. A plain `param()`
   block with no `[CmdletBinding()]` cannot accept `-ErrorAction SilentlyContinue` from
   the caller. This is the most important attribute to add to any function you want to
   behave like a real cmdlet.

2. **`Write-Error` vs `throw`.** Using `Write-Error` here is the correct choice because
   it respects the caller's `-ErrorAction` preference. If the caller passes
   `-ErrorAction SilentlyContinue`, the error is suppressed. If they pass `-ErrorAction Stop`,
   it becomes terminating. The function doesn't make that decision -- the caller does.
   Using `throw` would override the caller's preference, which breaks the cmdlet contract.

3. **`return $null` after `Write-Error`.** This is subtle: `Write-Error` does not exit
   the function. Execution continues on the next line. You must explicitly `return` to
   prevent the function from running the `Get-Content` call on a path that doesn't exist.
   Forgetting this `return` is a common bug in functions that use `Write-Error`.

---

## Ch-10, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Build a structured error logger that accepts an `[ErrorRecord]` and a log path,
appends a JSON entry containing `Timestamp`, `Message`, `Category`, `Script`, and `Line`,
then verify the output is valid JSON with the correct fields.

### Solution

```powershell
function Write-ErrorLog {
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory)]
        [string]$LogPath
    )

    $entry = [ordered]@{
        Timestamp = (Get-Date -Format 'o')
        Message   = $ErrorRecord.Exception.Message
        Category  = $ErrorRecord.CategoryInfo.Category.ToString()
        Script    = $ErrorRecord.InvocationInfo.ScriptName
        Line      = $ErrorRecord.InvocationInfo.ScriptLineNumber
    }

    $entry | ConvertTo-Json -Compress | Add-Content -Path $LogPath -Encoding UTF8
}

# --- Usage ---

$logPath = Join-Path $env:TEMP "ps-error-log-$(Get-Random).json"

try {
    # Trigger a real terminating error
    1 / 0
}
catch {
    Write-ErrorLog -ErrorRecord $_ -LogPath $logPath
}

# Read and inspect the log
$logged = Get-Content $logPath -Raw | ConvertFrom-Json

Write-Host "Timestamp: $($logged.Timestamp)"
Write-Host "Message:   $($logged.Message)"
Write-Host "Category:  $($logged.Category)"

# Cleanup
Remove-Item $logPath -ErrorAction SilentlyContinue
```

### Expected Output

```
Timestamp: 2026-03-17T14:32:08.4217190+00:00
Message:   Attempted to divide by zero.
Category:  NotSpecified
```

### What to notice

Four details that matter in production logging:

1. **ISO 8601 timestamps with `'o'` format.** The `'o'` (roundtrip) format produces
   `2026-03-17T14:32:08.421+00:00` -- a string that any JSON parser, log aggregator, or
   database can parse unambiguously. Avoid locale-sensitive formats like `MM/dd/yyyy` in
   log entries. They look fine until someone reads them on a machine with a different
   locale and everything breaks.

2. **`[ordered]@{}`** instead of `@{}`.** A regular hashtable does not guarantee property
   order. `[ordered]` preserves insertion order, so the JSON output is consistent and
   readable. This matters when humans are grepping log files or when downstream tools
   rely on field position.

3. **`-Compress` on `ConvertTo-Json`.** Without it, each log entry spans multiple lines
   with indentation. With it, each entry is a single line. One JSON object per line is
   the standard for log files -- it makes `Select-String`, `jq`, and log shippers like
   Filebeat parse the file correctly without needing a multi-line aggregation rule.

4. **`Add-Content` vs `Set-Content`.** `Set-Content` overwrites the file on every call.
   `Add-Content` appends. For a log file that accumulates entries over time, you always
   want `Add-Content`. The `-Encoding UTF8` ensures the appended bytes don't corrupt
   existing entries if the file was started on a different system.

This pattern -- `ErrorRecord` typed parameter, `[ordered]` hashtable, ISO timestamp,
`-Compress`, `Add-Content` -- is the skeleton of every production PowerShell error log.
The only thing a real implementation adds is file rotation and a max-size check.
