# Chapter 13: Objects and .NET

Sam discovers that strings have been lying to him this whole time.

![chapter-opener](assets/images/ch-13-opener.png)

---

## Everything Is an Object

You have been using objects since page one. Strings, integers, files, processes,
services -- every value in PowerShell is a .NET object. What you haven't done yet
is *talk to those objects directly*. That changes now.

The mental shift is simple: a value is not just data. It is data **plus** a set of
methods and properties attached to it. A string is not just characters. It is a
`System.String` object with `.Length`, `.ToUpper()`, `.Replace()`, `.Split()`,
and about fifty other members waiting to be called.

![objects-diagram](assets/images/ch-13-objects-diagram.png)

---

## Get-Member: The Magnifying Glass

Before you can use an object's members, you need to know what it has. `Get-Member`
(alias `gm`) is the command that shows you everything attached to an object.

```powershell
# What members does a string have?
'Hello' | Get-Member

# What members does a process object have?
Get-Process | Get-Member

# What members does a file have?
Get-Item ./README.md | Get-Member
```

The output is a table of `Name`, `MemberType`, and `Definition`. The `MemberType`
column tells you what kind of member it is:

| MemberType | What it means |
|---|---|
| `Property` | A value you can read (and sometimes set) |
| `Method` | A function you can call with `()` |
| `ScriptProperty` | A computed property added by PowerShell |
| `AliasProperty` | A friendly name for another property |
| `NoteProperty` | A property added at runtime (common on PSCustomObjects) |

```powershell
# Filter to only methods
'Hello' | Get-Member -MemberType Method

# Filter to only properties
Get-Process | Get-Member -MemberType Property

# Show static members (class-level, not instance-level)
[datetime] | Get-Member -Static
```

Once you know the members exist, calling them is just dot notation:

```powershell
$s = 'hello, world'
$s.Length           # 12
$s.ToUpper()        # HELLO, WORLD
$s.Replace(',', ';') # hello; world
$s.Split(', ')      # array: ['hello', 'world']
$s.Contains('world') # True
$s.StartsWith('he')  # True
$s.Substring(0, 5)   # hello
```

This is not special syntax. These are genuine .NET `System.String` method calls.
PowerShell just makes them look natural.

---

## PSCustomObject: Roll Your Own

The `[PSCustomObject]` type accelerator lets you create a lightweight object
with whatever properties you define. It is the workhorse of PowerShell data
modelling -- lean, pipeline-friendly, and needs no class definition.

### Hash Table Cast (the idiomatic way)

```powershell
$server = [PSCustomObject]@{
    Name   = 'web01'
    IP     = '10.0.0.1'
    Role   = 'WebServer'
    Status = 'Running'
}

$server.Name    # web01
$server.Status  # Running
```

The `[PSCustomObject]@{}` cast preserves property order, which a plain hashtable
does not. That matters when you pipe to `Format-Table` and want consistent columns.

```powershell
# Pipeline-friendly immediately
$server | Format-Table -AutoSize

# Build a collection
$servers = @(
    [PSCustomObject]@{ Name = 'web01'; IP = '10.0.0.1'; Role = 'WebServer' }
    [PSCustomObject]@{ Name = 'db01';  IP = '10.0.0.2'; Role = 'Database'  }
    [PSCustomObject]@{ Name = 'app01'; IP = '10.0.0.3'; Role = 'AppServer' }
)

$servers | Where-Object Role -eq 'WebServer'
$servers | Sort-Object Name
$servers | Export-Csv ./servers.csv -NoTypeInformation
```

PSCustomObject plugs into the entire pipeline ecosystem immediately. It works
with `Where-Object`, `Sort-Object`, `Select-Object`, `Export-Csv`, `ConvertTo-Json`
-- anything that speaks objects, which is everything.

### Add-Member: Extend at Runtime

Already have an object but need to bolt on an extra property or method? `Add-Member`
handles that without rebuilding the object.

```powershell
$server = [PSCustomObject]@{ Name = 'web01'; IP = '10.0.0.1'; Port = 443 }

# Add a NoteProperty (data)
$server | Add-Member -MemberType NoteProperty -Name 'Owner' -Value 'ops-team'
$server.Owner   # ops-team

# Add a ScriptMethod (behaviour)
$server | Add-Member -MemberType ScriptMethod -Name 'GetEndpoint' -Value {
    "$($this.IP):$($this.Port)"
}
$server.GetEndpoint()   # 10.0.0.1:443

# Shorthand: -PassThru returns the modified object inline
$enriched = $server | Add-Member -MemberType NoteProperty -Name 'Region' -Value 'eu-west' -PassThru
```

`$this` inside a `ScriptMethod` refers to the object the method was called on.
It behaves exactly like `$this` in a class -- because under the hood, it is.

---

## .NET Type Accelerators

Type accelerators are shorthand aliases for .NET types. They let you reach directly
into the .NET class library without writing fully-qualified names.

```powershell
[string]     # System.String
[int]        # System.Int32
[bool]       # System.Boolean
[datetime]   # System.DateTime
[math]       # System.Math
[regex]      # System.Text.RegularExpressions.Regex
[io.file]    # System.IO.File
[net.dns]    # System.Net.Dns
[guid]       # System.Guid
```

### Static Methods: The `::` Operator

Static methods belong to the *type*, not to an instance. You call them with `::`.

```powershell
# System.Math static methods
[math]::Round(3.14159, 2)          # 3.14
[math]::Abs(-42)                   # 42
[math]::Sqrt(144)                  # 12
[math]::Pow(2, 10)                 # 1024
[math]::Max(99, 100)               # 100
[math]::Min(99, 100)               # 99
[math]::PI                         # 3.14159265358979 (a static property)

# System.DateTime static methods
[datetime]::Now                    # Current date/time (instance property via static)
[datetime]::UtcNow                 # UTC now
[datetime]::Today                  # Today at midnight
[datetime]::Parse('2024-06-15')    # Parse a date string
[datetime]::ParseExact('15/06/2024', 'dd/MM/yyyy', $null)  # Strict parse

# System.Guid
[guid]::NewGuid()                  # Generate a new GUID

# System.IO.File
[io.file]::Exists('/etc/hosts')    # True or False
[io.file]::ReadAllText('/etc/hosts')  # Read entire file as string

# System.Net.Dns
[net.dns]::GetHostEntry('localhost').AddressList[0].ToString()
```

![static-vs-instance](assets/images/ch-13-static-vs-instance.png)

### [datetime]: Date and Time Manipulation

The `[datetime]` type accelerator gives you full access to .NET's date/time system.
In PowerShell, `Get-Date` returns a `[datetime]` object, so these methods work on
anything the pipeline gives you too.

```powershell
$now = Get-Date

# Arithmetic -- all return new datetime objects
$now.AddDays(7)       # One week from now
$now.AddMonths(-1)    # One month ago
$now.AddHours(2)      # Two hours from now

# Formatting
$now.ToString('yyyy-MM-dd')            # 2026-03-17
$now.ToString('dd/MM/yyyy HH:mm:ss')  # 17/03/2026 14:32:01
Get-Date -Format 'yyyyMMdd-HHmmss'    # 20260317-143201 (idiomatic PowerShell form)

# Properties
$now.Year          # 2026
$now.Month         # 3
$now.Day           # 17
$now.DayOfWeek     # Tuesday
$now.DayOfYear     # 76

# Comparison and calculation
$start = [datetime]::Parse('2026-01-01')
$diff  = $now - $start       # Returns a [timespan]
$diff.Days                   # Days elapsed since Jan 1
$diff.TotalHours             # Same in hours

# Parse a date from a non-standard string
$d = [datetime]::ParseExact('17-Mar-2026 14:00', 'dd-MMM-yyyy HH:mm', $null)
```

### [regex]: Regular Expressions the .NET Way

PowerShell's `-match` operator uses .NET regex under the hood. For more control --
named captures, compiled patterns, global replace -- reach for `[regex]` directly.

```powershell
# Named captures
$log = '2026-03-17 14:32:01 ERROR Database connection failed'
if ($log -match '(?<date>\d{4}-\d{2}-\d{2}) (?<level>\w+) (?<msg>.+)') {
    $Matches['date']   # 2026-03-17
    $Matches['level']  # ERROR
    $Matches['msg']    # Database connection failed
}

# Using [regex] directly for replace
$clean = [regex]::Replace($log, '\s+', ' ')   # Collapse multiple spaces

# Case-insensitive match
[regex]::IsMatch('Hello World', 'hello', 'IgnoreCase')   # True

# Find all matches (not just the first)
$text = 'IP: 10.0.0.1 and 192.168.1.1'
[regex]::Matches($text, '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') |
    ForEach-Object { $_.Value }
# 10.0.0.1
# 192.168.1.1
```

---

## PowerShell Classes (PS 5+)

When `PSCustomObject` is not enough -- when you need encapsulation, methods with
real logic, constructors, or reuse across scripts -- PowerShell classes step in.

Classes in PowerShell are .NET classes with PowerShell syntax. They compile to
actual `System.Object` descendants. This is not duck-typing or a scripting shortcut.

### Anatomy of a Class

```powershell
class ServerInfo {
    # Properties (typed)
    [string]$Name
    [string]$IP
    [int]$Port = 80    # Default value

    # Constructor
    ServerInfo([string]$name, [string]$ip, [int]$port) {
        $this.Name = $name
        $this.IP   = $ip
        $this.Port = $port
    }

    # Instance method
    [string] GetEndpoint() {
        return "$($this.IP):$($this.Port)"
    }

    # Method with parameter
    [bool] IsListeningOn([int]$port) {
        return $this.Port -eq $port
    }

    # Static method
    static [string] GetProtocol([int]$port) {
        if ($port -eq 443) { return 'HTTPS' }
        if ($port -eq 80)  { return 'HTTP'  }
        return 'Unknown'
    }
}
```

Creating instances and calling members:

```powershell
# Instantiate with constructor
$srv = [ServerInfo]::new('web01', '10.0.0.1', 443)

# Properties
$srv.Name          # web01
$srv.Port          # 443

# Instance methods
$srv.GetEndpoint()              # 10.0.0.1:443
$srv.IsListeningOn(443)         # True
$srv.IsListeningOn(80)          # False

# Static method -- called on the type, not the instance
[ServerInfo]::GetProtocol(443)  # HTTPS
[ServerInfo]::GetProtocol(8080) # Unknown
```

### Enums

Enums constrain a property to a fixed set of named values. They prevent the
classic "is it 'running', 'Running', or 'RUNNING'?" problem.

```powershell
enum ServerStatus {
    Unknown
    Starting
    Running
    Degraded
    Stopped
}

class Server {
    [string]$Name
    [ServerStatus]$Status = [ServerStatus]::Unknown

    Server([string]$name) { $this.Name = $name }

    [void] Start() {
        $this.Status = [ServerStatus]::Running
        Write-Verbose "$($this.Name) is now $($this.Status)"
    }
}

$s = [Server]::new('web01')
$s.Status           # Unknown
$s.Start()
$s.Status           # Running

# Enum comparison is clean and typo-proof
$s.Status -eq [ServerStatus]::Running    # True
```

---

## Inheritance

A derived class inherits all properties and methods of its base class, and can
override methods to change behaviour. The `: base()` call in the constructor
passes arguments up to the parent constructor.

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
```

Using the hierarchy:

```powershell
$dog = [Dog]::new('Rex', 5, 'Labrador')
$cat = [Cat]::new('Whiskers', 3, $true)

$dog.Speak()        # Woof!
$cat.Speak()        # Meow!

# Describe() is inherited from Animal -- it calls the overridden Speak()
$dog.Describe()     # Rex (age 5): Woof!
$cat.Describe()     # Whiskers (age 3): Meow!

# Type checking with -is
$dog -is [Animal]   # True -- Dog IS-A Animal
$dog -is [Dog]      # True
$dog -is [Cat]      # False

# Polymorphism: treat a collection of derived types as the base type
$animals = @([Dog]::new('Rex', 5, 'Labrador'), [Cat]::new('Luna', 2, $false))
$animals | ForEach-Object { $_.Describe() }
# Rex (age 5): Woof!
# Luna (age 2): Meow!
```

The `-is` operator tests the full inheritance chain. `$dog -is [Animal]` is `$true`
because `Dog` inherits from `Animal`. This is genuine polymorphism, not PowerShell
smoke and mirrors.

![class-hierarchy](assets/images/ch-13-class-hierarchy.png)

---

## Practical Pattern: Enriched Objects from the Pipeline

The real power of objects in PowerShell is building pipelines that transform plain
data into rich, typed results. Here is a pattern that combines everything in this
chapter:

```powershell
class PortResult {
    [string]$Host
    [int]$Port
    [bool]$Open
    [int]$LatencyMs
    [datetime]$Checked

    PortResult([string]$host, [int]$port, [bool]$open, [int]$latency) {
        $this.Host      = $host
        $this.Port      = $port
        $this.Open      = $open
        $this.LatencyMs = $latency
        $this.Checked   = [datetime]::UtcNow
    }

    [string] Summary() {
        $state = if ($this.Open) { 'OPEN' } else { 'CLOSED' }
        return "$($this.Host):$($this.Port) is $state ($($this.LatencyMs)ms)"
    }
}

# Build a port-check report
$targets = @(
    @{ Host = 'web01.local'; Port = 443 }
    @{ Host = 'db01.local';  Port = 5432 }
    @{ Host = 'app01.local'; Port = 8080 }
)

$results = $targets | ForEach-Object {
    $sw    = [System.Diagnostics.Stopwatch]::StartNew()
    $open  = (Test-NetConnection -ComputerName $_.Host -Port $_.Port -WarningAction SilentlyContinue).TcpTestSucceeded
    $sw.Stop()
    [PortResult]::new($_.Host, $_.Port, $open, $sw.ElapsedMilliseconds)
}

# Now the pipeline ecosystem is fully available
$results | Where-Object Open | ForEach-Object { $_.Summary() }
$results | Select-Object Host, Port, Open, LatencyMs | Format-Table -AutoSize
$results | Export-Csv ./port-check-$(Get-Date -Format yyyyMMdd).csv -NoTypeInformation
```

This pattern -- define a class, produce a collection, pipe it through standard
cmdlets -- is the PowerShell object model working exactly as designed. The class
does the encapsulation; the pipeline does the data processing.

---

## Exercises

### [Ch-13, Ex-1] Simple: Your First PSCustomObject

Create a `[PSCustomObject]` representing a server with four properties: `Name`,
`IP`, `Role`, and `Status`. Pipe it to `Format-Table`. Then create a second object
representing a different server and combine both into an array. Pipe the array to
`Format-Table -AutoSize`.

### [Ch-13, Ex-2] Normal: .NET Static Methods in Practice

Use `[datetime]` and `[math]` static methods to build a small "uptime report"
script. Given a `$startDate` string in `'yyyy-MM-dd'` format, calculate:
- The number of days the system has been running
- The elapsed time expressed as full weeks and remaining days
- Round the total uptime in hours to 1 decimal place

### [Ch-13, Ex-3] Advanced: PowerShell Class with Constructor and Methods

Write a PowerShell class called `ServerInfo` with the following spec:
- Properties: `[string]$Name`, `[string]$IP`, `[int]$Port`
- Constructor that sets all three properties
- Method `GetEndpoint()` that returns `"IP:Port"` as a string
- Method `IsDefaultPort()` that returns `$true` if the port is 80 or 443

Instantiate the class and verify all methods return correct values.

### [Ch-13, Ex-4] Extreme: A Class Hierarchy

Build a class hierarchy with a base class `Animal` and two derived classes
`Dog` and `Cat`. Requirements:
- `Animal` has `[string]$Name`, `[int]$Age`, a constructor, a `Speak()` method
  (returns `"..."`) and a `Describe()` method that returns `"Name (age N): <speak result>"`
- `Dog` adds `[string]$Breed` and overrides `Speak()` to return `"Woof!"`
- `Cat` adds `[bool]$Indoor` and overrides `Speak()` to return `"Meow!"`
- Both derived constructors call `: base($name, $age)`

Verify that `$dog -is [Animal]` is `$true`, that `Describe()` uses the overridden
`Speak()`, and that `Cat.Indoor` is settable through the constructor.

---

## Key Takeaways

- Every value in PowerShell is a .NET object. Strings, numbers, files -- all objects.
- `Get-Member` (or `gm`) shows you every property and method available on any object.
- `[PSCustomObject]@{}` creates lightweight objects that plug into the whole pipeline ecosystem.
- `Add-Member` bolts properties and methods onto existing objects at runtime.
- Type accelerators like `[datetime]`, `[math]`, and `[regex]` expose .NET's class library directly.
- Static methods are called with `::` on the type name, not on an instance.
- `class` defines a real .NET type with typed properties, constructors, and methods (PS 5+).
- Inheritance uses `: BaseClass` syntax; call the parent constructor with `: base(...)`.
- The `-is` operator checks the full inheritance chain, enabling genuine polymorphism.
- Enums constrain values to a fixed set of names -- use them to eliminate string-matching bugs.

---

*Next up: [Chapter 14 -- Remoting and Jobs](14-remote-and-jobs.md), where we
run work beyond the current PowerShell session.*
