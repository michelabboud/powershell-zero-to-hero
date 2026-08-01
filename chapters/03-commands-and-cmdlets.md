# Chapter 03: Commands and Cmdlets

In PowerShell, everything is a Verb-Noun. Once you get that, everything clicks.

![chapter-opener](assets/images/ch-03-opener.png)

---

## The Verb-Noun Convention

Every PowerShell cmdlet follows a strict **Verb-Noun** naming pattern. No exceptions
(well, almost -- aliases exist, but we'll pretend they don't for now).

![verb-noun](assets/images/ch-03-verb-noun.png)

The verb tells you *what* the command does. The noun tells you *what it acts on*.
This isn't just a suggestion -- it's enforced by the community and by PowerShell's
module system. If you publish a module with unapproved verbs, PowerShell will
passive-aggressively warn your users every time they import it.

### Approved Verbs

PowerShell maintains an official list of approved verbs. You can see them yourself:

```powershell
Get-Verb
```

That command returns every approved verb grouped by category. Here are the ones
you'll use 90% of the time:

| Verb     | What It Does                  | Example              |
|----------|-------------------------------|----------------------|
| `Get`    | Retrieves data                | `Get-Process`        |
| `Set`    | Changes an existing resource  | `Set-Location`       |
| `New`    | Creates something             | `New-Item`           |
| `Remove` | Deletes something             | `Remove-Item`        |
| `Start`  | Begins an operation           | `Start-Process`      |
| `Stop`   | Ends an operation             | `Stop-Process`       |
| `Test`   | Validates a condition         | `Test-Path`          |
| `Invoke` | Performs an action             | `Invoke-WebRequest`  |

Why does this matter? Because when you need to do something new, you can
*guess* the command name. Need to restart a service? Try `Restart-Service`.
Need to export data to CSV? Try `Export-Csv`. This predictability is one of
PowerShell's best features -- and the thing that CMD and Bash quietly envy.

---

## Get-Help: Your Built-In Manual

Before you Google anything, try `Get-Help`. It's the man page system that
actually wants you to succeed.

```powershell
# Basic help
Get-Help Get-ChildItem

# Show usage examples (the part you actually want)
Get-Help Get-ChildItem -Examples

# Full documentation with parameter details
Get-Help Get-ChildItem -Detailed

# The nuclear option: everything, including technical notes
Get-Help Get-ChildItem -Full

# Open the online docs in your browser (when local help isn't enough)
Get-Help Get-ChildItem -Online
```

### Updating Help Files

If `Get-Help` returns suspiciously thin results, your help files probably
haven't been downloaded yet. Fix that:

```powershell
# Run as admin -- downloads help for all installed modules
Update-Help -Force -ErrorAction SilentlyContinue
```

The `-ErrorAction SilentlyContinue` is there because some modules ship without
help files, and PowerShell will throw a tantrum about each one. You don't
need that energy in your life.

### Wildcards in Help

Don't know the exact command name? Use wildcards:

```powershell
# Find everything related to "process"
Get-Help *process*

# Find all commands that "get" something about the network
Get-Help Get-Net*
```

---

## Get-Command: Discovery Mode

While `Get-Help` explains a command, `Get-Command` helps you *find* commands
in the first place.

```powershell
# Find all commands with the verb "Stop"
Get-Command -Verb Stop

# Find all commands with the noun "Service"
Get-Command -Noun Service

# Wildcard search
Get-Command *firewall*

# Filter by module
Get-Command -Module Microsoft.PowerShell.Management

# Find out what type of command something is
Get-Command ping
# CommandType: Application (it's an external .exe, not a cmdlet)
```

### The Discovery Trio

These three commands are your survival kit. Memorize them:

| Command         | Question It Answers              |
|-----------------|----------------------------------|
| `Get-Command`   | "Does this command exist?"       |
| `Get-Help`      | "How do I use this command?"     |
| `Get-Member`    | "What did this command return?"  |

You'll hear PowerShell veterans call them the "Big Three." They're not wrong.

---

## Get-Member: X-Ray Vision for Objects

This is the command that separates people who *use* PowerShell from people who
*understand* PowerShell. `Get-Member` shows you the properties and methods of
whatever object you pipe into it.

```powershell
# What properties does a process object have?
Get-Process | Get-Member

# Filter to just properties
Get-Process | Get-Member -MemberType Property

# Filter to just methods
Get-Process | Get-Member -MemberType Method
```

When you run `Get-Process | Get-Member`, you'll see output like this:

```
TypeName: System.Diagnostics.Process

Name        MemberType Definition
----        ---------- ----------
Kill        Method     void Kill(), void Kill(bool entireProcessTree)
CPU         Property   double CPU {get;}
Id          Property   int Id {get;}
ProcessName Property   string ProcessName {get;}
WorkingSet64 Property  long WorkingSet64 {get;}
...
```

That `TypeName` line is critical. It tells you that `Get-Process` doesn't return
text -- it returns `System.Diagnostics.Process` objects. Each object carries
properties (data) and methods (actions). This is the fundamental difference
between PowerShell and every text-based shell: **the pipeline carries objects,
not strings.**

Once you internalize that, you stop thinking in "lines of text" and start
thinking in "collections of structured data." That shift changes everything.

---

## The Pipeline: Objects on a Conveyor Belt

The pipe character `|` takes the output of one command and feeds it as input
to the next. You've seen this in Bash, but PowerShell's version is fundamentally
different: it passes **objects**, not text.

![pipeline-flow](assets/images/ch-03-pipeline.png)

```powershell
# Get all processes, sort by CPU usage (descending), take the top 5
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
```

Think of it as a factory conveyor belt. Each cmdlet is a workstation:

1. `Get-Process` -- puts process objects on the belt
2. `Sort-Object CPU -Descending` -- rearranges them by CPU usage
3. `Select-Object -First 5` -- pulls the top 5 off the belt, discards the rest

No temporary variables. No intermediate files. No regex to parse column output.
The objects keep their structure through every stage.

### Common Pipeline Cmdlets

| Cmdlet              | Purpose                              |
|---------------------|--------------------------------------|
| `Where-Object`      | Filter objects by condition           |
| `Sort-Object`       | Sort by property                      |
| `Select-Object`     | Pick specific properties or N items   |
| `ForEach-Object`    | Run code against each object          |
| `Measure-Object`    | Count, sum, average, min, max         |
| `Group-Object`      | Group by property value               |
| `Format-Table`      | Display as table (terminal only)      |
| `Format-List`       | Display as list (terminal only)       |

A quick example combining several:

```powershell
# Running services, grouped by start type, counted
Get-Service |
    Where-Object Status -eq 'Running' |
    Group-Object StartType |
    Select-Object Name, Count
```

> **Warning:** `Format-*` cmdlets are for display only. Never pipe their output
> into another cmdlet for processing -- they produce formatting objects, not data.
> Put them at the *end* of your pipeline or not at all.

---

## Essential Cmdlets

These are the commands you'll reach for every single day. Get comfortable with
them before moving to the next chapter.

### Get-Process

```powershell
# All processes
Get-Process

# Specific process by name
Get-Process -Name pwsh

# With memory details
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Name, @{N='MemMB';E={[math]::Round($_.WorkingSet64/1MB)}}
```

### Get-Service

```powershell
# All services
Get-Service

# Running services only
Get-Service | Where-Object Status -eq 'Running'

# Check a specific service
Get-Service -Name sshd
```

### Get-ChildItem

The PowerShell equivalent of `ls` / `dir`. Works on the filesystem, registry,
certificates -- any PowerShell provider.

```powershell
# List current directory
Get-ChildItem

# Recursive search for .log files
Get-ChildItem -Path C:\ -Filter *.log -Recurse -ErrorAction SilentlyContinue

# Include hidden files
Get-ChildItem -Force
```

### Get-Content

Reads file contents. Think `cat` but with object superpowers.

```powershell
# Read a file
Get-Content ./server.log

# Last 20 lines (tail)
Get-Content ./server.log -Tail 20

# Follow a log in real time (tail -f)
Get-Content ./server.log -Wait -Tail 5
```

### Measure-Object

Your Swiss army knife for quick statistics.

```powershell
# Count items
Get-ChildItem | Measure-Object

# Sum file sizes
Get-ChildItem | Measure-Object -Property Length -Sum

# Line/word/character count (like wc)
Get-Content ./README.md | Measure-Object -Line -Word -Character
```

---

## Challenge: Find All Stop-Verb Cmdlets

Your first real task: find every cmdlet on your system that can *stop* something,
then explore what parameters they accept.

```powershell
# Step 1: Find them
Get-Command -Verb Stop

# Step 2: Pick one and explore its parameters
Get-Help Stop-Process -Detailed
```

Count how many you find. On a typical Windows system, you'll discover more
things you can stop than you probably should.

---

## Boss Level: System Health Summary

> <!-- tier: extreme -->
> Chain five or more cmdlets to produce a single `PSCustomObject` containing
> a system health summary. Include: total process count, number of running
> services, system uptime in hours, total memory used by all processes (in MB),
> and the number of files in your temp directory.

This is where everything in this chapter comes together -- `Get-Process`,
`Get-Service`, `Measure-Object`, `Get-ChildItem`, and `PSCustomObject`
construction. If you can do this, you own Chapter 03.

---

## Exercises

### [Ch-03, Ex-1] Simple: Get-Help for Get-ChildItem

Use `Get-Help` to look up the documentation for `Get-ChildItem`. Read the
synopsis and identify at least two parameters it supports.

### [Ch-03, Ex-2] Normal: Top 5 Processes by CPU

Write a one-liner that returns the 5 processes consuming the most CPU time.
Display them in descending order.

### [Ch-03, Ex-3] Advanced: All Stop-Verb Cmdlets

> <!-- tier: advanced -->

Find every cmdlet on your system that uses the verb `Stop`. Verify that every
result actually has `Stop` as its verb -- no false positives allowed.

### [Ch-03, Ex-4] Extreme: System Health Summary

> <!-- tier: extreme -->

Build a `PSCustomObject` that contains at least five data points about your
system's health. Use pipeline cmdlets, `Measure-Object`, and at least three
different `Get-*` cmdlets as data sources. The result should be a single object,
not a wall of text.

---

## Key Takeaways

- Every cmdlet follows **Verb-Noun** naming. Use `Get-Verb` to see approved verbs.
- The **Big Three** -- `Get-Command`, `Get-Help`, `Get-Member` -- answer "what exists,"
  "how to use it," and "what it returns."
- The pipeline passes **objects**, not text. This is the single most important
  concept in PowerShell.
- `Get-Member` reveals the type, properties, and methods of any object.
  Use it constantly.
- `Where-Object` filters, `Sort-Object` sorts, `Select-Object` picks,
  `Measure-Object` counts. These four are your pipeline workhorses.

---

*Next up: [Chapter 04 -- Variables and Types](04-variables-and-types.md), where
we learn that everything in PowerShell is an object, even when it doesn't look
like one.*
