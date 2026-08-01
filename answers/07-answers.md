# Chapter 07 -- Answers

---

## Ch-07, Ex-1 (Simple)

**Task:** Write a function named `Get-Greeting` that takes a `[string]$Name` parameter
and returns `"Hello, <Name>!"`. Call it with `'World'` and `'PowerShell'`.

### Solution

```powershell
function Get-Greeting {
    param([string]$Name)
    "Hello, $Name!"
}

Get-Greeting -Name 'World'
Get-Greeting -Name 'PowerShell'
```

### Expected Output

```
Hello, World!
Hello, PowerShell!
```

### What to notice

The string `"Hello, $Name!"` is placed as a bare expression inside the function body.
PowerShell writes it directly to the output stream -- no `Write-Output` or `return` needed.
The double-quoted string performs variable interpolation: `$Name` is replaced with its
current value at runtime. If you used single quotes (`'Hello, $Name!'`), the output would
be the literal text `Hello, $Name!` -- no interpolation. That distinction bites everyone
at least once.

The `param()` block without `[Parameter(Mandatory)]` means `$Name` is optional. Calling
`Get-Greeting` with no arguments would return `"Hello, !"` (empty string substitution).
In a production function you'd either mark it Mandatory or add a default: `[string]$Name = 'World'`.

---

## Ch-07, Ex-2 (Normal)

**Task:** Write an advanced function `Get-ServerInfo` with `[CmdletBinding()]`, a Mandatory
`$Name` parameter, and a `$Role` parameter restricted to `'Web'`, `'Database'`, or `'App'`.
Return a `PSCustomObject` with both values. Verify that an invalid role throws.

### Solution

```powershell
function Get-ServerInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [ValidateSet('Web', 'Database', 'App')]
        [string]$Role = 'Web'
    )

    [PSCustomObject]@{
        Name = $Name
        Role = $Role
    }
}

# Normal usage
$result = Get-ServerInfo -Name 'srv01' -Role 'Database'
$result.Name   # srv01
$result.Role   # Database

# Default role
$web = Get-ServerInfo -Name 'srv02'
$web.Role      # Web

# This throws -- ValidateSet rejects it before the function body runs
Get-ServerInfo -Name 'srv02' -Role 'Invalid'
```

### Expected Output

```
srv01
Database
Web
Get-ServerInfo: Cannot validate argument on parameter 'Role'. The argument "Invalid"
does not belong to the set "Web,Database,App" ...
```

### What to notice

`[ValidateSet()]` enforces its constraint before your function body executes. You get a
descriptive error with the valid options listed -- without writing a single `if` statement.
This is one of the most underused time-savers in PowerShell parameter design.

`[CmdletBinding()]` adds support for `-Verbose`, `-Debug`, `-ErrorAction`, and `-WarningAction`
automatically. Try calling `Get-ServerInfo -Name 'srv01' -Verbose` -- you don't get verbose
output because we never called `Write-Verbose`, but the parameter exists and is valid. That's
the baseline gift of `[CmdletBinding()]`.

The `[PSCustomObject]` cast from a hashtable is idiomatic PowerShell for lightweight structured
output. It is faster to type than `New-Object PSObject -Property @{}` and produces the same
result. Your callers can access properties by name, pipe the result to `Select-Object`,
`Where-Object`, `Export-Csv` -- everything works because it's a real object.

---

## Ch-07, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Write `ConvertTo-Upper` with `[CmdletBinding()]`, `[Parameter(ValueFromPipeline)]`
on `$Text`, and a `process` block that emits the uppercased string. Pipe `'hello', 'world'`
to it and confirm both values are transformed.

### Solution

```powershell
function ConvertTo-Upper {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Text
    )

    process {
        $Text.ToUpper()
    }
}

'hello', 'world' | ConvertTo-Upper
```

### Expected Output

```
HELLO
WORLD
```

### What to notice

The `process` block is the critical ingredient. Without it, `ValueFromPipeline` collects
all the pipeline input but only executes the function body once -- with the *last* value.
With a `process` block, PowerShell calls it once per incoming object. Try removing the
`process { }` wrapper and observe that only `WORLD` comes out. Then put it back.

`.ToUpper()` is a .NET `String` method called directly on a PowerShell string. You don't
need to import anything -- every PowerShell string is a `System.String` instance and all
its methods are available. `.ToLower()`, `.Trim()`, `.Replace()`, `.Split()` all work the
same way.

When `'hello', 'world'` is sent through the pipeline, PowerShell unrolls the array
automatically -- each element is sent to the function as a separate pipeline object.
You don't have to loop; the pipeline does the iteration for you.

---

## Ch-07, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Build `Write-Log` with `[CmdletBinding()]`, a Mandatory pipeline `$Message`
parameter, `$Level` restricted to `'INFO'`/`'WARN'`/`'ERROR'` (default `'INFO'`),
using `begin`/`process`/`end` to accumulate and output structured log entries.
Include comment-based help.

### Solution

```powershell
function Write-Log {
    <#
    .SYNOPSIS
        Collects structured log entries from pipeline input and outputs them as objects.

    .DESCRIPTION
        Accepts one or more messages from the pipeline and accumulates them into
        PSCustomObject entries with Timestamp, Level, and Message fields.
        All entries are output together in the end block, making the result suitable
        for Export-Csv, ConvertTo-Json, or further pipeline processing.

    .PARAMETER Message
        The log message text. Accepts pipeline input. Mandatory.

    .PARAMETER Level
        Severity level. Must be 'INFO', 'WARN', or 'ERROR'. Defaults to 'INFO'.

    .EXAMPLE
        'Server started', 'Listener ready' | Write-Log -Level 'INFO'

    .EXAMPLE
        'Disk 90% full' | Write-Log -Level 'WARN' | Export-Csv -Path alerts.csv -NoTypeInformation

    .OUTPUTS
        PSCustomObject[] with Timestamp, Level, and Message properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    begin {
        $entries = @()
        Write-Verbose "Write-Log starting. Level: $Level"
    }

    process {
        $entry = [PSCustomObject]@{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Level     = $Level
            Message   = $Message
        }
        $entries += $entry
        Write-Verbose "Logged: [$Level] $Message"
    }

    end {
        Write-Verbose "Write-Log complete. $($entries.Count) entries."
        $entries
    }
}

# Usage
$logs = 'Test1', 'Test2' | Write-Log -Level 'WARN'
$logs.Count       # 2
$logs[0].Level    # WARN
$logs[0].Message  # Test1
$logs[1].Message  # Test2

# Real-world pattern: pipe results to a file
'Deploy started', 'Migrating DB', 'Deploy complete' |
    Write-Log -Level 'INFO' |
    Export-Csv deploy.log.csv -NoTypeInformation
```

### Expected Output

```
Count: 2

Timestamp           Level Message
---------           ----- -------
2026-03-17 14:22:01 WARN  Test1
2026-03-17 14:22:01 WARN  Test2
```

### What to notice

Several design decisions here deserve examination:

**The `begin`/`process`/`end` contract.** `$entries` is initialized once in `begin`.
Each pipeline object is appended in `process`. The complete collection is emitted in
`end`. This is the standard accumulator pattern for pipeline functions that need to
produce a single batched result rather than streaming individual outputs.

**Array concatenation with `+=`.** `$entries += $entry` re-creates the array on every
iteration. For small log batches (under a few thousand items) this is fine. For
high-volume logging, use `[System.Collections.Generic.List[object]]::new()` in `begin`
and `.Add()` in `process` -- that's O(1) amortized instead of O(n) per element.

**Comment-based help makes this production-ready.** `Get-Help Write-Log -Full` now works
exactly like `Get-Help Get-ChildItem -Full`. Your team doesn't need to read the source to
know what the function does, what it accepts, and what it outputs. This is the difference
between a function that lives on one engineer's machine and a function that ships in a module.

**`Write-Verbose` in all three blocks.** Callers can pass `-Verbose` to get a running
commentary on what the function is doing -- without modifying the function. This is the
correct way to add diagnostic output: it's invisible by default and opt-in at the call site.

**`ValidateSet` on `$Level` with a default.** The parameter is not Mandatory because it
has a sensible default (`'INFO'`). If the caller passes any other string, they get an
error before the function body runs. The validation attribute does what an `if` statement
would otherwise do, but earlier, clearer, and with no code to maintain.
