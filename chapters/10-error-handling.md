# Chapter 10: Error Handling

> *"It's non-terminating. That means it's not a real error, right?"*
> *— Sam, five minutes before the server goes down*

![chapter-opener](assets/images/ch-10-opener.png)

---

## What You'll Learn

- The difference between terminating and non-terminating errors
- How `$ErrorActionPreference` and `-ErrorAction` control error behavior
- How to use `try`/`catch`/`finally` blocks
- How to inspect errors with `$_`, `$Error`, and `ErrorRecord`
- How to write functions that support `-ErrorAction` and `-ErrorVariable`
- How to signal errors with `Write-Error` vs `throw`
- What `trap` is and why you probably shouldn't use it

---

## 1. Two Kinds of Errors

PowerShell has a split personality when it comes to errors. Understanding this is the single most important concept in this chapter.

### Non-Terminating Errors

A **non-terminating error** is PowerShell's way of saying: "Something went wrong for this item, but I'm going to keep going." The cmdlet reports the problem, the red text appears, and execution continues to the next item in the pipeline.

```powershell
# Non-terminating: errors on individual items, but the pipeline keeps running
Get-Item 'C:\DoesNotExist', 'C:\Windows' -ErrorAction Continue
```

```
Get-Item: Cannot find path 'C:\DoesNotExist' because it does not exist.

    Directory: C:\

Mode                 LastWriteTime         Length Name
----                 -------------         ------
d-r--          3/15/2026  10:22 AM                Windows
```

The first path failed. The second succeeded. The pipeline continued. Sam would call this "fine." Max would not.

### Terminating Errors

A **terminating error** stops the current scope immediately. The command that generated it stops, and if it's inside a function, that function stops too. These are the errors that `try`/`catch` can intercept.

```powershell
# Terminating: the whole thing stops
try {
    [int]'not a number'   # throws a terminating parse error
} catch {
    "Caught it: $_"
}
```

```
Caught it: Cannot convert value "not a number" to type "System.Int32".
```

### Promoting Non-Terminating to Terminating

Here's the trick that makes `try`/`catch` useful for cmdlets: `-ErrorAction Stop` promotes a non-terminating error into a terminating one.

```powershell
try {
    Get-Item 'C:\DoesNotExist' -ErrorAction Stop
} catch {
    "Caught it: $_"
}
```

Without `-ErrorAction Stop`, the `catch` block would never run. This is the most common mistake beginners make with `try`/`catch` and PowerShell cmdlets.

---

## 2. Controlling Error Behavior

![error-preference](assets/images/ch-10-error-preference.png)

### `$ErrorActionPreference`

This global variable sets the default behavior for all error-generating cmdlets in the current session.

| Value | Behavior |
|-------|----------|
| `Continue` | Report the error and keep running. **Default.** |
| `Stop` | Treat all non-terminating errors as terminating. |
| `SilentlyContinue` | Suppress the error and keep running. No red text. |
| `Inquire` | Prompt the user for every error. Useful for interactive scripts. |
| `Ignore` | Suppress the error and don't record it in `$Error`. |

```powershell
# Set for the entire session (or script scope)
$ErrorActionPreference = 'Stop'

# Now every cmdlet error terminates
Get-Item 'C:\DoesNotExist'  # throws; no -ErrorAction needed
```

> **Rule of thumb for scripts:** Set `$ErrorActionPreference = 'Stop'` at the top of production scripts. It turns subtle silent failures into loud, catchable errors. Rina came from Python, where exceptions are the default. In PowerShell, you have to opt in. One line at the top is all it takes.

### `-ErrorAction` (Per-Cmdlet Override)

`-ErrorAction` (alias: `-EA`) overrides `$ErrorActionPreference` for a single cmdlet call.

```powershell
$ErrorActionPreference = 'Stop'

# This one cmdlet should be allowed to fail silently
$result = Get-Item 'C:\MightNotExist' -ErrorAction SilentlyContinue

if ($null -eq $result) {
    Write-Host "File not found, using defaults."
}
```

This pattern -- script-wide `Stop` with selective `SilentlyContinue` -- is the professional approach. You get loud failures by default and explicit opt-out for the cases you've consciously decided to ignore.

---

## 3. `try` / `catch` / `finally`

The classic structure. If you've written Python or C#, this is familiar. The PowerShell flavor has a few twists.

```powershell
try {
    # Code that might fail
    $value = [int]'abc'
}
catch {
    # Runs if a terminating error occurs in the try block
    Write-Host "Something went wrong: $_"
}
finally {
    # Runs no matter what -- error or no error
    Write-Host "Cleanup runs here."
}
```

```
Something went wrong: Cannot convert value "abc" to type "System.Int32".
Cleanup runs here.
```

### The `$_` Variable in `catch`

Inside a `catch` block, `$_` is automatically bound to the `ErrorRecord` object -- the full structured description of what went wrong. Calling `"$_"` converts it to a string (the error message). But you have access to the whole object.

```powershell
try {
    Get-Item 'C:\NoSuchFile' -ErrorAction Stop
}
catch {
    Write-Host "Message:   $($_.Exception.Message)"
    Write-Host "Category:  $($_.CategoryInfo.Category)"
    Write-Host "Script:    $($_.InvocationInfo.ScriptName)"
    Write-Host "Line:      $($_.InvocationInfo.ScriptLineNumber)"
}
```

```
Message:   Cannot find path 'C:\NoSuchFile' because it does not exist.
Category:  ObjectNotFound
Script:
Line:      2
```

### Catching Specific Exception Types

You can have multiple `catch` blocks, each targeting a different .NET exception type. PowerShell walks them in order and runs the first match.

```powershell
try {
    Get-Content 'C:\Secret\File.txt' -ErrorAction Stop
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "File not found. Check the path."
}
catch [System.UnauthorizedAccessException] {
    Write-Host "Access denied. Try running as Administrator."
}
catch {
    Write-Host "Unexpected error: $_"
}
```

The unqualified `catch` at the end is the catch-all. Always put it last.

> How do you know what exception type was thrown? Check `$_.Exception.GetType().FullName` in the catch block. That's your answer every time.

```powershell
try {
    Get-Content 'C:\NoSuchFile' -ErrorAction Stop
}
catch {
    $_.Exception.GetType().FullName
    # System.Management.Automation.ItemNotFoundException
}
```

### `finally`: The Cleanup Guarantee

`finally` runs regardless of success or failure. It's the right place for cleanup that must happen: closing file handles, removing temp files, resetting state.

```powershell
$stream = $null
try {
    $stream = [System.IO.File]::OpenRead('C:\data.bin')
    # ... process the stream
}
catch {
    Write-Error "Failed to read file: $_"
}
finally {
    if ($null -ne $stream) {
        $stream.Dispose()
    }
}
```

Even if `OpenRead` throws, `finally` runs and the stream is disposed. No resource leak.

---

## 4. The `$Error` Automatic Variable

PowerShell maintains a global list of the last errors in `$Error`. It's a fixed-size circular buffer -- by default, the 256 most recent errors.

```powershell
# Clear the history (useful at the start of a script)
$Error.Clear()

# Trigger a couple of errors
Get-Item 'C:\NoSuchA' -ErrorAction SilentlyContinue
Get-Item 'C:\NoSuchB' -ErrorAction SilentlyContinue

# Most recent error is $Error[0]
$Error[0].Exception.Message    # Cannot find path 'C:\NoSuchB'...
$Error[1].Exception.Message    # Cannot find path 'C:\NoSuchA'...

# Count of errors since last clear
$Error.Count                   # 2
```

![error-variable](assets/images/ch-10-error-variable.png)

`$Error` is useful for post-hoc debugging -- checking what went wrong after a block ran with `SilentlyContinue`. It's not a substitute for proper error handling, but it's valuable in interactive sessions and diagnostic scripts.

---

## 5. `-ErrorVariable`: Capture Per-Command

If you want to capture errors from a specific cmdlet without changing `$ErrorActionPreference`, use `-ErrorVariable`.

```powershell
# Capture errors into $myErrors (note: no $ in the parameter value)
Get-Item 'C:\NoSuchA', 'C:\Windows' -ErrorAction SilentlyContinue -ErrorVariable myErrors

Write-Host "Errors captured: $($myErrors.Count)"
Write-Host "First error: $($myErrors[0].Exception.Message)"
```

```
Errors captured: 1
First error: Cannot find path 'C:\NoSuchA' because it does not exist.
```

Key rules for `-ErrorVariable`:
- Pass the variable **name without the `$`** sign
- Prefix with `+` to **append** rather than replace: `-ErrorVariable +myErrors`
- The variable is populated even with `-ErrorAction SilentlyContinue`

---

## 6. `Write-Error` vs `throw`

These both signal errors, but they behave very differently.

### `Write-Error`

`Write-Error` generates a **non-terminating error**. Execution continues after it. It's the right tool for functions that should follow the same contract as built-in cmdlets.

```powershell
function Get-SafeFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return
    }
    Get-Content $Path
}

# Caller can decide what to do with the error
Get-SafeFile -Path 'C:\NoSuchFile' -ErrorAction SilentlyContinue
Get-SafeFile -Path 'C:\NoSuchFile' -ErrorAction Stop    # now terminating
```

The function respects `-ErrorAction` because `Write-Error` is a cmdlet that honors `$ErrorActionPreference`. This is what makes it the professional choice for `[CmdletBinding()]` functions.

### `throw`

`throw` generates a **terminating error** immediately. Execution stops. It cannot be silenced with `-ErrorAction`.

```powershell
function Assert-ValidPort {
    param([int]$Port)
    if ($Port -lt 1 -or $Port -gt 65535) {
        throw "Invalid port number: $Port. Must be 1-65535."
    }
    $Port
}

try {
    Assert-ValidPort -Port 99999
}
catch {
    Write-Host "Validation failed: $_"
}
```

```
Validation failed: Invalid port number: 99999. Must be 1-65535.
```

Use `throw` when the error is genuinely unrecoverable in the current context -- invalid input that would corrupt the operation, a prerequisite that simply isn't met, a contract violation.

| | `Write-Error` | `throw` |
|---|---|---|
| **Error type** | Non-terminating (by default) | Terminating |
| **Respects `-ErrorAction`** | Yes | No |
| **Caller can suppress** | With `SilentlyContinue` | Only with `try`/`catch` |
| **Use for** | Cmdlet-style functions | Fatal conditions, validation |

---

## 7. The `ErrorRecord` Object

When an error occurs, PowerShell wraps the exception in an `ErrorRecord`. This is what lives in `$Error[0]` and `$_` inside `catch`. Understanding its structure helps you write useful error messages and diagnostic logs.

```powershell
try {
    1 / 0
}
catch {
    $record = $_

    # The .NET exception that caused this
    $record.Exception.Message
    $record.Exception.GetType().FullName

    # Category information
    $record.CategoryInfo.Category
    $record.CategoryInfo.TargetName

    # Where the error happened
    $record.InvocationInfo.ScriptName
    $record.InvocationInfo.ScriptLineNumber
    $record.InvocationInfo.Line

    # A friendly one-liner
    $record.ToString()
}
```

```
Attempted to divide by zero.
System.DivideByZeroException
NotSpecified

<line contents here>
```

---

## 8. `trap`: The Legacy Approach

Before `try`/`catch`, PowerShell had `trap`. You'll find it in old scripts. You do not need to write new code with it.

```powershell
# Legacy style -- don't do this in new scripts
trap {
    Write-Host "Trapped: $_"
    continue   # or 'break' to propagate
}

1 / 0          # trap fires
Write-Host "Execution continued"
```

`trap` is a statement-level error handler that applies to the entire scope. It's harder to reason about than `try`/`catch` and mixes control flow in confusing ways. The only reason to know it: you will encounter it in scripts written before 2012.

---

## Boss Level

> <!-- tier: extreme -->
> **Build a retry wrapper function** that executes a given scriptblock up to N times with exponential back-off between attempts. It should:
> - Accept a scriptblock, a `MaxAttempts` count, and a `BaseDelayMs`
> - Catch all terminating errors and retry
> - On final failure, re-throw the last error as a terminating error
> - Log each attempt with timestamp, attempt number, and error message
> - Support `-Verbose` output for each retry

```powershell
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [ValidateRange(1, 10)]
        [int]$MaxAttempts = 3,

        [int]$BaseDelayMs = 500
    )

    $attempt    = 0
    $lastError  = $null

    while ($attempt -lt $MaxAttempts) {
        $attempt++
        try {
            Write-Verbose "[$(Get-Date -Format 'HH:mm:ss.fff')] Attempt $attempt of $MaxAttempts"
            $result = & $ScriptBlock
            Write-Verbose "[$(Get-Date -Format 'HH:mm:ss.fff')] Succeeded on attempt $attempt"
            return $result
        }
        catch {
            $lastError = $_
            $delay     = $BaseDelayMs * [math]::Pow(2, $attempt - 1)
            Write-Verbose "[$(Get-Date -Format 'HH:mm:ss.fff')] Attempt $attempt failed: $($_.Exception.Message)"

            if ($attempt -lt $MaxAttempts) {
                Write-Verbose "[$(Get-Date -Format 'HH:mm:ss.fff')] Waiting ${delay}ms before retry..."
                Start-Sleep -Milliseconds $delay
            }
        }
    }

    # All attempts exhausted -- re-throw the last error
    throw $lastError
}

# Usage
try {
    $i = 0
    Invoke-WithRetry -MaxAttempts 4 -BaseDelayMs 100 -Verbose -ScriptBlock {
        $i++
        if ($i -lt 4) { throw "Simulated transient failure (attempt $i)" }
        "Success on attempt $i"
    }
}
catch {
    Write-Host "All retries exhausted: $_" -ForegroundColor Red
}
```

---

## Exercises

### [Ch-10, Ex-1] Simple: Catch a Divide-by-Zero

Write a `try`/`catch` block that attempts to divide 1 by 0 and catches the error.
Print `"caught"` if the error is caught.

```powershell
$result = try { 1 / 0 } catch { 'caught' }
$result
```

### [Ch-10, Ex-2] Normal: Handle Specific Exception Types

Write a function `Test-SpecificCatch` that takes a `[string]$Path` parameter and
tries to read the file with `Get-Content -ErrorAction Stop`. Catch
`[System.Management.Automation.ItemNotFoundException]` and return `'NotFound'`.
Catch everything else and return `'OtherError'`.

> <!-- tier: advanced -->

### [Ch-10, Ex-3] Advanced: Cmdlet-Style Error Handling

> <!-- tier: advanced -->
> Build a function `Get-SafeContent` with `[CmdletBinding()]` that accepts a
> mandatory `[string]$Path`. If the path does not exist, use `Write-Error` to
> report the problem and return `$null`. Otherwise return `Get-Content $Path`.
>
> Verify the function correctly populates `-ErrorVariable` when the file is missing
> and `-ErrorAction SilentlyContinue` is used.

### [Ch-10, Ex-4] Extreme: Structured Error Logger

> <!-- tier: extreme -->
> Build a function `Write-ErrorLog` that accepts an `[ErrorRecord]` and a
> `[string]$LogPath`, then appends a JSON entry to the log file containing:
> `Timestamp`, `Message`, `Category`, `Script`, and `Line`.
>
> Call it from a `catch` block after a deliberate error and verify the log
> file contains valid JSON with the correct fields.

---

## Summary

PowerShell's error handling model rewards the people who actually read the manual. Non-terminating errors keep going until you tell them to stop. Terminating errors can be caught -- but only if you know they're terminating. `$ErrorActionPreference = 'Stop'` is the cheat code that makes the whole system behave the way you'd expect coming from any other language.

The hierarchy: `throw` for fatal conditions, `Write-Error` for cmdlet-style functions, `-ErrorAction Stop` to make cmdlets catchable, `try`/`catch`/`finally` for structured recovery, and `$Error`/`-ErrorVariable` for diagnostics.

Max has one rule: every script that touches production has `$ErrorActionPreference = 'Stop'` on line one. He's been burned enough times by silent failures to have that rule tattooed on his brain. Now you know why.

---

*Next: [Chapter 11 -- Regex and Text Processing](11-regex-and-text.md)*
