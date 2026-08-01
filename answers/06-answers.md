# Chapter 06 -- Answers

---

## Ch-06, Ex-1 (Simple)

**Task:** Write an `if`/`elseif`/`else` function that categorizes an integer as
`'Negative'`, `'Zero'`, or `'Positive'`.

### Solution

```powershell
function Get-NumberCategory {
    param([int]$Number)
    if ($Number -lt 0) { 'Negative' }
    elseif ($Number -eq 0) { 'Zero' }
    else { 'Positive' }
}

Get-NumberCategory -Number -5
Get-NumberCategory -Number 0
Get-NumberCategory -Number 42
```

### Expected Output

```
Negative
Zero
Positive
```

### What to notice

PowerShell functions return values implicitly -- there is no `return` keyword required when
the expression result is the last thing evaluated in a branch. Writing `'Negative'` as a
bare string expression puts that string on the output stream, which becomes the function's
return value when called from an assignment or pipeline.

The ordering of conditions matters: the `-lt 0` check comes first because if you put `else`
at the top you'd catch everything. Always order your conditions from most specific to most
general, or from smallest exclusive range to largest catch-all.

---

## Ch-06, Ex-2 (Normal)

**Task:** Use `switch -Regex` to classify a log line's severity level.

### Solution

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

Get-Severity '2026-03-17 ERROR disk full'
Get-Severity '2026-03-17 WARN low memory'
Get-Severity '2026-03-17 FATAL process crash'
Get-Severity '2026-03-17 DEBUG trace data'
```

### Expected Output

```
Error
Warning
Critical
Unknown
```

### What to notice

Three things to pay attention to here:

1. **`break` is mandatory for mutual exclusion.** Without `break`, PowerShell evaluates
   every arm of a `switch` that matches. A line containing `FATAL` also matches `ERROR`
   if the word appears anywhere in the line (e.g., `FATAL: ERROR details`). The `break`
   after each arm ensures only the first match fires.

2. **Arm order is a priority order.** `'FATAL|CRITICAL'` must appear before `'ERROR'`
   because regex matching is positional. If `ERROR` came first and a line read
   `CRITICAL ERROR: disk failure`, it would match `ERROR` first and return `'Error'`
   instead of the more urgent `'Critical'`. Treat the arms of a regex switch like
   exception handlers: most specific first.

3. **`default` needs no `break`.** It's already the last possible arm; falling through
   is not possible after `default`.

---

## Ch-06, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Iterate a server list, skip null/empty entries with `continue`, and halt
the loop with `break` when an `OFFLINE-*` server is encountered.

### Solution

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

### Expected Output

```
Processing: web01
(skip: empty entry)
Processing: db01
(skip: empty entry)
Encountered offline marker: OFFLINE-cache01 -- stopping.
Processed 2 server(s): web01, db01
```

### What to notice

`[string]::IsNullOrEmpty()` is the correct test for "either null or an empty string" -- do
not use `$server -eq ''` because that is false when `$server` is `$null`. PowerShell's
null handling is forgiving in many contexts but `$null -eq ''` is `$false`.

The `continue` and `break` paths are placed at the top of the loop body using the
**guard clause** pattern: detect invalid/exceptional cases first, handle them early, and
let the happy path proceed without nesting. This keeps the main logic at the left margin
instead of buried in an `else` block three levels deep.

`[System.Collections.Generic.List[string]]` is used instead of `@()` with `+=` because
list appending to a typed generic list is O(1) amortized, while `$array += $item` creates
a new array on every iteration (O(n) total O(n²) for the loop). For large server lists this
matters. For a ten-item test it doesn't -- but the habit does.

---

## Ch-06, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Build `Invoke-WithRetry` -- a generic retry wrapper with exponential backoff
that rethrows after `MaxRetries` attempts.

### Solution

```powershell
function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$MaxRetries = 3
    )

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            return & $Action
        }
        catch {
            if ($i -eq ($MaxRetries - 1)) {
                throw  # Rethrow the original exception to the caller
            }
            $delayMs = [math]::Pow(2, $i) * 100
            Write-Host "Attempt $($i + 1) failed: $($_.Exception.Message). Retrying in ${delayMs}ms..." -ForegroundColor Yellow
            Start-Sleep -Milliseconds $delayMs
        }
    }
}

# Simulate a flaky operation that succeeds on the 3rd try
$script:callCount = 0
$result = Invoke-WithRetry -Action {
    $script:callCount++
    if ($script:callCount -lt 3) { throw "Simulated transient failure" }
    "Connected successfully"
} -MaxRetries 5

Write-Host $result
Write-Host "Total attempts: $script:callCount"
```

### Expected Output

```
Attempt 1 failed: Simulated transient failure. Retrying in 100ms...
Attempt 2 failed: Simulated transient failure. Retrying in 200ms...
Connected successfully
Total attempts: 3
```

### What to notice

Several design decisions worth understanding:

1. **`for` loop, not `while`**: A `for` loop with an explicit counter is cleaner than a
   `while ($attempts -lt $max)` loop because the increment is built into the loop header.
   This reduces the risk of accidentally creating an infinite loop by forgetting to
   increment the counter inside a `catch` block.

2. **`return & $Action`**: The `&` call operator invokes the scriptblock. `return` exits
   the function immediately on success -- the `for` loop doesn't continue after a successful
   attempt. This is important: without `return`, PowerShell would continue looping even
   after the action succeeded.

3. **`if ($i -eq ($MaxRetries - 1)) { throw }`**: The rethrow check uses `throw` without
   an argument, which preserves the original exception's stack trace. Using
   `throw $_.Exception.Message` would create a new exception with a flattened string,
   losing the type information the caller might depend on.

4. **`$script:callCount`**: Scriptblocks capture variables from the calling scope, but
   modifications inside a scriptblock don't automatically write back to the parent scope.
   The `$script:` scope qualifier explicitly targets the script-level variable, making the
   counter increment visible outside the scriptblock.

5. **Exponential backoff math**: `[math]::Pow(2, $i) * 100` gives 100ms, 200ms, 400ms,
   800ms for attempts 0, 1, 2, 3. In production, add jitter:
   `$delayMs + (Get-Random -Minimum 0 -Maximum 50)` prevents all retrying clients from
   hitting your service at the same millisecond after a common failure.
