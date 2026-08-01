# Chapter 05 -- Answers

---

## Ch-05, Ex-1 (Simple)

**Task:** Compare `'Hello'` and `'hello'` using `-eq` and `-ceq`, explain the difference, and write a `Test-ExactMatch` function that returns `$true` only on a case-sensitive match.

### Solution

```powershell
# Part 1: observe the difference
'Hello' -eq 'hello'     # True  -- PowerShell string comparison is case-insensitive by default
'Hello' -ceq 'hello'    # False -- 'H' (0x48) != 'h' (0x68)

# Part 2: the function
function Test-ExactMatch {
    param([string]$A, [string]$B)
    $A -ceq $B
}

Test-ExactMatch -A 'Hello' -B 'hello'   # False
Test-ExactMatch -A 'Hello' -B 'Hello'   # True
```

### Expected Output

```
True
False
False
True
```

### What to notice

PowerShell's default string comparison is **culture-aware and case-insensitive**. This is a deliberate design choice for a shell that runs across Windows environments where `Get-ChildItem C:\Windows` and `Get-ChildItem c:\windows` must work identically. The unprefixed operators (`-eq`, `-ne`, `-gt`, etc.) all behave this way.

The `c` prefix forces an **ordinal byte-by-byte comparison** -- `H` (Unicode 0x48) and `h` (0x68) are different characters. The function body is a single expression: `$A -ceq $B` evaluates to a `[bool]` and PowerShell returns the last expression in a function implicitly.

This is also why you should reach for `-ceq` when comparing passwords, tokens, case-sensitive usernames, or file paths on Linux (where the filesystem itself is case-sensitive).

---

## Ch-05, Ex-2 (Normal)

**Task:** Create `1..20`, filter to numbers greater than 5 AND less than or equal to 15, verify the count is 10.

### Solution

```powershell
$nums = 1..20

$filtered = $nums | Where-Object { $_ -gt 5 -and $_ -le 15 }

"Count: $($filtered.Count)"
$filtered
```

### Expected Output

```
Count: 10
6
7
8
9
10
11
12
13
14
15
```

### What to notice

Three things happening here worth internalizing:

1. **Range operator `..`** -- `1..20` creates an `[int[]]` array in one token. Under the hood it calls `[System.Linq.Enumerable]::Range`. For small ranges this is instant; for `1..1000000` it still materializes the whole array in memory, so for very large sequences consider `foreach ($i in 1..1000000)` which enumerates lazily.

2. **`$_` in `Where-Object`** -- `$_` (or its alias `$PSItem`) refers to the current pipeline object. Inside `Where-Object { ... }`, the block must evaluate to a truthy value to pass the object through. Both conditions must be `$true` because `-and` requires both sides.

3. **Why 10?** The range 6..15 is inclusive on both ends: 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 -- ten integers. `$_ -gt 5` excludes 5, `$_ -le 15` includes 15. Nail this "off-by-one" intuition early.

---

## Ch-05, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Use `-match` with a regex pattern to extract date, time, severity, and component from a log line. Display results as a `[PSCustomObject]`.

### Solution

```powershell
$log = '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s'

if ($log -match '(\d{4}-\d{2}-\d{2})\s(\d{2}:\d{2}:\d{2})\s(\w+)\s\[(\w+)\]') {
    [PSCustomObject]@{
        Date      = $Matches[1]
        Time      = $Matches[2]
        Severity  = $Matches[3]
        Component = $Matches[4]
    }
}
```

### Expected Output

```
Date      : 2024-01-15
Time      : 14:30:22
Severity  : ERROR
Component : WebServer
```

### What to notice

The pattern breaks down as follows:

| Fragment | Matches |
|----------|---------|
| `(\d{4}-\d{2}-\d{2})` | Four digits, dash, two digits, dash, two digits -- ISO date |
| `\s` | Single whitespace separator |
| `(\d{2}:\d{2}:\d{2})` | HH:MM:SS time |
| `\s` | Whitespace |
| `(\w+)` | One or more word characters -- the severity level |
| `\s\[(\w+)\]` | A literal `[`, word characters, literal `]` -- component name |

`$Matches` is **automatically populated** by `-match` as a `[hashtable]`. `$Matches[0]` is always the full match; `$Matches[1]` through `$Matches[N]` are the capture groups in order. Named captures (`(?<date>\d{4}...)`) are also supported and populate `$Matches['date']` -- useful when you have many groups and positional indexing becomes error-prone.

The `if ($log -match ...)` idiom is idiomatic PowerShell: test the match *and* populate `$Matches` in one step, then use the results inside the block.

---

## Ch-05, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Build `Get-FilteredProcess` that accepts a hashtable of optional criteria and uses splatting, null-coalescing (`??`), and comparison operators to construct a dynamic, filtered process query.

### Solution

```powershell
function Get-FilteredProcess {
    param(
        [hashtable]$Criteria
    )

    # Conditionally build the splat -- only include Name if provided
    $splat = @{}
    if ($Criteria.Name) { $splat['Name'] = $Criteria.Name }

    # Use ?? to supply defaults for optional numeric criteria
    Get-Process @splat | Where-Object {
        $minCPU = $Criteria.MinCPU ?? 0
        $maxMem = $Criteria.MaxMemoryMB ?? [int]::MaxValue

        $_.CPU       -ge $minCPU -and
        ($_.WorkingSet64 / 1MB) -le $maxMem
    }
}

# Example calls
$result1 = Get-FilteredProcess -Criteria @{ Name = 'pwsh'; MinCPU = 0 }
$result1 | Select-Object Name, CPU, @{N='MemMB'; E={ [math]::Round($_.WorkingSet64/1MB,1) }}

$result2 = Get-FilteredProcess -Criteria @{ MaxMemoryMB = 50 }
"Processes using <= 50 MB: $($result2.Count)"

$result3 = Get-FilteredProcess -Criteria @{ MinCPU = 1; MaxMemoryMB = 500 }
"High-CPU, bounded memory processes: $($result3.Count)"
```

### Expected Output

```
# Result1 (your pwsh process)
Name  CPU  MemMB
----  ---  -----
pwsh  4.2  84.3

# Result2
Processes using <= 50 MB: 47

# Result3
High-CPU, bounded memory processes: 3
```

Exact numbers vary by system state.

### What to notice

Several patterns working together:

1. **Conditional splatting** -- `$splat['Name'] = $Criteria.Name` only runs when `$Criteria.Name` is truthy. `Get-Process @splat` then passes `-Name` only when it was added. Without splatting, you'd need nested `if/else` blocks to build the command call, or `Invoke-Expression` (which is a code smell). Splatting lets you build parameter sets dynamically and cleanly.

2. **`??` inside a script block** -- `$Criteria.MinCPU ?? 0` inside the `Where-Object` block is evaluated *per pipeline object*. This is fine for small process lists, but for performance-sensitive code, compute defaults *before* the pipeline and capture them in outer-scope variables. The block closure captures the outer variables automatically.

3. **`[int]::MaxValue` as a sentinel** -- when there is no upper bound on memory, using `.NET`'s maximum `int` value (`2,147,483,647`) means the `-le` comparison will always pass. This is safer than using `999999` or `[double]::PositiveInfinity` because `WorkingSet64 / 1MB` produces a `[double]` and the comparison still works correctly.

4. **`WorkingSet64 / 1MB`** -- `1MB` is `1048576` (a real PowerShell numeric constant). Dividing bytes by `1MB` gives megabytes as a `[double]`. `WorkingSet64` is the 64-bit working set property; always prefer it over `WorkingSet` on modern systems.

5. **The real lesson** -- this pattern (hashtable criteria + conditional splat + `??` defaults + operator composition) shows up constantly in production automation: user input is sparse, defaults must be safe, and you want one code path instead of a tree of `if/else`. This is the template.
