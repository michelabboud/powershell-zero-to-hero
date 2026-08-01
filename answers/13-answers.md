# Chapter 13 -- Answers

---

## Ch-13, Ex-1 (Simple)

**Task:** Create a `[PSCustomObject]` representing a server with four properties
(`Name`, `IP`, `Role`, `Status`), pipe it to `Format-Table`, then build a
two-item array and pipe that to `Format-Table -AutoSize`.

### Solution

```powershell
# Single object
$server = [PSCustomObject]@{
    Name   = 'web01'
    IP     = '10.0.0.1'
    Role   = 'WebServer'
    Status = 'Running'
}

$server | Format-Table

# Two-item collection
$servers = @(
    [PSCustomObject]@{
        Name   = 'web01'
        IP     = '10.0.0.1'
        Role   = 'WebServer'
        Status = 'Running'
    }
    [PSCustomObject]@{
        Name   = 'db01'
        IP     = '10.0.0.2'
        Role   = 'Database'
        Status = 'Stopped'
    }
)

$servers | Format-Table -AutoSize
```

### Expected Output

```
Name  IP        Role      Status
----  --        ----      ------
web01 10.0.0.1  WebServer Running

Name  IP        Role      Status
----  --        ----      ------
web01 10.0.0.1  WebServer Running
db01  10.0.0.2  Database  Stopped
```

### What to notice

**Property order is preserved.** The `[PSCustomObject]@{}` cast keeps the
property order you defined. A plain `@{}` hashtable randomises order because
hashtables are unordered dictionaries. When the object reaches `Format-Table`,
it uses that preserved order to build column headings. If property order
matters in your output -- and it usually does -- always cast with
`[PSCustomObject]@{}`, never just `@{}`.

**`PSObject.Properties` is the object's introspection API.** You can inspect
what properties an object has at runtime with
`$server.PSObject.Properties.Name`. This is the same mechanism Pester uses
when it asserts `-Contain 'Status'`. It is useful whenever you need to
validate an object's shape programmatically rather than just its values.

---

## Ch-13, Ex-2 (Normal)

**Task:** Use `[datetime]` and `[math]` static methods to build a small uptime
report. Given a `$startDate` string in `'yyyy-MM-dd'` format, calculate:
days running, full weeks and remaining days, and total hours rounded to
1 decimal place.

### Solution

```powershell
$startDate = '2024-01-15'

# Parse the start date strictly
$start = [datetime]::ParseExact($startDate, 'yyyy-MM-dd', $null)
$now   = [datetime]::UtcNow

# Elapsed timespan
$uptime = $now - $start

# Calculations using [math] static methods
$totalDays  = $uptime.Days
$fullWeeks  = [math]::Floor($totalDays / 7)
$remDays    = $totalDays % 7
$totalHours = [math]::Round($uptime.TotalHours, 1)

# Report
Write-Host "System start : $($start.ToString('yyyy-MM-dd'))"
Write-Host "Uptime       : $totalDays days ($fullWeeks weeks, $remDays days)"
Write-Host "Total hours  : $totalHours h"
```

### Expected Output

*(values depend on when you run it, but the structure is fixed)*

```
System start : 2024-01-15
Uptime       : 792 days (113 weeks, 1 days)
Total hours  : 19015.4 h
```

### What to notice

**`[datetime]::ParseExact` vs `[datetime]::Parse`.** `Parse` is lenient -- it
accepts many formats but can misinterpret ambiguous dates like `01/02/03`.
`ParseExact` requires an exact format string and throws a clear error if the
input does not match. In scripts that ingest dates from external sources
(CSV exports, API responses, log files), always use `ParseExact`. Mysterious
off-by-one-month bugs are almost always a `Parse` vs `ParseExact` issue.

**Arithmetic on datetime objects returns a `[timespan]`.** The expression
`$now - $start` does not return a number -- it returns a `System.TimeSpan`
object with properties like `.Days`, `.Hours`, `.TotalHours`, `.TotalMinutes`.
`$uptime.Days` gives you whole days only (the integer part). `$uptime.TotalHours`
gives the full floating-point total including the fractional part. Know the
difference before you write an SLA report.

**`[math]::Floor` vs integer division.** `[math]::Floor(13.9)` gives `13`.
`[int]13.9` gives `14` because PowerShell uses banker's rounding on casts.
For "how many whole weeks" you always want `Floor`, not a cast. The `%`
(modulo) operator for the remaining days works on the integer `$totalDays`
so there is no rounding issue there.

---

## Ch-13, Ex-3 (Advanced)

**Task:** Write a `ServerInfo` PowerShell class with a typed constructor, a
`GetEndpoint()` method, and an `IsDefaultPort()` method.

### Solution

```powershell
class ServerInfo {
    [string]$Name
    [string]$IP
    [int]$Port

    ServerInfo([string]$name, [string]$ip, [int]$port) {
        $this.Name = $name
        $this.IP   = $ip
        $this.Port = $port
    }

    [string] GetEndpoint() {
        return "$($this.IP):$($this.Port)"
    }

    [bool] IsDefaultPort() {
        return $this.Port -eq 80 -or $this.Port -eq 443
    }
}

# Instantiate
$srv = [ServerInfo]::new('web01', '10.0.0.1', 443)

# Test properties
$srv.Name               # web01
$srv.IP                 # 10.0.0.1
$srv.Port               # 443

# Test methods
$srv.GetEndpoint()      # 10.0.0.1:443
$srv.IsDefaultPort()    # True

# Non-default port
$dev = [ServerInfo]::new('dev01', '192.168.0.1', 8080)
$dev.IsDefaultPort()    # False
$dev.GetEndpoint()      # 192.168.0.1:8080
```

### Expected Output

```
web01
10.0.0.1
443
10.0.0.1:443
True
False
192.168.0.1:8080
```

### What to notice

**Classes are defined at parse time, not at runtime.** If you define a class
inside a function or a script block that runs conditionally, PowerShell may
not see it until execution reaches that block. The safest place for class
definitions is the top of a script file or a module, before any functions
that use them. This is a common gotcha when moving from PSCustomObject
(which you can create anywhere) to classes (which have scoping rules).

**`[ServerInfo]::new()` is the constructor call syntax.** Unlike C# `new
ServerInfo()`, PowerShell requires the `::new()` form on the type. This
is not optional syntax; it is how PowerShell exposes constructors. The
parameters must match a defined constructor signature exactly -- PowerShell
classes do not support optional parameters in constructors the way functions
do with `[Parameter]`.

**Return type annotations are enforced at runtime, not compile time.**
`[string] GetEndpoint()` tells PowerShell the method must return a
`[string]`. If your method body returns something that cannot be coerced
to a string, you will get a runtime error, not a build-time error.
This catches bugs that would otherwise silently produce wrong types in
pipeline output.

---

## Ch-13, Ex-4 (Extreme)

**Task:** Build an `Animal` base class and `Dog` / `Cat` derived classes.
Verify IS-A relationships, constructor chaining, method overriding, and
polymorphic dispatch through the base class.

### Solution

```powershell
class Animal {
    [string]$Name
    [int]$Age

    Animal([string]$name, [int]$age) {
        $this.Name = $name
        $this.Age  = $age
    }

    [string] Speak() {
        return '...'
    }

    [string] Describe() {
        return "$($this.Name) (age $($this.Age)): $($this.Speak())"
    }
}

class Dog : Animal {
    [string]$Breed

    Dog([string]$name, [int]$age, [string]$breed) : base($name, $age) {
        $this.Breed = $breed
    }

    [string] Speak() {
        return 'Woof!'
    }
}

class Cat : Animal {
    [bool]$Indoor

    Cat([string]$name, [int]$age, [bool]$indoor) : base($name, $age) {
        $this.Indoor = $indoor
    }

    [string] Speak() {
        return 'Meow!'
    }
}

# Instantiate
$dog = [Dog]::new('Rex', 5, 'Labrador')
$cat = [Cat]::new('Whiskers', 3, $true)

# Method overriding
$dog.Speak()              # Woof!
$cat.Speak()              # Meow!

# Inherited method calling the overridden version
$dog.Describe()           # Rex (age 5): Woof!
$cat.Describe()           # Whiskers (age 3): Meow!

# IS-A checks
$dog -is [Animal]         # True
$cat -is [Animal]         # True
$dog -is [Dog]            # True
$dog -is [Cat]            # False

# Derived-class properties
$dog.Breed                # Labrador
$cat.Indoor               # True

# Polymorphic collection
$animals = @($dog, $cat)
$animals | ForEach-Object { $_.Describe() }
# Rex (age 5): Woof!
# Whiskers (age 3): Meow!
```

### Expected Output

```
Woof!
Meow!
Rex (age 5): Woof!
Whiskers (age 3): Meow!
True
True
True
False
Labrador
True
Rex (age 5): Woof!
Whiskers (age 3): Meow!
```

### What to notice

**`: base()` is not optional when the parent has no default constructor.**
`Animal` defines a constructor that takes `$name` and `$age`. This means
PowerShell will not generate a default (no-argument) constructor for
`Animal`. Any derived class *must* call `: base(...)` with the correct
arguments, or the object cannot be constructed. If you forget `: base()`,
you get an error at instantiation time, not a silently broken object.

**`Describe()` dispatches to the overridden `Speak()`.** This is the key
test of polymorphism. The `Describe()` method is defined in `Animal` and
calls `$this.Speak()`. When `$this` is a `Dog`, `$this.Speak()` dispatches
to `Dog.Speak()`, not `Animal.Speak()`. PowerShell's class system uses
virtual dispatch by default -- every overridable method is virtual unless
you are working with a final/sealed type. The base class does not need to
declare `virtual`; derived classes just redefine the method with the same
signature.

**The `-is` operator traverses the full inheritance chain.** `$dog -is [Animal]`
is `$true` even though `Dog` is not `Animal` directly -- it inherits from it.
This makes `-is` useful for type-safe dispatch: you can test `if ($obj -is
[Animal])` to handle any animal subtype with a single branch.

**Class definitions in a script must appear before they are referenced.**
Because `Dog` inherits from `Animal`, the `Animal` class definition must
come first in the file. PowerShell processes class definitions in order
during the parse pass. If `Dog` appears before `Animal`, you get a
"type not found" error. This is different from functions, which can be
defined after they are called (as long as they are in the same scope by
execution time).

**This pattern is the foundation for real automation tooling.** Production
infrastructure automation scripts commonly define a base `Resource` class
with shared properties (`Name`, `Region`, `Tags`, `CreatedAt`) and methods
(`Validate()`, `ToJson()`), then derive `VirtualMachine`, `StorageAccount`,
and `NetworkInterface` from it. The polymorphic `Validate()` and `ToJson()`
calls make bulk operations (deploy 40 mixed resources) clean and uniform
rather than a maze of type-checking if/else blocks.
