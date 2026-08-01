# Chapter 03 -- Answers

---

## Ch-03, Ex-1 (Simple)

**Task:** Use `Get-Help` to look up the documentation for `Get-ChildItem`.

### Solution

```powershell
Get-Help Get-ChildItem
```

For more detail, add the `-Examples` flag:

```powershell
Get-Help Get-ChildItem -Examples
```

### Expected Output

```
NAME
    Get-ChildItem

SYNOPSIS
    Gets the items and child items in one or more specified locations.

...

PARAMETERS
    -Path <String[]>
    -Filter <String>
    -Recurse [<SwitchParameter>]
    -Force [<SwitchParameter>]
    ...
```

The exact output varies by PowerShell version, but you should see the command
name, a synopsis, and a parameter list. Two commonly used parameters:

- `-Path` -- specifies where to look
- `-Recurse` -- descends into subdirectories

### What to notice

`Get-Help` returns a **HelpInfo object**, not raw text. That means the `Name`
property always matches the cmdlet name exactly -- useful for programmatic
checks. Also note the `-Online` flag, which opens Microsoft's web docs. When
the local help feels incomplete, `-Online` is your escape hatch.

---

## Ch-03, Ex-2 (Normal)

**Task:** Write a one-liner that returns the 5 processes consuming the most CPU.

### Solution

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
```

### Expected Output

```
 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
 ------    -----      -----     ------      --  -- -----------
    120   432.12     510.33   1,204.55   12340   1 firefox
     85   310.44     298.76     892.11    5678   1 code
     42   198.00     187.22     443.67    9012   1 pwsh
     ...
```

Your actual results will differ -- it depends on what's running. The important
thing is that the list is sorted in descending CPU order and has exactly 5 rows.

### What to notice

`Sort-Object CPU -Descending` sorts by the `CPU` property (total processor time
in seconds). Without `-Descending`, you'd get the *lowest* consumers first --
not terribly useful. `Select-Object -First 5` is PowerShell's equivalent of
`head -n 5`, but it works on objects, not lines. The objects that come through
still have all their properties intact; `Select-Object` just limits *how many*
pass through, not *what data* they carry (unless you also specify property names).

---

## Ch-03, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Find every cmdlet on your system that uses the verb `Stop`.

### Solution

```powershell
Get-Command -Verb Stop
```

To verify there are no false positives:

```powershell
$stopCmds = Get-Command -Verb Stop
$stopCmds | ForEach-Object { $_.Verb | Should -Be 'Stop' }  # Pester assertion
```

Or without Pester, a quick sanity check:

```powershell
$stopCmds = Get-Command -Verb Stop
$stopCmds | ForEach-Object {
    if ($_.Verb -ne 'Stop') {
        Write-Warning "False positive: $($_.Name)"
    }
}
```

### Expected Output

```
CommandType     Name                    Version    Source
-----------     ----                    -------    ------
Cmdlet          Stop-Computer           7.0.0.0    Microsoft.PowerShell.Management
Cmdlet          Stop-Job                7.0.0.0    Microsoft.PowerShell.Core
Cmdlet          Stop-Process            7.0.0.0    Microsoft.PowerShell.Management
Cmdlet          Stop-Service            7.0.0.0    Microsoft.PowerShell.Management
Cmdlet          Stop-Transcript         7.0.0.0    Microsoft.PowerShell.Host
...
```

The count varies by system. A clean Windows install typically has 5-8 Stop
cmdlets. A system with additional modules (Az, Exchange, VMware) can have dozens.

### What to notice

`Get-Command -Verb Stop` filters at the source -- it only returns commands whose
`Verb` property is literally `Stop`. This is more reliable than wildcard matching
like `Get-Command Stop-*`, which could match a hypothetical command named
`Stop-AndStartOver-Nonsense` where the verb is actually something else entirely.
(Okay, that's unlikely, but the principle matters when you're writing scripts
that need to be correct, not just close enough.)

---

## Ch-03, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Build a `PSCustomObject` with five or more system health data points
using pipeline cmdlets and multiple `Get-*` sources.

### Solution

```powershell
$health = [PSCustomObject]@{
    ProcessCount  = (Get-Process).Count
    ThreadCount   = (
        Get-Process |
            ForEach-Object { $_.Threads.Count } |
            Measure-Object -Sum
    ).Sum
    Uptime        = (Get-Uptime).TotalHours
    UsedMemoryMB  = [math]::Round(
        (Get-Process | Measure-Object WorkingSet64 -Sum).Sum / 1MB
    )
    TempFileCount = (
        Get-ChildItem ([System.IO.Path]::GetTempPath()) -ErrorAction SilentlyContinue
    ).Count
}

$health
```

### Expected Output

```
ProcessCount : 247
ThreadCount  : 1842
Uptime       : 72.4533
UsedMemoryMB : 8934
TempFileCount: 142
```

Your numbers will vary. The point is that all five properties are populated
and the result is a single object, not five separate Write-Host calls.

### What to notice

Several things are happening that deserve attention:

1. **Subexpression syntax** -- `(Get-Process).Count` wraps the cmdlet in
   parentheses so you can access a property on the *collection*, not on
   individual items. Without the parens, PowerShell would try to find a
   `Count` parameter on `Get-Process`, which doesn't exist.

2. **Measure-Object** -- `Get-Process | Measure-Object WorkingSet64 -Sum`
   returns a `MeasureInfo` object. You access the `.Sum` property to get the
   total. The `/1MB` division uses PowerShell's built-in size multipliers
   (`1KB`, `1MB`, `1GB`, `1TB`). These are real constants, not string suffixes.

3. **[math]::Round()** -- calls a .NET static method directly. PowerShell
   is built on .NET, and you can reach into it whenever you need to. No
   `Import-Module` required for core framework types.

4. **-ErrorAction SilentlyContinue** -- the platform-neutral temporary directory might
   contain items you don't have permission to enumerate. Without this flag,
   you'd get red error text mixed into your clean output. In production
   scripts, you'd want `-ErrorAction Stop` with a try/catch instead, but
   for a quick health check, silencing permission errors is pragmatic.

5. **PSCustomObject** -- this is PowerShell's lightweight way to create
   structured data on the fly. The `@{}` is a hashtable, and `[PSCustomObject]`
   casts it into a proper object with named properties. You'll use this
   pattern constantly in real-world scripts.
