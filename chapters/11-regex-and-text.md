# Chapter 11: Regex and Text Processing

Sam is on line 347 of a log file. He's using `IndexOf`. This chapter is for Sam.

![chapter-opener](assets/images/ch-11-opener.png)

---

## Why Regex Exists and Why You Will Use It

Every sysadmin eventually reaches the point where log files, config data, or
API responses arrive in a format that is "almost structured." Timestamps in
slightly different positions. IPs buried in prose. Severity words sprinkled
between other words. You could split on spaces and count fields -- and you
will, the first time. The second time you'll reach for regex.

Regular expressions are a pattern language for text. They don't replace good
data structures; they're the tool you use to extract them from chaos.
PowerShell bakes regex into the language itself via the `-match` and `-replace`
operators, making common tasks a single expression rather than a function call.

![regex-mental-model](assets/images/ch-11-mental-model.png)

---

## The `-match` Operator and `$Matches`

`-match` tests whether a string contains a pattern. It returns `$true` or
`$false`, and as a side effect it populates `$Matches`, an automatic variable
that holds the matched text and any capture groups.

```powershell
# Basic match -- does the string contain this pattern?
'PowerShell 7.6.4' -match '\d+\.\d+'
# True

# After a successful match, $Matches is populated
$Matches[0]
# 7.6

# $Matches[0] is always the full match
# $Matches[1], [2], ... are numbered capture groups
'2024-01-15' -match '(\d{4})-(\d{2})-(\d{2})'
$Matches[0]   # 2024-01-15
$Matches[1]   # 2024
$Matches[2]   # 01
$Matches[3]   # 15
```

A few things worth burning into memory:

- `-match` is **case-insensitive by default**. Use `-cmatch` for
  case-sensitive matching.
- `$Matches` is updated by the most recent **successful scalar** `-match` in
  the current scope. A failed match leaves the previous value intact, so use
  it only inside the branch guarded by that match.
- `-match` tests for **containment**, not full-string equality. The pattern
  `'\d+'` matches `'abc123def'` because the digits appear somewhere in it.
  Anchor with `^` and `$` when you need full-string validation.

```powershell
# Case-insensitive (default)
'ERROR' -match 'error'   # True

# Case-sensitive
'ERROR' -cmatch 'error'  # False

# Anchored full-string match
'192.168.1.1' -match '^\d{1,3}(\.\d{1,3}){3}$'  # True
'not an IP'   -match '^\d{1,3}(\.\d{1,3}){3}$'  # False
```

---

## Named Capture Groups

Numbered groups (`$Matches[1]`, `$Matches[2]`) work fine until you have six of
them and can't remember which index is which. Named captures solve that.

```powershell
# Syntax: (?<name>pattern)
$line = '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout'

$line -match '(?<date>\d{4}-\d{2}-\d{2})\s(?<time>\d{2}:\d{2}:\d{2})\s(?<level>\w+)\s\[(?<source>\w+)\]'

$Matches.date    # 2024-01-15
$Matches.time    # 14:30:22
$Matches.level   # ERROR
$Matches.source  # WebServer
```

Named groups appear in `$Matches` by their name as well as by number. You can
mix named and unnamed groups in the same pattern, though it's rarely a good
idea for readability.

```powershell
# Practical: parse an Apache-style access log entry
$entry = '192.168.1.50 - admin [15/Jan/2024:14:30:22] "GET /api/status HTTP/1.1" 200 1042'

$entry -match '(?<ip>[\d.]+)\s+-\s+(?<user>\S+)\s+\[(?<ts>[^\]]+)\]\s+"(?<method>\w+)\s+(?<path>\S+)'

$Matches.ip     # 192.168.1.50
$Matches.user   # admin
$Matches.method # GET
$Matches.path   # /api/status
```

---

## The `-replace` Operator

`-replace` substitutes matches with replacement text. The replacement string
can reference capture groups using `$1`, `$2`, or `${name}` syntax.

```powershell
# Simple substitution
'Hello World' -replace 'World', 'PowerShell'
# Hello PowerShell

# Using capture group back-references
'2024-01-15' -replace '(\d{4})-(\d{2})-(\d{2})', '$3/$2/$1'
# 15/01/2024

# Named group back-reference
'2024-01-15' -replace '(?<y>\d{4})-(?<m>\d{2})-(?<d>\d{2})', '${d}/${m}/${y}'
# 15/01/2024

# Remove matches (replace with empty string)
'Price: $42.00 (USD)' -replace '\$[\d.]+', '[REDACTED]'
# Price: [REDACTED] (USD)
```

Note the escaped `\$` in the last example. In regex, `$` anchors to end-of-line.
To match a literal dollar sign, escape it with `\`. Inside the replacement
string, `$` introduces back-references -- which is why you'll sometimes see
`$$` to produce a literal `$` in output.

```powershell
# Bulk replacement on an array -- -replace works on collections
$logs = @(
    'Server: web01.prod.example.com',
    'Server: db01.prod.example.com',
    'Server: app01.prod.example.com'
)
$logs -replace '\.prod\.example\.com', '.staging.example.com'
# Server: web01.staging.example.com
# Server: db01.staging.example.com
# Server: app01.staging.example.com
```

String operators also accept collections, but their return contracts differ:
`-replace` returns every transformed element, while collection input to
`-match` returns only the elements that matched. Collection-mode `-match`
doesn't populate `$Matches`; use a scalar match inside a loop when you need
capture groups.

---

## `-split` with Regex

You know `-split` from basic string work. Fed a regex pattern, it becomes a
proper tokenizer.

```powershell
# Split on any whitespace sequence (the default)
'one   two    three' -split '\s+'
# one
# two
# three

# Split on comma or semicolon
'alpha,beta;gamma,delta' -split '[,;]'
# alpha
# beta
# gamma
# delta

# Split and limit result count
'a:b:c:d:e' -split ':', 3
# a
# b
# c:d:e       <-- remainder captured in last element

# Split on a word boundary to tokenize
'CamelCaseIdentifier' -split '(?=[A-Z])'
# Camel
# Case
# Identifier
```

The last example uses a **zero-width lookahead** -- `(?=[A-Z])` matches the
position immediately before an uppercase letter without consuming it. The split
happens at the boundary without removing any characters.

---

## `Select-String`: Grep for PowerShell

`Select-String` searches files or strings for pattern matches and returns
`MatchInfo` objects -- not just lines, but structured result objects with file,
line number, and match context.

```powershell
# Search a single file
Select-String -Path ./app.log -Pattern 'ERROR'

# Search recursively across files
Select-String -Path ./logs/*.log -Pattern 'FATAL|CRITICAL'

# Pipe strings in
Get-Content ./server.log | Select-String 'Connection refused'

# Case-sensitive search
Select-String -Path ./app.log -Pattern 'Error' -CaseSensitive

# Show context lines (2 before, 3 after each match)
Select-String -Path ./app.log -Pattern 'FATAL' -Context 2, 3

# Extract just the matched text (not the full line)
Select-String -Path ./app.log -Pattern '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' |
    ForEach-Object { $_.Matches.Value }
```

The `MatchInfo` object has useful properties:

| Property | Content |
|---|---|
| `Filename` | Name of the file |
| `LineNumber` | Line number of the match |
| `Line` | Full text of the matched line |
| `Matches` | Collection of `[System.Text.RegularExpressions.Match]` objects |
| `Context` | Lines before/after (when `-Context` is specified) |

```powershell
# Build a structured error report from log files
$errors = Select-String -Path ./logs/*.log -Pattern '(?<level>ERROR|FATAL)\s+(?<msg>.+)$'
$errors | ForEach-Object {
    [PSCustomObject]@{
        File    = $_.Filename
        Line    = $_.LineNumber
        Level   = $_.Matches[0].Groups['level'].Value
        Message = $_.Matches[0].Groups['msg'].Value
    }
}
```

---

## The `[regex]` Class

For repeated use of the same pattern -- or for operations that operators don't
expose directly -- compile the pattern with the `[regex]` type accelerator.

```powershell
# Compile once, use many times (more efficient in tight loops)
$ipPattern = [regex]'\b(?:\d{1,3}\.){3}\d{1,3}\b'

$logLines | ForEach-Object {
    $m = $ipPattern.Match($_)
    if ($m.Success) { $m.Value }
}

# IsMatch -- boolean test
[regex]::IsMatch('user@example.com', '^[\w.+-]+@[\w-]+\.[\w.]+$')

# Replace with a scriptblock (dynamic replacement)
$pattern = [regex]'(?<user>\w+)@(?<domain>[\w.]+)'
$pattern.Replace('admin@corp.com and guest@corp.com', {
    param($m)
    "$($m.Groups['user'].Value.ToUpper())@$($m.Groups['domain'].Value)"
})
# ADMIN@corp.com and GUEST@corp.com

# Find all matches (not just the first)
$pattern = [regex]'\d+'
$pattern.Matches('Server1 has 4 CPUs and 32 GB RAM') |
    ForEach-Object { $_.Value }
# 1, 4, 32
```

The scriptblock replacement form is only available on the `[regex]` class, not
on the `-replace` operator. Use it when your replacement logic depends on the
matched content in a non-trivial way.

---

## Lookahead and Lookbehind

Zero-width assertions match positions in the string without consuming
characters. They let you write patterns that say "this pattern, but only when
it's followed by / preceded by something else."

```powershell
# Positive lookahead: \d+ followed by 'px'
'The margin is 24px and padding is 8px' -replace '\d+(?=px)', '**'
# The margin is **px and padding is **px

# Negative lookahead: 'error' NOT followed by 's'
# (matches 'error' but not 'errors')
'Found 3 errors, 1 critical error' -replace 'error(?!s)', 'ALERT'
# Found 3 errors, 1 critical ALERT

# Positive lookbehind: digits preceded by '$'
'USD: $1500, EUR: 1200, GBP: $900' -replace '(?<=\$)\d+', 'XXXX'
# USD: $XXXX, EUR: 1200, GBP: $XXXX

# Negative lookbehind: digits NOT preceded by '#'
'Ticket #1234 costs $45 for 3 users' -replace '(?<!#)\b\d+\b', '[N]'
# Ticket #1234 costs $[N] for [N] users
```

Lookaheads and lookbehinds are the difference between "replace a number" and
"replace a number that appears in a specific context." They're worth learning
even if you only use them occasionally -- the patterns that require them have
no clean alternative.

---

## Common Patterns Reference

These patterns cover 80% of real-world text extraction work.

![common-patterns](assets/images/ch-11-patterns.png)

```powershell
# IPv4 address (permissive -- catches 999.999.999.999 too; validate separately)
$ipv4 = '\b(?:\d{1,3}\.){3}\d{1,3}\b'

# Email address (common heuristic, not RFC-complete)
$email = '^[\w.+-]+@[\w-]+\.[\w.]{2,}$'

# ISO date
$isoDate = '\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])'

# 24-hour time
$time24 = '(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?'

# Semantic version
$semver = '\d+\.\d+\.\d+(?:-[\w.]+)?(?:\+[\w.]+)?'

# Windows file path
$winPath = '[A-Za-z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*'

# Common log line (timestamp level message)
$logLine = '(?<date>\d{4}-\d{2}-\d{2})\s+(?<time>\d{2}:\d{2}:\d{2})\s+(?<level>\w+)\s+(?<msg>.+)'
```

---

## Practical Pattern: Log Classifier

Here's the shape of a real-world log analysis script, putting everything
together.

```powershell
function Invoke-LogAnalysis {
    param(
        [Parameter(Mandatory)][string[]]$Path,
        [string]$Since
    )

    $linePattern = [regex]'(?<date>\d{4}-\d{2}-\d{2})\s+(?<time>\d{2}:\d{2}:\d{2})\s+(?<level>FATAL|CRITICAL|ERROR|WARN|WARNING|INFO|DEBUG)\s+(?<msg>.+)'
    $ipPattern   = [regex]'\b(?:\d{1,3}\.){3}\d{1,3}\b'
    $cutoff      = if ($Since) { [datetime]::Parse($Since) } else { [datetime]::MinValue }

    Get-Content $Path | ForEach-Object {
        $m = $linePattern.Match($_)
        if (-not $m.Success) { return }

        $ts = [datetime]::Parse("$($m.Groups['date'].Value) $($m.Groups['time'].Value)")
        if ($ts -lt $cutoff) { return }

        $ips = $ipPattern.Matches($m.Groups['msg'].Value) | ForEach-Object { $_.Value }

        [PSCustomObject]@{
            Timestamp = $ts
            Level     = $m.Groups['level'].Value
            Message   = $m.Groups['msg'].Value
            IPs       = $ips -join ', '
            Severity  = switch -Regex ($m.Groups['level'].Value) {
                'FATAL|CRITICAL' { 'Critical' }
                'ERROR'          { 'Error' }
                'WARN'           { 'Warning' }
                'INFO'           { 'Info' }
                default          { 'Debug' }
            }
        }
    }
}

# Usage
$results = Invoke-LogAnalysis -Path './app.log', './system.log' -Since '2024-01-15'
$results | Where-Object Severity -in 'Critical', 'Error' | Format-Table -AutoSize
$results | Group-Object Severity | Select-Object Name, Count | Sort-Object Count -Descending
```

---

## Exercises

### [Ch-11, Ex-1] Simple: Validate Email Addresses with `-match`

Write a validation check using `-match` that returns `$true` for a valid email
address and `$false` for an invalid one. Test at least one valid and one
invalid case.

### [Ch-11, Ex-2] Normal: Extract IPs from Log Lines

Given an array of log lines (some containing IP addresses, some not), use
`-match` and `$Matches` to extract every IP address found. Return only the
lines that contained an IP.

### [Ch-11, Ex-3] Advanced: Named Captures on Structured Log Lines

> <!-- tier: advanced -->

Parse a structured log line using named capture groups to extract the date,
time, severity level, and source component into separate properties on a
`PSCustomObject`.

### [Ch-11, Ex-4] Extreme: Multi-Pattern Log Analyzer

> <!-- tier: extreme -->

Given an array of log lines with mixed severity levels (`FATAL`, `CRITICAL`,
`ERROR`, `WARN`, `INFO`, `DEBUG`), classify each line into a `Severity`
category (`Critical`, `Error`, `Warning`, `Info`, `Debug`) using a cascading
`-match` strategy. Return structured objects with both the original line and
the assigned severity.

---

## Key Takeaways

- `-match` tests containment; anchor with `^` and `$` for full-string validation.
- `$Matches[0]` is always the full match; `$Matches[1]` onward are capture groups.
- Named captures (`(?<name>pattern)`) turn `$Matches.name` into self-documenting code.
- `-replace` supports back-references (`$1`, `${name}`) in the replacement string.
- `-replace` transforms collection elements; collection-mode `-match` filters
  matching elements and doesn't populate `$Matches`.
- `Select-String` returns `MatchInfo` objects with file, line number, and match context -- not raw strings.
- `[regex]` compiles patterns for reuse and unlocks scriptblock replacements and `Matches()` (all matches, not just first).
- Lookaheads/lookbehinds match positions without consuming characters -- use them for context-sensitive substitution.
- Regex validates shape, not semantics. `999.999.999.999` passes most IP patterns. Validate ranges separately.

---

*Next up: [Chapter 12 -- Modules and Packages](12-modules-and-packages.md), where
we package reusable PowerShell for other people and projects.*
