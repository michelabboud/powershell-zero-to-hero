# Chapter 08: The Pipeline Deep Dive

Sam has achieved something remarkable. Nobody is quite sure if it's art or a
cry for help.

![chapter-opener](assets/images/ch-08-opener.png)

---

## How the Pipeline Actually Works

You've been using the pipeline since Chapter 03. Now we go under the hood.

When you write `Get-Process | Where-Object { $_.CPU -gt 10 }`, PowerShell does
something that surprises most people coming from Bash: it does **not** wait for
`Get-Process` to finish before starting `Where-Object`. The two cmdlets run
**concurrently**, connected by an object queue. As soon as `Get-Process`
produces the first process object, it drops it on the queue and `Where-Object`
picks it up immediately.

This is called **streaming execution**, and it has two practical consequences:

1. **Memory efficiency** -- you never have all objects in RAM at once (unless
   you force it by assigning to a variable).
2. **Early termination** -- `Select-Object -First 5` can stop the pipeline the
   moment it has enough data. `Get-Process` never needs to enumerate everything.

The visual model is a conveyor belt -- but it's a *live* belt, not a batch
loader.

![pipeline-conveyor](assets/images/ch-08-conveyor.png)

### The Pipeline Variable: `$_` and `$PSItem`

Inside a script block in a pipeline, the current object is always available as
`$_`. Its formal alias is `$PSItem` -- they are identical, and `$_` wins on
brevity in every practical scenario.

```powershell
# $_ is the object currently flowing through the pipe
Get-Process | Where-Object { $_.CPU -gt 5 }

# $PSItem is exactly the same thing, just more readable for beginners
Get-Process | Where-Object { $PSItem.CPU -gt 5 }
```

Use `$PSItem` in teaching contexts or shared code where clarity matters. Use
`$_` in everything else, because you will be typing it five hundred times a day.

---

## Where-Object: The Gatekeeper

`Where-Object` (alias: `?`) filters objects from the pipeline. Only objects for
which the condition evaluates to `$true` continue downstream.

```powershell
# Verbose syntax -- explicit script block with $_
Get-Process | Where-Object { $_.WorkingSet64 -gt 100MB }

# Comparison syntax -- cleaner for simple property comparisons
Get-Process | Where-Object WorkingSet64 -gt 100MB

# Alias: ? (the question mark asks "does this pass?")
Get-Process | ? { $_.WorkingSet64 -gt 100MB }
```

The comparison syntax (without braces) is syntactic sugar introduced in
PowerShell 3.0. It only works for simple one-property comparisons. The moment
you need `and`, `or`, or any expression, you go back to the script block form.

```powershell
# Compound condition -- needs the script block
Get-Process | Where-Object { $_.WorkingSet64 -gt 100MB -and $_.CPU -gt 10 }

# String match with -like
Get-Service | Where-Object { $_.DisplayName -like '*Windows*' }

# Null check -- filter out empty properties
Get-Process | Where-Object { $null -ne $_.MainWindowTitle }
```

> **Performance rule: filter left.** Put `Where-Object` as early in the
> pipeline as possible. Every object that doesn't make it past the filter saves
> all downstream cmdlets from doing unnecessary work. On large datasets, this
> matters enormously.

---

## ForEach-Object: The Worker

`ForEach-Object` (alias: `%`) runs a script block against every object in the
pipeline. Unlike assigning to a variable and using a `foreach` loop,
`ForEach-Object` maintains streaming -- it processes one object at a time.

```powershell
# Basic usage: restart every stopped service (careful with this one)
Get-Service | Where-Object Status -eq 'Stopped' | ForEach-Object {
    Write-Host "Would restart: $($_.Name)"
}

# Alias: %
1..5 | % { $_ * $_ }   # Squares: 1, 4, 9, 16, 25

# Three-block form: Begin / Process / End
Get-Process | ForEach-Object `
    -Begin   { $total = 0 } `
    -Process { $total += $_.WorkingSet64 } `
    -End     { "Total memory: $([math]::Round($total/1MB)) MB" }
```

The `-Begin` block runs once before any objects arrive. The `-Process` block
runs once per object. The `-End` block runs once after all objects are consumed.
This is how you accumulate state across a streaming pipeline without breaking
the stream.

---

## Select-Object: The Sculptor

`Select-Object` does three distinct things, and knowing all three is what
separates pipeline users from pipeline artists.

### 1. Choose Properties

```powershell
# Only return Name and CPU from each process object
Get-Process | Select-Object Name, CPU, WorkingSet64
```

This does not filter rows -- it shapes columns. The resulting objects have only
the properties you named.

### 2. First, Last, Skip, Unique

```powershell
# First N objects (can short-circuit the pipeline)
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Last N objects
Get-EventLog -LogName System -Newest 100 | Select-Object -Last 5

# Skip the first N, take the rest
Get-ChildItem | Select-Object -Skip 10

# Skip AND take
Get-ChildItem | Select-Object -Skip 5 -First 10  # items 6-15

# Deduplicate by value
'Alpha','Beta','Alpha','Gamma' | Select-Object -Unique
```

### 3. Calculated Properties

This is the feature that makes people realize PowerShell is genuinely powerful.
A calculated property is a hashtable with a `Name` (or `N`) key and an
`Expression` (or `E`) key. The expression is a script block evaluated against
each object.

```powershell
# Convert WorkingSet64 bytes to megabytes, rounded to 2 decimal places
Get-Process | Select-Object Name, @{
    Name       = 'MemoryMB'
    Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) }
}
```

```powershell
# Combine two properties into one
Get-Process | Select-Object @{
    N = 'Label'
    E = { "$($_.Name) (PID $($_.Id))" }
}, CPU
```

```powershell
# Short form: N= and E= work as aliases for Name= and Expression=
Get-ChildItem | Select-Object Name, @{N='SizeKB'; E={[math]::Round($_.Length/1KB,1)}}
```

Calculated properties are how you reshape data mid-pipeline without writing to
a variable, creating a function, or breaking the stream. They are used
constantly in real-world automation.

---

## Sort-Object: Ordering the Chaos

`Sort-Object` sorts by one or more properties. By default, ascending. Add
`-Descending` to flip it.

```powershell
# Sort processes by working set, largest first
Get-Process | Sort-Object WorkingSet64 -Descending

# Sort by multiple keys: primary descending, secondary ascending
Get-Process | Sort-Object @{E='CPU'; D=$true}, @{E='Name'; D=$false}

# Sort strings case-insensitively (default) vs case-sensitively
'banana','Apple','cherry' | Sort-Object
'banana','Apple','cherry' | Sort-Object -CaseSensitive

# Remove duplicates while sorting
1,3,2,3,1 | Sort-Object -Unique
```

Multi-key sorting uses an array of hashtables. Each hashtable has an `E`
(expression) key and a `D` (descending) key. This looks awkward but it reads
well once you accept it: "sort by CPU descending, then by Name ascending."

---

## Group-Object: The Analyst

`Group-Object` groups pipeline objects by the value of a property (or expression).
Each group becomes a `GroupInfo` object with a `Name`, a `Count`, and a `Group`
array containing the original objects.

```powershell
# Group services by status
Get-Service | Group-Object Status

# Group processes by their first letter (using a script block)
Get-Process | Group-Object { $_.Name.Substring(0,1).ToUpper() }

# Count files by extension
Get-ChildItem -File | Group-Object Extension | Sort-Object Count -Descending

# Access the grouped objects themselves
$byStatus = Get-Service | Group-Object Status
$byStatus | ForEach-Object {
    "Status: $($_.Name) | Count: $($_.Count)"
}
```

`Group-Object` is your go-to for any "how many of each" question. Combine it
with `Measure-Object` (next section) to answer "how many, and what are the
aggregate stats per group."

---

## Measure-Object: The Statistician

`Measure-Object` computes aggregate statistics across a collection of objects.
It can count, sum, average, find the minimum, and find the maximum.

```powershell
# Count objects (the simplest use)
Get-Process | Measure-Object

# Sum and average a numeric property
Get-Process | Measure-Object CPU -Sum -Average -Maximum -Minimum

# Count lines/words/characters in text
Get-Content ./README.md | Measure-Object -Line -Word -Character
```

`Measure-Object` returns a `GenericMeasureInfo` object with properties like
`Count`, `Sum`, `Average`, `Maximum`, `Minimum`. You access these via dot
notation:

```powershell
$stats = Get-Process | Measure-Object CPU -Sum -Average
"Total CPU:   $($stats.Sum)"
"Average CPU: $([math]::Round($stats.Average, 2))"
```

### Group + Measure Pattern

This combination answers "what are the stats per category?" and you will use it
constantly:

```powershell
# Average CPU per process group (by first character of name)
Get-Process | Group-Object { $_.Name[0].ToString().ToUpper() } | ForEach-Object {
    [PSCustomObject]@{
        Group      = $_.Name
        Count      = $_.Count
        AvgCPU     = [math]::Round(($_.Group | Measure-Object CPU -Average).Average, 3)
        TotalMemMB = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 1)
    }
} | Sort-Object TotalMemMB -Descending
```

This is a complete mini-analytics pipeline: group, measure each group, build a
shaped result object, sort. Four conceptual stages, one expression.

---

## Tee-Object: The Wiretap

`Tee-Object` is named after the T-shaped pipe fitting. It passes objects through
unchanged *and simultaneously* captures them to a variable or a file. It lets
you inspect what's flowing through a pipeline without breaking the flow.

```powershell
# Capture to a variable while continuing the pipeline
Get-Process |
    Tee-Object -Variable allProcs |
    Where-Object { $_.WorkingSet64 -gt 100MB }

# $allProcs now holds ALL processes; the pipeline continues with filtered ones
"Total processes: $($allProcs.Count)"

# Capture to a file (appends one object per line as text)
Get-Process | Tee-Object -FilePath ./process-snapshot.txt | Select-Object -First 5
```

`Tee-Object` is invaluable for debugging long pipelines. Insert it between two
stages to capture the intermediate state:

```powershell
Get-Service |
    Tee-Object -Variable beforeFilter |
    Where-Object Status -eq 'Running' |
    Tee-Object -Variable afterFilter |
    Sort-Object DisplayName
```

Now `$beforeFilter` and `$afterFilter` both exist after the pipeline completes,
and you can inspect them to see exactly where objects dropped out.

---

## Pipeline Performance: The Two Golden Rules

### Rule 1: Filter Left

Every object that doesn't pass a filter saves all downstream cmdlets from
processing it. The earlier you filter, the less work everything else does.

```powershell
# Slow: fetches all 10,000 events, THEN filters
Get-EventLog -LogName Application -Newest 10000 | Where-Object EntryType -eq 'Error'

# Fast: filters at the source, only fetches what you need
Get-EventLog -LogName Application -Newest 10000 -EntryType Error
```

When a cmdlet has native parameters that do the filtering (like `-EntryType`,
`-Filter`, `-Include`, `-Exclude`), use those instead of `Where-Object`. The
cmdlet does the filtering before objects even enter the pipeline.

### Rule 2: Format Right

`Format-Table`, `Format-List`, and `Format-Wide` produce **formatting directive
objects**, not data objects. Once you call them, the pipeline contains
presentation instructions, not your original data. Nothing useful can process
those downstream.

```powershell
# Wrong: Format-Table kills the pipeline data
Get-Process | Format-Table Name, CPU | Export-Csv ./out.csv  # Export-Csv gets garbage

# Right: Format-Table goes last, only for display
Get-Process | Export-Csv ./out.csv  # Save real data first
Get-Process | Format-Table Name, CPU  # Then display if you want to see it
```

The rule is simple: `Format-*` is always the last thing in the pipeline.
Always. No exceptions.

---

## Putting It All Together

Here is the shape of a complete analytics pipeline that uses every concept from
this chapter:

```powershell
Get-Process |
    Where-Object { $_.WorkingSet64 -gt 10MB } |          # filter left
    Select-Object Name, CPU, @{                           # calculated property
        N = 'MemMB'
        E = { [math]::Round($_.WorkingSet64 / 1MB, 1) }
    } |
    Group-Object { if ($_.MemMB -gt 200) { 'Heavy' } else { 'Normal' } } |
    ForEach-Object {
        [PSCustomObject]@{
            Tier    = $_.Name
            Count   = $_.Count
            AvgMem  = [math]::Round(($_.Group | Measure-Object MemMB -Average).Average, 1)
            TotalMem = ($_.Group | Measure-Object MemMB -Sum).Sum
        }
    } |
    Sort-Object TotalMem -Descending |
    Tee-Object -Variable tierSummary |
    Format-Table -AutoSize                                # format right
```

After this runs, `$tierSummary` holds the data objects, and the terminal shows
a formatted table. Data and display are both available.

---

## Exercises

### [Ch-08, Ex-1] Simple: Filter Heavy Processes

Use `Where-Object` to find all processes currently using more than 100MB of
working memory. Display only the `Name`, `Id`, and `WorkingSet64` properties.

### [Ch-08, Ex-2] Normal: Average CPU Per Group

Use `Group-Object` combined with `Measure-Object` to calculate the average CPU
time per process-name group. Output a `PSCustomObject` per group containing
`Category` and `Average`. Sort by average descending.

### [Ch-08, Ex-3] Advanced: Calculated Property in Select-Object

> <!-- tier: advanced -->

Build a `Select-Object` pipeline against `Get-Process` that adds a calculated
property `MemoryMB` which is `WorkingSet64` converted to megabytes and rounded
to 2 decimal places. The result should include `Name`, `Id`, and `MemoryMB`.
Verify via `Get-Member` that `MemoryMB` is a `NoteProperty` on the result objects.

### [Ch-08, Ex-4] Extreme: Event Pipeline to CSV

> <!-- tier: extreme -->

Write a single pipeline expression (no intermediate variables, except an
optional `$tempCsv` for the output path) that:

1. Sources data (use a synthetic array of `[PSCustomObject]` if live event logs
   are not available in your environment)
2. Groups by `Source`
3. Calculates `Count` and `AvgDuration` per group via `Measure-Object`
4. Exports the result to a CSV file
5. Re-imports the CSV and verifies the row count matches the number of groups

---

## Key Takeaways

- The pipeline is **streaming** -- objects flow through concurrently, not in
  batches. Early termination and memory efficiency follow from this.
- `$_` / `$PSItem` is the current object inside any pipeline script block.
- **Filter left with `Where-Object`**, or better: use source cmdlet parameters.
- **Format right** -- `Format-*` cmdlets always go last or not at all.
- `Where-Object` gates objects; `ForEach-Object` transforms them; `Select-Object`
  shapes them; `Sort-Object` orders them; `Group-Object` buckets them;
  `Measure-Object` aggregates them; `Tee-Object` taps them.
- Calculated properties in `Select-Object` let you reshape data mid-stream
  using `@{Name='...'; Expression={...}}`.
- `Group-Object` + `Measure-Object` inside a `ForEach-Object` is the canonical
  pattern for per-group statistics.

---

*Next up: [Chapter 09 -- Functions and Script Blocks](09-functions-and-script-blocks.md),
where we learn to stop writing the same pipeline twelve times and start writing
it once.*
