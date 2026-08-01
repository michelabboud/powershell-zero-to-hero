# Chapter 14: Remoting and Background Jobs

Rina is logged into 50 servers simultaneously. Her terminal looks like the
opening credits of a spy thriller.

![chapter-opener](assets/images/ch-14-opener.png)

---

## Why This Chapter Matters

Everything up to this point has been PowerShell talking to the local machine.
That's useful. What's more useful is PowerShell talking to *all* your machines
simultaneously, or doing five expensive things at once while you drink coffee.

Remoting and background jobs are the infrastructure engineer's force
multiplier. One well-written script replaces an afternoon of SSH tab-switching.
One parallel pipeline replaces a sequential loop that takes three minutes.

Here's the terrain we're covering:

![remoting-overview](assets/images/ch-14-overview.png)

---

## Part 1: PowerShell Remoting

PowerShell Remoting (PSRemoting) lets you run commands on remote machines as
if you were sitting at their keyboard. Under the hood it uses WS-Management
(WSMan) over HTTP/HTTPS on Windows, or SSH on Linux/macOS/cross-platform.

### Enabling Remoting

On Windows (run as Administrator):

```powershell
# Enable PSRemoting on the target machine
Enable-PSRemoting -Force

# Verify the WinRM service is running
Get-Service WinRM
```

On Linux/macOS or for SSH-based remoting (covered below), no separate
enabling step is needed beyond having an SSH server running.

> **Note for this chapter:** All examples and tests use `localhost` as the
> target. Real-world remoting to other machines requires network access,
> firewall rules, and (on Windows) either domain trust or explicit credential
> configuration. The mechanics are identical; only the target changes.

---

### Invoke-Command: The One-Shot Remote Call

`Invoke-Command` is the workhorse of PowerShell remoting. You give it a
ScriptBlock and a target; it runs the block there and returns the results here.

```powershell
# Run a scriptblock on localhost (test remoting without a real remote host)
Invoke-Command -ComputerName localhost -ScriptBlock {
    Get-Date
    $env:COMPUTERNAME
}

# Run on multiple machines at once -- results come back as objects
$servers = @('web01', 'web02', 'db01')
Invoke-Command -ComputerName $servers -ScriptBlock {
    [PSCustomObject]@{
        Host   = $env:COMPUTERNAME
        Uptime = (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime
    }
}
```

When you target multiple machines, `Invoke-Command` fans out in parallel
automatically (up to 32 concurrent connections by default, controlled by
`-ThrottleLimit`). The results come back as objects with a `PSComputerName`
property added automatically, so you always know which machine produced
which result.

```powershell
# Throttle to 5 concurrent connections
Invoke-Command -ComputerName $servers -ScriptBlock { Get-Process } -ThrottleLimit 5
```

**The `-ScriptBlock` scope trap:** Variables from your local session are
*not* automatically available inside the ScriptBlock. The block runs in a
fresh remote session.

```powershell
$threshold = 500MB

# This FAILS -- $threshold is undefined in the remote session
Invoke-Command -ComputerName localhost -ScriptBlock {
    Get-Process | Where-Object WorkingSet -gt $threshold
}

# This WORKS -- use $using: to inject local variables
Invoke-Command -ComputerName localhost -ScriptBlock {
    Get-Process | Where-Object WorkingSet -gt $using:threshold
}
```

The `$using:` scope modifier is the key. Any local variable can be
projected into a remote ScriptBlock this way. It serializes the value
and deserializes it on the other side, so complex objects may lose their
methods -- stick to primitive types, arrays, and simple hashtables when
passing values across the wire.

---

### Enter-PSSession: Interactive Remoting

`Enter-PSSession` opens an interactive shell on a remote machine. Your prompt
changes to reflect the remote host. Everything you type runs there.

```powershell
# Connect interactively
Enter-PSSession -ComputerName web01

# Your prompt becomes:
# [web01]: PS C:\Users\sam\Documents>

# Exit when done
Exit-PSSession
```

This is the PowerShell equivalent of SSH for interactive work. It's useful
for ad-hoc investigation, but if you catch yourself typing the same commands
on five boxes in sequence, stop and use `Invoke-Command` instead.

---

### New-PSSession: Persistent Sessions

Every `Invoke-Command -ComputerName` call creates a new session, authenticates,
runs, and tears down. That overhead adds up. `New-PSSession` creates a
*reusable* session object you can pass to multiple commands.

```powershell
# Create a persistent session
$session = New-PSSession -ComputerName web01

# Reuse the same session for multiple calls -- no reconnect overhead
Invoke-Command -Session $session -ScriptBlock { Get-Service }
Invoke-Command -Session $session -ScriptBlock { Get-EventLog -LogName System -Newest 10 }

# Jump into it interactively
Enter-PSSession -Session $session

# Clean up when done
Remove-PSSession $session

# Or clean up all open sessions
Get-PSSession | Remove-PSSession
```

Sessions also preserve state between calls. A variable set in one
`Invoke-Command -Session` is still there in the next one, because it's the
same runspace. This is useful for complex multi-step workflows.

```powershell
# State persists within a session
Invoke-Command -Session $session -ScriptBlock { $deployPath = "C:\Deploy\v2.1" }
Invoke-Command -Session $session -ScriptBlock { Get-ChildItem $deployPath }  # Works
```

---

### SSH-Based Remoting

PowerShell 7 supports SSH as a transport, which means cross-platform remoting
works natively: Windows to Linux, Linux to Windows, anything to anything that
runs an SSH server and PowerShell 7.

```powershell
# Connect to a Linux host via SSH
$linuxSession = New-PSSession -HostName ubuntu-server -UserName deploy -SSHTransport

# Run a command -- same API, different transport
Invoke-Command -Session $linuxSession -ScriptBlock {
    uname -a
    $PSVersionTable.PSVersion
}

# Works with Enter-PSSession too
Enter-PSSession -HostName ubuntu-server -UserName deploy -SSHTransport
```

Key differences from WSMan remoting:
- Uses SSH key authentication by default (add `-KeyFilePath` for a specific key)
- No `Enable-PSRemoting` required on the target -- just OpenSSH server + PowerShell 7
- Works through firewalls that already allow port 22
- Does not support `-ComputerName` on `Invoke-Command`; use `-HostName` instead

![ssh-vs-wsrman](assets/images/ch-14-ssh-vs-wsrman.png)

---

### Session Configuration

PowerShell remoting uses *session configurations* (also called endpoints) on
the server side. The default endpoint is named `microsoft.powershell`. You can
create custom endpoints to constrain what callers can do.

```powershell
# List available session configurations
Get-PSSessionConfiguration

# Create a constrained endpoint (Just Enough Administration pattern)
New-PSSessionConfigurationFile -Path ./jea-ops.pssc -SessionType RestrictedRemoteServer
Register-PSSessionConfiguration -Name 'OpsTeam' -Path ./jea-ops.pssc -Force

# Connect to a specific configuration
Invoke-Command -ComputerName web01 -ConfigurationName 'OpsTeam' -ScriptBlock {
    Get-Service  # Only allowed cmdlets work here
}
```

Session configurations are how serious shops implement Just Enough
Administration (JEA): operators get a remoting endpoint that only exposes the
specific cmdlets they need, with no path to a full shell. The topic is its
own chapter in any security-focused guide; the above is enough to know it
exists and where to look.

---

## Part 2: Background Jobs

Background jobs let PowerShell start work in a separate process or thread and
return control to you immediately. You check back later when you want the
results.

![jobs-flow](assets/images/ch-14-jobs-flow.png)

---

### Start-Job / Get-Job / Receive-Job

`Start-Job` launches a ScriptBlock in a *child PowerShell process*. It's
fully isolated: separate runspace, separate memory, separate module imports.

```powershell
# Fire off a background job
$job = Start-Job -ScriptBlock {
    Start-Sleep -Seconds 5
    "I ran in the background at $(Get-Date)"
}

# Check its status without waiting
Get-Job

# Wait for it to finish (blocks until done or timeout)
$job | Wait-Job -Timeout 30

# Pull the results
$result = Receive-Job $job
$result

# Clean up -- always do this or jobs accumulate in memory
Remove-Job $job
```

`Receive-Job` *consumes* output: call it twice and the second call returns
nothing unless you use `-Keep`. The job object remembers its state, but the
output stream is a queue that empties as you read it.

```powershell
# Keep output in the buffer for multiple reads
Receive-Job $job -Keep

# One-liner: wait, receive, clean up
$result = $job | Wait-Job | Receive-Job
Remove-Job $job
```

**The process isolation cost:** Because `Start-Job` spawns a full child
PowerShell process, each job carries ~50-100ms startup overhead and uses
its own memory. For CPU-bound work that takes seconds or longer, this is
negligible. For launching 100 tiny jobs that each take 10ms, the overhead
dominates. Use thread jobs for that case (below).

```powershell
# Jobs run in a child process -- modules must be imported there
$job = Start-Job -ScriptBlock {
    # This may fail if the module isn't auto-imported in the child session
    Import-Module ActiveDirectory
    Get-ADUser -Filter { Name -like 'sam*' }
}
```

---

### Start-ThreadJob: Lightweight Concurrent Work

`Start-ThreadJob` (from the `ThreadJob` module, included in PS7) runs the
ScriptBlock in a *thread* within the current process rather than a child
process. Faster startup, lower overhead, shared process memory.

```powershell
# Install if not present (usually pre-installed in PS7)
# Install-Module ThreadJob -Scope CurrentUser

# Thread jobs have the same API as regular jobs
$job = Start-ThreadJob -ScriptBlock {
    1..10 | ForEach-Object { $_ * $_ }
}

$job | Wait-Job | Out-Null
$result = Receive-Job $job
Remove-Job $job
$result
```

The API is identical to `Start-Job`. Swap one for the other without changing
anything else. Use `Start-ThreadJob` when:
- You need many short-lived concurrent tasks
- Your work is I/O-bound (waiting on network calls, file reads)
- You want lower memory overhead

Use `Start-Job` when:
- Your work genuinely needs process isolation (security boundary)
- You're concerned about runspace pollution from badly-behaved modules
- You need the job to outlive the current session

---

### ForEach-Object -Parallel: Inline Parallelism

PowerShell 7 added `-Parallel` to `ForEach-Object`. It runs the ScriptBlock
for each input object concurrently using thread jobs under the hood, but the
syntax is a clean inline pipeline stage -- no `Start-Job`, no `Wait-Job`, no
`Receive-Job` boilerplate.

```powershell
# Process 10 items, 3 at a time, concurrently
$results = 1..10 | ForEach-Object -Parallel {
    $n = $_
    Start-Sleep -Milliseconds (Get-Random -Min 50 -Max 300)  # Simulate work
    [PSCustomObject]@{
        Input   = $n
        Squared = $n * $n
        Thread  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    }
} -ThrottleLimit 3

$results | Sort-Object Input | Format-Table
```

Notice the `Thread` column will show different thread IDs -- the items really
are running concurrently. The results arrive in *completion order*, not input
order. If you need input order, sort afterward.

**`$using:` is required here too:**

```powershell
$multiplier = 7

# Wrong -- $multiplier is not in scope inside -Parallel
1..5 | ForEach-Object -Parallel { $_ * $multiplier }

# Right
1..5 | ForEach-Object -Parallel { $_ * $using:multiplier }
```

**`-ThrottleLimit`:** The default is 5 concurrent threads. More is not always
better. CPU-bound work should match your core count. I/O-bound work can go
higher. Start with 5-10 and measure; don't just crank it to 100 and wonder
why the server is unresponsive.

```powershell
# Practical example: check disk space on a list of paths concurrently
$paths = @('C:\', 'D:\', 'E:\', 'C:\Windows', 'C:\Program Files')

$diskReport = $paths | ForEach-Object -Parallel {
    $path = $_
    if (Test-Path $path) {
        $drive = Split-Path $path -Qualifier
        $disk  = Get-PSDrive ($drive.TrimEnd(':'))
        [PSCustomObject]@{
            Path      = $path
            FreeGB    = [math]::Round($disk.Free / 1GB, 2)
            UsedGB    = [math]::Round($disk.Used / 1GB, 2)
        }
    }
} -ThrottleLimit 5

$diskReport | Where-Object { $_ } | Format-Table
```

---

### Comparing the Three Parallelism Approaches

| | `Start-Job` | `Start-ThreadJob` | `ForEach-Object -Parallel` |
|---|---|---|---|
| Isolation | Full process | Thread | Thread |
| Startup cost | High (~100ms) | Low (~1ms) | Low (~1ms) |
| Syntax | Explicit lifecycle | Explicit lifecycle | Inline pipeline |
| Best for | Long tasks, isolation | Many short tasks | Batch processing |
| `$using:` required | Yes | Yes | Yes |
| Output ordering | Any | Any | Completion order |

---

## Part 3: The Fan-Out Pattern

The highest-leverage use of remoting and jobs together is the *fan-out*:
send work to many targets in parallel, collect and aggregate the results.

```powershell
# Fan-out: collect uptime from multiple servers with throttling
$servers = @('web01', 'web02', 'web03', 'db01', 'db02', 'cache01')

$report = $servers | ForEach-Object -Parallel {
    $server = $_
    try {
        $os = Invoke-Command -ComputerName $server -ScriptBlock {
            [PSCustomObject]@{
                Host    = $env:COMPUTERNAME
                Uptime  = ((Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime).Days
                OSBuild = (gcim Win32_OperatingSystem).BuildNumber
            }
        } -ErrorAction Stop
        $os | Add-Member -MemberType NoteProperty -Name Status -Value 'OK' -PassThru
    } catch {
        [PSCustomObject]@{
            Host    = $server
            Uptime  = -1
            OSBuild = 'N/A'
            Status  = "Error: $($_.Exception.Message)"
        }
    }
} -ThrottleLimit 10

# Aggregate
$report | Sort-Object Host | Format-Table Host, Status, Uptime, OSBuild

$failed = $report | Where-Object Status -ne 'OK'
if ($failed) {
    Write-Warning "$($failed.Count) server(s) did not respond:"
    $failed | Select-Object Host, Status | Format-Table
}
```

The try/catch inside the parallel block is critical. Without it, one
unreachable server terminates the entire block with an error. Wrap the
per-target work in try/catch, return a structured error object, and handle
failures in the aggregation pass.

![fan-out-pattern](assets/images/ch-14-fan-out.png)

---

## Exercises

### [Ch-14, Ex-1] Simple: Invoke-Command Locally

Use `Invoke-Command` with only a `-ScriptBlock` parameter (no
`-ComputerName`) to run a block of code and return the computer name or
hostname. Verify the result is not null or empty.

**Stretch goal:** Pass a local variable into the ScriptBlock using `$using:`.

### [Ch-14, Ex-2] Normal: Background Job Lifecycle

Start a background job that computes `1..5 | ForEach-Object { $_ * 2 }`.
Wait for it to complete (with a sensible timeout), receive the results, and
remove the job. Verify the output is `@(2, 4, 6, 8, 10)`.

**Stretch goal:** Add error handling for the case where the job fails or
times out.

### [Ch-14, Ex-3] Advanced: Parallel Processing with ForEach-Object

Use `ForEach-Object -Parallel` to process the integers 1 through 5,
producing a custom object for each with `Input` and `Squared` properties.
Set `-ThrottleLimit 3`. Verify you get 5 results back and that the item
with `Input -eq 3` has `Squared -eq 9`.

**Stretch goal:** Add a `ThreadId` property and confirm more than one
distinct thread was used (proving actual concurrency).

### [Ch-14, Ex-4] Extreme: Fan-Out with Throttling and Aggregation

Given a list of five named tasks (`task-A` through `task-E`), simulate a
fan-out where each task runs in parallel with a random simulated duration
(50-200ms). Collect the results and verify:
- All 5 results are returned
- All have `Status -eq 'Success'`
- Every `Target` value appears in your original list

Use `-ThrottleLimit 2` to throttle. Include structured error handling inside
the parallel block so a single failure does not abort the others.

---

## Key Takeaways

- `Invoke-Command -ScriptBlock` runs code remotely (or locally); add
  `-ComputerName` for remote targets, `-Session` for reuse.
- `$using:` is how local variables enter a remote ScriptBlock or a
  `-Parallel` block. Without it, your variables are invisible.
- `New-PSSession` creates a persistent, reusable connection that preserves
  state between calls and avoids per-call authentication overhead.
- SSH remoting works cross-platform with `-HostName` and `-SSHTransport`;
  no `Enable-PSRemoting` needed on the target.
- `Start-Job` is process-isolated and heavy; `Start-ThreadJob` and
  `ForEach-Object -Parallel` are thread-based and lightweight.
- `-ThrottleLimit` is not decorative. Tune it to your workload -- more
  threads are not always better.
- The fan-out pattern (parallel dispatch + result aggregation) is the core
  infrastructure automation pattern. Always wrap per-target work in
  try/catch and return structured error objects.
- Results from parallel operations arrive in completion order, not input
  order. Sort explicitly if order matters.

---

*Next up: [Chapter 15 -- Active Directory](15-active-directory.md), where we
apply PowerShell automation to directory administration.*
