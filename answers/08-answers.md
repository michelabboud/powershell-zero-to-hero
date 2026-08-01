# Chapter 08 -- Answers

---

## Ch-08, Ex-1 (Simple)

**Task:** Use `Where-Object` to find all processes using more than 100MB of
working memory. Display `Name`, `Id`, and `WorkingSet64`.

### Solution

```powershell
Get-Process |
    Where-Object { $_.WorkingSet64 -gt 100MB } |
    Select-Object Name, Id, WorkingSet64
```

Or using the comparison syntax for the filter:

```powershell
Get-Process |
    Where-Object WorkingSet64 -gt 100MB |
    Select-Object Name, Id, WorkingSet64
```

### Expected Output

```
Name          Id WorkingSet64
----          -- ------------
chrome      1234    524288000
code        5678    314572800
pwsh        9012    157286400
...
```

Results vary by system. The important thing is that every row's `WorkingSet64`
value is greater than `104857600` (100 * 1024 * 1024).

### What to notice

`100MB` is a PowerShell numeric literal -- the language understands `1KB`, `1MB`,
`1GB`, `1TB`, and `1PB` directly. This is not a string suffix; it is a real
numeric constant. `100MB` equals `104857600` at parse time, so the comparison
is a plain integer comparison at runtime. No string parsing, no unit conversion
ceremony.

The comparison syntax form (`Where-Object WorkingSet64 -gt 100MB`) is cleaner
for single-property comparisons, but it cannot handle compound conditions
(`-and`, `-or`) or any expression beyond a property name on the left side.
When in doubt, use the script block form -- it is never wrong.

---

## Ch-08, Ex-2 (Normal)

**Task:** Use `Group-Object` combined with `Measure-Object` to calculate the
average CPU time per process-name group. Output a `PSCustomObject` per group
with `Category` and `Average`. Sort by average descending.

### Solution

```powershell
Get-Process |
    Group-Object Name |
    ForEach-Object {
        [PSCustomObject]@{
            Category = $_.Name
            Average  = [math]::Round(
                ($_.Group | Measure-Object CPU -Average).Average, 3
            )
        }
    } |
    Sort-Object Average -Descending
```

### Expected Output

```
Category         Average
--------         -------
chrome           412.733
code             198.441
SearchIndexer     87.200
pwsh              12.005
...
```

Your numbers will differ. Processes with multiple instances (like `chrome`)
will have their CPU values averaged across all instances sharing that name.

### What to notice

Inside `ForEach-Object`, `$_` is a `GroupInfo` object. Its `.Group` property
is the array of original process objects belonging to that group. You pipe
that array into `Measure-Object CPU -Average` to get the average, then access
`.Average` on the result.

`Measure-Object` returns `$null` for `.Average` if the property contains no
numeric values (e.g., all `$null`). The `[math]::Round()` call would throw
in that case. In production code, guard with a null check:
`if ($null -ne $avg) { ... }`. For this exercise, all processes have a
numeric `CPU` value, so it is safe.

---

## Ch-08, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Build a `Select-Object` pipeline against `Get-Process` that adds a
`MemoryMB` calculated property (WorkingSet64 in MB, rounded to 2 decimal places),
alongside `Name` and `Id`. Verify via `Get-Member` that `MemoryMB` is a
`NoteProperty`.

### Solution

```powershell
$result = Get-Process | Select-Object Name, Id, @{
    Name       = 'MemoryMB'
    Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) }
}

# Spot-check the first result
$result[0]

# Verify the property type
$result[0] | Get-Member -Name MemoryMB
```

### Expected Output

```
Name     Id MemoryMB
----     -- --------
chrome 1234   512.34
code   5678   302.11
pwsh   9012   154.88

   TypeName: Selected.System.Diagnostics.Process

Name     MemberType   Definition
----     ----------   ----------
MemoryMB NoteProperty double MemoryMB=512.34
```

The `TypeName` changes to `Selected.System.Diagnostics.Process` -- PowerShell
wraps the original type to indicate it has been shaped by `Select-Object`.

### What to notice

Several things worth internalizing here:

1. **NoteProperty vs ScriptProperty** -- A `NoteProperty` is a simple stored
   value attached to the object. A `ScriptProperty` would be a live script
   block that re-evaluates on every access. `Select-Object` bakes the
   expression result in as a `NoteProperty` at selection time. The division and
   rounding happen once, not repeatedly.

2. **Short-form keys** -- `@{N='MemoryMB'; E={...}}` is identical to
   `@{Name='MemoryMB'; Expression={...}}`. Both `N` and `Name` are accepted,
   as are `E` and `Expression`. The short form is idiomatic in one-liners; the
   long form reads better in multi-line scripts or documentation.

3. **`/1MB` is exact** -- `1MB` is `1048576` (2^20), not `1000000`. PowerShell
   uses binary prefixes (powers of 2), consistent with how operating systems
   report memory. If you ever need decimal megabytes (powers of 10), divide by
   `1000000` explicitly and comment why.

4. **Chaining `Select-Object`** -- You can call `Select-Object` twice in a
   pipeline. The first pass might add calculated properties; a second might
   reduce the property set further. This is occasionally useful but can hurt
   readability. Prefer combining both operations into a single `Select-Object`
   when possible.

---

## Ch-08, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Write a single pipeline expression that sources data, groups by
`Source`, calculates `Count` and `AvgDuration` per group via `Measure-Object`,
exports to CSV, re-imports, and verifies row count matches group count.

### Solution

```powershell
$tempCsv = Join-Path $env:TEMP "pipeline-deep-dive-$(Get-Random).csv"

# Synthetic data (Get-WinEvent is a Windows-only live source)
$sourceData = @(
    [PSCustomObject]@{ Source = 'ApplicationA'; Duration = 120 },
    [PSCustomObject]@{ Source = 'ApplicationA'; Duration = 240 },
    [PSCustomObject]@{ Source = 'ApplicationA'; Duration = 180 },
    [PSCustomObject]@{ Source = 'DatabaseB';    Duration = 55  },
    [PSCustomObject]@{ Source = 'DatabaseB';    Duration = 75  },
    [PSCustomObject]@{ Source = 'NetworkC';     Duration = 400 }
)

$sourceData |
    Group-Object Source |
    ForEach-Object {
        [PSCustomObject]@{
            Source      = $_.Name
            Count       = $_.Count
            AvgDuration = [math]::Round(
                ($_.Group | Measure-Object Duration -Average).Average, 2
            )
        }
    } |
    Export-Csv -Path $tempCsv -NoTypeInformation

$imported = Import-Csv $tempCsv
"Groups exported : $($imported.Count)"
"AvgDuration present: $($imported[0].PSObject.Properties.Name -contains 'AvgDuration')"

# Cleanup
Remove-Item $tempCsv -ErrorAction SilentlyContinue
```

### Expected Output

```
Groups exported : 3
AvgDuration present: True
```

### What to notice

1. **CSV round-trip type loss** -- `Export-Csv` serializes everything as
   strings. When you re-import with `Import-Csv`, `Count` and `AvgDuration`
   come back as `[string]`, not `[int]` or `[double]`. If you need to do math
   on re-imported data, cast explicitly: `[double]$imported[0].AvgDuration`.
   This is a constant source of subtle bugs. Know it going in.

2. **`-NoTypeInformation`** -- Without this flag, `Export-Csv` adds a `#TYPE`
   comment as the first line. That comment breaks many downstream CSV consumers.
   Always use `-NoTypeInformation` in scripts unless you specifically need the
   type hint for PowerShell-to-PowerShell round-trips.

3. **`Join-Path $env:TEMP`** -- Hard-coding `C:\Temp` or `/tmp` makes scripts
   non-portable. `$env:TEMP` is the current user's temporary directory on any
   platform. Always use it for scratch files in scripts.

4. **`Get-Random` in file names** -- Appending a random number prevents
   collisions when the script runs concurrently (e.g., in parallel Pester test
   runs). It is a light alternative to a full UUID/GUID when uniqueness within
   a session is sufficient.

5. **Replacing synthetic data with live event data** -- In a real environment,
   replace the `$sourceData` block with:
   ```powershell
   Get-WinEvent -LogName Application -MaxEvents 500 |
       Select-Object ProviderName, @{N='Duration'; E={1}} |
       ...
   ```
   The pipeline structure stays identical; only the source changes. This is the
   composability benefit of building pipelines around `[PSCustomObject]` shapes.
