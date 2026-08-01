# Chapter 14 -- Answers

---

## Ch-14, Ex-1 (Simple)

**Task:** Use `Invoke-Command -ScriptBlock` (no `-ComputerName`) to run a
block locally and return the computer name or hostname. Verify the result is
not null or empty.

### Solution

```powershell
# Invoke-Command without a remote target invokes the block locally.
$result = Invoke-Command -ScriptBlock {
    [Environment]::MachineName
}

$result
# Verify it came back
if ([string]::IsNullOrEmpty($result)) {
    throw "Expected a hostname but got nothing"
}
Write-Host "Local hostname: $result"
```

### Stretch goal: explicit arguments

```powershell
$greeting = 'Hello from'

$result = Invoke-Command -ScriptBlock {
    param($Prefix)
    "$Prefix $([Environment]::MachineName)"
} -ArgumentList $greeting

$result  # "Hello from MYPC" or similar
```

### Expected Output

```
MYPC
Local hostname: MYPC
```

(Your actual computer name will appear instead of `MYPC`.)

### What to notice

This local parameter set is useful for testing scriptblock output, but it does
not test authentication, serialization, or a remoting transport. `$using:` is
valid for remote `Invoke-Command` calls; for local invocation, use ordinary
parameters with `-ArgumentList`. `[Environment]::MachineName` is a
cross-platform hostname API.

---

## Ch-14, Ex-2 (Normal)

**Task:** Start a background job that runs `1..5 | ForEach-Object { $_ * 2 }`.
Wait for it (timeout 30s), receive results, remove the job. Verify output is
`@(2, 4, 6, 8, 10)`.

### Solution

```powershell
# Start the job
$job = Start-Job -ScriptBlock {
    1..5 | ForEach-Object { $_ * 2 }
}

Write-Host "Job started: ID $($job.Id), State: $($job.State)"

# Wait -- blocks until the job completes or 30 seconds pass
$completed = $job | Wait-Job -Timeout 30

if ($completed.State -ne 'Completed') {
    Remove-Job $job -Force
    throw "Job did not complete within timeout. Final state: $($job.State)"
}

# Receive the output -- consumes the output stream
$result = Receive-Job $job

# Clean up -- always, or jobs accumulate and waste memory
Remove-Job $job

$result  # 2, 4, 6, 8, 10

# Verify
if ($result.Count -ne 5) {
    throw "Expected 5 results, got $($result.Count)"
}
Write-Host "Results: $($result -join ', ')"
```

### With error handling (stretch goal)

```powershell
$job = Start-Job -ScriptBlock {
    # Simulating possible failure
    if ($false) { throw "Simulated error" }
    1..5 | ForEach-Object { $_ * 2 }
}

try {
    $job | Wait-Job -Timeout 30 | Out-Null

    if ($job.State -eq 'Failed') {
        # Receive-Job on a failed job throws the terminating error
        Receive-Job $job -ErrorAction Stop
    }

    $result = Receive-Job $job
    $result
} catch {
    Write-Error "Job failed: $_"
} finally {
    Remove-Job $job -ErrorAction SilentlyContinue
}
```

### Expected Output

```
Job started: ID 3, State: Running
2
4
6
8
10
Results: 2, 4, 6, 8, 10
```

(Job ID will vary.)

### What to notice

1. **`Receive-Job` drains the output queue.** Call it once and the data is
   gone (unless you used `-Keep`). If you pipe the job straight to
   `Wait-Job | Receive-Job`, you lose the chance to check the job state first.
   For simple cases the one-liner is fine; for anything that could fail, check
   `$job.State -eq 'Completed'` before receiving.

2. **Always `Remove-Job`.** A `Start-Job` call creates a job object that lives
   in the current session's job table (`Get-Job`). These accumulate in memory
   if you never clean them up. In a long-running script that fires jobs in a
   loop, this will eventually exhaust available memory. The `finally` block
   in the error-handling variant ensures cleanup happens even on failure.

3. **Process isolation means a fresh environment.** The job's ScriptBlock does
   not inherit your `$PSDefaultParameterValues`, your loaded modules, your
   imported functions, or your `$env:` customisations. If your job needs a
   module, `Import-Module` it inside the ScriptBlock. If it needs an
   value from the caller, pass it with `$using:` or as an argument. A child
   process inherits a snapshot of environment variables at startup, not later
   changes to the parent process.

4. **`Wait-Job -Timeout` returns the job object** (or `$null` if it times out).
   Check `.State` after waiting; do not assume completion means success.

---

## Ch-14, Ex-3 (Advanced)

**Task:** Use `ForEach-Object -Parallel` on integers 1-5, producing a
`[PSCustomObject]` with `Input` and `Squared` properties for each. Set
`-ThrottleLimit 3`. Verify 5 results and that `Input == 3` gives
`Squared == 9`.

### Solution

```powershell
$results = 1..5 | ForEach-Object -Parallel {
    $n = $_
    [PSCustomObject]@{
        Input   = $n
        Squared = $n * $n
    }
} -ThrottleLimit 3

# Results arrive in completion order, not input order -- sort to inspect
$sorted = $results | Sort-Object Input

$sorted | Format-Table

# Verify count
$results.Count  # 5

# Verify specific value
$item3 = $results | Where-Object Input -eq 3
$item3.Squared  # 9
```

### Stretch goal: confirm actual concurrency

```powershell
$results = 1..5 | ForEach-Object -Parallel {
    $n = $_
    Start-Sleep -Milliseconds 50   # Force overlap
    [PSCustomObject]@{
        Input    = $n
        Squared  = $n * $n
        ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    }
} -ThrottleLimit 3

$results | Sort-Object Input | Format-Table

# Count distinct thread IDs -- should be > 1
$distinctThreads = ($results.ThreadId | Sort-Object -Unique).Count
Write-Host "Distinct threads used: $distinctThreads"
# With ThrottleLimit 3 and 5 items, expect 2-3 distinct threads
```

### Expected Output

```
Input Squared
----- -------
    1       1
    2       4
    3       9
    4      16
    5      25

5
9
Distinct threads used: 3
```

### What to notice

1. **Order is not guaranteed.** The raw `$results` array may list item 4
   before item 1 because item 4 happened to finish first. Never rely on
   output order from a parallel operation. `Sort-Object Input` restores the
   logical sequence for display or downstream processing.

2. **`-ThrottleLimit` is a ceiling, not a guarantee.** With `-ThrottleLimit 3`
   and 5 items, PowerShell runs at most 3 items simultaneously. Items 4 and 5
   wait until one of the first three finishes. The thread count in the stretch
   goal may be 2 or 3 depending on timing -- threads are reused across batches.

3. **`$_` is still the current item.** The pipeline semantics work exactly as
   in a normal `ForEach-Object`; `-Parallel` just adds concurrency. Assign
   `$_` to a named variable (`$n = $_`) when it improves readability. Each
   iteration has its own runspace context, so a later iteration doesn't race
   to overwrite the current iteration's `$_`.

4. **Thread vs process.** Unlike `Start-Job`, `ForEach-Object -Parallel` runs
   in threads of the *current process*. No child process startup cost. This
   makes startup cheaper for small workloads, but it also means a
   catastrophically-behaved ScriptBlock (one that crashes the runtime, not just
   throws an error) can affect your session. For untrusted code, use
   `Start-Job` instead.

---

## Ch-14, Ex-4 (Extreme)

**Task:** Fan-out to five named tasks (`task-A` through `task-E`) in parallel
with `-ThrottleLimit 2`. Each task simulates random work duration (50-200ms).
Collect results; verify all 5 return, all have `Status == 'Success'`, and all
`Target` values are in the original list.

### Solution

```powershell
$targets = @('task-A', 'task-B', 'task-C', 'task-D', 'task-E')

$results = $targets | ForEach-Object -Parallel {
    $target = $_

    try {
        # Simulate variable-duration work
        $duration = Get-Random -Minimum 50 -Maximum 200
        Start-Sleep -Milliseconds $duration

        # Return a structured result
        [PSCustomObject]@{
            Target   = $target
            Status   = 'Success'
            Duration = $duration
        }
    } catch {
        # Structured failure -- never let one task kill the fan-out
        [PSCustomObject]@{
            Target   = $target
            Status   = "Error: $($_.Exception.Message)"
            Duration = -1
        }
    }
} -ThrottleLimit 2

# Aggregate and display
$results | Sort-Object Target | Format-Table Target, Status, Duration

# Verification
$results.Count   # 5

$successCount = ($results | Where-Object Status -eq 'Success').Count
Write-Host "Successful: $successCount / $($results.Count)"

$failed = $results | Where-Object { $_.Status -ne 'Success' }
if ($failed.Count -gt 0) {
    Write-Warning "Failed tasks:"
    $failed | Format-Table Target, Status
}

# Confirm all targets are accounted for
foreach ($r in $results) {
    if ($r.Target -notin $targets) {
        throw "Unexpected target in results: $($r.Target)"
    }
}
Write-Host "All targets verified."
```

### Advanced variant: measure total wall-clock time vs serial time

```powershell
$targets = @('task-A', 'task-B', 'task-C', 'task-D', 'task-E')

# Estimate serial time
$serialEstimate = 125ms * 5   # 625ms at average duration

$sw = [System.Diagnostics.Stopwatch]::StartNew()

$results = $targets | ForEach-Object -Parallel {
    $target = $_
    $duration = Get-Random -Minimum 50 -Maximum 200
    Start-Sleep -Milliseconds $duration
    [PSCustomObject]@{
        Target   = $target
        Status   = 'Success'
        Duration = $duration
    }
} -ThrottleLimit 2

$sw.Stop()

$totalDuration = ($results | Measure-Object Duration -Sum).Sum
Write-Host "Wall-clock time : $($sw.ElapsedMilliseconds)ms"
Write-Host "Sum of durations: ${totalDuration}ms"
Write-Host "Speedup factor  : $([math]::Round($totalDuration / $sw.ElapsedMilliseconds, 1))x"
# With ThrottleLimit 2, expect roughly 2-2.5x speedup vs serial
```

### Expected Output

```
Target Status  Duration
------ ------  --------
task-A Success      142
task-B Success       67
task-C Success      189
task-D Success       91
task-E Success      113

5
Successful: 5 / 5
All targets verified.

Wall-clock time : 318ms
Sum of durations: 602ms
Speedup factor  : 1.9x
```

(Durations are random; your numbers will differ. Speedup with limit 2 on 5
tasks is typically 1.8-2.5x.)

### What to notice

1. **Use try/catch per task in fan-outs.** An unhandled iteration error is
   written as an error and is difficult to correlate consistently with the
   corresponding target. With try/catch, you get structured failure objects
   mixed with success objects and can decide what to do in aggregation.

2. **`-ThrottleLimit 2` allows at most two active iterations.** New work starts
   whenever a slot becomes free, so variable-duration tasks aren't rigid
   batches. The wall time depends on how durations are distributed across the
   two runspaces; measure it rather than relying on a batch formula.

3. **Structured results make aggregation composable.** Every object -- success
   or failure -- has the same shape: `Target`, `Status`, `Duration`. This lets
   you use consistent `Where-Object`, `Group-Object`, and `Measure-Object`
   calls on the full result set regardless of what happened inside each task.
   Inconsistent shapes (`$null` on failure, objects on success) force ugly
   type-checks throughout the aggregation logic.

4. **The speedup measurement pattern is worth keeping.** A `Stopwatch` around
   a parallel block next to a `Measure-Object -Sum` of individual durations
   gives you empirical data on whether your throttle limit is set correctly.
   If wall-clock time is close to sum-of-durations, your throttle is too low.
   If it's barely less than the single slowest task, your throttle is higher
   than needed.

5. **Production fan-outs add logging, idempotency, and retry.** The pattern
   here is the foundation. A production-grade script would emit structured log
   entries per task, check whether work already completed before re-doing it
   (idempotency guard), and retry transient failures with exponential backoff.
   Those concerns are application-level; the parallel mechanics stay the same.
