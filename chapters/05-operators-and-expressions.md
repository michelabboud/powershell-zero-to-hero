# Chapter 05: Operators and Expressions

> *"The right operator in the right place is the difference between a script that works and a script that ruins someone's Friday."*

![chapter-opener](assets/images/ch-05-opener.png)

---

## What You'll Learn

- Comparison operators and their case-sensitive variants
- Wildcard and regex matching
- Logical, arithmetic, and string operators
- Modern PowerShell: ternary, null-coalescing, and the range operator
- Type operators: `-is` and `-as`
- How PowerShell's operator syntax compares to Python, Bash, and C#

---

## 1. The Operator Problem

Rina writes her first PowerShell conditional:

```powershell
if ($x == 5) { "match" }
```

```
ParserError: Unexpected token '==' in expression or statement.
```

She stares at it. Sam wheels his chair over. "Double equals doesn't work here?" Max, from across the room, not looking up: "PowerShell uses `-eq`. We're not savages."

This catches everyone coming from Python, JavaScript, or Bash. PowerShell uses **named operators** for comparisons. There are no symbolic `==`, `!=`, `>`, `<`. The trade-off is zero ambiguity: `-gt` is always greater-than, no matter what types you're comparing.

---

## 2. Comparison Operators

![operators-comparison](assets/images/ch-05-comparison.png)

The core six:

| Operator | Meaning | Example | Result |
|----------|---------|---------|--------|
| `-eq` | Equal | `5 -eq 5` | `True` |
| `-ne` | Not equal | `5 -ne 3` | `True` |
| `-gt` | Greater than | `10 -gt 5` | `True` |
| `-lt` | Less than | `3 -lt 7` | `True` |
| `-ge` | Greater than or equal | `5 -ge 5` | `True` |
| `-le` | Less than or equal | `4 -le 5` | `True` |

```powershell
$age = 30
$age -ge 18    # True
$age -lt 65    # True
$age -eq 31    # False
```

### Case Sensitivity: The Silent Trap

By default, string comparisons in PowerShell are **case-insensitive**. This surprises people from case-sensitive ecosystems.

Both the case-insensitive and case-sensitive comparison operators use .NET's
invariant culture, so their results don't change with the machine's current
locale. The `c` prefix changes case handling; it does not select an ordinal or
byte-by-byte comparison.

```powershell
'Hello' -eq 'hello'    # True  -- case-insensitive by default
'Hello' -eq 'HELLO'    # True
```

If you need case-sensitive matching, prefix with `c`:

| Operator | Case-sensitive version |
|----------|----------------------|
| `-eq` | `-ceq` |
| `-ne` | `-cne` |
| `-gt` | `-cgt` |
| `-lt` | `-clt` |
| `-ge` | `-cge` |
| `-le` | `-cle` |

```powershell
'Hello' -ceq 'hello'    # False -- 'H' != 'h'
'Hello' -ceq 'Hello'    # True
```

There are also explicitly case-**insensitive** variants (`-ieq`, `-ine`, etc.) that read like documentation in code where you want to be explicit. Most people use the unprefixed defaults.

---

## 3. Wildcard Operators: `-like` and `-notlike`

When you need glob-style matching (`*`, `?`, `[range]`), use `-like`:

```powershell
'PowerShell' -like 'Power*'      # True
'PowerShell' -like '*Shell'      # True
'PowerShell' -like 'Power?hell'  # True  (? matches exactly one char)
'PowerShell' -like 'power*'      # True  (case-insensitive)
'PowerShell' -clike 'power*'     # False (case-sensitive wildcard)

'notepad.exe' -notlike '*.dll'   # True
```

Wildcard characters:

| Pattern | Meaning |
|---------|---------|
| `*` | Zero or more characters |
| `?` | Exactly one character |
| `[abc]` | One character from the set |
| `[a-z]` | One character in the range |

```powershell
# Filter files by extension pattern
Get-ChildItem $PSHOME -File |
    Where-Object { $_.Name -like '*.log' }
```

---

## 4. Regex Operators: `-match` and `-notmatch`

For real pattern power, `-match` uses **.NET regular expressions** and, as a bonus, populates the automatic `$Matches` hashtable with captured groups.

```powershell
$log = '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s'

$log -match '(\d{4}-\d{2}-\d{2})\s(\d{2}:\d{2}:\d{2})\s(\w+)\s\[(\w+)\]'
# Returns: True

$Matches[0]   # Full match: '2024-01-15 14:30:22 ERROR [WebServer]'
$Matches[1]   # Capture group 1: '2024-01-15'
$Matches[2]   # Capture group 2: '14:30:22'
$Matches[3]   # Capture group 3: 'ERROR'
$Matches[4]   # Capture group 4: 'WebServer'
```

> **Important:** `$Matches` is only populated on the most recent `-match` call in the current scope. If you're using it inside a loop, capture what you need immediately.

```powershell
# -notmatch: the logical inverse
'hello@example.com' -notmatch '@'      # False (it does match)
'not-an-email' -notmatch '@'           # True

# Case-sensitive regex variant
'PowerShell' -cmatch '^power'          # False (capital P required)
'PowerShell' -cmatch '^Power'          # True
```

---

## 5. Logical Operators

Combine conditions with:

| Operator | Symbol shorthand | Meaning |
|----------|-----------------|---------|
| `-and` | (none) | Both must be true |
| `-or` | (none) | At least one must be true |
| `-not` | `!` | Invert a boolean |
| `-xor` | (none) | Exactly one must be true |

```powershell
$user = 'admin'
$role = 'sysop'

$user -eq 'admin' -and $role -eq 'sysop'    # True
$user -eq 'guest' -or  $role -eq 'sysop'    # True
-not ($user -eq 'guest')                     # True
!($user -eq 'guest')                         # True  (same as -not)

# Short-circuit evaluation: -and stops at first False
# -or stops at first True
$false -and (1/0 -eq 0)    # False (division never evaluated)
$true  -or  (1/0 -eq 0)    # True  (division never evaluated)
```

---

## 6. Arithmetic Operators

Nothing exotic here, but a few PowerShell touches are worth knowing:

```powershell
10 + 3      # 13
10 - 3      # 7
10 * 3      # 30
10 / 3      # 3.3333...
10 % 3      # 1  (modulo)
```

### Type-driven `+`

The `+` operator changes behavior based on the **left operand's type**:

```powershell
1 + '2'           # 3      (int + string coercion → int arithmetic)
'1' + 2           # '12'   (string + anything → string concatenation)
@(1,2) + @(3,4)   # @(1,2,3,4)  (array concatenation)
```

This trips people up. When in doubt, be explicit: `[int]'2'` or `"$number"`.

### Size multipliers (built-in constants)

```powershell
1KB    # 1024
1MB    # 1048576
1GB    # 1073741824
1TB    # 1099511627776

# Practical example: is a file larger than 100 MB?
(Get-Item 'bigfile.iso').Length -gt 100MB
```

---

## 7. String Operators

PowerShell has dedicated operators for common string operations so you don't have to reach for .NET methods every time.

### `-replace`

Uses regex. Returns a new string -- PowerShell strings are immutable.

```powershell
'Hello, World!' -replace 'World', 'PowerShell'   # 'Hello, PowerShell!'
'foo123bar' -replace '\d+', 'NUM'                 # 'fooNUMbar'
'  spaces  ' -replace '^\s+|\s+$', ''             # 'spaces' (trim)
```

### `-split`

```powershell
'one,two,three' -split ','         # @('one', 'two', 'three')
'one  two   three' -split '\s+'    # @('one', 'two', 'three')
'a:b:c:d' -split ':', 2            # @('a', 'b:c:d')  (max 2 parts)
```

### `-join`

```powershell
@('one', 'two', 'three') -join ', '    # 'one, two, three'
@('GET', '/api/users', 'HTTP/1.1') -join ' '  # 'GET /api/users HTTP/1.1'
```

```powershell
# A real workflow: parse a CSV-style string, transform, rejoin
$raw = 'alice,bob,charlie,dave'
$processed = ($raw -split ',') | ForEach-Object { $_.ToUpper() }
$processed -join ' | '
# Output: 'ALICE | BOB | CHARLIE | DAVE'
```

---

## 8. Type Operators: `-is` and `-as`

### `-is` and `-isnot`

Check the runtime type of a value:

```powershell
42 -is [int]           # True
42 -is [string]        # False
'hello' -is [string]   # True
(Get-Date) -is [DateTime]   # True

42 -isnot [string]     # True
```

### `-as`

Safe type conversion. Returns `$null` if conversion fails (unlike hard casts which throw):

```powershell
'42' -as [int]          # 42
'not-a-number' -as [int]    # $null  (no exception!)
'2024-01-15' -as [DateTime] # Monday, January 15, 2024 ...

# Compare to hard cast -- this throws:
[int]'not-a-number'     # InvalidArgument exception
```

```powershell
# Safe pattern: try to convert, check for null
$value = $userInput -as [int]
if ($null -eq $value) {
    Write-Warning "Input is not a valid integer"
} else {
    "You entered: $value"
}
```

---

## 9. The Range Operator `..`

Create integer sequences without a loop:

```powershell
1..10                  # @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
10..1                  # Descending: @(10, 9, 8 ... 1)
1..5 | ForEach-Object { $_ * $_ }   # @(1, 4, 9, 16, 25)

# Slice an array by index range
$letters = 'a'..'z'    # @('a', 'b', 'c', ..., 'z')  yes, chars too
$letters[0..4]         # @('a', 'b', 'c', 'd', 'e')
```

```powershell
# Quick port scan stub (educational example)
80..85 | ForEach-Object {
    "Checking port $_..."
}
```

The range operator produces a materialized array. For a very large sequence,
use a counter-based `for` loop so PowerShell doesn't build the entire range in
memory before the loop begins.

---

## 10. Modern PowerShell: Ternary and Null-Coalescing

These landed in **PowerShell 7.0** and were immediately controversial among people who learned PowerShell before 2020. They're standard now. Use them.

### Ternary operator `? :`

```powershell
$age = 20
$status = $age -ge 18 ? 'adult' : 'minor'
# $status = 'adult'

# Equivalent legacy form (works everywhere):
$status = if ($age -ge 18) { 'adult' } else { 'minor' }
```

### Null-coalescing `??`

Return the left value if it's not `$null`, otherwise return the right value:

```powershell
$name = $null
$displayName = $name ?? 'Anonymous'
# $displayName = 'Anonymous'

$name = 'Sam'
$displayName = $name ?? 'Anonymous'
# $displayName = 'Sam'
```

### Null-coalescing assignment `??=`

Assign to a variable only if it's currently `$null`:

```powershell
$config = $null
$config ??= 'default.json'
# $config is now 'default.json'

$config ??= 'other.json'
# $config is still 'default.json' -- it's no longer null
```

```powershell
# Real-world pattern: provide defaults for missing environment variables
$logLevel = $env:LOG_LEVEL ?? 'info'
$outputDir = $env:OUTPUT_DIR ?? "$HOME/output"
$maxRetries = ($env:MAX_RETRIES -as [int]) ?? 3
```

Max approval-stamps this pattern every code review. It's cleaner than four lines of `if (-not $var) { $var = 'default' }`.

---

## 11. Operator Precedence

For the operators introduced in this chapter, PowerShell evaluates them in
this order (highest to lowest):

1. `()` -- parentheses (always first)
2. Unary `-not`, `!`
3. Arithmetic: `*`, `/`, `%`
4. Arithmetic: `+`, `-`
5. Comparison: `-eq`, `-ne`, `-gt`, `-lt`, `-ge`, `-le`, `-like`, `-match`, `-is`, `-as`
6. Logical AND: `-and`
7. Logical XOR: `-xor`
8. Logical OR: `-or`

```powershell
# Without parens: comparison before -and
5 -gt 3 -and 10 -lt 20     # True  (both are True)

# Arithmetic before comparison
2 + 3 -gt 4                # True  (5 > 4)

# Force order with parens
-not (5 -eq 5 -or 3 -eq 3) # False (-not True)
```

When in doubt, **add parentheses**. They cost nothing and save debugging sessions.

---

## Boss Level

> <!-- tier: extreme -->
> PowerShell's `-replace` operator uses .NET regex with **substitution patterns** in the replacement string. The `$1`, `$2` syntax references captured groups.
>
> Write a function `Format-LogLine` that takes a raw log string in the format:
> `2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s`
>
> And returns a reformatted string:
> `[2024-01-15 14:30:22] [ERROR] [WebServer] Connection timeout after 30s`
>
> Requirements: use a **single `-replace` call**. No intermediate variables, no `-split`, no `$Matches`.

```powershell
# boss-level-05.ps1 -- single-replace log reformatter
function Format-LogLine {
    param([string]$LogLine)

    $LogLine -replace '^(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})\s+(\w+)\s+\[(\w+)\]\s+(.*)',
                      '[$1 $2] [$3] [$4] $5'
}

# Test it
$lines = @(
    '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s'
    '2024-01-15 14:31:05 INFO  [Auth]      User alice logged in'
    '2024-01-15 14:32:44 WARN  [Database]  Query took 2400ms'
)

$lines | ForEach-Object { Format-LogLine $_ }
```

Output:

```
[2024-01-15 14:30:22] [ERROR] [WebServer] Connection timeout after 30s
[2024-01-15 14:31:05] [INFO] [Auth] User alice logged in
[2024-01-15 14:32:44] [WARN] [Database] Query took 2400ms
```

---

## Exercises

### [Ch-05, Ex-1] Simple: Case-Sensitive String Comparison

Compare the strings `'Hello'` and `'hello'` using both `-eq` and `-ceq`. Explain why one returns `$true` and the other returns `$false`. Then write a short function `Test-ExactMatch` that takes two strings and returns `$true` only when they match case-sensitively.

```powershell
# Part 1: explore the difference
'Hello' -eq 'hello'     # What does this return?
'Hello' -ceq 'hello'    # What does this return?

# Part 2: write the function
function Test-ExactMatch {
    param([string]$A, [string]$B)
    # Your code here
}

Test-ExactMatch -A 'Hello' -B 'hello'   # should be False
Test-ExactMatch -A 'Hello' -B 'Hello'   # should be True
```

### [Ch-05, Ex-2] Normal: Filter an Array with Multiple Operators

Create an array of integers from 1 to 20 using the range operator. Then filter it to keep only numbers that are **greater than 5 AND less than or equal to 15**. Display the result and verify the count is correct.

```powershell
$nums = 1..20

$filtered = $nums | Where-Object {
    # Your conditions here
}

"Count: $($filtered.Count)"  # Should be 10
$filtered                     # Should be 6..15
```

### [Ch-05, Ex-3] Advanced: Regex Extraction from a Log Line

> <!-- tier: advanced -->

Given this log line:

```
2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s
```

Use `-match` to extract:
- The date (`2024-01-15`)
- The time (`14:30:22`)
- The severity level (`ERROR`)
- The component (`WebServer`)

Store each in a named variable and display a summary table using `[PSCustomObject]`.

```powershell
$log = '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s'

if ($log -match '<your pattern here>') {
    [PSCustomObject]@{
        Date      = $Matches[1]
        Time      = $Matches[2]
        Severity  = $Matches[3]
        Component = $Matches[4]
    }
}
```

### [Ch-05, Ex-4] Extreme: Dynamic Query Builder with Splatting

> <!-- tier: extreme -->

Build a function `Get-FilteredProcess` that accepts a hashtable of optional criteria and constructs a filtered process query dynamically. Use **splatting** to pass the `Name` parameter to `Get-Process` only when provided, and use operator expressions (`-ge`, `??=`) to handle missing keys gracefully.

```powershell
function Get-FilteredProcess {
    param(
        [hashtable]$Criteria
    )

    # Build the splat for Get-Process conditionally
    $splat = @{}
    if ($Criteria.Name) { $splat['Name'] = $Criteria.Name }

    # Apply additional filters with comparison operators
    Get-Process @splat | Where-Object {
        $minCPU = $Criteria.MinCPU ?? 0
        $maxMem = $Criteria.MaxMemoryMB ?? [int]::MaxValue

        $_.CPU -ge $minCPU -and
        ($_.WorkingSet64 / 1MB) -le $maxMem
    }
}

# Usage examples
Get-FilteredProcess -Criteria @{ Name = 'pwsh'; MinCPU = 0 }
Get-FilteredProcess -Criteria @{ MaxMemoryMB = 200 }
Get-FilteredProcess -Criteria @{ MinCPU = 1; MaxMemoryMB = 500 }
```

---

## Summary

You now have the full operator toolkit for PowerShell expressions:

- **Comparison** (`-eq`, `-ne`, `-gt`, `-lt`, `-ge`, `-le`) are always named, always readable
- **Case sensitivity** is opt-in via the `c` prefix (`-ceq`, `-clike`, `-cmatch`)
- **Wildcards** (`-like`) for glob patterns, **regex** (`-match`) for real pattern power -- and `$Matches` captures groups automatically
- **Logical** (`-and`, `-or`, `-not`) compose conditions cleanly
- **String operators** (`-replace`, `-split`, `-join`) keep you out of .NET method calls for the common cases
- **Type operators** (`-is`, `-as`) let you inspect and safely convert types
- **Range** (`..`) gives you sequences without loops
- **Ternary** (`? :`), **null-coalescing** (`??`), and **null-coalescing assignment** (`??=`) are your modernization kit for cleaner defaults and conditionals

The pattern: when you're tempted to write four lines of `if ($thing)`, there's usually a one-liner waiting with the right operator.

---

*Next: [Chapter 06 -- Control Flow](06-control-flow.md)*
