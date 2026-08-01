# Chapter 04 -- Answers

---

## Ch-04, Ex-1 (Simple)

**Task:** Create one variable of each of the following types and verify each
with `.GetType().Name`: `String`, `Int32`, `Boolean`, `Object[]`, `Hashtable`.

### Solution

```powershell
$str  = "hello"
$int  = 42
$bool = $true
$arr  = @(1, 2, 3)
$hash = @{ a = 1 }

$str.GetType().Name    # String
$int.GetType().Name    # Int32
$bool.GetType().Name   # Boolean
$arr.GetType().Name    # Object[]
$hash.GetType().Name   # Hashtable
```

### Expected Output

```
String
Int32
Boolean
Object[]
Hashtable
```

### What to notice

PowerShell infers types silently. You didn't write `[string]$str` or
`[int]$int` -- you just assigned a value and the runtime figured it out.
This is dynamic typing at work.

Two things worth burning into memory:

1. **Arrays report as `Object[]`** (`System.Object[]`), not `Array`. If you
   check with `.GetType().BaseType.Name` you'll get `Array` -- that's the
   abstract base class. The concrete type is always `Object[]` for a plain
   `@()` array. The Pester test uses `.BaseType.Name` for this reason.

2. **`$true` is a `Boolean`, not an integer.** In Bash, true/false are
   exit codes. In PowerShell, they are proper .NET `System.Boolean` objects.
   `$true.GetType().Name` gives you `Boolean`, not `Int32`. This matters when
   you pass values to .NET methods that are type-strict.

---

## Ch-04, Ex-2 (Normal)

**Task:** Build an array of three hashtables, each representing a server with
keys `Name`, `IP`, and `Role`. Verify the array has three elements and that
the first element contains the key `Name`.

### Solution

```powershell
$servers = @(
    @{ Name = 'web01'; IP = '10.0.0.1'; Role = 'Web'      },
    @{ Name = 'db01';  IP = '10.0.0.2'; Role = 'Database' },
    @{ Name = 'app01'; IP = '10.0.0.3'; Role = 'App'      }
)

$servers.Count          # 3
$servers[0].Keys        # Name, IP, Role (order may vary -- hashtables are unordered)
$servers[0].Name        # web01
$servers | ForEach-Object { "$($_.Name) -- $($_.IP) -- $($_.Role)" }
```

### Expected Output

```
3
Name IP Role
web01 -- 10.0.0.1 -- Web
db01  -- 10.0.0.2 -- Database
app01 -- 10.0.0.3 -- App
```

### What to notice

This pattern -- an array of hashtables -- is PowerShell's equivalent of a
"list of records" and appears constantly in real scripts: server inventories,
configuration sets, test data, API payloads. Three things to absorb:

1. **Hashtable key order is not guaranteed.** `$servers[0].Keys` might return
   `IP`, `Role`, `Name` in any sequence. If display order matters, use
   `[ordered]@{}` or convert to `PSCustomObject`. For data access by key name,
   order is irrelevant -- `$servers[0].Name` always works.

2. **Dot notation vs bracket notation.** `$servers[0].Name` and
   `$servers[0]['Name']` are identical. Dot notation is cleaner for known keys;
   bracket notation is essential when the key name is stored in a variable:
   `$servers[0][$keyName]`.

3. **Semicolons inside `@{}`** are just key-value separators when you keep
   everything on one line. Newlines work just as well -- it's a style choice.
   The multi-line form is easier to read in production; the single-line form
   is handy for quick one-liners.

---

## Ch-04, Ex-3 (Advanced)

> <!-- tier: advanced -->

**Task:** Demonstrate string interpolation with `$()`, a here-string with
interpolation, and the `-f` format operator -- each producing visible output.

### Solution

```powershell
# 1. Double-quoted interpolation with subexpression
$servers = @('web01', 'db01', 'app01')
"We are managing $($servers.Count) servers in this environment."

# 2. Here-string with interpolation
$hostname = $env:COMPUTERNAME
$report = @"
=== Daily Status Report ===
Host       : $hostname
Generated  : $(Get-Date -Format 'yyyy-MM-dd HH:mm')
PS Version : $($PSVersionTable.PSVersion)
User       : $env:USERNAME
"@
$report

# 3. Format operator -f
$name    = "PowerShell"
$version = 7
$pad     = 12
'Tool: {0,-12} Version: {1}' -f $name, $version
'Memory: {0:N2} MB' -f ((Get-Process -Id $PID).WorkingSet64 / 1MB)
```

### Expected Output

```
We are managing 3 servers in this environment.

=== Daily Status Report ===
Host       : WORKSTATION01
Generated  : 2026-03-17 09:42
PS Version : 7.4.6
User       : sam

Tool: PowerShell   Version: 7
Memory: 142.87 MB
```

(Actual values for hostname, date, version, and memory will vary.)

### What to notice

Three distinct string systems, each with its own strength:

1. **`$()` inside double quotes** is how you interpolate *expressions*, not
   just variables. `"Count: $servers.Count"` would give you `Count: web01
   db01 app01.Count` -- PowerShell expands `$servers` (the whole array) and
   then treats `.Count` as literal text. Always wrap method calls and property
   accesses in `$()` inside strings.

2. **Here-strings** shine for templated documents. Notice that `$env:USERNAME`
   works directly without `$()` -- simple variable references don't need it.
   The `"@` closing delimiter must be at column zero (no leading spaces or
   tabs). One misplaced space and PowerShell throws a parse error that looks
   completely unrelated. Ask anyone who's been burned by it.

3. **`-f` format strings** are lifted directly from .NET's
   `String.Format()`. The `{0:N2}` syntax means "argument 0, formatted as a
   number with 2 decimal places." Other useful specifiers: `{0:D}` (integer),
   `{0:X}` (hex), `{0:yyyy-MM-dd}` (date). Left-padding with `{0,-12}` is
   particularly useful for building aligned columnar output without
   `Format-Table`.

---

## Ch-04, Ex-4 (Extreme)

> <!-- tier: extreme -->

**Task:** Build a nested hashtable with 3+ top-level keys, each holding a
sub-hashtable. At least two values must be explicitly type-cast. Validate the
structure programmatically.

### Solution

```powershell
# Build the nested config
$config = @{
    Server = @{
        Host    = 'localhost'
        Port    = [int]8080
        TLS     = [bool]$true
    }
    Database = @{
        ConnectionString = 'Server=.;Database=AppDB;Integrated Security=True'
        Timeout          = [int]30
        PoolSize         = [int]10
    }
    Logging = @{
        Level  = 'Info'
        Path   = '/var/log/app'
        Rotate = [bool]$true
        MaxMB  = [int]100
    }
}

# Validation block
Write-Host "--- Config Validation ---"

# Top-level key count
$keyCount = $config.Keys.Count
"Top-level sections : $keyCount"
if ($keyCount -ne 3) { throw "Expected 3 top-level keys, got $keyCount" }

# Type checks
$portType    = $config.Server.Port.GetType().Name
$timeoutType = $config.Database.Timeout.GetType().Name
"Server.Port type    : $portType"
"Database.Timeout type: $timeoutType"
if ($config.Server.Port     -isnot [int]) { throw "Port must be [int]"    }
if ($config.Database.Timeout -isnot [int]) { throw "Timeout must be [int]" }

# Access a nested value
"Logging.MaxMB value : $($config.Logging.MaxMB)"
"Logging.MaxMB type  : $($config.Logging.MaxMB.GetType().Name)"

Write-Host "All validations passed." -ForegroundColor Green
```

### Expected Output

```
--- Config Validation ---
Top-level sections : 3
Server.Port type    : Int32
Database.Timeout type: Int32
Logging.MaxMB value : 100
Logging.MaxMB type  : Int32
All validations passed.
```

### What to notice

This exercise combines every type concept from the chapter into one realistic
pattern. Several things deserve attention:

1. **`[int]8080` vs `8080`.** Without the cast, `8080` is *already* an `Int32`
   here -- PowerShell infers it. The explicit cast is about **intent**:
   documenting that this must be an integer, making the code self-explanatory,
   and ensuring that if someone later changes the value to `'8080'` (a string
   from a config file), the cast will enforce the correct type rather than
   silently propagating a string into a context that expects a number.

2. **`-isnot [int]` operator.** PowerShell has `-is` and `-isnot` for
   type-checking. They check the runtime type including inheritance, so
   `42 -is [int]` is `$true`, and `42 -is [object]` is also `$true` (because
   everything inherits from `[object]`). Use `-is` for validation logic
   rather than `.GetType().Name -eq 'Int32'` -- it handles subclasses correctly.

3. **Nested access with dot notation.** `$config.Server.Port` works for
   accessing nested hashtable values the same way it does for object
   properties. PowerShell resolves each key hop in sequence. This is syntactic
   sugar -- under the hood it's calling the hashtable indexer at each step.

4. **`throw` for hard validation failures.** In a production config loader,
   you'd use `throw` (or `Write-Error -ErrorAction Stop`) when a validation
   fails, not `Write-Warning`. Scripts that silently continue past a bad
   config are much harder to debug than scripts that fail loudly at the point
   of the problem. Max has the scars to prove it.

5. **Why `[bool]$true` and not just `$true`?** You're right that it's
   redundant here -- `$true` is already a `Boolean`. In this exercise, the
   explicit `[bool]` is pedagogical: showing how you *would* cast if the
   value came from user input, a CSV file, or an environment variable (where
   it might arrive as a string `"True"`). `[bool]"True"` evaluates to `$true`.
   `[bool]"False"` also evaluates to `$true` -- because any non-empty string
   is truthy. If you're parsing boolean strings from config files, use
   `[System.Convert]::ToBoolean("False")` instead, which handles it correctly.
