# Chapter 11 -- Answers

---

## Ch-11, Ex-1 (Simple)

**Task:** Use `-match` to validate email addresses. Return `$true` for a valid
address, `$false` for an invalid one.

### Solution

```powershell
# The pattern: local part @ domain . TLD (common heuristic)
$emailPattern = '^[\w.+-]+@[\w-]+\.[\w.]{2,}$'

# Valid cases
'user@example.com'          -match $emailPattern   # True
'first.last+tag@corp.co.uk' -match $emailPattern   # True
'admin@sub.domain.org'      -match $emailPattern   # True

# Invalid cases
'not-an-email'              -match $emailPattern   # False
'@nodomain.com'             -match $emailPattern   # False
'user@'                     -match $emailPattern   # False
'user@domain'               -match $emailPattern   # False (no TLD)
```

For a validation function:

```powershell
function Test-EmailAddress {
    param([string]$Address)
    $Address -match '^[\w.+-]+@[\w-]+\.[\w.]{2,}$'
}

Test-EmailAddress 'user@example.com'   # True
Test-EmailAddress 'not-an-email'       # False
```

### Expected Output

```
True
True
True
False
False
False
False
```

### What to notice

The pattern uses `^` and `$` anchors. Without them, `-match` tests for
containment: `'not-an-email'` would match `'^[\w.+-]+'` because the local-part
pattern appears at the start of the string. Anchors enforce that the entire
string must conform to the pattern, which is what validation requires.

`\w` in .NET regex is Unicode-aware and includes letters, decimal digits,
connector punctuation, and combining marks. The `+` after the character class
means "one or more." This pattern is a useful heuristic, not an RFC 5321
compliance checker. For production email validation, send a confirmation
message; don't try to out-clever the RFC with regex.

---

## Ch-11, Ex-2 (Normal)

**Task:** Given an array of log lines, use `-match` and `$Matches` to extract
IP addresses. Return only the IPs from lines that contain one.

### Solution

```powershell
$logs = @(
    '2024-01-15 Connection from 192.168.1.100 accepted',
    '2024-01-15 Failed login from 10.0.0.50',
    '2024-01-15 No IP address on this line',
    '2024-01-15 Probe detected from 172.16.254.1'
)

$ips = $logs | ForEach-Object {
    if ($_ -match '\b(\d{1,3}\.){3}\d{1,3}\b') {
        $Matches[0]
    }
}

$ips
```

Or using the pipeline more expressively:

```powershell
$ips = $logs | Where-Object { $_ -match '\b(\d{1,3}\.){3}\d{1,3}\b' } |
               ForEach-Object { $Matches[0] }
```

> Warning: the `Where-Object | ForEach-Object` form has a subtle gotcha.
> `$Matches` is scoped to the last `-match` call in the current scope. The
> `-match` inside `Where-Object` populates `$Matches`, but by the time
> `ForEach-Object` runs, the variable is still valid -- it hasn't been
> overwritten. This is safe, but only because no `-match` happens between the
> filter and the projection. The first form (single `ForEach-Object` with an
> `if`) is more robust in complex pipelines.

### Expected Output

```
192.168.1.100
10.0.0.50
172.16.254.1
```

### What to notice

The IP pattern `\b(\d{1,3}\.){3}\d{1,3}\b` uses:

- `\b` word boundaries so the pattern doesn't match `1192.168.1.100` embedded
  in a longer number string.
- `(\d{1,3}\.){3}` -- three repetitions of "1-3 digits followed by a dot."
- `\d{1,3}` -- the final octet with no trailing dot.

This pattern matches the shape of an IPv4 address. It does not validate
ranges: `999.999.999.999` would match. For operational log parsing where you
control the source, shape-matching is sufficient and avoids the complexity of
a range-validating pattern. If you need to validate ranges, parse the octets
after extraction and check each one with `-le 255`.

---

## Ch-11, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Parse a structured log line using named capture groups. Extract
`date`, `time`, `level`, and `source` into a `PSCustomObject`.

### Solution

```powershell
function ConvertFrom-LogLine {
    param([string]$Line)

    $pattern = '(?<date>\d{4}-\d{2}-\d{2})\s+' +
               '(?<time>\d{2}:\d{2}:\d{2})\s+' +
               '(?<level>\w+)\s+' +
               '\[(?<source>[^\]]+)\]\s+' +
               '(?<msg>.+)'

    if ($Line -match $pattern) {
        [PSCustomObject]@{
            Date    = $Matches.date
            Time    = $Matches.time
            Level   = $Matches.level
            Source  = $Matches.source
            Message = $Matches.msg
        }
    } else {
        Write-Warning "Line did not match expected log format: $Line"
        $null
    }
}

# Test it
$line = '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout'
$parsed = ConvertFrom-LogLine $line

$parsed.Date     # 2024-01-15
$parsed.Time     # 14:30:22
$parsed.Level    # ERROR
$parsed.Source   # WebServer
$parsed.Message  # Connection timeout

# Process a batch of lines
$logLines = @(
    '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout',
    '2024-01-15 14:30:23 INFO  [Database] Query completed in 42ms',
    '2024-01-15 14:30:24 WARN  [Auth] Failed login attempt'
)

$logLines | ForEach-Object { ConvertFrom-LogLine $_ } | Format-Table -AutoSize
```

### Expected Output

```
Date       Time     Level Source    Message
----       ----     ----- ------    -------
2024-01-15 14:30:22 ERROR WebServer Connection timeout
2024-01-15 14:30:23 INFO  Database  Query completed in 42ms
2024-01-15 14:30:24 WARN  Auth      Failed login attempt
```

### What to notice

1. **Named groups as documentation** -- compare `$Matches[3]` to
   `$Matches.level`. The named form is readable months later without counting
   parentheses. When a pattern has more than two groups, names pay for
   themselves immediately.

2. **Pattern building with string concatenation** -- long patterns become
   unreadable as single strings. Splitting across multiple lines with `+`
   keeps each capture group on its own line. PowerShell's `[regex]` class
   also supports the `(?x)` verbose mode flag (whitespace and comments inside
   the pattern) for even longer patterns, though that is rarer in practice.

3. **`[^\]]+` inside `\[...\]`** -- the source component is captured as
   "everything that isn't a closing bracket" (`[^\]]+`) between literal
   brackets. This is safer than `\w+` because source names might contain
   hyphens or dots (`[Web-Server]`, `[Corp.Auth]`). Match the structure, not
   an assumed character set.

4. **Graceful non-match handling** -- the function emits a warning and returns
   `$null` rather than throwing. In a pipeline processing thousands of lines,
   a single malformed entry shouldn't abort the run. Collect warnings
   separately; let the good lines through.

---

## Ch-11, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Classify log lines by severity using cascading `-match`. Return
structured objects with the original line and an assigned `Severity` category.

### Solution

```powershell
function Invoke-LogClassifier {
    param([string[]]$LogLines)

    $logLines | ForEach-Object {
        $line = $_

        $severity = if ($line -match '\b(FATAL|CRITICAL)\b') {
            'Critical'
        } elseif ($line -match '\bERROR\b') {
            'Error'
        } elseif ($line -match '\b(WARN|WARNING)\b') {
            'Warning'
        } elseif ($line -match '\bINFO\b') {
            'Info'
        } else {
            'Debug'
        }

        [PSCustomObject]@{
            Line     = $line
            Severity = $severity
        }
    }
}

# Test data
$logLines = @(
    '2024-01-15 14:30:22 FATAL Database connection lost',
    '2024-01-15 14:30:23 ERROR Disk space below threshold',
    '2024-01-15 14:30:24 WARN  Memory usage at 87%',
    '2024-01-15 14:30:25 INFO  Deployment completed successfully',
    '2024-01-15 14:30:26 DEBUG Entering authentication handler',
    '2024-01-15 14:30:27 CRITICAL Certificate expiry in 2 days',
    '2024-01-15 14:30:28 WARNING Slow query detected: 4200ms'
)

$classified = Invoke-LogClassifier -LogLines $logLines

# Summary by severity
$classified | Group-Object Severity | Select-Object Name, Count |
    Sort-Object Count -Descending

# Critical and Error lines only
$classified | Where-Object Severity -in 'Critical', 'Error' |
    Select-Object Severity, Line | Format-Table -AutoSize
```

### Expected Output

```
Name     Count
----     -----
Debug        1
Info         1
Warning      2
Error        1
Critical     2
```

```
Severity Line
-------- ----
Critical 2024-01-15 14:30:22 FATAL Database connection lost
Error    2024-01-15 14:30:23 ERROR Disk space below threshold
Critical 2024-01-15 14:30:27 CRITICAL Certificate expiry in 2 days
```

### What to notice

1. **Cascade order matters** -- `FATAL` must be checked before `ERROR` because
   some log frameworks write lines like `ERROR FATAL: ...`. If you checked
   `ERROR` first, those lines would be classified as `Error` rather than
   `Critical`. Always test more specific patterns before less specific ones.

2. **`\b` word boundaries** -- without them, `ERROR` would match inside
   `ERRORCODE` or `NOERROR`. Word boundaries `\b` anchor the match to a word
   edge. This is the difference between matching a severity keyword and
   matching any string that contains those letters.

3. **Handling aliases** -- real log frameworks use `WARN` and `WARNING`
   interchangeably, and `FATAL` and `CRITICAL` overlap in meaning across
   frameworks. The classifier normalizes both to a single canonical severity
   level. This normalization is where most production log parsers spend their
   complexity budget.

4. **The `else { 'Debug' }` default** -- rather than matching `\bDEBUG\b`
   explicitly, the final `else` handles both `DEBUG` and any unrecognized
   level. This is a deliberate choice: if a new log framework introduces
   `TRACE` or `VERBOSE`, those lines get classified as `Debug` rather than
   crashing the pipeline. Unknown-is-lowest-severity is the safer default
   for operational tooling.

5. **Extending this pattern** -- a production version would add IP extraction
   (from the previous exercise), timestamp parsing, source component parsing
   (Ex-3), and output to CSV or a monitoring system. Each exercise builds a
   piece; this one provides the classification backbone that glues them
   together.
