# Chapter 04: Variables and Types

> *"Why does `'2' + 2` give me `'22'`?" -- Sam. "Welcome to types. PowerShell is helpful... sometimes too helpful." -- Max.*

![chapter-opener](assets/images/ch-04-opener.png)

---

## What You'll Learn

- How to declare and use variables with `$variable` syntax
- PowerShell's automatic variables (`$_`, `$PSVersionTable`, `$null`, `$true`, `$false`)
- String quoting rules: single vs double, and when it matters
- Here-strings for multi-line text blocks
- Numbers, arrays, and hashtables
- Type casting and `.GetType()` for type introspection

---

## Variables: Dollar Signs All the Way Down

In PowerShell, every variable starts with `$`. That's it. That's the whole syntax rule.

```powershell
$name    = "Sam"
$count   = 42
$running = $true
```

No `var`, no `let`, no `const`. Just `$` and a name. PowerShell infers the type
automatically based on the value you assign -- a system called **dynamic typing**.
This is convenient until it quietly does something you didn't expect, which brings
us right back to Sam's problem.

### Naming Rules

Variable names are case-insensitive (`$Name` and `$name` are the same variable)
and can contain letters, numbers, and underscores. By convention, use
**camelCase** for local variables and **PascalCase** for parameters.

```powershell
$serverName  = "web01"       # camelCase -- local variable, fine
$ServerName  = "web01"       # PascalCase -- same variable! just a style choice
$server_name = "web01"       # valid, but unusual in PowerShell
```

> **Note for Bash people (hi, Rina):** In Bash, `$` is for reading a variable;
> you write it bare: `name="Sam"`. In PowerShell, `$` is always there --
> on reads *and* on writes. If you forget it when writing, PowerShell will
> tell you. Loudly.

---

## Automatic Variables

PowerShell ships with a set of variables that are always defined for you. These
are called **automatic variables**. Some are read-only constants; others update
as your script runs.

![auto-vars](assets/images/ch-04-auto-vars.png)

### The Most Useful Automatic Variables

| Variable          | What It Is                                               |
|-------------------|----------------------------------------------------------|
| `$_`              | The current object in a pipeline (alias: `$PSItem`)      |
| `$null`           | Explicit nothing -- not zero, not empty string           |
| `$true`           | Boolean true (read-only constant)                        |
| `$false`          | Boolean false (read-only constant)                       |
| `$PSVersionTable` | Hashtable of PowerShell version information              |
| `$Error`          | Array of the most recent errors (newest at index 0)      |
| `$HOME`           | Current user's home directory                            |
| `$env:PATH`       | The system PATH (and any other environment variable)     |

```powershell
# $_ in action -- current pipeline object
Get-Process | Where-Object { $_.CPU -gt 10 }

# $null -- checking for missing values
$value = $null
if ($value -eq $null) { "Nothing here" }

# $PSVersionTable -- what version are we on?
$PSVersionTable.PSVersion

# Environment variables via $env:
$env:USERNAME
$env:COMPUTERNAME
```

---

## Strings: Quoting Is Not Optional

PowerShell has two flavours of string literal. They look similar. They behave
very differently.

### Single Quotes: What You See Is What You Get

Single-quoted strings are **literal**. No substitution, no escape sequences,
no funny business.

```powershell
$name = "Sam"
'Hello, $name'       # Output: Hello, $name   (literal dollar sign)
'Line1`nLine2'       # Output: Line1`nLine2   (literal backtick-n)
```

Use single quotes when you want the string exactly as written -- regex patterns,
paths with backslashes, anything where you don't want PowerShell second-guessing you.

### Double Quotes: The Expressive One

Double-quoted strings support **variable interpolation** and **escape sequences**.

```powershell
$name = "Sam"
"Hello, $name"       # Output: Hello, Sam
"Tab:`there"         # Output: Tab:    here
"Line1`nLine2"       # Output: two lines
```

You can embed entire expressions using `$()` -- the **subexpression operator**:

```powershell
$servers = @("web01", "db01", "app01")
"We manage $($servers.Count) servers."
# Output: We manage 3 servers.
```

Without the `$()`, PowerShell would expand `$servers` to its string
representation and then try to access `.Count` as a literal character -- which
is not what you want.

### The Format Operator: `-f`

When interpolation gets messy, reach for `-f`. It's .NET's string format method
in operator form:

```powershell
$name = "PowerShell"
$ver  = 7
'{0} version {1}' -f $name, $ver
# Output: PowerShell version 7

'Server: {0,-10} IP: {1}' -f 'web01', '10.0.0.1'
# Output: Server: web01       IP: 10.0.0.1
```

The `{0}`, `{1}` are positional placeholders. Optionally add `,N` for padding
(negative = left-aligned, positive = right-aligned). This pattern shines when
you're building formatted reports or log lines.

### Here-Strings: Multi-Line Without the Mess

A here-string lets you write multi-line text without escaping anything. The
opening `@"` and closing `"@` must be at the start of their lines.

```powershell
# Double-quoted here-string (supports interpolation)
$server = "web01"
$report = @"
Server Report
=============
Hostname : $server
Date     : $(Get-Date -Format 'yyyy-MM-dd')
Status   : Online
"@

# Single-quoted here-string (fully literal -- great for regex or JSON templates)
$pattern = @'
^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$
'@
```

Here-strings are invaluable for embedding JSON, XML, SQL queries, or any
multi-line text where escaping would become a maintenance nightmare.

---

## Numbers

PowerShell infers numeric types based on the value:

```powershell
$i   = 42           # [int]    -- System.Int32
$big = 10000000000  # [long]   -- System.Int64 (too big for Int32)
$pi  = 3.14159      # [double] -- System.Double
```

### Arithmetic and Size Multipliers

PowerShell knows about common byte-size multipliers. They're genuine integer
constants, not string parsing tricks:

```powershell
1KB   # 1024
1MB   # 1048576
1GB   # 1073741824
1TB   # 1099511627776

# Practical example
$diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
```

---

## Arrays

An array is an ordered collection of objects. Use `@()` to create one explicitly:

```powershell
$empty  = @()
$colors = @('red', 'green', 'blue')
$mixed  = @(1, 'two', $true, $null)   # PowerShell arrays are untyped by default
```

Access elements by index (zero-based). Negative indices count from the end:

```powershell
$colors[0]    # 'red'
$colors[-1]   # 'blue'  (last element)
$colors[1..2] # @('green', 'blue')  (range operator)
```

Add to an array with `+=`. Fair warning: this creates a new array under the
hood each time (because arrays are fixed-size in .NET). For heavy append
workloads, use `[System.Collections.Generic.List[object]]` instead.

```powershell
$colors += 'yellow'   # works, but allocates a new array
```

---

## Hashtables

A hashtable stores **key/value pairs**. This is PowerShell's equivalent of
a dictionary, a map, or -- for Rina -- a Python `dict`.

```powershell
$server = @{
    Name = 'web01'
    IP   = '10.0.0.1'
    Role = 'Web'
}

# Access by key
$server['Name']    # 'web01'
$server.Name       # same thing -- dot notation works too

# Add or update a key
$server.Port = 443

# Remove a key
$server.Remove('Port')

# Iterate
$server.GetEnumerator() | Sort-Object Key
```

Hashtables are **unordered by default**. If key order matters (e.g., for
display), use `[ordered]`:

```powershell
$config = [ordered]@{
    Host    = 'localhost'
    Port    = 5432
    Timeout = 30
}
```

---

## Type Hierarchy

Everything in PowerShell is a .NET object. Understanding the hierarchy helps
you predict how types behave when mixed.

![type-hierarchy](assets/images/ch-04-type-hierarchy.png)

| Type Literal   | .NET Type              | Example Value          |
|----------------|------------------------|------------------------|
| `[string]`     | `System.String`        | `"hello"`              |
| `[int]`        | `System.Int32`         | `42`                   |
| `[long]`       | `System.Int64`         | `10000000000`          |
| `[double]`     | `System.Double`        | `3.14`                 |
| `[bool]`       | `System.Boolean`       | `$true`                |
| `[datetime]`   | `System.DateTime`      | `Get-Date`             |
| `[array]`      | `System.Object[]`      | `@(1, 2, 3)`           |
| `[hashtable]`  | `System.Collections.Hashtable` | `@{a=1}`     |

---

## Type Casting

You can coerce a value into a specific type by prefixing it with `[TypeName]`:

```powershell
[int]'42'           # converts string to integer: 42
[string]99          # converts integer to string: "99"
[bool]0             # $false  (0 is falsy in .NET)
[bool]1             # $true
[double]'3.14'      # 3.14
[datetime]'2024-01-15'  # a proper DateTime object
```

Casting is **strict** -- if the conversion fails, you get a terminating error:

```powershell
[int]'banana'   # ERROR: Cannot convert "banana" to type "System.Int32"
```

This is actually useful. Putting `[int]` on a variable declaration enforces
the type for the lifetime of that variable:

```powershell
[int]$port = 8080
$port = 'http'    # ERROR -- PowerShell refuses to store a non-integer
```

That's how you get self-documenting, self-validating variables. Max uses this
trick in every production script he writes.

---

## `.GetType()`: Interrogate Any Value

When in doubt about what you're holding, ask it:

```powershell
42 .GetType()
# IsPublic IsSerial Name   BaseType
# -------- -------- ----   --------
# True     True     Int32  System.ValueType

"hello".GetType().FullName   # System.String
(Get-Date).GetType().Name    # DateTime
@().GetType().Name           # Object[]
@{}.GetType().Name           # Hashtable
```

This is your debugging companion. Before you write `$x.SomeProperty`, run
`$x.GetType()` to confirm what you're dealing with. Rina does this out of
habit every time she gets an unexpected result -- a habit worth stealing.

---

## Back to Sam's Problem

```powershell
'2' + 2
```

PowerShell sees a **string** on the left side of `+`, so it promotes the
right-hand `2` to a string and concatenates: `'22'`. This is operator
**left-hand-type precedence** -- the left operand wins.

```powershell
2 + '2'    # 4  -- integer wins, string is cast to int
'2' + 2    # '22' -- string wins, int is cast to string
```

The fix when you actually want arithmetic:

```powershell
[int]'2' + 2    # 4  -- explicit cast before the operation
```

Once you understand left-hand precedence, PowerShell's "helpfulness" becomes
predictable. It never changes the rule -- it just picks it based on what's
already on the left.

---

## Exercises

### [Ch-04, Ex-1] Simple: Five Types, Five Proofs

Create one variable of each of the following types and call `.GetType().Name`
on each to verify PowerShell's inference: `String`, `Int32`, `Boolean`,
`Object[]` (array), `Hashtable`.

### [Ch-04, Ex-2] Normal: Array of Server Hashtables

Build an array of three hashtables, each representing a server with keys
`Name`, `IP`, and `Role`. Verify the array has three elements and that each
element contains the `Name` key.

### [Ch-04, Ex-3] Advanced: String Kung Fu

> <!-- tier: advanced -->

Demonstrate three string techniques in a single script:

1. Double-quoted interpolation with a subexpression `$()`
2. A here-string that spans at least four lines and uses an interpolated variable
3. The `-f` format operator with at least two positional arguments

Each technique should produce visible, verifiable output.

### [Ch-04, Ex-4] Extreme: Nested Config Hashtable

> <!-- tier: extreme -->

Build a nested hashtable representing an application configuration system
with at least three top-level keys, each holding a sub-hashtable. At least
two values must be explicitly type-cast (e.g., `[int]`, `[bool]`). After
building it, write a validation block that:

- Confirms the top-level key count equals 3
- Confirms a nested integer value is of type `[int]`
- Confirms a nested integer value is of type `[int]`
- Accesses a third-level value if you have one (bonus depth)

---

## Key Takeaways

- Variables always start with `$`. PowerShell is case-insensitive but
  convention-sensitive.
- Automatic variables (`$_`, `$null`, `$true`, `$false`, `$PSVersionTable`)
  are always available -- learn them once, use them everywhere.
- **Single quotes are literal. Double quotes interpolate.** When unsure, ask
  yourself: "do I want PowerShell to expand anything in here?"
- Arrays use `@()`, hashtables use `@{}`. The difference is critical and not
  just syntactic.
- Type casting with `[TypeName]` is how you assert intent and catch bugs early.
  Use it in production scripts.
- `'2' + 2` equals `'22'` because the left operand sets the type. This is not
  a bug. It is a rule. Now you know the rule.

---

*Next up: [Chapter 05 -- Operators and Expressions](05-operators-and-expressions.md),
where we learn how values combine, compare, and transform.*
