# Chapter 06: Control Flow

> *The difference between a script and a program is that a program knows when to stop repeating itself.*

![chapter-opener](assets/images/ch-06-opener.png)

---

## What You'll Learn

- `if` / `elseif` / `else` for branching logic
- `switch` with simple values, wildcards, regex, and file input
- `for`, `foreach`, and `while` loops
- `do-while` and `do-until` for post-condition loops
- `break` and `continue` for fine-grained loop control
- `ForEach-Object` in the pipeline
- Labeled loops for nested break/continue

---

## 1. Branching: `if` / `elseif` / `else`

The classic conditional. PowerShell's syntax will feel familiar if you've touched C, Python, or JavaScript -- with one twist: comparison operators are words, not symbols.

```powershell
$temp = 37

if ($temp -gt 38) {
    Write-Host "Server is overheating!" -ForegroundColor Red
}
elseif ($temp -gt 35) {
    Write-Host "Temperature is elevated -- keep an eye on it." -ForegroundColor Yellow
}
else {
    Write-Host "Temperature nominal." -ForegroundColor Green
}
```

```
Temperature is elevated -- keep an eye on it.
```

### Comparison operators at a glance

| Operator | Meaning | Example |
|----------|---------|---------|
| `-eq` | Equal | `$x -eq 5` |
| `-ne` | Not equal | `$x -ne 0` |
| `-gt` | Greater than | `$x -gt 10` |
| `-lt` | Less than | `$x -lt 100` |
| `-ge` | Greater or equal | `$x -ge 1` |
| `-le` | Less or equal | `$x -le 255` |
| `-like` | Wildcard match | `$s -like 'web*'` |
| `-match` | Regex match | `$s -match '^\d{3}'` |
| `-in` | In collection | `$s -in @('a','b','c')` |
| `-not` / `!` | Negation | `-not $flag` |

> **Rina's note:** Coming from Python, the `-eq` syntax feels verbose. Coming from Bash,
> it feels refreshingly readable. After a week you stop noticing. After a month you wonder
> why every other language uses `==` for comparison and `=` for assignment in the same scope.

### Logical operators

```powershell
# -and, -or, -not, -xor
if ($IsWindows -and ($PSVersionTable.PSVersion.Major -ge 7)) {
    Write-Host "Modern PowerShell on Windows. Nice."
}

if (-not $IsLinux) {
    Write-Host "Not Linux -- consider your life choices."
}
```

---

## 2. `switch`: The Statement Sam Should Have Used

When you find yourself writing three or more `elseif` branches on the same variable, that's
PowerShell asking you politely -- then firmly -- to use `switch`.

### Basic switch

```powershell
$day = (Get-Date).DayOfWeek.ToString()

switch ($day) {
    'Monday'    { Write-Host "Back to the mines." }
    'Friday'    { Write-Host "Freedom is imminent." }
    'Saturday'  { Write-Host "No alerts, please." }
    'Sunday'    { Write-Host "Pre-Monday anxiety loading..." }
    default     { Write-Host "Mid-week. Coffee helps." }
}
```

### Wildcard switch (`-Wildcard`)

```powershell
$hostname = 'web-prod-03'

switch -Wildcard ($hostname) {
    'web-*'  { Write-Host "$hostname is a web server." }
    'db-*'   { Write-Host "$hostname is a database server." }
    'app-*'  { Write-Host "$hostname is an app server." }
    default  { Write-Host "$hostname: unknown role." }
}
```

```
web-prod-03 is a web server.
```

> **Note:** Without `-Wildcard`, `web-*` is treated as a literal string -- not a pattern.
> PowerShell won't warn you. This is a classic gotcha.

### Regex switch (`-Regex`)

![switch-flowchart](assets/images/ch-06-switch-modes.png)

```powershell
$logLine = '2026-03-17 ERROR disk usage at 95%'

switch -Regex ($logLine) {
    'FATAL|CRITICAL' { Write-Host "CRITICAL: Page the on-call." -ForegroundColor Red;    break }
    'ERROR'          { Write-Host "ERROR: Create a ticket."     -ForegroundColor Red;    break }
    'WARN'           { Write-Host "WARNING: Add to backlog."    -ForegroundColor Yellow; break }
    'INFO'           { Write-Host "Info: Log and move on."      -ForegroundColor Cyan;   break }
    default          { Write-Host "Unknown format. Investigate." }
}
```

```
ERROR: Create a ticket.
```

**Important:** Without `break`, PowerShell's `switch` keeps evaluating. Unlike `switch`
in C or Java, it does **not** stop at the first match by default. Every matching arm runs.
For log severity classification this is a bug, not a feature. Use `break` liberally.

### switch with multiple matching values

```powershell
# This is intentional -- no break
$permissions = @('Read', 'Write', 'Execute')

foreach ($perm in $permissions) {
    switch ($perm) {
        'Read'    { Write-Host "Can read files." }
        'Write'   { Write-Host "Can modify files." }
        'Execute' { Write-Host "Can run scripts." }
    }
}
```

### switch on a file (`-File`)

```powershell
# Process each line of a file as a switch value
switch -Regex -File '/var/log/app.log' {
    'FATAL' { Write-Host "FATAL found: $_" -ForegroundColor Red }
    'ERROR' { Write-Host "Error found: $_" }
}
```

`$_` inside a `-File` switch is the current line. This is PowerShell doing what PowerShell
does: turning a tedious `Get-Content | ForEach-Object` loop into one clean statement.

---

## 3. Loops

### `for` -- when you know the count

```powershell
for ($i = 0; $i -lt 5; $i++) {
    Write-Host "Iteration $i"
}
```

```
Iteration 0
Iteration 1
Iteration 2
Iteration 3
Iteration 4
```

Use `for` when you need an explicit counter -- array indexing, retry logic with a ceiling,
generating numbered files. For everything else, `foreach` is usually cleaner.

### `foreach` -- iterating collections

```powershell
$servers = @('web01', 'db01', 'app01', 'cache01')

foreach ($server in $servers) {
    Write-Host "Pinging $server..."
    # Test-Connection $server -Count 1 -Quiet
}
```

`foreach` is not a cmdlet -- it's a language keyword. It does **not** accept pipeline input.
It is, however, faster than `ForEach-Object` for in-memory collections because it doesn't
create a pipeline.

### `while` -- condition-first loop

```powershell
$retries = 0
$maxRetries = 5
$connected = $false

while (-not $connected -and $retries -lt $maxRetries) {
    Write-Host "Connection attempt $($retries + 1)..."
    # $connected = Test-Connection db01 -Count 1 -Quiet
    $retries++
    Start-Sleep -Seconds 2
}

if ($connected) {
    Write-Host "Connected."
} else {
    Write-Host "Failed after $retries attempts." -ForegroundColor Red
}
```

The condition is checked **before** each iteration. If it's false from the start, the body
never runs. That's the right behavior when "zero iterations" is a valid outcome.

### `do-while` and `do-until` -- condition-last loops

```powershell
# do-while: runs at least once, continues WHILE condition is true
$serverNameInput = ''
do {
    $serverNameInput = Read-Host "Enter a server name (or 'done' to finish)"
    if ($serverNameInput -ne 'done') {
        Write-Host "Queued: $serverNameInput"
    }
} while ($serverNameInput -ne 'done')

# do-until: runs at least once, continues UNTIL condition becomes true
$attempts = 0
do {
    $attempts++
    Write-Host "Attempt $attempts..."
    $success = ($attempts -ge 3)  # Simulate success on 3rd try
} until ($success)

Write-Host "Succeeded on attempt $attempts."
```

```
Attempt 1...
Attempt 2...
Attempt 3...
Succeeded on attempt 3.
```

> **Max's rule:** If the loop must run at least once -- user prompts, connection warmup,
> first-attempt execution -- use `do`. If "zero iterations" is valid, use `while`. Getting
> this wrong wastes CPU cycles at best and causes infinite loops at worst.

---

## 4. Loop Control: `break` and `continue`

![loop-decision](assets/images/ch-06-loop-decision.png)

### `break` -- exit the loop immediately

```powershell
$servers = @('web01', 'db01', 'CRITICAL-db02', 'app01')

foreach ($server in $servers) {
    if ($server -like 'CRITICAL-*') {
        Write-Host "Critical server found: $server -- halting scan." -ForegroundColor Red
        break
    }
    Write-Host "Scanned: $server"
}
```

```
Scanned: web01
Scanned: db01
Critical server found: CRITICAL-db02 -- halting scan.
```

### `continue` -- skip this iteration, resume with the next

```powershell
$servers = @('web01', '', 'db01', $null, 'app01')

foreach ($server in $servers) {
    if ([string]::IsNullOrEmpty($server)) {
        Write-Host "(skipping empty entry)"
        continue
    }
    Write-Host "Processing: $server"
}
```

```
Processing: web01
(skipping empty entry)
Processing: db01
(skipping empty entry)
Processing: app01
```

### Labeled loops -- breaking out of nested loops

Unlabeled `break` only exits the **innermost** loop. When you need to escape all the way
out of a nested structure, use labels.

```powershell
:outerLoop foreach ($datacenter in @('DC1', 'DC2', 'DC3')) {
    foreach ($rack in @('Rack-A', 'Rack-B')) {
        if ($datacenter -eq 'DC2' -and $rack -eq 'Rack-B') {
            Write-Host "Found the problem rack: $datacenter / $rack -- stopping all scans."
            break outerLoop
        }
        Write-Host "Scanned: $datacenter / $rack"
    }
}
Write-Host "Scan complete."
```

```
Scanned: DC1 / Rack-A
Scanned: DC1 / Rack-B
Scanned: DC2 / Rack-A
Found the problem rack: DC2 / Rack-B -- stopping all scans.
Scan complete.
```

Labels work with `continue` too: `continue outerLoop` skips the rest of the inner loop and
moves to the next iteration of the outer one.

---

## 5. `ForEach-Object` -- Looping in the Pipeline

The `foreach` keyword is fast but disconnected from the pipeline. `ForEach-Object` (alias
`%`) lives in the pipeline and processes objects as they stream through.

```powershell
# Pipeline-style: objects flow through
Get-Process | Where-Object CPU -gt 1 | ForEach-Object {
    Write-Host "$($_.Name) has used $([math]::Round($_.CPU, 1)) CPU seconds."
}

# Equivalent foreach keyword (no pipeline, in-memory):
$activeProcesses = Get-Process | Where-Object CPU -gt 1
foreach ($process in $activeProcesses) {
    Write-Host "$($process.Name) has used $([math]::Round($process.CPU, 1)) CPU seconds."
}
```

### `ForEach-Object` with `-Begin`, `-Process`, `-End`

```powershell
1..5 | ForEach-Object -Begin {
    Write-Host "--- Starting batch ---"
    $sum = 0
} -Process {
    $sum += $_
    Write-Host "  Added $_ (running total: $sum)"
} -End {
    Write-Host "--- Final total: $sum ---"
}
```

```
--- Starting batch ---
  Added 1 (running total: 1)
  Added 2 (running total: 3)
  Added 3 (running total: 6)
  Added 4 (running total: 10)
  Added 5 (running total: 15)
--- Final total: 15 ---
```

### Parallel `ForEach-Object` (PowerShell 7+)

```powershell
# Process 4 servers simultaneously instead of one by one
$servers = @('web01', 'db01', 'app01', 'cache01')

$results = $servers | ForEach-Object -Parallel {
    $ping = Test-Connection $_ -Count 1 -Quiet -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Server = $_
        Online = $ping
    }
} -ThrottleLimit 4

$results | Format-Table -AutoSize
```

> **Rina:** In Python this would need `asyncio` or `concurrent.futures`. In Bash you'd
> background jobs and wait. In PowerShell 7 it's one flag. I still resent it a little.

`-Parallel` uses separate runspaces. Output order isn't guaranteed, and values
from the caller's scope must be referenced with `$using:`. Use it for work
large enough to justify the startup and serialization overhead, not for tiny
in-memory calculations.

---

## 6. Choosing the Right Loop

| Scenario | Recommended construct |
|----------|----------------------|
| Fixed-count iteration (0 to N) | `for` |
| Iterating a known collection | `foreach` |
| Streaming pipeline objects | `ForEach-Object` |
| Polling until a condition | `while` or `do-until` |
| User prompt / must-run-once | `do-while` |
| Parallel processing | `ForEach-Object -Parallel` |
| Pattern-matching on a value | `switch` |
| Multi-branch on same variable | `switch` (not `if`/`elseif`) |

---

## Exercises

### [Ch-06, Ex-1] Simple: Categorize a Number

Write a function using `if`/`elseif`/`else` that takes an integer and returns the string
`'Negative'`, `'Zero'`, or `'Positive'`.

```powershell
function Get-NumberCategory {
    param([int]$Number)
    if ($Number -lt 0) { 'Negative' }
    elseif ($Number -eq 0) { 'Zero' }
    else { 'Positive' }
}

Get-NumberCategory -Number -5    # Negative
Get-NumberCategory -Number 0     # Zero
Get-NumberCategory -Number 42    # Positive
```

**Expected output:**
```
Negative
Zero
Positive
```

---

### [Ch-06, Ex-2] Normal: Classify Log Severity with `switch -Regex`

Write a function `Get-Severity` that accepts a log line string and returns the severity
label using a `switch -Regex` statement.

```powershell
function Get-Severity {
    param([string]$Line)
    switch -Regex ($Line) {
        'FATAL|CRITICAL' { 'Critical'; break }
        'ERROR'          { 'Error'; break }
        'WARN'           { 'Warning'; break }
        'INFO'           { 'Info'; break }
        default          { 'Unknown' }
    }
}

Get-Severity '2026-03-17 ERROR disk full'      # Error
Get-Severity '2026-03-17 WARN low memory'      # Warning
Get-Severity '2026-03-17 FATAL process crash'  # Critical
Get-Severity '2026-03-17 DEBUG trace data'     # Unknown
```

**Expected output:**
```
Error
Warning
Critical
Unknown
```

Notice that `FATAL|CRITICAL` must come before `ERROR` -- if the pattern `ERROR` appeared
first and a line contained `CRITICAL ERROR`, you'd get `Error` instead of `Critical`.
Order of arms matters in `switch -Regex`.

---

### [Ch-06, Ex-3] Advanced: Process a Server List with `foreach` + `break`/`continue`

> <!-- tier: advanced -->
> Write a script that iterates a server list, skips null/empty entries using `continue`,
> and stops the entire loop if it encounters a server name starting with `OFFLINE-`.

```powershell
$servers = @('web01', '', 'db01', $null, 'OFFLINE-cache01', 'app01')
$processed = [System.Collections.Generic.List[string]]::new()

foreach ($server in $servers) {
    if ([string]::IsNullOrEmpty($server)) {
        Write-Host "(skip: empty entry)"
        continue
    }
    if ($server -like 'OFFLINE-*') {
        Write-Host "Encountered offline marker: $server -- stopping." -ForegroundColor Yellow
        break
    }
    Write-Host "Processing: $server"
    $processed.Add($server)
}

Write-Host "Processed $($processed.Count) server(s): $($processed -join ', ')"
```

**Expected output:**
```
Processing: web01
(skip: empty entry)
Processing: db01
(skip: empty entry)
Encountered offline marker: OFFLINE-cache01 -- stopping.
Processed 2 server(s): web01, db01
```

---

### [Ch-06, Ex-4] Extreme: Retry Loop with Exponential Backoff

> <!-- tier: extreme -->
> Build an `Invoke-WithRetry` function that accepts a `[scriptblock]` and a `MaxRetries`
> parameter. On each failure, wait `2^attempt * 100ms` before retrying (exponential backoff).
> If all retries are exhausted, rethrow the last exception.

```powershell
function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3
    )

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            return & $Action
        }
        catch {
            if ($i -eq ($MaxRetries - 1)) {
                throw  # Last attempt -- rethrow to caller
            }
            $delayMs = [math]::Pow(2, $i) * 100
            Write-Host "Attempt $($i + 1) failed: $($_.Exception.Message). Retrying in ${delayMs}ms..." -ForegroundColor Yellow
            Start-Sleep -Milliseconds $delayMs
        }
    }
}

# Test with a flaky operation that succeeds on the 3rd try
$script:callCount = 0
$result = Invoke-WithRetry -Action {
    $script:callCount++
    if ($script:callCount -lt 3) { throw "Simulated transient failure" }
    "Connected successfully"
} -MaxRetries 5

Write-Host $result
Write-Host "Total attempts: $script:callCount"
```

**Expected output:**
```
Attempt 1 failed: Simulated transient failure. Retrying in 100ms...
Attempt 2 failed: Simulated transient failure. Retrying in 200ms...
Connected successfully
Total attempts: 3
```

The backoff delays are 100ms, 200ms, 400ms, 800ms -- doubling each time. In production
you'd add jitter (randomized offset) to prevent thundering herd when dozens of services
retry simultaneously. That's an exercise left for the ops engineers reading this at 3 AM.

---

## Summary

You can now branch with `if`/`elseif`/`else` and collapse multi-branch logic into clean
`switch` statements -- with exact, wildcard, regex, or file-based matching. You have four
loop constructs: `for` (counter-driven), `foreach` (collection iteration), `while`
(condition-first), and `do` variants (condition-last, always runs once). `break` exits a
loop, `continue` skips an iteration, and labeled loops let you escape nested structures
without hacks. In the pipeline, `ForEach-Object` carries objects through instead of
breaking the stream -- and `-Parallel` adds runspace-based concurrency when
the workload justifies its overhead.

Control flow is where scripts stop being sequences of commands and start being programs
that make decisions. Sam's 200-line `if`/`elseif` chain is now a 10-line `switch`. Max
has gone back to his coffee.

---

*Next: [Chapter 07 -- Functions and Scripts](07-functions-and-scripts.md)*
