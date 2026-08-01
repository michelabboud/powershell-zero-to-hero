# Chapter 01: What Is PowerShell?

> *Every great journey starts with a single cmdlet.*

![chapter-opener](assets/images/ch-01-opener.png)

---

## What You'll Learn

- What PowerShell is and why it matters
- How PowerShell differs from other shells
- How to install PowerShell 7 on any OS

---

## 1. What Is PowerShell?

PowerShell is not "just another shell." It is a **cross-platform automation framework** built
on top of .NET. Where most shells trade in plain text -- lines of output you `grep` and `awk`
your way through -- PowerShell trades in **objects**. Real, structured, typed objects with
properties and methods.

That distinction matters more than anything else you'll learn today. When you run a command in
Bash, you get a wall of text. When you run the equivalent in PowerShell, you get objects you
can filter, sort, format, and pipe without ever parsing a string.

```powershell
# This returns objects, not text
Get-Process | Select-Object -First 3 -Property Name, Id, CPU
```

```
Name       Id      CPU
----       --      ---
System      4        -
smss      348        -
csrss     512    18.42
```

Each row is a `System.Diagnostics.Process` object. You can access `.Name`, `.Id`, `.CPU`
directly -- no regex required.

PowerShell is also a **scripting language**. It has variables, loops, functions, classes,
error handling, and a module system. Think of it as what you'd get if someone merged a
Unix shell with C# and gave it a verb-noun naming convention that actually makes sense.

---

## 2. A Brief History

Jeffrey Snover wrote the **Monad Manifesto** in 2002, arguing that Windows needed an
automation shell built on objects rather than text. Microsoft agreed -- eventually.

![ps-timeline](assets/images/ch-01-timeline.png)

| Year | Version | Milestone |
|------|---------|-----------|
| 2006 | 1.0 | First release. Windows only. 129 cmdlets. |
| 2009 | 2.0 | Remoting, background jobs, modules, ISE. |
| 2012 | 3.0 | Workflows, scheduled jobs, improved pipeline. |
| 2016 | Open source | Microsoft released PowerShell's source and began the cross-platform project. |
| 2018 | 6.0 | First generally available cross-platform release on .NET Core. |
| 2024 | 7.4 LTS | Long-term-support release built on .NET 8. |
| 2026 | 7.6 LTS | Current LTS line, built on .NET 10. |

The rename from "Windows PowerShell" (5.1, .NET Framework) to just "PowerShell" (7.x, .NET)
wasn't cosmetic. It signaled a fundamental shift: PowerShell is no longer Windows-only, and
5.1 is in maintenance mode. If you're starting fresh, **always use PowerShell 7**.

---

## 3. Why PowerShell?

Five reasons working sysadmins, DevOps engineers, and developers reach for PowerShell:

1. **Object pipeline** -- No more parsing `awk '{print $3}'`. Properties are properties.
2. **.NET integration** -- Need to call a .NET library? `[System.IO.File]::ReadAllText()` works inline.
3. **Cross-platform** -- The language and core modules run on Windows, Linux, and macOS; platform-specific cmdlets still need explicit guards.
4. **Module ecosystem** -- The PowerShell Gallery provides community and Microsoft modules through `Install-PSResource` (or the older `Install-Module`).
5. **Windows administration** -- Active Directory, Exchange, Azure, Microsoft 365 -- all PowerShell-first.

```powershell
# One line: get the 5 largest files in your home directory
Get-ChildItem ~ -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 5 -Property Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}
```

Try that in `cmd.exe`. We'll wait.

---

## 4. PowerShell vs Other Shells

![ps-vs-shells](assets/images/ch-01-comparison.png)

| Feature | PowerShell | Bash | cmd.exe |
|---------|-----------|------|---------|
| **Pipeline data** | Objects | Text streams | Text |
| **Naming** | Verb-Noun (`Get-Process`) | Arbitrary (`ps`, `ls`) | Arbitrary (`dir`, `type`) |
| **Runtime** | .NET | C / POSIX | Win32 |
| **Scripting** | Full language | Shell scripting | Batch (limited) |
| **Cross-platform** | Yes (7.x) | Yes (native) | Windows only |
| **Error handling** | Try/Catch + ErrorAction | Exit codes + `trap` | `ERRORLEVEL` |
| **Discoverability** | `Get-Command`, `Get-Help` | `man`, `--help` | `/?` (inconsistent) |

**The key insight:** Bash is brilliant at composing small text-processing utilities. PowerShell
is brilliant at composing operations on structured data. They solve different problems well.
Knowing both makes you dangerous in the best way.

---

## 5. Installing PowerShell 7

PowerShell 7 runs alongside Windows PowerShell 5.1 -- they don't conflict. Use the
installation method supported for your operating system and verify the current package on
the official PowerShell installation page before automating a fleet rollout.

### Windows (winget)

```powershell
winget install --id Microsoft.PowerShell --source winget
```

### macOS (Microsoft-signed package)

Download the package for your CPU architecture from the official stable release page and
open the `.pkg`. Current packages are signed and notarized by Microsoft.

Homebrew is a community-supported alternative (not a Microsoft-supported package):

```bash
brew install powershell
```

### Linux -- Ubuntu/Debian (apt)

```bash
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
source /etc/os-release
wget -q "https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
```

### Linux -- Snap (Canonical-maintained alternative)

```bash
sudo snap install powershell --classic
```

After installation, launch with:

```bash
pwsh
```

You should see the familiar `PS>` prompt. If you see it, you're in business.

---

## 6. Your First Session

Open a terminal and type `pwsh`. Let's run a few commands to prove everything works.

### Check your version

```powershell
# What version am I running?
$PSVersionTable
```

```
Name                           Value
----                           -----
PSVersion                      7.6.4
PSEdition                      Core
GitCommitId                    7.6.4
OS                             Microsoft Windows 10.0.22631
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0, 5.0, 5.1...}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

The three fields that matter most right now: **PSVersion** (should start with 7),
**PSEdition** (should be `Core`), and **OS** (whatever you're running on).

### Get the current date

```powershell
Get-Date
```

```
Saturday, August 1, 2026 10:42:15 AM
```

That returned a `[DateTime]` object. You can chain methods on it:

```powershell
(Get-Date).DayOfWeek    # Saturday
(Get-Date).Year         # 2026
```

### List running processes

```powershell
Get-Process | Select-Object -First 3
```

```
 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
 ------    -----      -----     ------      --  -- -----------
     10     2.34       8.12       0.03    1284   1 agent_ovr
     18    14.67      22.45       1.42    3056   1 ApplicationFrame
      8     1.89       6.78       0.00    4520   0 armsvc
```

Notice the column headers? Those are **property names**. Every row is an object. Welcome to
PowerShell.

---

## Challenge

> <!-- tier: advanced -->
> **Install PowerShell 7 on three different operating systems** (or VMs/containers). Run
> `$PSVersionTable` on each and compare the output.
>
> Questions to answer:
> - Which keys are identical across all three?
> - Which keys differ?
> - What does `PSCompatibleVersions` tell you about backward compatibility?

---

## Boss Level

> <!-- tier: extreme -->
> **Write a script that detects the current OS** using `$IsWindows`, `$IsLinux`, and
> `$IsMacOS`, then installs or updates to the latest PowerShell 7 using the appropriate
> package manager (`winget`, `apt`, or `brew`). Handle errors gracefully -- what if the
> package manager isn't installed? What if the user isn't root on Linux?

```powershell
# boss-level-01.ps1 -- OS-aware PowerShell installer
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

function Invoke-NativeChecked {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string[]]$ArgumentList
    )

    & $Command @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE."
    }
}

function Install-PowerShellUpdate {
    if ($IsWindows) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw "winget not found. Install App Installer from the Microsoft Store."
        }
        Invoke-NativeChecked winget @(
            'upgrade', '--id', 'Microsoft.PowerShell', '--source', 'winget',
            '--accept-source-agreements', '--accept-package-agreements'
        )
    }
    elseif ($IsMacOS) {
        if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
            throw "Homebrew not found. Install from https://brew.sh"
        }
        Invoke-NativeChecked brew @('upgrade', 'powershell')
    }
    elseif ($IsLinux) {
        # Check for root/sudo
        $whoami = whoami
        if ($whoami -ne 'root' -and -not (Get-Command sudo -ErrorAction SilentlyContinue)) {
            throw "Must run as root or have sudo installed."
        }
        if (Get-Command apt-get -ErrorAction SilentlyContinue) {
            if ($whoami -eq 'root') {
                Invoke-NativeChecked apt-get @('update', '-qq')
                Invoke-NativeChecked apt-get @('install', '-y', 'powershell')
            }
            else {
                Invoke-NativeChecked sudo @('apt-get', 'update', '-qq')
                Invoke-NativeChecked sudo @('apt-get', 'install', '-y', 'powershell')
            }
        }
        elseif (Get-Command snap -ErrorAction SilentlyContinue) {
            if ($whoami -eq 'root') {
                Invoke-NativeChecked snap @('refresh', 'powershell')
            }
            else {
                Invoke-NativeChecked sudo @('snap', 'refresh', 'powershell')
            }
        }
        else {
            throw "No supported package manager found (apt-get or snap)."
        }
    }
    else {
        throw "Unknown OS. Cannot determine package manager."
    }
}

try {
    Write-Host "Detected OS: $($PSVersionTable.OS)" -ForegroundColor Cyan
    Write-Host "Current PS version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host ""
    Install-PowerShellUpdate
    Write-Host "`nUpdate complete. Restart your shell to use the new version." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
```

---

## Exercises

### [Ch-01, Ex-1] Simple: Identify Your PowerShell Version

Run `$PSVersionTable` and identify three things: your PowerShell version, the edition
(Desktop or Core), and your operating system.

```powershell
# Run this and read the output
$PSVersionTable
```

### [Ch-01, Ex-2] Normal: Discover "Get" Cmdlets in a Module

Use `Get-Command` to find all cmdlets whose verb is `Get` in the
`Microsoft.PowerShell.Utility` module. How many are there?

```powershell
Get-Command -Verb Get -Module Microsoft.PowerShell.Utility
```

### [Ch-01, Ex-3] Advanced: Count Commands by Type

> <!-- tier: advanced -->
> Find the total count of **cmdlets**, **functions**, and **aliases** available on your
> system. Use `Get-Command` and `Where-Object`.

### [Ch-01, Ex-4] Extreme: One-Liner Command Census

> <!-- tier: extreme -->
> Write a **single pipeline** that outputs a formatted table showing the count of each
> command type on your system, sorted by count descending.

---

## Summary

You now know what PowerShell is (an object-based automation framework), where it came from
(Monad manifesto, 2002), why it matters (objects beat text), how it compares to other shells,
and how to install it on any OS. Most importantly, you've run your first commands and seen
real objects come back instead of raw text.

In the next chapter, we'll explore the PowerShell console itself -- profiles, prompts,
tab completion, and the tools that make your daily life faster.

---

*Next: [Chapter 02 -- The Console](02-the-console.md)*
