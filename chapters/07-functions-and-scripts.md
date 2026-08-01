# Chapter 07: Functions and Scripts

> *A 500-line script with no functions is not a script. It's a cry for help.*

![chapter-opener](assets/images/ch-07-opener.png)

---

## What You'll Learn

- How to define and call functions with the `function` keyword
- How to declare typed parameters with `param()` blocks
- How `[CmdletBinding()]` turns a function into an advanced function
- Validation attributes: `Mandatory`, `ValidateSet`, `ValidateRange`, `ValidateScript`
- Pipeline processing with `begin`, `process`, and `end` blocks
- How PowerShell's output stream differs from `return`
- Scope rules: local, script, global, `$script:`, and `$global:`
- The anatomy of `.ps1` scripts, `#Requires`, and comment-based help
- Splatting with `@params` for cleaner function calls

---

## 1. Why Functions?

Sam's 500-line script worked. Technically. It ran the server health checks, generated the
report, sent the email, and archived the logs. It just did all of that in one enormous,
unbroken waterfall of code -- no structure, no reuse, no way to test any piece in isolation.

When Rina had to add a single new check three weeks later, she spent forty-five minutes just
finding the right line. When it broke at 2 AM, Max had no idea which part failed.

**Functions are the unit of reuse in PowerShell.** They let you name a piece of logic,
give it a defined interface, test it independently, and call it from anywhere. Once you
think in functions, you never go back.

```powershell
# Before functions
$servers = Get-Content servers.txt
foreach ($s in $servers) {
    $ping = Test-Connection $s -Count 1 -Quiet
    if ($ping) { Write-Host "$s is up" }
    else { Write-Host "$s is DOWN" -ForegroundColor Red }
}
# ... 495 more lines of similar density ...

# After functions
function Test-ServerHealth {
    param([string]$ServerName)
    $up = Test-Connection $ServerName -Count 1 -Quiet
    [PSCustomObject]@{ Server = $ServerName; Online = $up }
}

Get-Content servers.txt | ForEach-Object { Test-ServerHealth $_ }
```

The second version is testable, readable, and reusable. That's the entire pitch.

---

## 2. Basic Functions

The `function` keyword defines a named block of code. Call it by name.

```powershell
function Get-Greeting {
    param(
        [string]$Name = 'World'
    )
    "Hello, $Name!"
}

Get-Greeting              # Hello, World!
Get-Greeting -Name 'Sam'  # Hello, Sam!
```

### Return Values: The Output Stream

Here is the most important thing PowerShell beginners get wrong about functions: **everything
you write to the output stream is returned**. The `return` keyword just exits the function
early -- it does not define what the function "returns" in the traditional sense.

```powershell
function Get-Numbers {
    1      # Written to output stream
    2      # Also written to output stream
    return 3  # Written to output stream AND exits
    4      # Never reached
}

$result = Get-Numbers
$result  # 1, 2, 3 -- all three values
```

This trips up everyone who comes from Python or Bash. In PowerShell, think of the output
stream as a pipe, not a return slot. Any expression that produces a value -- and isn't
assigned or redirected -- flows into that pipe automatically.

```powershell
function Get-ServerReport {
    param([string]$Name)

    # This WRITES to output stream (returns the object)
    [PSCustomObject]@{ Server = $Name; Checked = (Get-Date) }

    # This DOES NOT write to output stream (assigned to a variable)
    $internalState = "temporary data"

    # This DOES NOT write to output stream (redirected to host)
    Write-Host "Processing $Name..." -ForegroundColor Cyan
}
```

`Write-Host` goes to the host (your terminal), not the output stream. Your callers never
see it. `Write-Output` (or just a bare expression) goes into the stream. Know the
difference and you'll never accidentally contaminate a pipeline.

---

## 3. The `param()` Block

Parameters are the function's contract with its callers. PowerShell's parameter system is
remarkably powerful -- it handles type conversion, validation, and pipeline binding
automatically.

```powershell
function Invoke-Deployment {
    param(
        [string]$AppName,       # Optional string
        [string]$Environment,   # Optional string
        [int]$TimeoutSeconds = 300,  # With default value
        [switch]$WhatIf         # Switch parameter (flag)
    )

    if ($WhatIf) {
        Write-Host "Would deploy $AppName to $Environment (dry run)"
        return
    }

    Write-Host "Deploying $AppName to $Environment (timeout: ${TimeoutSeconds}s)"
}

Invoke-Deployment -AppName 'api' -Environment 'staging' -WhatIf
Invoke-Deployment -AppName 'api' -Environment 'prod' -TimeoutSeconds 600
```

### Positional Parameters

By default, parameters are positional in the order they're declared. Specify `[Parameter(Position=0)]`
to be explicit:

```powershell
function Get-StatusCode {
    param(
        [Parameter(Position=0)]
        [string]$Url,
        [Parameter(Position=1)]
        [int]$Timeout = 30
    )
    # Invoke-WebRequest $Url -TimeoutSec $Timeout
    "Checking $Url with ${Timeout}s timeout"
}

Get-StatusCode 'https://example.com' 10  # Positional works
Get-StatusCode -Url 'https://example.com' -Timeout 10  # Named also works
```

---

## 4. Advanced Functions with `[CmdletBinding()]`

Adding `[CmdletBinding()]` to a function promotes it from a basic function to an
**advanced function** -- effectively a first-class cmdlet. This single decoration unlocks:

- Automatic `-Verbose`, `-Debug`, `-ErrorAction`, `-WhatIf`, `-Confirm` support
- `$PSCmdlet` variable for accessing the cmdlet runtime
- `Write-Verbose` and `Write-Debug` output controlled by preference variables
- Full parameter attribute support

![advanced-function-anatomy](assets/images/ch-07-anatomy.png)

```powershell
function Get-DiskUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Path,

        [ValidateSet('GB', 'MB', 'KB')]
        [string]$Unit = 'GB'
    )

    Write-Verbose "Scanning path: $Path"

    $bytes = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum).Sum

    $divisor = switch ($Unit) {
        'GB' { 1GB }
        'MB' { 1MB }
        'KB' { 1KB }
    }

    [PSCustomObject]@{
        Path  = $Path
        Size  = [math]::Round($bytes / $divisor, 2)
        Unit  = $Unit
    }
}

Get-DiskUsage -Path 'C:\Logs' -Unit 'MB'
Get-DiskUsage -Path 'C:\Logs' -Unit 'MB' -Verbose  # Shows verbose messages
```

### Mandatory Parameters

`[Parameter(Mandatory)]` forces the caller to provide a value. If they forget, PowerShell
prompts interactively -- no null checks required:

```powershell
function Remove-OldLogs {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [Parameter(Mandatory)]
        [ValidateRange(1, 365)]
        [int]$OlderThanDays
    )

    $cutoff = (Get-Date).AddDays(-$OlderThanDays)
    $files = Get-ChildItem $LogPath -Filter '*.log' |
             Where-Object { $_.LastWriteTime -lt $cutoff }

    foreach ($file in $files) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Remove")) {
            Remove-Item $file.FullName
        }
    }
}

Remove-OldLogs -LogPath 'C:\Logs' -OlderThanDays 30
Remove-OldLogs -LogPath 'C:\Logs' -OlderThanDays 30 -WhatIf  # Preview only
```

---

## 5. Validation Attributes

Validation attributes run automatically before your function body executes. If a value
fails validation, PowerShell throws a descriptive error -- no manual validation code needed.

```powershell
function Set-ServerConfig {
    [CmdletBinding()]
    param(
        # Only these exact values are accepted
        [ValidateSet('Web', 'Database', 'App', 'Cache')]
        [string]$Role = 'Web',

        # Must be between 1 and 65535
        [ValidateRange(1, 65535)]
        [int]$Port = 80,

        # Must match this regex pattern
        [ValidatePattern('^[a-z][a-z0-9\-]{2,}$')]
        [string]$Hostname,

        # Custom validation logic
        [ValidateScript({
            if (Test-Path $_) { $true }
            else { throw "Config file '$_' does not exist." }
        })]
        [string]$ConfigFile
    )

    Write-Host "Configuring $Hostname as $Role on port $Port"
}

Set-ServerConfig -Role 'Web' -Port 8080 -Hostname 'web-01'
Set-ServerConfig -Role 'Invalid'  # ERROR: ValidateSet rejects this immediately
Set-ServerConfig -Port 99999      # ERROR: ValidateRange rejects this immediately
```

> <!-- tier: advanced -->
> `ValidateScript` receives the parameter value as `$_`. Return `$true` to accept or
> `throw` a descriptive message to reject. This is the escape hatch for anything
> `ValidateSet`, `ValidateRange`, and `ValidatePattern` cannot express -- file existence
> checks, API calls, database lookups. Keep it cheap: this code runs on every invocation.

---

## 6. Pipeline Functions: `begin`, `process`, `end`

This is where PowerShell functions go from useful to genuinely powerful. A function that
accepts pipeline input can process thousands of objects with minimal memory overhead --
one at a time, as they arrive, rather than buffering the whole collection.

```powershell
function ConvertTo-ServerReport {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$ServerName
    )

    begin {
        # Runs ONCE before any pipeline input arrives
        Write-Verbose "Starting server report batch"
        $startTime = Get-Date
        $processed = 0
    }

    process {
        # Runs ONCE PER OBJECT in the pipeline
        $processed++
        Write-Verbose "Processing: $ServerName"

        [PSCustomObject]@{
            Server  = $ServerName
            Online  = Test-Connection $ServerName -Count 1 -Quiet
            Checked = Get-Date
        }
    }

    end {
        # Runs ONCE after all pipeline input is consumed
        $duration = (Get-Date) - $startTime
        Write-Verbose "Processed $processed servers in $($duration.TotalSeconds)s"
    }
}

# Use it as a pipeline stage
'web-01', 'db-01', 'app-01' | ConvertTo-ServerReport
Get-Content servers.txt | ConvertTo-ServerReport | Export-Csv report.csv
```

### Why `begin`/`process`/`end` Matters

Without these blocks, a function that takes `ValueFromPipeline` only processes the *last*
object. The `process` block is what makes it iterate. Compare:

```powershell
# BAD: Only processes last item
function Bad-UpperCase {
    param([Parameter(ValueFromPipeline)][string]$Text)
    $Text.ToUpper()  # Only runs for the last piped value
}

# GOOD: Processes every item
function ConvertTo-Upper {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)][string]$Text)
    process { $Text.ToUpper() }
}

'hello', 'world' | Bad-UpperCase   # WORLD  (only last item)
'hello', 'world' | ConvertTo-Upper # HELLO, WORLD  (both items)
```

Rina learned this one the hard way. Three hours of debugging a "broken" pipeline that
was working perfectly -- just silently discarding 99% of its input.

---

## 7. Scope Rules

PowerShell variables live in scopes. Functions create their own local scope. Changes to
variables inside a function don't affect the caller's scope unless you use scope modifiers.

```powershell
$counter = 0  # Script scope

function Increment-Counter {
    $counter = 99  # Creates a LOCAL variable -- does NOT affect the outer $counter
    Write-Host "Inside function: $counter"
}

Increment-Counter
Write-Host "Outside function: $counter"
# Inside function: 99
# Outside function: 0  <-- unchanged!
```

### Scope Modifiers

Use explicit scope prefixes to break through the default scope boundary:

```powershell
$script:deployCount = 0  # Script-scoped variable

function Register-Deployment {
    param([string]$AppName)
    $script:deployCount++  # Modifies the script-scoped variable
    Write-Host "Deployed $AppName. Total deployments: $script:deployCount"
}

Register-Deployment 'api'    # Deployed api. Total deployments: 1
Register-Deployment 'worker' # Deployed worker. Total deployments: 2

Write-Host "Final count: $script:deployCount"  # 2
```

| Scope | Modifier | Visibility |
|-------|----------|------------|
| Local | (none) | Current function/script only |
| Script | `$script:` | Current `.ps1` file and all its functions |
| Global | `$global:` | Entire PowerShell session |
| Private | `$private:` | Current scope only (blocks child scope access) |

> <!-- tier: advanced -->
> **Global scope is a code smell.** If you find yourself reaching for `$global:` in a
> function, step back and ask whether you should be returning a value instead. Global
> mutations are invisible side effects that make functions untestable. `$script:` is
> acceptable for module-internal state. `$global:` is for session-level settings and
> very little else.

---

## 8. Scripts vs. Functions, and `#Requires`

A `.ps1` file is a script. A `function` block inside a file is a function. You can have
both, and they interact the way you'd expect: the script body runs top-to-bottom, and
functions defined in the script are callable within it.

The `#Requires` directive lives at the top of a `.ps1` file and enforces prerequisites
before a single line runs:

```powershell
#Requires -Version 7.2
#Requires -Modules ActiveDirectory, @{ ModuleName = 'Az'; ModuleVersion = '10.0' }
#Requires -RunAsAdministrator

# If any requirement fails, PowerShell stops here with a clear error.
# Your script never runs in a broken environment.

param(
    [Parameter(Mandatory)]
    [string]$OUPath
)

function Get-InactiveAccounts {
    param(
        [string]$OUPath,
        [int]$DaysInactive = 90
    )
    $cutoff = (Get-Date).AddDays(-$DaysInactive)
    Get-ADUser -Filter { LastLogonDate -lt $cutoff } -SearchBase $OUPath
}

Get-InactiveAccounts -OUPath $OUPath | Export-Csv inactive-accounts.csv
```

---

## 9. Comment-Based Help

PowerShell has a built-in documentation system that makes your functions first-class
citizens alongside system cmdlets. Add a comment block before the function, and
`Get-Help` picks it up automatically.

```powershell
function Send-AlertEmail {
    <#
    .SYNOPSIS
        Sends an HTML alert email to the operations team.

    .DESCRIPTION
        Builds a formatted HTML email with the alert details and sends it via
        SMTP. Supports multiple recipients and optional attachment paths.
        All timestamps are normalized to UTC.

    .PARAMETER Subject
        The email subject line. Required. Keep it under 100 characters.

    .PARAMETER Body
        The plain-text body. Automatically converted to basic HTML.

    .PARAMETER Recipients
        One or more recipient email addresses. Mandatory.

    .PARAMETER Attachments
        Optional array of file paths to attach to the message.

    .EXAMPLE
        Send-AlertEmail -Subject 'Disk 90% full' -Body 'C:\ on WEB-01' -Recipients 'ops@company.com'

    .EXAMPLE
        Send-AlertEmail -Subject 'Deploy failed' -Body $errorLog -Recipients 'dev@company.com','ops@company.com' -Attachments 'deploy.log'

    .NOTES
        Requires SMTP relay access. Set $env:ALERT_SMTP_SERVER before calling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Subject,

        [Parameter(Mandatory)]
        [string]$Body,

        [Parameter(Mandatory)]
        [string[]]$Recipients,

        [string[]]$Attachments = @()
    )

    # ... implementation ...
}

Get-Help Send-AlertEmail -Full    # Full help output
Get-Help Send-AlertEmail -Examples  # Just the examples
```

The six most useful comment-based help keywords: `.SYNOPSIS`, `.DESCRIPTION`,
`.PARAMETER <name>`, `.EXAMPLE`, `.NOTES`, `.OUTPUTS`.

---

## 10. Splatting

Splatting lets you pass a hashtable of parameter values to a function, instead of listing
them all inline. It keeps long calls readable and makes parameter sets programmable.

```powershell
function Deploy-Application {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$AppName,
        [Parameter(Mandatory)] [string]$Environment,
        [int]$TimeoutSeconds = 300,
        [string]$ConfigFile,
        [switch]$WhatIf
    )
    Write-Host "Deploying $AppName to $Environment"
}

# Without splatting -- one long, fragile line
Deploy-Application -AppName 'api-service' -Environment 'production' -TimeoutSeconds 600 -ConfigFile 'prod.json' -WhatIf

# With splatting -- readable and maintainable
$deployParams = @{
    AppName        = 'api-service'
    Environment    = 'production'
    TimeoutSeconds = 600
    ConfigFile     = 'prod.json'
    WhatIf         = $true
}
Deploy-Application @deployParams

# Splatting shines when parameters are conditional
$deployParams = @{
    AppName     = $AppName
    Environment = $TargetEnv
}

if ($Verbose) { $deployParams['Verbose'] = $true }
if ($ConfigOverride) { $deployParams['ConfigFile'] = $ConfigOverride }

Deploy-Application @deployParams
```

Note the `@` sigil when calling: `Deploy-Application @deployParams`. The `$` sigil
reads the hashtable as a variable; the `@` sigil splats it as parameters.

> <!-- tier: extreme -->
> **Splatting for proxy functions.** When you write a wrapper around an existing cmdlet,
> use `$PSBoundParameters` -- which is automatically populated with all parameters the
> caller explicitly passed -- and splat it to the inner command. This passes through every
> parameter without you having to enumerate them:
>
> ```powershell
> function Invoke-SafeRemoveItem {
>     [CmdletBinding(SupportsShouldProcess)]
>     param(
>         [Parameter(Mandatory, ValueFromPipeline)]
>         [string]$Path,
>         [switch]$Recurse
>     )
>     process {
>         Write-Verbose "Validated: $Path exists before removing"
>         if (Test-Path $Path) {
>             Remove-Item @PSBoundParameters
>         }
>     }
> }
> ```

---

## Exercises

### [Ch-07, Ex-1] Simple: A Greeting Function

Write a function named `Get-Greeting` that accepts a `[string]$Name` parameter and
returns the string `"Hello, <Name>!"`. Call it with two different names.

```powershell
function Get-Greeting {
    param([string]$Name)
    # Your code here
}

Get-Greeting -Name 'World'      # Hello, World!
Get-Greeting -Name 'PowerShell' # Hello, PowerShell!
```

### [Ch-07, Ex-2] Normal: An Advanced Server Info Function

Write a function named `Get-ServerInfo` with `[CmdletBinding()]` that:

- Requires a `[string]$Name` parameter (Mandatory)
- Accepts a `[string]$Role` parameter with `ValidateSet` for `'Web'`, `'Database'`, `'App'`
- Defaults `$Role` to `'Web'`
- Returns a `PSCustomObject` with `Name` and `Role` properties

Test that passing an invalid role throws an error.

```powershell
function Get-ServerInfo {
    [CmdletBinding()]
    param(
        # Your parameters here
    )
    # Your code here
}

$result = Get-ServerInfo -Name 'srv01' -Role 'Database'
$result.Name  # srv01
$result.Role  # Database

Get-ServerInfo -Name 'srv02' -Role 'Invalid'  # Should throw
```

### [Ch-07, Ex-3] Advanced: A Pipeline Processing Function

> <!-- tier: advanced -->
> Write a function named `ConvertTo-Upper` that:
>
> - Has `[CmdletBinding()]`
> - Accepts `[string]$Text` from the pipeline via `[Parameter(ValueFromPipeline)]`
> - Uses a `process` block to convert each input string to uppercase
> - Returns the uppercase string
>
> Test it by piping an array of strings: `'hello', 'world' | ConvertTo-Upper`
>
> ```powershell
> function ConvertTo-Upper {
>     [CmdletBinding()]
>     param(
>         [Parameter(ValueFromPipeline)]
>         [string]$Text
>     )
>     # Your begin/process/end blocks here
> }
>
> 'hello', 'world' | ConvertTo-Upper  # HELLO, WORLD
> ```

### [Ch-07, Ex-4] Extreme: A Structured Logging Function

> <!-- tier: extreme -->
> Build a function named `Write-Log` that:
>
> - Has `[CmdletBinding()]`
> - Accepts `[string]$Message` as Mandatory, from the pipeline
> - Accepts `[string]$Level` with `ValidateSet('INFO', 'WARN', 'ERROR')`, defaulting to `'INFO'`
> - Uses `begin` to initialize a `$entries` array
> - Uses `process` to append a `PSCustomObject` with `Timestamp`, `Level`, and `Message` to `$entries`
> - Uses `end` to output `$entries` (the complete log batch)
> - Add comment-based help with `.SYNOPSIS` and at least one `.EXAMPLE`
>
> ```powershell
> function Write-Log {
>     <#
>     .SYNOPSIS
>         # Your synopsis here
>     .EXAMPLE
>         # Your example here
>     #>
>     [CmdletBinding()]
>     param(
>         # Your parameters here
>     )
>     begin { }
>     process { }
>     end { }
> }
>
> $logs = 'Test1', 'Test2' | Write-Log -Level 'WARN'
> $logs.Count    # 2
> $logs[0].Level # WARN
> ```

---

## Summary

Functions are the architecture of a PowerShell codebase. `function` defines one; `param()`
gives it a typed interface; `[CmdletBinding()]` promotes it to a full cmdlet with automatic
`-Verbose`, `-Debug`, and error handling; `begin`/`process`/`end` makes it a first-class
pipeline citizen. Scope rules keep variables from leaking; `#Requires` enforces prerequisites;
comment-based help makes your functions self-documenting; splatting with `@params` keeps
call sites clean.

Max's rule: every script longer than 30 lines needs at least one function. Every function
needs at least one comment. Every pipeline function needs a `process` block. Follow these
three rules and 2 AM pages become 2-minute fixes.

---

*Next: [Chapter 08 -- Modules](08-modules.md)*
