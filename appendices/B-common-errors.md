# Appendix B: Common Errors and How to Fix Them

> *Everyone's PowerShell journey is paved with red text. Here's a map of the potholes.*

![app-b-error-anatomy](assets/images/app-B-error-anatomy.png)

---

Each error below includes the exact message (as it appears in the terminal), the most common cause, a concrete fix, and a one-sentence prevention tip. Bookmark this page; you will be back.

---

## Error 1: The term 'X' is not recognized

```
The term 'Get-Thingo' is not recognized as a name of a cmdlet, function, script
file, or operable program. Check the spelling of the name, or if a path was
included, verify that the path is correct and try again.
```

**Common cause:** Typo in the cmdlet name, a required module is not imported, or the command only exists in a newer version of PowerShell.

**Fix:**
```powershell
# Check spelling with a wildcard search
Get-Command *Thingo*

# If it's in a module, import it first
Import-Module ActiveDirectory
Get-ADUser -Filter *

# Check your PowerShell version
$PSVersionTable.PSVersion
```

**Prevention tip:** Use tab-completion — if PowerShell won't complete it, it doesn't exist in your current session.

---

## Error 2: Cannot bind argument to parameter 'X' because it is null

```
Cannot bind argument to parameter 'Path' because it is null.
```

**Common cause:** A variable you're passing to a cmdlet is `$null`, usually because a previous step returned nothing or a property doesn't exist on the object.

**Fix:**
```powershell
# Check before using
$file = Get-Item 'missing.txt' -ErrorAction SilentlyContinue
if ($null -ne $file) {
    Get-Content $file.FullName
}

# Or use the null-coalescing operator (PS 7+)
$path = $file?.FullName ?? 'C:\default.txt'
Get-Content $path
```

**Prevention tip:** Treat every variable that comes from a function or pipeline as potentially null until proven otherwise with `$null -ne $x`.

---

## Error 3: Access is denied

```
Access to the path 'C:\Windows\System32\drivers\etc\hosts' is denied.
```

**Common cause:** Your PowerShell session does not have the required privileges. On Windows, many system paths require an elevated (Administrator) session.

**Fix:**
```powershell
# Check if you are elevated
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Run PowerShell as Administrator, then retry
# Or use -Credential with appropriate rights
Get-Content 'C:\restricted.txt' -ErrorAction Stop
```

**Prevention tip:** Open a new "Run as Administrator" terminal for anything touching system paths, services, or registry hives under `HKLM`.

---

## Error 4: The RPC server is unavailable

```
[server01] Connecting to remote server server01 failed with the following error
message : The RPC server is unavailable.
```

**Common cause:** On a Windows WSMan target, WinRM is not running, the machine
is unreachable, or a firewall is blocking TCP port 5985 (HTTP) or 5986
(HTTPS). This diagnosis does not apply to PowerShell remoting over SSH.

**Fix:**
```powershell
# Test connectivity first
Test-NetConnection -ComputerName server01 -Port 5985

# On the remote machine (requires local access or GPO):
Enable-PSRemoting -Force

# If the machine is in a workgroup, add it to TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'server01' -Force
```

Use an exact host list, not `*`. `TrustedHosts` weakens mutual authentication;
prefer domain/Kerberos or HTTPS with certificate validation where available.

**Prevention tip:** Run `Test-WSMan server01` before any `Invoke-Command` — it's a fast sanity check that costs nothing.

---

## Error 5: Cannot convert value 'X' to type 'System.Int32'

```
Cannot convert value "abc" to type "System.Int32". Error: "Input string was
not in a correct format."
```

**Common cause:** You are assigning or passing a string where an integer is expected — often when reading from CSV, JSON, or user input (which is always a string).

**Fix:**
```powershell
# Explicit cast
[int]"42"            # 42
[int]"abc"           # throws — don't do this blindly

# Safe parse
$val = 0
if ([int]::TryParse($input, [ref]$val)) {
    "Valid: $val"
} else {
    "Not a number"
}

# When reading CSVs, cast in calculated properties
Import-Csv .\data.csv | Select-Object Name, @{N='Age'; E={ [int]$_.Age }}
```

**Prevention tip:** After `Import-Csv`, always cast numeric columns — everything arrives as a string.

---

## Error 6: A positional parameter cannot be found

```
A positional parameter cannot be found that accepts argument 'SomeValue'.
```

**Common cause:** You passed a positional argument that the cmdlet doesn't accept at that position, or you accidentally included an extra bare value.

**Fix:**
```powershell
# Wrong (extra positional arg)
Get-ChildItem C:\Temp 'more stuff'

# Right: use named parameters
Get-ChildItem -Path C:\Temp -Filter '*.txt'

# Use Get-Help to see which parameters are positional
Get-Help Get-ChildItem -Parameter *
```

**Prevention tip:** Name your parameters explicitly; positional arguments are convenient until they aren't.

---

## Error 7: Missing closing '}' in statement block

```
Missing closing '}' in statement block or type definition.
```

**Common cause:** Mismatched braces in a script block, function, `if`, `foreach`, or pipeline. PowerShell counts every `{` and `}` and won't execute until they balance.

**Fix:**
```powershell
# Wrong
Get-Process | Where-Object { $_.CPU -gt 10

# Right
Get-Process | Where-Object { $_.CPU -gt 10 }

# For complex scripts, use an IDE (VS Code + PS extension) to spot mismatches
# Or test with: $null = [scriptblock]::Create($code)
```

**Prevention tip:** Use VS Code with the PowerShell extension — it highlights unmatched braces in real time, before you even press Enter.

---

## Error 8: The variable '$X' cannot be retrieved because it has not been set

```
The variable '$config' cannot be retrieved because it has not been set.
```

**Common cause:** You are using `Set-StrictMode -Version Latest` (or a calling script is), which disallows reading undefined variables. Without strict mode this silently returns `$null`.

**Fix:**
```powershell
# Initialise before use
$config = $null

# Or check first
if (Test-Path variable:config) {
    "Config is: $config"
}

# Or use -ErrorAction
$val = $undefined -as [string]   # returns $null without throwing
```

**Prevention tip:** Use `Set-StrictMode -Version Latest` in all your scripts — catching uninitialised variables at development time beats debugging production surprises.

---

## Error 9: Cannot index into a null array

```
Cannot index into a null array.
```

**Common cause:** You are doing `$array[0]` (or similar) on a variable that is `$null` rather than an empty array. This often happens when a cmdlet returns nothing.

**Fix:**
```powershell
# Guard before indexing
$results = Get-ChildItem -Filter '*.xyz' -ErrorAction SilentlyContinue
if ($results -and $results.Count -gt 0) {
    $first = $results[0]
}

# Force array result even for single/zero items
$results = @(Get-ChildItem -Filter '*.xyz')
$first = $results[0]   # now safely returns $null instead of throwing
```

**Prevention tip:** Wrap cmdlet calls that might return nothing in `@()` when you intend to index into the result.

---

## Error 10: The input object cannot be bound to any parameters

```
The input object cannot be bound to any parameters for the command either
because the command does not take pipeline input or the value and its type
cannot be converted to a parameter type.
```

**Common cause:** You piped an object to a cmdlet that doesn't accept that type via the pipeline, or the cmdlet has no `ValueFromPipeline` parameter matching the object type.

**Fix:**
```powershell
# Instead of piping the object directly, expand the property you need
Get-Process | Select-Object -ExpandProperty Name | Stop-Process -Name  # still wrong

# Use ForEach-Object to call the cmdlet explicitly
Get-Process | ForEach-Object { Stop-Process -Id $_.Id -WhatIf }

# Or use pipeline-aware alternative cmdlets
Get-ChildItem *.tmp | Remove-Item   # Remove-Item accepts pipeline input
```

**Prevention tip:** Check `Get-Help <Cmdlet> -Parameter *` for parameters marked `Accept pipeline input: True` before assuming a cmdlet is pipeline-friendly.

---

## Error 11: Running scripts is disabled on this system (Windows)

```
File C:\scripts\deploy.ps1 cannot be loaded because running scripts is
disabled on this system. For more information, see about_Execution_Policies.
```

**Common cause:** On Windows, the execution policy is set to `Restricted` or
`AllSigned`, and your script is not signed. Execution policy is not enforced
on Linux or macOS and isn't a security boundary.

**Fix:**
```powershell
# Check current policy
Get-ExecutionPolicy -List

# Set for current user (recommended for dev machines)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**Prevention tip:** Use the narrowest policy your organization permits and
sign trusted automation. Don't use `Bypass` as a routine fix, and never treat
a policy change as evidence that an untrusted script is safe.

---

## Error 12: Cannot find path 'X' because it does not exist

```
Cannot find path 'C:\Reports\output.csv' because it does not exist.
```

**Common cause:** The file or directory path doesn't exist — either a wrong path, an incorrect drive letter, a missing directory, or a network share that isn't mounted.

**Fix:**
```powershell
# Test before acting
if (Test-Path 'C:\Reports\output.csv') {
    Import-Csv 'C:\Reports\output.csv'
} else {
    Write-Warning "File not found — creating directory"
    New-Item -ItemType Directory -Path 'C:\Reports' -Force
}

# Resolve path to catch symlink / relative path issues
Resolve-Path '.\output.csv'
```

**Prevention tip:** Build paths with `Join-Path` instead of string concatenation — it handles trailing slashes and platform separators automatically.

---

## Error 13: A command that prompts the user failed because the host program or the command type does not support user interaction

```
A command that prompts the user failed because the host program or the command
type does not support user interaction.
```

**Common cause:** A cmdlet called `Read-Host`, `Get-Credential`, or a similar interactive prompt inside a non-interactive context: a background job, a scheduled task, or a remoting session.

**Fix:**
```powershell
# Pass credentials as a parameter instead of prompting
$cred = Get-Credential   # do this in an interactive session first
Invoke-Command -ComputerName server01 -Credential $cred -ScriptBlock { ... }

# In automation, retrieve the secret from an approved secret store.
# Example with Microsoft.PowerShell.SecretManagement:
$pwd  = Get-Secret -Name 'service-account-password'
$cred = [PSCredential]::new('user', $pwd)
```

**Prevention tip:** Unattended scripts must not prompt. Parameterize inputs and
use a workload identity or secret manager; don't embed plaintext passwords or
treat environment variables as a secure vault.

---

## Error 14: Method invocation failed because [null-valued expression]

```
You cannot call a method on a null-valued expression.
At line:5 char:1
+     $result.Trim()
```

**Common cause:** Calling a .NET method (`.Trim()`, `.Length`, `.Split()`, etc.) on a variable that is `$null`. The variable was either never set or the previous step returned nothing.

**Fix:**
```powershell
# Guard with null check
if ($null -ne $result) {
    $result.Trim()
}

# Use null-conditional operator (PS 7.1+)
$result?.Trim()

# Provide a default value
($result ?? '').Trim()
```

**Prevention tip:** Use `$result?.Method()` null-conditional syntax in PS 7+ — it silently returns `$null` instead of throwing, and makes intent clear.

---

## Error 15: The module 'X' could not be loaded

```
The module 'Az' could not be loaded. For more information, run
'Import-Module Az'.
```

**Common cause:** The module is not installed in any path listed in `$env:PSModulePath`, or it was installed for a different user/version of PowerShell.

**Fix:**
```powershell
# Find if the module exists anywhere
Find-PSResource Az   # searches PSGallery

# Install it (current user, no admin required)
Install-PSResource Az -Scope CurrentUser

# Check where modules are loaded from
$env:PSModulePath -split [IO.Path]::PathSeparator

# Import explicitly from a custom path
Import-Module 'C:\MyModules\MyModule.psm1'
```

**Prevention tip:** Pin module versions in `#Requires -Modules @{ ModuleName='Az'; ModuleVersion='12.0.0' }` at the top of scripts that depend on specific APIs.

---

## Error 16: Cannot process argument transformation on parameter

```
Cannot process argument transformation on parameter 'InputObject'. Cannot
convert value "System.String" to type "System.IO.FileInfo".
```

**Common cause:** You passed a string (usually a file path) where the cmdlet expects an object of a specific .NET type, such as `FileInfo`, `DirectoryInfo`, or `PSCredential`.

**Fix:**
```powershell
# Wrong: passing a string path where FileInfo is expected
$file = 'C:\log.txt'
$file.LastWriteTime   # string has no LastWriteTime

# Right: get the object first
$file = Get-Item 'C:\log.txt'
$file.LastWriteTime   # now it works

# Or cast inline
([System.IO.FileInfo]'C:\log.txt').LastWriteTime
```

**Prevention tip:** When a cmdlet wants an object type, retrieve that object with `Get-Item`, `Get-Process`, etc. rather than constructing string paths yourself.

---

## Error 17: You cannot call a method on a null-valued expression (array variant)

```
You cannot call a method on a null-valued expression.
At line:3 char:1
+     $services.Where({ $_.Status -eq 'Running' })
```

**Common cause:** Using a `.Where()` or `.ForEach()` intrinsic method (the "magic" array methods) on a variable that is `$null` rather than an empty array. This is the array-flavoured cousin of Error 14.

**Fix:**
```powershell
# Always initialise collection variables as arrays
$processes = @(Get-Process -ErrorAction SilentlyContinue)
$active    = $processes.Where({ $_.Responding })

# Or use the pipeline equivalent, which handles $null gracefully
Get-Process | Where-Object { $_.Responding }
```

**Prevention tip:** Prefer pipeline `Where-Object` over the `.Where()` method unless you're in a hot loop and need the performance; the pipeline version degrades gracefully when input is empty.

---

## Error 18: Connecting to remote server X failed

```
[webserver02] Connecting to remote server webserver02 failed with the
following error message: WinRM cannot complete the operation.
```

**Common cause:** On a Windows WSMan target, WinRM is enabled but the target
name cannot be resolved, trust/authentication is misconfigured, or the caller
lacks permission to create a remote session.

**Fix:**
```powershell
# Step-by-step diagnosis
Resolve-DnsName webserver02                            # DNS (Windows cmdlet)
Test-NetConnection webserver02 -Port 5985             # WinRM HTTP
Test-WSMan webserver02                                 # WinRM handshake

# Try with explicit credentials
$cred = Get-Credential
Enter-PSSession -ComputerName webserver02 -Credential $cred

# Cross-domain: specify authentication mechanism
New-PSSession -ComputerName webserver02 -Credential $cred -Authentication Negotiate
```

**Prevention tip:** Validate DNS, the configured port, authentication, and
`Test-WSMan` before automation. Ping may be blocked even when WinRM is healthy,
so don't make ICMP success a prerequisite.

---

## Error 19: Format-Table: The pipeline has been stopped

```
Format-Table : The pipeline has been stopped.
```

**Common cause:** You piped the output of `Format-Table` (or any `Format-*` cmdlet) into another processing cmdlet. `Format-*` outputs formatting directives, not objects — further processing fails.

**Fix:**
```powershell
# Wrong: piping Format-Table output into Export-Csv
Get-Process | Format-Table Name, CPU | Export-Csv .\procs.csv   # broken

# Right: Select-Object, then export
Get-Process | Select-Object Name, CPU | Export-Csv .\procs.csv -NoTypeInformation

# Format-* is the last data transformation
Get-Process | Select-Object Name, CPU | Format-Table
```

**Prevention tip:** After `Format-Table`, `Format-List`, or `Format-Wide`, only
send formatting output to a display-oriented sink such as `Out-Host`,
`Out-String`, or `Out-File`.

---

## Error 20: Cannot overwrite variable X because it is read-only

```
Cannot overwrite variable PSVersionTable because it is read-only or constant.
```

**Common cause:** You tried to assign a value to a built-in read-only variable (`$PSVersionTable`, `$true`, `$false`, `$null`, `$PID`, etc.) or a variable your script marked as constant with `Set-Variable -Option Constant`.

**Fix:**
```powershell
# Check variable options
Get-Variable PSVersionTable | Select-Object -ExpandProperty Options
# Output: ReadOnly

# If you declared it as constant/readonly by mistake:
Set-Variable -Name MyVar -Option None -Force   # remove ReadOnly (not Constant)

# For built-ins: don't try to overwrite them. Use a different name.
$psVersion = $PSVersionTable.PSVersion   # copy the value you need
```

**Prevention tip:** Avoid variable names that shadow built-ins (`$error`, `$input`, `$args`, `$_`, `$null`, `$true`, `$false`) — even the ones that aren't read-only can cause confusing behaviour.

---

![app-b-erroraction-flowchart](assets/images/app-B-erroraction-flowchart.png)

---

## ErrorAction Quick Reference

| Value | Behaviour |
|---|---|
| `Continue` | Print error and keep going (default) |
| `SilentlyContinue` | Suppress error, keep going |
| `Stop` | Convert to terminating error (catchable with `try/catch`) |
| `Inquire` | Ask the user what to do (interactive sessions only) |
| `Ignore` | Suppress error and don't populate `$Error` |

```powershell
# Set default for a script
$ErrorActionPreference = 'Stop'   # promotes PowerShell non-terminating errors in this scope

# Per-command override
Get-Item 'missing.txt' -ErrorAction SilentlyContinue

# Capture the error object
Get-Item 'missing.txt' -ErrorAction SilentlyContinue -ErrorVariable myErr
if ($myErr) { Write-Warning $myErr[0].Exception.Message }
```

---

![app-b-fix-patterns](assets/images/app-B-fix-patterns.png)

---

## The Universal Debug Workflow

When all else fails:

```powershell
# 1. Read the last error in full
$Error[0] | Format-List * -Force

# 2. Find the inner exception
$Error[0].Exception.InnerException

# 3. Get the full stack trace
$Error[0].ScriptStackTrace

# 4. Run the failing command with -Verbose and -Debug
Get-SomeCmdlet -Parameter value -Verbose -Debug

# 5. Set a breakpoint (VS Code) or use Wait-Debugger
Wait-Debugger   # drops you into the debugger at that line

# 6. Use transcript to capture everything
Start-Transcript .\debug.log
# ... reproduce the issue ...
Stop-Transcript
```

![app-b-debug-workflow](assets/images/app-B-debug-workflow.png)

---

> **Survival tip:** PowerShell error messages are verbose for a reason — read the whole thing before Googling.
> The last line almost always tells you exactly what went wrong, if you give it the chance.
