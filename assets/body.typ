// ── Pandoc Compatibility (auto-prepended) ──
#let blockquote(body) = {
  v(2pt)
  block(
    width: 100%,
    fill: rgb("#F8FAFC"),
    stroke: (left: 3pt + rgb("#94A3B8")),
    radius: 2pt,
    inset: (x: 12pt, y: 8pt),
    text(style: "italic", fill: rgb("#475569"), body)
  )
  v(2pt)
}

#let horizontalrule = {
  v(4pt)
  line(length: 100%, stroke: 0.5pt + rgb("#CBD5E1"))
  v(4pt)
}

= Preface: Welcome to PowerShell
<preface-welcome-to-powershell>
#blockquote[
#emph["The best time to learn PowerShell was five years ago. The second best time is right now."]
]

You are reading this for one of three reasons: your boss told you to, your bash scripts finally collapsed under their own weight, or you watched someone automate in ten lines what took you an entire afternoon of clicking. Whatever brought you here – welcome. You are in the right place.

PowerShell is not just another shell. It is a full object-oriented automation framework that runs on Windows, Linux, and macOS. It passes objects through the pipeline instead of text, which means you stop writing fragile regex to parse command output and start writing code that actually knows what it is working with. That single difference changes everything.

This guide will take you from zero – literally "what is a cmdlet?" – to writing production-grade automation scripts, building modules, and orchestrating infrastructure. No prior PowerShell experience required. If you can open a terminal and type a command, you have enough to start.

#figure([#image("images/ch-00-cast.png")],
  caption: [
    preface-cast
  ]
)

#horizontalrule

== How This Guide Works
<how-this-guide-works>
Every chapter uses a four-tier exercise system. You pick the level that matches your confidence – or your caffeine intake.

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Tier], [Label], [What It Means],
  [1],
  [#strong[Simple]],
  [Follow-along exercises. Copy, run, observe. Build muscle memory without breaking anything.],
  [2],
  [#strong[Normal]],
  [Apply what you just learned with minor twists. You will need to think, but the guardrails are still up.],
  [3],
  [#strong[Challenge]],
  [Open-ended problems that require combining concepts. Less hand-holding, more stack-tracing.],
  [4],
  [#strong[Boss Level]],
  [Real-world scenarios that would make a sysadmin sweat. These are designed to stretch you. No shame in peeking at the answer booklet – after you have tried.],
)
]

Start wherever you are comfortable. If Simple feels too easy, jump to Normal. If Boss Level makes you question your career choices, that is working as intended.

Each chapter also includes short narrative segments featuring three characters who will be your companions throughout the guide. They make mistakes so you do not have to. (They also make mistakes you absolutely will, and that is the point.)

#horizontalrule

== Meet Your Guides
<meet-your-guides>
#strong[Sam] – Junior IT Technician

Sam is mid-twenties, six months into a helpdesk-turned-sysadmin role, and held together by energy drinks and optimism. Sam’s desktop has fourteen browser tabs open, half of them Stack Overflow. Sam represents the beginner perspective: asking the "obvious" questions that turn out to be not obvious at all, making the mistakes that everyone makes but nobody admits to, and gradually discovering that automation is not magic – it is just laziness applied strategically.

#strong[Rina] – DevOps Engineer

Rina came up through Python and Bash. She joined the Windows side of the shop two years ago and quickly realized that `grep | awk | sed` pipelines do not translate well when your infrastructure runs on Active Directory. Rina bridges the gap between Linux tooling and the PowerShell ecosystem. When she says "in Python you would do it like this, but in PowerShell you do it like that," pay attention – she has already made the translation errors so you do not have to. She also has strong opinions about YAML, but that is a different book.

#strong[Max] – Infrastructure Lead

Max has been in the industry since before "DevOps" was a word. Started as a developer, drifted into operations because someone had to keep the servers running, and never left. Max has the kind of dry humor that comes from twenty years of 3 AM outage calls. His whiteboard is covered in architecture diagrams that only he fully understands, and his coffee mug reads "sudo rm -rf /my-problems." When Max shares a war story, it is because he watched a production system fail in exactly the way you are about to make it fail. Listen to Max.

#horizontalrule

== What You Need
<what-you-need>
Not much:

- #strong[A computer.] Windows, macOS, or Linux – PowerShell 7 runs on all three.
- #strong[Ten minutes to install PowerShell 7.] Chapter 1 walks you through it step by step. If you are on Windows 10 or later, you may already have Windows PowerShell 5.1 installed, but we target PowerShell 7 (the cross-platform, open-source version) throughout this guide. The differences matter, and we will point them out when they do.
- #strong[A text editor.] VS Code with the PowerShell extension is the recommended setup. Any editor that can save `.ps1` files will work, but VS Code gives you IntelliSense, integrated terminal, and a debugger – three things you will appreciate by Chapter 3.
- #strong[Willingness to type things wrong.] Seriously. The error messages in PowerShell are verbose and informative. Learning to read them is half the skill.

That is it. No cloud subscriptions, no lab environment, no prior scripting experience. If you have administered anything – a home network, a Minecraft server, a spreadsheet that got out of hand – you have enough context to follow along.

#horizontalrule

== The Answer Booklet
<the-answer-booklet>
Every exercise in this guide has a complete, tested solution in the companion #strong[Answer Booklet] (available as a separate document). Every answer is validated with Pester tests – PowerShell’s built-in testing framework – so you can verify that the solutions actually work and are not just plausible-looking pseudocode.

Here is the deal: #strong[try the exercises first.] Give yourself at least fifteen minutes of honest effort before reaching for the answers. The struggle is where the learning happens. Reading a solution and nodding along is not the same as writing one yourself, watching it fail, swearing quietly, fixing it, and watching it succeed.

When you do check the Answer Booklet, do not just read the code – read the commentary. Each solution explains #emph[why] it works that way, not just #emph[what] it does. Sometimes there are multiple valid approaches, and the booklet will walk through the tradeoffs.

#horizontalrule

== Let’s Go
<lets-go>
You do not learn PowerShell by reading about PowerShell. You learn it by opening a terminal, typing commands, watching things happen (or break), and building from there. Every expert you admire started by running `Get-Process` and thinking "wait, that just… worked?"

Chapter 1 starts with installation and your first commands. By the end of it, you will have a working PowerShell 7 environment and the confidence that comes from making the computer do what you told it to.

Turn the page. Open a terminal. Let’s build something.

= Chapter 01: What Is PowerShell?
<chapter-01-what-is-powershell>
#blockquote[
#emph[Every great journey starts with a single cmdlet.]
]

#figure([#image("images/ch-01-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== What You’ll Learn
<what-youll-learn>
- What PowerShell is and why it matters
- How PowerShell differs from other shells
- How to install PowerShell 7 on any OS

#horizontalrule

== 1. What Is PowerShell?
<what-is-powershell>
PowerShell is not "just another shell." It is a #strong[cross-platform automation framework] built on top of .NET. Where most shells trade in plain text – lines of output you `grep` and `awk` your way through – PowerShell trades in #strong[objects]. Real, structured, typed objects with properties and methods.

That distinction matters more than anything else you’ll learn today. When you run a command in Bash, you get a wall of text. When you run the equivalent in PowerShell, you get objects you can filter, sort, format, and pipe without ever parsing a string.

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

Each row is a `System.Diagnostics.Process` object. You can access `.Name`, `.Id`, `.CPU` directly – no regex required.

PowerShell is also a #strong[scripting language]. It has variables, loops, functions, classes, error handling, and a module system. Think of it as what you’d get if someone merged a Unix shell with C\# and gave it a verb-noun naming convention that actually makes sense.

#horizontalrule

== 2. A Brief History
<a-brief-history>
Jeffrey Snover wrote the #strong[Monad Manifesto] in 2002, arguing that Windows needed an automation shell built on objects rather than text. Microsoft agreed – eventually.

#figure([#image("images/ch-01-timeline.png")],
  caption: [
    ps-timeline
  ]
)

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Year], [Version], [Milestone],
  [2006],
  [1.0],
  [First release. Windows only. 129 cmdlets.],
  [2009],
  [2.0],
  [Remoting, background jobs, modules, ISE.],
  [2012],
  [3.0],
  [Workflows, scheduled jobs, improved pipeline.],
  [2016],
  [6.0],
  [#strong[Open-sourced.] Cross-platform on .NET Core.],
  [2024],
  [7.4],
  [Modern, stable, .NET 8, production-ready everywhere.],
)
]

The rename from "Windows PowerShell" (5.1, .NET Framework) to just "PowerShell" (7.x, .NET) wasn’t cosmetic. It signaled a fundamental shift: PowerShell is no longer Windows-only, and 5.1 is in maintenance mode. If you’re starting fresh, #strong[always use PowerShell 7].

#horizontalrule

== 3. Why PowerShell?
<why-powershell>
Five reasons working sysadmins, DevOps engineers, and developers reach for PowerShell:

+ #strong[Object pipeline] – No more parsing `awk '{print $3}'`. Properties are properties.
+ #strong[.NET integration] – Need to call a .NET library? `[System.IO.File]::ReadAllText()` works inline.
+ #strong[Cross-platform] – Same scripts run on Windows, Linux, and macOS.
+ #strong[Module ecosystem] – The PowerShell Gallery hosts 10,000+ modules. `Install-Module` and go.
+ #strong[Windows administration] – Active Directory, Exchange, Azure, Microsoft 365 – all PowerShell-first.

```powershell
# One line: get the 5 largest files in your home directory
Get-ChildItem ~ -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 5 -Property Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}
```

Try that in `cmd.exe`. We’ll wait.

#horizontalrule

== 4. PowerShell vs Other Shells
<powershell-vs-other-shells>
#figure([#image("images/ch-01-comparison.png")],
  caption: [
    ps-vs-shells
  ]
)

#align(center)[#table(
  columns: 4,
  align: (col, row) => (auto,auto,auto,auto,).at(col),
  inset: 6pt,
  [Feature], [PowerShell], [Bash], [cmd.exe],
  [#strong[Pipeline data]],
  [Objects],
  [Text streams],
  [Text],
  [#strong[Naming]],
  [Verb-Noun (`Get-Process`)],
  [Arbitrary (`ps`, `ls`)],
  [Arbitrary (`dir`, `type`)],
  [#strong[Runtime]],
  [.NET],
  [C / POSIX],
  [Win32],
  [#strong[Scripting]],
  [Full language],
  [Shell scripting],
  [Batch (limited)],
  [#strong[Cross-platform]],
  [Yes (7.x)],
  [Yes (native)],
  [Windows only],
  [#strong[Error handling]],
  [Try/Catch + ErrorAction],
  [Exit codes + `trap`],
  [`ERRORLEVEL`],
  [#strong[Discoverability]],
  [`Get-Command`, `Get-Help`],
  [`man`, `--help`],
  [`/?` (inconsistent)],
)
]

#strong[The key insight:] Bash is brilliant at composing small text-processing utilities. PowerShell is brilliant at composing operations on structured data. They solve different problems well. Knowing both makes you dangerous in the best way.

#horizontalrule

== 5. Installing PowerShell 7
<installing-powershell-7>
PowerShell 7 runs alongside Windows PowerShell 5.1 – they don’t conflict. Install it on any OS with one command:

=== Windows (winget)
<windows-winget>
```powershell
winget install Microsoft.PowerShell
```

=== macOS (Homebrew)
<macos-homebrew>
```bash
brew install powershell/tap/powershell
```

=== Linux – Ubuntu/Debian (apt)
<linux-ubuntudebian-apt>
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

=== Linux – Snap (universal)
<linux-snap-universal>
```bash
sudo snap install powershell --classic
```

After installation, launch with:

```bash
pwsh
```

You should see the familiar `PS>` prompt. If you see it, you’re in business.

#horizontalrule

== 6. Your First Session
<your-first-session>
Open a terminal and type `pwsh`. Let’s run a few commands to prove everything works.

=== Check your version
<check-your-version>
```powershell
# What version am I running?
$PSVersionTable
```

```
Name                           Value
----                           -----
PSVersion                      7.4.6
PSEdition                      Core
GitCommitId                    7.4.6
OS                             Microsoft Windows 10.0.22631
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0, 5.0, 5.1...}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

The three fields that matter most right now: #strong[PSVersion] (should start with 7), #strong[PSEdition] (should be `Core`), and #strong[OS] (whatever you’re running on).

=== Get the current date
<get-the-current-date>
```powershell
Get-Date
```

```
Tuesday, March 17, 2026 10:42:15 AM
```

That returned a `[DateTime]` object. You can chain methods on it:

```powershell
(Get-Date).DayOfWeek    # Tuesday
(Get-Date).Year         # 2026
```

=== List running processes
<list-running-processes>
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

Notice the column headers? Those are #strong[property names]. Every row is an object. Welcome to PowerShell.

#horizontalrule

== Challenge
<challenge>
#blockquote[
#strong[Install PowerShell 7 on three different operating systems] (or VMs/containers). Run `$PSVersionTable` on each and compare the output.

Questions to answer: - Which keys are identical across all three? - Which keys differ? - What does `PSCompatibleVersions` tell you about backward compatibility?
]

#horizontalrule

== Boss Level
<boss-level>
#blockquote[
#strong[Write a script that detects the current OS] using `$IsWindows`, `$IsLinux`, and `$IsMacOS`, then installs or updates to the latest PowerShell 7 using the appropriate package manager (`winget`, `apt`, or `brew`). Handle errors gracefully – what if the package manager isn’t installed? What if the user isn’t root on Linux?
]

```powershell
# boss-level-01.ps1 -- OS-aware PowerShell installer
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Install-PowerShellUpdate {
    if ($IsWindows) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw "winget not found. Install App Installer from the Microsoft Store."
        }
        winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements
    }
    elseif ($IsMacOS) {
        if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
            throw "Homebrew not found. Install from https://brew.sh"
        }
        brew upgrade powershell/tap/powershell 2>&1 | Write-Host
    }
    elseif ($IsLinux) {
        # Check for root/sudo
        $whoami = whoami
        if ($whoami -ne 'root' -and -not (Get-Command sudo -ErrorAction SilentlyContinue)) {
            throw "Must run as root or have sudo installed."
        }
        $prefix = if ($whoami -ne 'root') { 'sudo' } else { '' }

        if (Get-Command apt-get -ErrorAction SilentlyContinue) {
            Invoke-Expression "$prefix apt-get update -qq"
            Invoke-Expression "$prefix apt-get install -y powershell"
        }
        elseif (Get-Command snap -ErrorAction SilentlyContinue) {
            Invoke-Expression "$prefix snap refresh powershell 2>&1" | Write-Host
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

#horizontalrule

== Exercises
<exercises>
=== \[Ch-01, Ex-1\] Simple: Identify Your PowerShell Version
<ch-01-ex-1-simple-identify-your-powershell-version>
Run `$PSVersionTable` and identify three things: your PowerShell version, the edition (Desktop or Core), and your operating system.

```powershell
# Run this and read the output
$PSVersionTable
```

=== \[Ch-01, Ex-2\] Normal: Discover "Get" Cmdlets in a Module
<ch-01-ex-2-normal-discover-get-cmdlets-in-a-module>
Use `Get-Command` to find all cmdlets whose verb is `Get` in the `Microsoft.PowerShell.Utility` module. How many are there?

```powershell
Get-Command -Verb Get -Module Microsoft.PowerShell.Utility
```

=== \[Ch-01, Ex-3\] Advanced: Count Commands by Type
<ch-01-ex-3-advanced-count-commands-by-type>
#blockquote[
Find the total count of #strong[cmdlets], #strong[functions], and #strong[aliases] available on your system. Use `Get-Command` and `Where-Object`.
]

=== \[Ch-01, Ex-4\] Extreme: One-Liner Command Census
<ch-01-ex-4-extreme-one-liner-command-census>
#blockquote[
Write a #strong[single pipeline] that outputs a formatted table showing the count of each command type on your system, sorted by count descending.
]

#horizontalrule

== Summary
<summary>
You now know what PowerShell is (an object-based automation framework), where it came from (Monad manifesto, 2002), why it matters (objects beat text), how it compares to other shells, and how to install it on any OS. Most importantly, you’ve run your first commands and seen real objects come back instead of raw text.

In the next chapter, we’ll explore the PowerShell console itself – profiles, prompts, tab completion, and the tools that make your daily life faster.

#horizontalrule

#emph[Next: #link("02-the-console.md")[Chapter 02 – The Console]]

= Chapter 02: The Console
<chapter-02-the-console>
#blockquote[
Your terminal is your workbench. Time to set it up right.
]

#figure([#image("images/ch-02-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

You can write PowerShell in Notepad and run it from `cmd.exe`. You can also eat soup with a fork. Both technically work, and both say something unflattering about your decision-making. This chapter is about choosing proper tools so that every minute you spend in the shell is productive instead of painful.

== Terminal Options
<terminal-options>
PowerShell is an engine. The terminal is the car you bolt it into. Pick the right chassis and the driving experience improves dramatically.

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Terminal], [Platform], [Best For],
  [#strong[Windows Terminal]],
  [Windows],
  [Daily driving – tabs, splits, GPU rendering],
  [#strong[VS Code Integrated]],
  [Cross-platform],
  [Scripting – IntelliSense, debugging, git],
  [#strong[ISE]],
  [Windows only],
  [Legacy scripts – do not start new work here],
  [#strong[macOS Terminal / iTerm2]],
  [macOS],
  [Native feel, good enough for most tasks],
  [#strong[GNOME Terminal / Konsole]],
  [Linux],
  [Solid defaults, integrates with your DE],
)
]

#blockquote[
ISE shipped its last update with Windows PowerShell 5.1. Microsoft has officially told it to enjoy retirement. If someone at work insists on ISE, smile politely and update your resume.
]

== Windows Terminal
<windows-terminal>
Windows Terminal is the recommended host on Windows. If you don’t have it yet, install it from the Microsoft Store or with:

```powershell
winget install Microsoft.WindowsTerminal
```

=== Why it matters
<why-it-matters>
- #strong[Tabs and split panes] – run PowerShell 7 and Windows PowerShell 5.1 side by side to test compatibility.
- #strong[GPU-accelerated rendering] – smooth scrolling even when dumping 50,000 log lines (you’ll do this more than you think).
- #strong[Profiles] – one click to launch PowerShell, cmd, WSL, or Azure Cloud Shell.
- #strong[Customization] – themes, fonts, background images, and opacity. Your terminal, your rules.

=== Key shortcuts
<key-shortcuts>
#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Action], [Shortcut],
  [New tab],
  [`Ctrl+Shift+T`],
  [Split pane right],
  [`Alt+Shift+Plus`],
  [Split pane down],
  [`Alt+Shift+Minus`],
  [Switch pane],
  [`Alt+Arrow`],
  [Close pane],
  [`Ctrl+Shift+W`],
)
]

Spend five minutes memorizing these. You’ll recoup that time investment before lunch.

== VS Code + The PowerShell Extension
<vs-code-the-powershell-extension>
For anything longer than a one-liner, VS Code is the environment you want. Install the #strong[PowerShell extension] (`ms-vscode.powershell`) and you get:

- #strong[IntelliSense] – tab completion that actually knows the parameter names, types, and valid values.
- #strong[Integrated debugging] – set breakpoints, inspect variables, step through code. No more `Write-Host "got here 3"`.
- #strong[Integrated terminal] – runs PowerShell right inside the editor. One window, everything accessible.
- #strong[Script analysis] – PSScriptAnalyzer runs in the background and highlights questionable code before you embarrass yourself in a PR.

```powershell
# Install the extension from the command line
code --install-extension ms-vscode.powershell
```

#blockquote[
VS Code is where you write scripts. Windows Terminal is where you run them interactively. Most professionals keep both open all day.
]

== PowerShell Profiles
<powershell-profiles>
A profile is a `.ps1` script that runs automatically every time PowerShell starts. Think of it as your shell’s morning routine – it loads your aliases, sets your prompt, imports your favorite modules, and generally makes the environment feel like home.

=== The \$PROFILE variable
<the-profile-variable>
PowerShell exposes the path to your profile as a built-in variable:

```powershell
$PROFILE
```

This returns the path for the #strong[CurrentUser, CurrentHost] profile – the one you’ll use 99% of the time.

=== The four profile paths
<the-four-profile-paths>
PowerShell actually supports four profiles, loaded in a specific order:

#figure([#image("images/ch-02-profiles.png")],
  caption: [
    profile-paths
  ]
)

#align(center)[#table(
  columns: 4,
  align: (col, row) => (auto,auto,auto,auto,).at(col),
  inset: 6pt,
  [\#], [Scope], [Path Variable], [When to Use],
  [1],
  [All Users, All Hosts],
  [`$PROFILE.AllUsersAllHosts`],
  [Machine-wide defaults (rare)],
  [2],
  [All Users, Current Host],
  [`$PROFILE.AllUsersCurrentHost`],
  [Terminal-specific machine defaults],
  [3],
  [Current User, All Hosts],
  [`$PROFILE.CurrentUserAllHosts`],
  [Your personal cross-host settings],
  [4],
  [Current User, Current Host],
  [`$PROFILE.CurrentUserCurrentHost`],
  [Your personal, terminal-specific settings],
)
]

They load top to bottom. If the same alias is defined in profile 1 and profile 4, profile 4 wins because it loads last.

=== Creating your first profile
<creating-your-first-profile>
Check if the file exists, then create it if it doesn’t:

```powershell
# Does the profile file exist?
Test-Path $PROFILE

# Create it (and any missing parent directories)
if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force
}

# Open it in your editor
code $PROFILE    # VS Code
notepad $PROFILE # Notepad (the fork-for-soup option)
```

Add something useful to start with:

```powershell
# ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1

# Aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

# Greeting
Write-Host "PowerShell $($PSVersionTable.PSVersion) ready." -ForegroundColor Cyan
Write-Host "Profile loaded from: $PROFILE" -ForegroundColor DarkGray
```

Save, close, and open a new PowerShell window. Your greeting should appear. If it doesn’t, check that your execution policy allows scripts:

```powershell
Get-ExecutionPolicy
# If "Restricted":
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

== PSReadLine
<psreadline>
PSReadLine is the module that makes PowerShell’s interactive experience tolerable. It ships with PowerShell 7 and handles syntax highlighting, history, key bindings, and predictive IntelliSense. You’ve been using it this whole time – you just didn’t know it had a name.

=== Syntax highlighting
<syntax-highlighting>
Type a valid cmdlet and it appears in one color. Mistype it and the color changes. This alone prevents a staggering number of typos.

=== Predictive IntelliSense
<predictive-intellisense>
PowerShell can suggest completions based on your command history:

```powershell
# Enable inline prediction (ghost text after your cursor)
Set-PSReadLineOption -PredictionSource History

# Or use ListView for a dropdown of suggestions
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
```

The `ListView` style shows a dropdown below your cursor with the top matches from your history. Press `DownArrow` to select, `Enter` to accept. Once you’ve used it for a day, you’ll wonder how you lived without it.

=== History search
<history-search>
Press `Ctrl+R` and start typing. PSReadLine searches backward through your history for matching commands. This is faster than pressing `UpArrow` forty times to find that `Invoke-RestMethod` call from last Tuesday.

```powershell
# Bind Ctrl+R to reverse history search (usually default)
Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
```

=== Useful key bindings
<useful-key-bindings>
#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Key], [Action],
  [`Ctrl+R`],
  [Reverse search history],
  [`Ctrl+S`],
  [Forward search history],
  [`Tab`],
  [Complete command/parameter],
  [`Ctrl+Space`],
  [Show all completions],
  [`F2`],
  [Toggle between inline and list prediction],
  [`Ctrl+d`],
  [Delete character (or exit if line is empty)],
)
]

== Customizing Your Prompt
<customizing-your-prompt>
The prompt is controlled by a function literally named `prompt`. Override it in your profile and PowerShell will call your version every time it draws a new line.

=== Basic custom prompt
<basic-custom-prompt>
```powershell
function prompt {
    $location = Get-Location
    $time = Get-Date -Format "HH:mm"
    "[$time] $location> "
}
```

This gives you something like `[14:32] C:\Projects>` instead of the default `PS C:\Projects>`.

=== Adding color
<adding-color>
```powershell
function prompt {
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time]" -ForegroundColor DarkGray -NoNewline
    Write-Host " $(Get-Location)" -ForegroundColor Cyan -NoNewline
    return "> "
}
```

#blockquote[
The `prompt` function must return a string. If it returns nothing, PowerShell falls back to `"PS> "`. The `Write-Host` calls handle the colorful parts, and the returned `"> "` is the actual prompt character.
]

=== Adding git status
<adding-git-status>
If you work with git repositories (and you will), showing the current branch in your prompt saves constant `git status` checks:

```powershell
function prompt {
    $branch = ""
    if (Test-Path .git) {
        $branch = git branch --show-current 2>$null
        if ($branch) { $branch = " ($branch)" }
    }
    $path = Split-Path (Get-Location) -Leaf
    Write-Host "$path" -ForegroundColor Cyan -NoNewline
    Write-Host $branch -ForegroundColor Yellow -NoNewline
    return "> "
}
```

For a more polished experience, look into #strong[Oh My Posh] or #strong[Starship] – prompt frameworks that handle themes, git status, execution time, and more with minimal configuration. We’ll revisit those in later chapters.

#horizontalrule

== Exercises
<exercises-1>
=== \[Ch-02, Ex-1\] Find Your Profile Path (Simple)
<ch-02-ex-1-find-your-profile-path-simple>
Use the `$PROFILE` variable to display your profile path. Then check whether the file actually exists using `Test-Path`.

=== \[Ch-02, Ex-2\] Create a Profile with Aliases and Greeting (Normal)
<ch-02-ex-2-create-a-profile-with-aliases-and-greeting-normal>
Create a profile script that: 1. Sets an alias `ll` that maps to `Get-ChildItem` 2. Sets an alias `np` that maps to `notepad` 3. Displays a greeting message when the shell starts

=== \[Ch-02, Ex-3\] Configure PSReadLine (Advanced)
<ch-02-ex-3-configure-psreadline-advanced>
#blockquote[
#strong[Advanced exercise.] Add PSReadLine configuration to your profile: set prediction to `ListView` style and bind `Ctrl+d` to `DeleteCharOrExit`.
]

=== \[Ch-02, Ex-4\] Admin-Aware Prompt (Extreme)
<ch-02-ex-4-admin-aware-prompt-extreme>
#blockquote[
#strong[Extreme exercise.] Build a profile that detects whether you’re running as an administrator (or root on Linux). Change the prompt color to red for admin sessions and green for normal user sessions. The detection logic must work on both Windows and Linux.
]

#horizontalrule

== Challenge: PSReadLine Power User
<challenge-psreadline-power-user>
#blockquote[
Configure PSReadLine with `ListView` prediction, custom key bindings for `UpArrow` and `DownArrow` history navigation, and a custom color scheme for the prediction list. Your configuration should be clean enough to drop into any colleague’s profile without modification.
]

== Boss Level: The Universal Profile
<boss-level-the-universal-profile>
#blockquote[
Build a profile that:

+ Detects the environment – admin vs. standard user, VS Code terminal vs. Windows Terminal vs. other, Windows vs. Linux vs. macOS.
+ Conditionally loads modules (e.g., `posh-git` only if installed).
+ Sets different prompt colors per context (admin \= red, VS Code \= blue, default \= green).
+ Measures and displays its own load time so you know when the profile is getting bloated.

The entire profile should load in under 500ms on a cold start. Profile performance matters – a 3-second profile startup is a 3-second tax on every terminal you open, every day, forever.
]

#horizontalrule

#blockquote[
#strong[Next up:] #link("03-commands-and-cmdlets.md")[Chapter 03 – Commands and Cmdlets], where you’ll learn the Verb-Noun pattern that makes PowerShell discoverable without a cheat sheet.
]

= Chapter 03: Commands and Cmdlets
<chapter-03-commands-and-cmdlets>
In PowerShell, everything is a Verb-Noun. Once you get that, everything clicks.

#figure([#image("images/ch-03-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== The Verb-Noun Convention
<the-verb-noun-convention>
Every PowerShell cmdlet follows a strict #strong[Verb-Noun] naming pattern. No exceptions (well, almost – aliases exist, but we’ll pretend they don’t for now).

#figure([#image("images/ch-03-verb-noun.png")],
  caption: [
    verb-noun
  ]
)

The verb tells you #emph[what] the command does. The noun tells you #emph[what it acts on]. This isn’t just a suggestion – it’s enforced by the community and by PowerShell’s module system. If you publish a module with unapproved verbs, PowerShell will passive-aggressively warn your users every time they import it.

=== Approved Verbs
<approved-verbs>
PowerShell maintains an official list of approved verbs. You can see them yourself:

```powershell
Get-Verb
```

That command returns every approved verb grouped by category. Here are the ones you’ll use 90% of the time:

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Verb], [What It Does], [Example],
  [`Get`],
  [Retrieves data],
  [`Get-Process`],
  [`Set`],
  [Changes an existing resource],
  [`Set-Location`],
  [`New`],
  [Creates something],
  [`New-Item`],
  [`Remove`],
  [Deletes something],
  [`Remove-Item`],
  [`Start`],
  [Begins an operation],
  [`Start-Process`],
  [`Stop`],
  [Ends an operation],
  [`Stop-Process`],
  [`Test`],
  [Validates a condition],
  [`Test-Path`],
  [`Invoke`],
  [Performs an action],
  [`Invoke-WebRequest`],
)
]

Why does this matter? Because when you need to do something new, you can #emph[guess] the command name. Need to restart a service? Try `Restart-Service`. Need to export data to CSV? Try `Export-Csv`. This predictability is one of PowerShell’s best features – and the thing that CMD and Bash quietly envy.

#horizontalrule

== Get-Help: Your Built-In Manual
<get-help-your-built-in-manual>
Before you Google anything, try `Get-Help`. It’s the man page system that actually wants you to succeed.

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

=== Updating Help Files
<updating-help-files>
If `Get-Help` returns suspiciously thin results, your help files probably haven’t been downloaded yet. Fix that:

```powershell
# Run as admin -- downloads help for all installed modules
Update-Help -Force -ErrorAction SilentlyContinue
```

The `-ErrorAction SilentlyContinue` is there because some modules ship without help files, and PowerShell will throw a tantrum about each one. You don’t need that energy in your life.

=== Wildcards in Help
<wildcards-in-help>
Don’t know the exact command name? Use wildcards:

```powershell
# Find everything related to "process"
Get-Help *process*

# Find all commands that "get" something about the network
Get-Help Get-Net*
```

#horizontalrule

== Get-Command: Discovery Mode
<get-command-discovery-mode>
While `Get-Help` explains a command, `Get-Command` helps you #emph[find] commands in the first place.

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

=== The Discovery Trio
<the-discovery-trio>
These three commands are your survival kit. Memorize them:

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Command], [Question It Answers],
  [`Get-Command`],
  ["Does this command exist?"],
  [`Get-Help`],
  ["How do I use this command?"],
  [`Get-Member`],
  ["What did this command return?"],
)
]

You’ll hear PowerShell veterans call them the "Big Three." They’re not wrong.

#horizontalrule

== Get-Member: X-Ray Vision for Objects
<get-member-x-ray-vision-for-objects>
This is the command that separates people who #emph[use] PowerShell from people who #emph[understand] PowerShell. `Get-Member` shows you the properties and methods of whatever object you pipe into it.

```powershell
# What properties does a process object have?
Get-Process | Get-Member

# Filter to just properties
Get-Process | Get-Member -MemberType Property

# Filter to just methods
Get-Process | Get-Member -MemberType Method
```

When you run `Get-Process | Get-Member`, you’ll see output like this:

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

That `TypeName` line is critical. It tells you that `Get-Process` doesn’t return text – it returns `System.Diagnostics.Process` objects. Each object carries properties (data) and methods (actions). This is the fundamental difference between PowerShell and every text-based shell: #strong[the pipeline carries objects, not strings.]

Once you internalize that, you stop thinking in "lines of text" and start thinking in "collections of structured data." That shift changes everything.

#horizontalrule

== The Pipeline: Objects on a Conveyor Belt
<the-pipeline-objects-on-a-conveyor-belt>
The pipe character `|` takes the output of one command and feeds it as input to the next. You’ve seen this in Bash, but PowerShell’s version is fundamentally different: it passes #strong[objects], not text.

#figure([#image("images/ch-03-pipeline.png")],
  caption: [
    pipeline-flow
  ]
)

```powershell
# Get all processes, sort by CPU usage (descending), take the top 5
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
```

Think of it as a factory conveyor belt. Each cmdlet is a workstation:

+ `Get-Process` – puts process objects on the belt
+ `Sort-Object CPU -Descending` – rearranges them by CPU usage
+ `Select-Object -First 5` – pulls the top 5 off the belt, discards the rest

No temporary variables. No intermediate files. No regex to parse column output. The objects keep their structure through every stage.

=== Common Pipeline Cmdlets
<common-pipeline-cmdlets>
#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Cmdlet], [Purpose],
  [`Where-Object`],
  [Filter objects by condition],
  [`Sort-Object`],
  [Sort by property],
  [`Select-Object`],
  [Pick specific properties or N items],
  [`ForEach-Object`],
  [Run code against each object],
  [`Measure-Object`],
  [Count, sum, average, min, max],
  [`Group-Object`],
  [Group by property value],
  [`Format-Table`],
  [Display as table (terminal only)],
  [`Format-List`],
  [Display as list (terminal only)],
)
]

A quick example combining several:

```powershell
# Running services, grouped by start type, counted
Get-Service |
    Where-Object Status -eq 'Running' |
    Group-Object StartType |
    Select-Object Name, Count
```

#blockquote[
#strong[Warning:] `Format-*` cmdlets are for display only. Never pipe their output into another cmdlet for processing – they produce formatting objects, not data. Put them at the #emph[end] of your pipeline or not at all.
]

#horizontalrule

== Essential Cmdlets
<essential-cmdlets>
These are the commands you’ll reach for every single day. Get comfortable with them before moving to the next chapter.

=== Get-Process
<get-process>
```powershell
# All processes
Get-Process

# Specific process by name
Get-Process -Name pwsh

# With memory details
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Name, @{N='MemMB';E={[math]::Round($_.WorkingSet64/1MB)}}
```

=== Get-Service
<get-service>
```powershell
# All services
Get-Service

# Running services only
Get-Service | Where-Object Status -eq 'Running'

# Check a specific service
Get-Service -Name sshd
```

=== Get-ChildItem
<get-childitem>
The PowerShell equivalent of `ls` / `dir`. Works on the filesystem, registry, certificates – any PowerShell provider.

```powershell
# List current directory
Get-ChildItem

# Recursive search for .log files
Get-ChildItem -Path C:\ -Filter *.log -Recurse -ErrorAction SilentlyContinue

# Include hidden files
Get-ChildItem -Force
```

=== Get-Content
<get-content>
Reads file contents. Think `cat` but with object superpowers.

```powershell
# Read a file
Get-Content ./server.log

# Last 20 lines (tail)
Get-Content ./server.log -Tail 20

# Follow a log in real time (tail -f)
Get-Content ./server.log -Wait -Tail 5
```

=== Measure-Object
<measure-object>
Your Swiss army knife for quick statistics.

```powershell
# Count items
Get-ChildItem | Measure-Object

# Sum file sizes
Get-ChildItem | Measure-Object -Property Length -Sum

# Line/word/character count (like wc)
Get-Content ./README.md | Measure-Object -Line -Word -Character
```

#horizontalrule

== Challenge: Find All Stop-Verb Cmdlets
<challenge-find-all-stop-verb-cmdlets>
Your first real task: find every cmdlet on your system that can #emph[stop] something, then explore what parameters they accept.

```powershell
# Step 1: Find them
Get-Command -Verb Stop

# Step 2: Pick one and explore its parameters
Get-Help Stop-Process -Detailed
```

Count how many you find. On a typical Windows system, you’ll discover more things you can stop than you probably should.

#horizontalrule

== Boss Level: System Health Summary
<boss-level-system-health-summary>
#blockquote[
Chain five or more cmdlets to produce a single `PSCustomObject` containing a system health summary. Include: total process count, number of running services, system uptime in hours, total memory used by all processes (in MB), and the number of files in your temp directory.
]

This is where everything in this chapter comes together – `Get-Process`, `Get-Service`, `Measure-Object`, `Get-ChildItem`, and `PSCustomObject` construction. If you can do this, you own Chapter 03.

#horizontalrule

== Exercises
<exercises-2>
=== \[Ch-03, Ex-1\] Simple: Get-Help for Get-ChildItem
<ch-03-ex-1-simple-get-help-for-get-childitem>
Use `Get-Help` to look up the documentation for `Get-ChildItem`. Read the synopsis and identify at least two parameters it supports.

=== \[Ch-03, Ex-2\] Normal: Top 5 Processes by CPU
<ch-03-ex-2-normal-top-5-processes-by-cpu>
Write a one-liner that returns the 5 processes consuming the most CPU time. Display them in descending order.

=== \[Ch-03, Ex-3\] Advanced: All Stop-Verb Cmdlets
<ch-03-ex-3-advanced-all-stop-verb-cmdlets>
#blockquote[
]

Find every cmdlet on your system that uses the verb `Stop`. Verify that every result actually has `Stop` as its verb – no false positives allowed.

=== \[Ch-03, Ex-4\] Extreme: System Health Summary
<ch-03-ex-4-extreme-system-health-summary>
#blockquote[
]

Build a `PSCustomObject` that contains at least five data points about your system’s health. Use pipeline cmdlets, `Measure-Object`, and at least three different `Get-*` cmdlets as data sources. The result should be a single object, not a wall of text.

#horizontalrule

== Key Takeaways
<key-takeaways>
- Every cmdlet follows #strong[Verb-Noun] naming. Use `Get-Verb` to see approved verbs.
- The #strong[Big Three] – `Get-Command`, `Get-Help`, `Get-Member` – answer "what exists," "how to use it," and "what it returns."
- The pipeline passes #strong[objects], not text. This is the single most important concept in PowerShell.
- `Get-Member` reveals the type, properties, and methods of any object. Use it constantly.
- `Where-Object` filters, `Sort-Object` sorts, `Select-Object` picks, `Measure-Object` counts. These four are your pipeline workhorses.

#horizontalrule

#emph[Next up: #link("04-variables-and-types.md")[Chapter 04 – Variables and Types], where we learn that everything in PowerShell is an object, even when it doesn’t look like one.]

= Chapter 04: Variables and Types
<chapter-04-variables-and-types>
#blockquote[
#emph["Why does `'2' + 2` give me `'22'`?" – Sam. "Welcome to types. PowerShell is helpful… sometimes too helpful." – Max.]
]

#figure([#image("images/ch-04-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== What You’ll Learn
<what-youll-learn-1>
- How to declare and use variables with `$variable` syntax
- PowerShell’s automatic variables (`$_`, `$PSVersionTable`, `$null`, `$true`, `$false`)
- String quoting rules: single vs double, and when it matters
- Here-strings for multi-line text blocks
- Numbers, arrays, and hashtables
- Type casting and `.GetType()` for type introspection

#horizontalrule

== Variables: Dollar Signs All the Way Down
<variables-dollar-signs-all-the-way-down>
In PowerShell, every variable starts with `$`. That’s it. That’s the whole syntax rule.

```powershell
$name    = "Sam"
$count   = 42
$running = $true
```

No `var`, no `let`, no `const`. Just `$` and a name. PowerShell infers the type automatically based on the value you assign – a system called #strong[dynamic typing]. This is convenient until it quietly does something you didn’t expect, which brings us right back to Sam’s problem.

=== Naming Rules
<naming-rules>
Variable names are case-insensitive (`$Name` and `$name` are the same variable) and can contain letters, numbers, and underscores. By convention, use #strong[camelCase] for local variables and #strong[PascalCase] for parameters.

```powershell
$serverName  = "web01"       # camelCase -- local variable, fine
$ServerName  = "web01"       # PascalCase -- same variable! just a style choice
$server_name = "web01"       # valid, but unusual in PowerShell
```

#blockquote[
#strong[Note for Bash people (hi, Rina):] In Bash, `$` is for reading a variable; you write it bare: `name="Sam"`. In PowerShell, `$` is always there – on reads #emph[and] on writes. If you forget it when writing, PowerShell will tell you. Loudly.
]

#horizontalrule

== Automatic Variables
<automatic-variables>
PowerShell ships with a set of variables that are always defined for you. These are called #strong[automatic variables]. Some are read-only constants; others update as your script runs.

#figure([#image("images/ch-04-auto-vars.png")],
  caption: [
    auto-vars
  ]
)

=== The Most Useful Automatic Variables
<the-most-useful-automatic-variables>
#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Variable], [What It Is],
  [`$_`],
  [The current object in a pipeline (alias: `$PSItem`)],
  [`$null`],
  [Explicit nothing – not zero, not empty string],
  [`$true`],
  [Boolean true (read-only constant)],
  [`$false`],
  [Boolean false (read-only constant)],
  [`$PSVersionTable`],
  [Hashtable of PowerShell version information],
  [`$Error`],
  [Array of the most recent errors (newest at index 0)],
  [`$HOME`],
  [Current user’s home directory],
  [`$env:PATH`],
  [The system PATH (and any other environment variable)],
)
]

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

#horizontalrule

== Strings: Quoting Is Not Optional
<strings-quoting-is-not-optional>
PowerShell has two flavours of string literal. They look similar. They behave very differently.

=== Single Quotes: What You See Is What You Get
<single-quotes-what-you-see-is-what-you-get>
Single-quoted strings are #strong[literal]. No substitution, no escape sequences, no funny business.

```powershell
$name = "Sam"
'Hello, $name'       # Output: Hello, $name   (literal dollar sign)
'Line1`nLine2'       # Output: Line1`nLine2   (literal backtick-n)
```

Use single quotes when you want the string exactly as written – regex patterns, paths with backslashes, anything where you don’t want PowerShell second-guessing you.

=== Double Quotes: The Expressive One
<double-quotes-the-expressive-one>
Double-quoted strings support #strong[variable interpolation] and #strong[escape sequences].

```powershell
$name = "Sam"
"Hello, $name"       # Output: Hello, Sam
"Tab:`there"         # Output: Tab:    here
"Line1`nLine2"       # Output: two lines
```

You can embed entire expressions using `$()` – the #strong[subexpression operator]:

```powershell
$servers = @("web01", "db01", "app01")
"We manage $($servers.Count) servers."
# Output: We manage 3 servers.
```

Without the `$()`, PowerShell would expand `$servers` to its string representation and then try to access `.Count` as a literal character – which is not what you want.

=== The Format Operator: `-f`
<the-format-operator--f>
When interpolation gets messy, reach for `-f`. It’s .NET’s string format method in operator form:

```powershell
$name = "PowerShell"
$ver  = 7
'{0} version {1}' -f $name, $ver
# Output: PowerShell version 7

'Server: {0,-10} IP: {1}' -f 'web01', '10.0.0.1'
# Output: Server: web01       IP: 10.0.0.1
```

The `{0}`, `{1}` are positional placeholders. Optionally add `,N` for padding (negative \= left-aligned, positive \= right-aligned). This pattern shines when you’re building formatted reports or log lines.

=== Here-Strings: Multi-Line Without the Mess
<here-strings-multi-line-without-the-mess>
A here-string lets you write multi-line text without escaping anything. The opening `@"` and closing `"@` must be at the start of their lines.

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

Here-strings are invaluable for embedding JSON, XML, SQL queries, or any multi-line text where escaping would become a maintenance nightmare.

#horizontalrule

== Numbers
<numbers>
PowerShell infers numeric types based on the value:

```powershell
$i   = 42           # [int]    -- System.Int32
$big = 10000000000  # [long]   -- System.Int64 (too big for Int32)
$pi  = 3.14159      # [double] -- System.Double
```

=== Arithmetic and Size Multipliers
<arithmetic-and-size-multipliers>
PowerShell knows about common byte-size multipliers. They’re genuine integer constants, not string parsing tricks:

```powershell
1KB   # 1024
1MB   # 1048576
1GB   # 1073741824
1TB   # 1099511627776

# Practical example
$diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
```

#horizontalrule

== Arrays
<arrays>
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

Add to an array with `+=`. Fair warning: this creates a new array under the hood each time (because arrays are fixed-size in .NET). For heavy append workloads, use `[System.Collections.Generic.List[object]]` instead.

```powershell
$colors += 'yellow'   # works, but allocates a new array
```

#horizontalrule

== Hashtables
<hashtables>
A hashtable stores #strong[key/value pairs]. This is PowerShell’s equivalent of a dictionary, a map, or – for Rina – a Python `dict`.

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

Hashtables are #strong[unordered by default]. If key order matters (e.g., for display), use `[ordered]`:

```powershell
$config = [ordered]@{
    Host    = 'localhost'
    Port    = 5432
    Timeout = 30
}
```

#horizontalrule

== Type Hierarchy
<type-hierarchy>
Everything in PowerShell is a .NET object. Understanding the hierarchy helps you predict how types behave when mixed.

#figure([#image("images/ch-04-type-hierarchy.png")],
  caption: [
    type-hierarchy
  ]
)

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Type Literal], [.NET Type], [Example Value],
  [`[string]`],
  [`System.String`],
  [`"hello"`],
  [`[int]`],
  [`System.Int32`],
  [`42`],
  [`[long]`],
  [`System.Int64`],
  [`10000000000`],
  [`[double]`],
  [`System.Double`],
  [`3.14`],
  [`[bool]`],
  [`System.Boolean`],
  [`$true`],
  [`[datetime]`],
  [`System.DateTime`],
  [`Get-Date`],
  [`[array]`],
  [`System.Object[]`],
  [`@(1, 2, 3)`],
  [`[hashtable]`],
  [`System.Collections.Hashtable`],
  [`@{a=1}`],
)
]

#horizontalrule

== Type Casting
<type-casting>
You can coerce a value into a specific type by prefixing it with `[TypeName]`:

```powershell
[int]'42'           # converts string to integer: 42
[string]99          # converts integer to string: "99"
[bool]0             # $false  (0 is falsy in .NET)
[bool]1             # $true
[double]'3.14'      # 3.14
[datetime]'2024-01-15'  # a proper DateTime object
```

Casting is #strong[strict] – if the conversion fails, you get a terminating error:

```powershell
[int]'banana'   # ERROR: Cannot convert "banana" to type "System.Int32"
```

This is actually useful. Putting `[int]` on a variable declaration enforces the type for the lifetime of that variable:

```powershell
[int]$port = 8080
$port = 'http'    # ERROR -- PowerShell refuses to store a non-integer
```

That’s how you get self-documenting, self-validating variables. Max uses this trick in every production script he writes.

#horizontalrule

== `.GetType()`: Interrogate Any Value
<gettype-interrogate-any-value>
When in doubt about what you’re holding, ask it:

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

This is your debugging companion. Before you write `$x.SomeProperty`, run `$x.GetType()` to confirm what you’re dealing with. Rina does this out of habit every time she gets an unexpected result – a habit worth stealing.

#horizontalrule

== Back to Sam’s Problem
<back-to-sams-problem>
```powershell
'2' + 2
```

PowerShell sees a #strong[string] on the left side of `+`, so it promotes the right-hand `2` to a string and concatenates: `'22'`. This is operator #strong[left-hand-type precedence] – the left operand wins.

```powershell
2 + '2'    # 4  -- integer wins, string is cast to int
'2' + 2    # '22' -- string wins, int is cast to string
```

The fix when you actually want arithmetic:

```powershell
[int]'2' + 2    # 4  -- explicit cast before the operation
```

Once you understand left-hand precedence, PowerShell’s "helpfulness" becomes predictable. It never changes the rule – it just picks it based on what’s already on the left.

#horizontalrule

== Exercises
<exercises-3>
=== \[Ch-04, Ex-1\] Simple: Five Types, Five Proofs
<ch-04-ex-1-simple-five-types-five-proofs>
Create one variable of each of the following types and call `.GetType().Name` on each to verify PowerShell’s inference: `String`, `Int32`, `Boolean`, `Object[]` (array), `Hashtable`.

=== \[Ch-04, Ex-2\] Normal: Array of Server Hashtables
<ch-04-ex-2-normal-array-of-server-hashtables>
Build an array of three hashtables, each representing a server with keys `Name`, `IP`, and `Role`. Verify the array has three elements and that each element contains the `Name` key.

=== \[Ch-04, Ex-3\] Advanced: String Kung Fu
<ch-04-ex-3-advanced-string-kung-fu>
#blockquote[
]

Demonstrate three string techniques in a single script:

+ Double-quoted interpolation with a subexpression `$()`
+ A here-string that spans at least four lines and uses an interpolated variable
+ The `-f` format operator with at least two positional arguments

Each technique should produce visible, verifiable output.

=== \[Ch-04, Ex-4\] Extreme: Nested Config Hashtable
<ch-04-ex-4-extreme-nested-config-hashtable>
#blockquote[
]

Build a nested hashtable representing an application configuration system with at least three top-level keys, each holding a sub-hashtable. At least two values must be explicitly type-cast (e.g., `[int]`, `[bool]`). After building it, write a validation block that:

- Confirms the top-level key count equals 3
- Confirms a nested integer value is of type `[int]`
- Confirms a nested integer value is of type `[int]`
- Accesses a third-level value if you have one (bonus depth)

#horizontalrule

== Key Takeaways
<key-takeaways-1>
- Variables always start with `$`. PowerShell is case-insensitive but convention-sensitive.
- Automatic variables (`$_`, `$null`, `$true`, `$false`, `$PSVersionTable`) are always available – learn them once, use them everywhere.
- #strong[Single quotes are literal. Double quotes interpolate.] When unsure, ask yourself: "do I want PowerShell to expand anything in here?"
- Arrays use `@()`, hashtables use `@{}`. The difference is critical and not just syntactic.
- Type casting with `[TypeName]` is how you assert intent and catch bugs early. Use it in production scripts.
- `'2' + 2` equals `'22'` because the left operand sets the type. This is not a bug. It is a rule. Now you know the rule.

#horizontalrule

#emph[Next up: #link("05-control-flow.md")[Chapter 05 – Control Flow], where we stop running single commands and start making decisions.]

= Chapter 05: Operators and Expressions
<chapter-05-operators-and-expressions>
#blockquote[
#emph["The right operator in the right place is the difference between a script that works and a script that ruins someone’s Friday."]
]

#figure([#image("images/ch-05-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== What You’ll Learn
<what-youll-learn-2>
- Comparison operators and their case-sensitive variants
- Wildcard and regex matching
- Logical, arithmetic, and string operators
- Modern PowerShell: ternary, null-coalescing, and the range operator
- Type operators: `-is` and `-as`
- How PowerShell’s operator syntax compares to Python, Bash, and C\#

#horizontalrule

== 1. The Operator Problem
<the-operator-problem>
Rina writes her first PowerShell conditional:

```powershell
if ($x == 5) { "match" }
```

```
ParserError: Unexpected token '==' in expression or statement.
```

She stares at it. Sam wheels his chair over. "Double equals doesn’t work here?" Max, from across the room, not looking up: "PowerShell uses `-eq`. We’re not savages."

This catches everyone coming from Python, JavaScript, or Bash. PowerShell uses #strong[named operators] for comparisons. There are no symbolic `==`, `!=`, `>`, `<`. The trade-off is zero ambiguity: `-gt` is always greater-than, no matter what types you’re comparing.

#horizontalrule

== 2. Comparison Operators
<comparison-operators>
#figure([#image("images/ch-05-comparison.png")],
  caption: [
    operators-comparison
  ]
)

The core six:

#align(center)[#table(
  columns: 4,
  align: (col, row) => (auto,auto,auto,auto,).at(col),
  inset: 6pt,
  [Operator], [Meaning], [Example], [Result],
  [`-eq`],
  [Equal],
  [`5 -eq 5`],
  [`True`],
  [`-ne`],
  [Not equal],
  [`5 -ne 3`],
  [`True`],
  [`-gt`],
  [Greater than],
  [`10 -gt 5`],
  [`True`],
  [`-lt`],
  [Less than],
  [`3 -lt 7`],
  [`True`],
  [`-ge`],
  [Greater than or equal],
  [`5 -ge 5`],
  [`True`],
  [`-le`],
  [Less than or equal],
  [`4 -le 5`],
  [`True`],
)
]

```powershell
$age = 30
$age -ge 18    # True
$age -lt 65    # True
$age -eq 31    # False
```

=== Case Sensitivity: The Silent Trap
<case-sensitivity-the-silent-trap>
By default, string comparisons in PowerShell are #strong[case-insensitive]. This surprises people from case-sensitive ecosystems.

```powershell
'Hello' -eq 'hello'    # True  -- case-insensitive by default
'Hello' -eq 'HELLO'    # True
```

If you need case-sensitive matching, prefix with `c`:

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Operator], [Case-sensitive version],
  [`-eq`],
  [`-ceq`],
  [`-ne`],
  [`-cne`],
  [`-gt`],
  [`-cgt`],
  [`-lt`],
  [`-clt`],
  [`-ge`],
  [`-cge`],
  [`-le`],
  [`-cle`],
)
]

```powershell
'Hello' -ceq 'hello'    # False -- 'H' != 'h'
'Hello' -ceq 'Hello'    # True
```

There are also explicitly case-#strong[insensitive] variants (`-ieq`, `-ine`, etc.) that read like documentation in code where you want to be explicit. Most people use the unprefixed defaults.

#horizontalrule

== 3. Wildcard Operators: `-like` and `-notlike`
<wildcard-operators--like-and--notlike>
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

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Pattern], [Meaning],
  [`*`],
  [Zero or more characters],
  [`?`],
  [Exactly one character],
  [`[abc]`],
  [One character from the set],
  [`[a-z]`],
  [One character in the range],
)
]

```powershell
# Filter files by extension pattern
Get-ChildItem C:\Windows -File |
    Where-Object { $_.Name -like '*.log' }
```

#horizontalrule

== 4. Regex Operators: `-match` and `-notmatch`
<regex-operators--match-and--notmatch>
For real pattern power, `-match` uses #strong[.NET regular expressions] and, as a bonus, populates the automatic `$Matches` hashtable with captured groups.

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

#blockquote[
#strong[Important:] `$Matches` is only populated on the most recent `-match` call in the current scope. If you’re using it inside a loop, capture what you need immediately.
]

```powershell
# -notmatch: the logical inverse
'hello@example.com' -notmatch '@'      # False (it does match)
'not-an-email' -notmatch '@'           # True

# Case-sensitive regex variant
'PowerShell' -cmatch '^power'          # False (capital P required)
'PowerShell' -cmatch '^Power'          # True
```

#horizontalrule

== 5. Logical Operators
<logical-operators>
Combine conditions with:

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Operator], [Symbol shorthand], [Meaning],
  [`-and`],
  [(none)],
  [Both must be true],
  [`-or`],
  [(none)],
  [At least one must be true],
  [`-not`],
  [`!`],
  [Invert a boolean],
  [`-xor`],
  [(none)],
  [Exactly one must be true],
)
]

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

#horizontalrule

== 6. Arithmetic Operators
<arithmetic-operators>
Nothing exotic here, but a few PowerShell touches are worth knowing:

```powershell
10 + 3      # 13
10 - 3      # 7
10 * 3      # 30
10 / 3      # 3.3333...
10 % 3      # 1  (modulo)
```

=== Type-driven `+`
<type-driven>
The `+` operator changes behavior based on the #strong[left operand’s type]:

```powershell
1 + '2'           # 3      (int + string coercion → int arithmetic)
'1' + 2           # '12'   (string + anything → string concatenation)
@(1,2) + @(3,4)   # @(1,2,3,4)  (array concatenation)
```

This trips people up. When in doubt, be explicit: `[int]'2'` or `"$number"`.

=== Size multipliers (built-in constants)
<size-multipliers-built-in-constants>
```powershell
1KB    # 1024
1MB    # 1048576
1GB    # 1073741824
1TB    # 1099511627776

# Practical example: is a file larger than 100 MB?
(Get-Item 'bigfile.iso').Length -gt 100MB
```

#horizontalrule

== 7. String Operators
<string-operators>
PowerShell has dedicated operators for common string operations so you don’t have to reach for .NET methods every time.

=== `-replace`
<replace>
Uses regex. Returns a new string – PowerShell strings are immutable.

```powershell
'Hello, World!' -replace 'World', 'PowerShell'   # 'Hello, PowerShell!'
'foo123bar' -replace '\d+', 'NUM'                 # 'fooNUMbar'
'  spaces  ' -replace '^\s+|\s+$', ''             # 'spaces' (trim)
```

=== `-split`
<split>
```powershell
'one,two,three' -split ','         # @('one', 'two', 'three')
'one  two   three' -split '\s+'    # @('one', 'two', 'three')
'a:b:c:d' -split ':', 2            # @('a', 'b:c:d')  (max 2 parts)
```

=== `-join`
<join>
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

#horizontalrule

== 8. Type Operators: `-is` and `-as`
<type-operators--is-and--as>
=== `-is` and `-isnot`
<is-and--isnot>
Check the runtime type of a value:

```powershell
42 -is [int]           # True
42 -is [string]        # False
'hello' -is [string]   # True
(Get-Date) -is [DateTime]   # True

42 -isnot [string]     # True
```

=== `-as`
<as>
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

#horizontalrule

== 9. The Range Operator `..`
<the-range-operator-..>
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

#horizontalrule

== 10. Modern PowerShell: Ternary and Null-Coalescing
<modern-powershell-ternary-and-null-coalescing>
These landed in #strong[PowerShell 7.0] and were immediately controversial among people who learned PowerShell before 2020. They’re standard now. Use them.

=== Ternary operator `? :`
<ternary-operator>
```powershell
$age = 20
$status = $age -ge 18 ? 'adult' : 'minor'
# $status = 'adult'

# Equivalent legacy form (works everywhere):
$status = if ($age -ge 18) { 'adult' } else { 'minor' }
```

=== Null-coalescing `??`
<null-coalescing>
Return the left value if it’s not `$null`, otherwise return the right value:

```powershell
$name = $null
$displayName = $name ?? 'Anonymous'
# $displayName = 'Anonymous'

$name = 'Sam'
$displayName = $name ?? 'Anonymous'
# $displayName = 'Sam'
```

=== Null-coalescing assignment `??=`
<null-coalescing-assignment>
Assign to a variable only if it’s currently `$null`:

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

Max approval-stamps this pattern every code review. It’s cleaner than four lines of `if (-not $var) { $var = 'default' }`.

#horizontalrule

== 11. Operator Precedence
<operator-precedence>
When multiple operators appear in one expression, PowerShell evaluates them in this order (highest to lowest):

+ `()` – parentheses (always first)
+ Unary `-not`, `!`
+ Arithmetic: `*`, `/`, `%`
+ Arithmetic: `+`, `-`
+ Comparison: `-eq`, `-ne`, `-gt`, `-lt`, `-ge`, `-le`, `-like`, `-match`, `-is`, `-as`
+ Logical: `-and`, `-or`, `-xor`

```powershell
# Without parens: comparison before -and
5 -gt 3 -and 10 -lt 20     # True  (both are True)

# Arithmetic before comparison
2 + 3 -gt 4                # True  (5 > 4)

# Force order with parens
-not (5 -eq 5 -or 3 -eq 3) # False (-not True)
```

When in doubt, #strong[add parentheses]. They cost nothing and save debugging sessions.

#horizontalrule

== Boss Level
<boss-level-1>
#blockquote[
PowerShell’s `-replace` operator uses .NET regex with #strong[substitution patterns] in the replacement string. The `$1`, `$2` syntax references captured groups.

Write a function `Format-LogLine` that takes a raw log string in the format: `2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s`

And returns a reformatted string: `[2024-01-15 14:30:22] [ERROR] [WebServer] Connection timeout after 30s`

Requirements: use a #strong[single `-replace` call]. No intermediate variables, no `-split`, no `$Matches`.
]

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

#horizontalrule

== Exercises
<exercises-4>
=== \[Ch-05, Ex-1\] Simple: Case-Sensitive String Comparison
<ch-05-ex-1-simple-case-sensitive-string-comparison>
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

=== \[Ch-05, Ex-2\] Normal: Filter an Array with Multiple Operators
<ch-05-ex-2-normal-filter-an-array-with-multiple-operators>
Create an array of integers from 1 to 20 using the range operator. Then filter it to keep only numbers that are #strong[greater than 5 AND less than or equal to 15]. Display the result and verify the count is correct.

```powershell
$nums = 1..20

$filtered = $nums | Where-Object {
    # Your conditions here
}

"Count: $($filtered.Count)"  # Should be 10
$filtered                     # Should be 6..15
```

=== \[Ch-05, Ex-3\] Advanced: Regex Extraction from a Log Line
<ch-05-ex-3-advanced-regex-extraction-from-a-log-line>
#blockquote[
]

Given this log line:

```
2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s
```

Use `-match` to extract: - The date (`2024-01-15`) - The time (`14:30:22`) - The severity level (`ERROR`) - The component (`WebServer`)

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

=== \[Ch-05, Ex-4\] Extreme: Dynamic Query Builder with Splatting
<ch-05-ex-4-extreme-dynamic-query-builder-with-splatting>
#blockquote[
]

Build a function `Get-FilteredProcess` that accepts a hashtable of optional criteria and constructs a filtered process query dynamically. Use #strong[splatting] to pass the `Name` parameter to `Get-Process` only when provided, and use operator expressions (`-ge`, `??=`) to handle missing keys gracefully.

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

#horizontalrule

== Summary
<summary-1>
You now have the full operator toolkit for PowerShell expressions:

- #strong[Comparison] (`-eq`, `-ne`, `-gt`, `-lt`, `-ge`, `-le`) are always named, always readable
- #strong[Case sensitivity] is opt-in via the `c` prefix (`-ceq`, `-clike`, `-cmatch`)
- #strong[Wildcards] (`-like`) for glob patterns, #strong[regex] (`-match`) for real pattern power – and `$Matches` captures groups automatically
- #strong[Logical] (`-and`, `-or`, `-not`) compose conditions cleanly
- #strong[String operators] (`-replace`, `-split`, `-join`) keep you out of .NET method calls for the common cases
- #strong[Type operators] (`-is`, `-as`) let you inspect and safely convert types
- #strong[Range] (`..`) gives you sequences without loops
- #strong[Ternary] (`? :`), #strong[null-coalescing] (`??`), and #strong[null-coalescing assignment] (`??=`) are your modernization kit for cleaner defaults and conditionals

The pattern: when you’re tempted to write four lines of `if ($thing)`, there’s usually a one-liner waiting with the right operator.

#horizontalrule

#emph[Next: #link("06-control-flow.md")[Chapter 06 – Control Flow]]

= Chapter 06: Control Flow
<chapter-06-control-flow>
#blockquote[
#emph[The difference between a script and a program is that a program knows when to stop repeating itself.]
]

#figure([#image("images/ch-06-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== What You’ll Learn
<what-youll-learn-3>
- `if` / `elseif` / `else` for branching logic
- `switch` with simple values, wildcards, regex, and file input
- `for`, `foreach`, and `while` loops
- `do-while` and `do-until` for post-condition loops
- `break` and `continue` for fine-grained loop control
- `ForEach-Object` in the pipeline
- Labeled loops for nested break/continue

#horizontalrule

== 1. Branching: `if` / `elseif` / `else`
<branching-if-elseif-else>
The classic conditional. PowerShell’s syntax will feel familiar if you’ve touched C, Python, or JavaScript – with one twist: comparison operators are words, not symbols.

```powershell
$temp = 37

if ($temp -gt 38) {
    Write-Host "Server is overheating!" -ForegroundColor Red
}
elseif ($temp -gt 35) {
    Write-Host "Temperature is elevated -- keep an eye on it." -ForegroundColor Yellow
}
else {
    Write-Host "Temperature nominal." -ForegroundColor Green
}
```

```
Temperature is elevated -- keep an eye on it.
```

=== Comparison operators at a glance
<comparison-operators-at-a-glance>
#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Operator], [Meaning], [Example],
  [`-eq`],
  [Equal],
  [`$x -eq 5`],
  [`-ne`],
  [Not equal],
  [`$x -ne 0`],
  [`-gt`],
  [Greater than],
  [`$x -gt 10`],
  [`-lt`],
  [Less than],
  [`$x -lt 100`],
  [`-ge`],
  [Greater or equal],
  [`$x -ge 1`],
  [`-le`],
  [Less or equal],
  [`$x -le 255`],
  [`-like`],
  [Wildcard match],
  [`$s -like 'web*'`],
  [`-match`],
  [Regex match],
  [`$s -match '^\d{3}'`],
  [`-in`],
  [In collection],
  [`$s -in @('a','b','c')`],
  [`-not` / `!`],
  [Negation],
  [`-not $flag`],
)
]

#blockquote[
#strong[Rina’s note:] Coming from Python, the `-eq` syntax feels verbose. Coming from Bash, it feels refreshingly readable. After a week you stop noticing. After a month you wonder why every other language uses `==` for comparison and `=` for assignment in the same scope.
]

=== Logical operators
<logical-operators-1>
```powershell
# -and, -or, -not, -xor
if ($IsWindows -and ($PSVersionTable.PSVersion.Major -ge 7)) {
    Write-Host "Modern PowerShell on Windows. Nice."
}

if (-not $IsLinux) {
    Write-Host "Not Linux -- consider your life choices."
}
```

#horizontalrule

== 2. `switch`: The Statement Sam Should Have Used
<switch-the-statement-sam-should-have-used>
When you find yourself writing three or more `elseif` branches on the same variable, that’s PowerShell asking you politely – then firmly – to use `switch`.

=== Basic switch
<basic-switch>
```powershell
$day = (Get-Date).DayOfWeek.ToString()

switch ($day) {
    'Monday'    { Write-Host "Back to the mines." }
    'Friday'    { Write-Host "Freedom is imminent." }
    'Saturday'  { Write-Host "No alerts, please." }
    'Sunday'    { Write-Host "Pre-Monday anxiety loading..." }
    default     { Write-Host "Mid-week. Coffee helps." }
}
```

=== Wildcard switch (`-Wildcard`)
<wildcard-switch--wildcard>
```powershell
$hostname = 'web-prod-03'

switch -Wildcard ($hostname) {
    'web-*'  { Write-Host "$hostname is a web server." }
    'db-*'   { Write-Host "$hostname is a database server." }
    'app-*'  { Write-Host "$hostname is an app server." }
    default  { Write-Host "$hostname: unknown role." }
}
```

```
web-prod-03 is a web server.
```

#blockquote[
#strong[Note:] Without `-Wildcard`, `web-*` is treated as a literal string – not a pattern. PowerShell won’t warn you. This is a classic gotcha.
]

=== Regex switch (`-Regex`)
<regex-switch--regex>
#figure([#image("images/ch-06-switch-modes.png")],
  caption: [
    switch-flowchart
  ]
)

```powershell
$logLine = '2026-03-17 ERROR disk usage at 95%'

switch -Regex ($logLine) {
    'FATAL|CRITICAL' { Write-Host "CRITICAL: Page the on-call." -ForegroundColor Red;    break }
    'ERROR'          { Write-Host "ERROR: Create a ticket."     -ForegroundColor Red;    break }
    'WARN'           { Write-Host "WARNING: Add to backlog."    -ForegroundColor Yellow; break }
    'INFO'           { Write-Host "Info: Log and move on."      -ForegroundColor Cyan;   break }
    default          { Write-Host "Unknown format. Investigate." }
}
```

```
ERROR: Create a ticket.
```

#strong[Important:] Without `break`, PowerShell’s `switch` keeps evaluating. Unlike `switch` in C or Java, it does #strong[not] stop at the first match by default. Every matching arm runs. For log severity classification this is a bug, not a feature. Use `break` liberally.

=== switch with multiple matching values
<switch-with-multiple-matching-values>
```powershell
# This is intentional -- no break
$permissions = @('Read', 'Write', 'Execute')

foreach ($perm in $permissions) {
    switch ($perm) {
        'Read'    { Write-Host "Can read files." }
        'Write'   { Write-Host "Can modify files." }
        'Execute' { Write-Host "Can run scripts." }
    }
}
```

=== switch on a file (`-File`)
<switch-on-a-file--file>
```powershell
# Process each line of a file as a switch value
switch -Regex -File '/var/log/app.log' {
    'FATAL' { Write-Host "FATAL found: $_" -ForegroundColor Red }
    'ERROR' { Write-Host "Error found: $_" }
}
```

`$_` inside a `-File` switch is the current line. This is PowerShell doing what PowerShell does: turning a tedious `Get-Content | ForEach-Object` loop into one clean statement.

#horizontalrule

== 3. Loops
<loops>
=== `for` – when you know the count
<for-when-you-know-the-count>
```powershell
for ($i = 0; $i -lt 5; $i++) {
    Write-Host "Iteration $i"
}
```

```
Iteration 0
Iteration 1
Iteration 2
Iteration 3
Iteration 4
```

Use `for` when you need an explicit counter – array indexing, retry logic with a ceiling, generating numbered files. For everything else, `foreach` is usually cleaner.

=== `foreach` – iterating collections
<foreach-iterating-collections>
```powershell
$servers = @('web01', 'db01', 'app01', 'cache01')

foreach ($server in $servers) {
    Write-Host "Pinging $server..."
    # Test-Connection $server -Count 1 -Quiet
}
```

`foreach` is not a cmdlet – it’s a language keyword. It does #strong[not] accept pipeline input. It is, however, faster than `ForEach-Object` for in-memory collections because it doesn’t create a pipeline.

=== `while` – condition-first loop
<while-condition-first-loop>
```powershell
$retries = 0
$maxRetries = 5
$connected = $false

while (-not $connected -and $retries -lt $maxRetries) {
    Write-Host "Connection attempt $($retries + 1)..."
    # $connected = Test-Connection db01 -Count 1 -Quiet
    $retries++
    Start-Sleep -Seconds 2
}

if ($connected) {
    Write-Host "Connected."
} else {
    Write-Host "Failed after $retries attempts." -ForegroundColor Red
}
```

The condition is checked #strong[before] each iteration. If it’s false from the start, the body never runs. That’s the right behavior when "zero iterations" is a valid outcome.

=== `do-while` and `do-until` – condition-last loops
<do-while-and-do-until-condition-last-loops>
```powershell
# do-while: runs at least once, continues WHILE condition is true
$input = ''
do {
    $input = Read-Host "Enter a server name (or 'done' to finish)"
    if ($input -ne 'done') {
        Write-Host "Queued: $input"
    }
} while ($input -ne 'done')

# do-until: runs at least once, continues UNTIL condition becomes true
$attempts = 0
do {
    $attempts++
    Write-Host "Attempt $attempts..."
    $success = ($attempts -ge 3)  # Simulate success on 3rd try
} until ($success)

Write-Host "Succeeded on attempt $attempts."
```

```
Attempt 1...
Attempt 2...
Attempt 3...
Succeeded on attempt 3.
```

#blockquote[
#strong[Max’s rule:] If the loop must run at least once – user prompts, connection warmup, first-attempt execution – use `do`. If "zero iterations" is valid, use `while`. Getting this wrong wastes CPU cycles at best and causes infinite loops at worst.
]

#horizontalrule

== 4. Loop Control: `break` and `continue`
<loop-control-break-and-continue>
#figure([#image("images/ch-06-loop-decision.png")],
  caption: [
    loop-decision
  ]
)

=== `break` – exit the loop immediately
<break-exit-the-loop-immediately>
```powershell
$servers = @('web01', 'db01', 'CRITICAL-db02', 'app01')

foreach ($server in $servers) {
    if ($server -like 'CRITICAL-*') {
        Write-Host "Critical server found: $server -- halting scan." -ForegroundColor Red
        break
    }
    Write-Host "Scanned: $server"
}
```

```
Scanned: web01
Scanned: db01
Critical server found: CRITICAL-db02 -- halting scan.
```

=== `continue` – skip this iteration, resume with the next
<continue-skip-this-iteration-resume-with-the-next>
```powershell
$servers = @('web01', '', 'db01', $null, 'app01')

foreach ($server in $servers) {
    if ([string]::IsNullOrEmpty($server)) {
        Write-Host "(skipping empty entry)"
        continue
    }
    Write-Host "Processing: $server"
}
```

```
Processing: web01
(skipping empty entry)
Processing: db01
(skipping empty entry)
Processing: app01
```

=== Labeled loops – breaking out of nested loops
<labeled-loops-breaking-out-of-nested-loops>
Unlabeled `break` only exits the #strong[innermost] loop. When you need to escape all the way out of a nested structure, use labels.

```powershell
:outerLoop foreach ($datacenter in @('DC1', 'DC2', 'DC3')) {
    foreach ($rack in @('Rack-A', 'Rack-B')) {
        if ($datacenter -eq 'DC2' -and $rack -eq 'Rack-B') {
            Write-Host "Found the problem rack: $datacenter / $rack -- stopping all scans."
            break outerLoop
        }
        Write-Host "Scanned: $datacenter / $rack"
    }
}
Write-Host "Scan complete."
```

```
Scanned: DC1 / Rack-A
Scanned: DC1 / Rack-B
Scanned: DC2 / Rack-A
Found the problem rack: DC2 / Rack-B -- stopping all scans.
Scan complete.
```

Labels work with `continue` too: `continue outerLoop` skips the rest of the inner loop and moves to the next iteration of the outer one.

#horizontalrule

== 5. `ForEach-Object` – Looping in the Pipeline
<foreach-object-looping-in-the-pipeline>
The `foreach` keyword is fast but disconnected from the pipeline. `ForEach-Object` (alias `%`) lives in the pipeline and processes objects as they stream through.

```powershell
# Pipeline-style: objects flow through
Get-Service | Where-Object Status -eq 'Running' | ForEach-Object {
    Write-Host "$($_.Name) is running."
}

# Equivalent foreach keyword (no pipeline, in-memory):
$runningServices = Get-Service | Where-Object Status -eq 'Running'
foreach ($svc in $runningServices) {
    Write-Host "$($svc.Name) is running."
}
```

=== `ForEach-Object` with `-Begin`, `-Process`, `-End`
<foreach-object-with--begin--process--end>
```powershell
1..5 | ForEach-Object -Begin {
    Write-Host "--- Starting batch ---"
    $sum = 0
} -Process {
    $sum += $_
    Write-Host "  Added $_ (running total: $sum)"
} -End {
    Write-Host "--- Final total: $sum ---"
}
```

```
--- Starting batch ---
  Added 1 (running total: 1)
  Added 2 (running total: 3)
  Added 3 (running total: 6)
  Added 4 (running total: 10)
  Added 5 (running total: 15)
--- Final total: 15 ---
```

=== Parallel `ForEach-Object` (PowerShell 7+)
<parallel-foreach-object-powershell-7>
```powershell
# Process 4 servers simultaneously instead of one by one
$servers = @('web01', 'db01', 'app01', 'cache01')

$results = $servers | ForEach-Object -Parallel {
    $ping = Test-Connection $_ -Count 1 -Quiet -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Server = $_
        Online = $ping
    }
} -ThrottleLimit 4

$results | Format-Table -AutoSize
```

#blockquote[
#strong[Rina:] In Python this would need `asyncio` or `concurrent.futures`. In Bash you’d background jobs and wait. In PowerShell 7 it’s one flag. I still resent it a little.
]

#horizontalrule

== 6. Choosing the Right Loop
<choosing-the-right-loop>
#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Scenario], [Recommended construct],
  [Fixed-count iteration (0 to N)],
  [`for`],
  [Iterating a known collection],
  [`foreach`],
  [Streaming pipeline objects],
  [`ForEach-Object`],
  [Polling until a condition],
  [`while` or `do-until`],
  [User prompt / must-run-once],
  [`do-while`],
  [Parallel processing],
  [`ForEach-Object -Parallel`],
  [Pattern-matching on a value],
  [`switch`],
  [Multi-branch on same variable],
  [`switch` (not `if`/`elseif`)],
)
]

#horizontalrule

== Exercises
<exercises-5>
=== \[Ch-06, Ex-1\] Simple: Categorize a Number
<ch-06-ex-1-simple-categorize-a-number>
Write a function using `if`/`elseif`/`else` that takes an integer and returns the string `'Negative'`, `'Zero'`, or `'Positive'`.

```powershell
function Get-NumberCategory {
    param([int]$Number)
    if ($Number -lt 0) { 'Negative' }
    elseif ($Number -eq 0) { 'Zero' }
    else { 'Positive' }
}

Get-NumberCategory -Number -5    # Negative
Get-NumberCategory -Number 0     # Zero
Get-NumberCategory -Number 42    # Positive
```

#strong[Expected output:]

```
Negative
Zero
Positive
```

#horizontalrule

=== \[Ch-06, Ex-2\] Normal: Classify Log Severity with `switch -Regex`
<ch-06-ex-2-normal-classify-log-severity-with-switch--regex>
Write a function `Get-Severity` that accepts a log line string and returns the severity label using a `switch -Regex` statement.

```powershell
function Get-Severity {
    param([string]$Line)
    switch -Regex ($Line) {
        'FATAL|CRITICAL' { 'Critical'; break }
        'ERROR'          { 'Error'; break }
        'WARN'           { 'Warning'; break }
        'INFO'           { 'Info'; break }
        default          { 'Unknown' }
    }
}

Get-Severity '2026-03-17 ERROR disk full'      # Error
Get-Severity '2026-03-17 WARN low memory'      # Warning
Get-Severity '2026-03-17 FATAL process crash'  # Critical
Get-Severity '2026-03-17 DEBUG trace data'     # Unknown
```

#strong[Expected output:]

```
Error
Warning
Critical
Unknown
```

Notice that `FATAL|CRITICAL` must come before `ERROR` – if the pattern `ERROR` appeared first and a line contained `CRITICAL ERROR`, you’d get `Error` instead of `Critical`. Order of arms matters in `switch -Regex`.

#horizontalrule

=== \[Ch-06, Ex-3\] Advanced: Process a Server List with `foreach` + `break`/`continue`
<ch-06-ex-3-advanced-process-a-server-list-with-foreach-breakcontinue>
#blockquote[
Write a script that iterates a server list, skips null/empty entries using `continue`, and stops the entire loop if it encounters a server name starting with `OFFLINE-`.
]

```powershell
$servers = @('web01', '', 'db01', $null, 'OFFLINE-cache01', 'app01')
$processed = [System.Collections.Generic.List[string]]::new()

foreach ($server in $servers) {
    if ([string]::IsNullOrEmpty($server)) {
        Write-Host "(skip: empty entry)"
        continue
    }
    if ($server -like 'OFFLINE-*') {
        Write-Host "Encountered offline marker: $server -- stopping." -ForegroundColor Yellow
        break
    }
    Write-Host "Processing: $server"
    $processed.Add($server)
}

Write-Host "Processed $($processed.Count) server(s): $($processed -join ', ')"
```

#strong[Expected output:]

```
Processing: web01
(skip: empty entry)
Processing: db01
(skip: empty entry)
Encountered offline marker: OFFLINE-cache01 -- stopping.
Processed 2 server(s): web01, db01
```

#horizontalrule

=== \[Ch-06, Ex-4\] Extreme: Retry Loop with Exponential Backoff
<ch-06-ex-4-extreme-retry-loop-with-exponential-backoff>
#blockquote[
Build an `Invoke-WithRetry` function that accepts a `[scriptblock]` and a `MaxRetries` parameter. On each failure, wait `2^attempt * 100ms` before retrying (exponential backoff). If all retries are exhausted, rethrow the last exception.
]

```powershell
function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$MaxRetries = 3
    )

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            return & $Action
        }
        catch {
            if ($i -eq ($MaxRetries - 1)) {
                throw  # Last attempt -- rethrow to caller
            }
            $delayMs = [math]::Pow(2, $i) * 100
            Write-Host "Attempt $($i + 1) failed: $($_.Exception.Message). Retrying in ${delayMs}ms..." -ForegroundColor Yellow
            Start-Sleep -Milliseconds $delayMs
        }
    }
}

# Test with a flaky operation that succeeds on the 3rd try
$script:callCount = 0
$result = Invoke-WithRetry -Action {
    $script:callCount++
    if ($script:callCount -lt 3) { throw "Simulated transient failure" }
    "Connected successfully"
} -MaxRetries 5

Write-Host $result
Write-Host "Total attempts: $script:callCount"
```

#strong[Expected output:]

```
Attempt 1 failed: Simulated transient failure. Retrying in 100ms...
Attempt 2 failed: Simulated transient failure. Retrying in 200ms...
Connected successfully
Total attempts: 3
```

The backoff delays are 100ms, 200ms, 400ms, 800ms – doubling each time. In production you’d add jitter (randomized offset) to prevent thundering herd when dozens of services retry simultaneously. That’s an exercise left for the ops engineers reading this at 3 AM.

#horizontalrule

== Summary
<summary-2>
You can now branch with `if`/`elseif`/`else` and collapse multi-branch logic into clean `switch` statements – with exact, wildcard, regex, or file-based matching. You have four loop constructs: `for` (counter-driven), `foreach` (collection iteration), `while` (condition-first), and `do` variants (condition-last, always runs once). `break` exits a loop, `continue` skips an iteration, and labeled loops let you escape nested structures without hacks. In the pipeline, `ForEach-Object` carries objects through instead of breaking the stream – and `-Parallel` makes it concurrent with one flag.

Control flow is where scripts stop being sequences of commands and start being programs that make decisions. Sam’s 200-line `if`/`elseif` chain is now a 10-line `switch`. Max has gone back to his coffee.

#horizontalrule

#emph[Next: #link("07-functions.md")[Chapter 07 – Functions]]

= Chapter 07: Functions and Scripts
<chapter-07-functions-and-scripts>
#blockquote[
#emph[A 500-line script with no functions is not a script. It’s a cry for help.]
]

#figure([#image("images/ch-07-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== What You’ll Learn
<what-youll-learn-4>
- How to define and call functions with the `function` keyword
- How to declare typed parameters with `param()` blocks
- How `[CmdletBinding()]` turns a function into an advanced function
- Validation attributes: `Mandatory`, `ValidateSet`, `ValidateRange`, `ValidateScript`
- Pipeline processing with `begin`, `process`, and `end` blocks
- How PowerShell’s output stream differs from `return`
- Scope rules: local, script, global, `$script:`, and `$global:`
- The anatomy of `.ps1` scripts, `#Requires`, and comment-based help
- Splatting with `@params` for cleaner function calls

#horizontalrule

== 1. Why Functions?
<why-functions>
Sam’s 500-line script worked. Technically. It ran the server health checks, generated the report, sent the email, and archived the logs. It just did all of that in one enormous, unbroken waterfall of code – no structure, no reuse, no way to test any piece in isolation.

When Rina had to add a single new check three weeks later, she spent forty-five minutes just finding the right line. When it broke at 2 AM, Max had no idea which part failed.

#strong[Functions are the unit of reuse in PowerShell.] They let you name a piece of logic, give it a defined interface, test it independently, and call it from anywhere. Once you think in functions, you never go back.

```powershell
# Before functions
$servers = Get-Content servers.txt
foreach ($s in $servers) {
    $ping = Test-Connection $s -Count 1 -Quiet
    if ($ping) { Write-Host "$s is up" }
    else { Write-Host "$s is DOWN" -ForegroundColor Red }
}
# ... 495 more lines of similar density ...

# After functions
function Test-ServerHealth {
    param([string]$ServerName)
    $up = Test-Connection $ServerName -Count 1 -Quiet
    [PSCustomObject]@{ Server = $ServerName; Online = $up }
}

Get-Content servers.txt | ForEach-Object { Test-ServerHealth $_ }
```

The second version is testable, readable, and reusable. That’s the entire pitch.

#horizontalrule

== 2. Basic Functions
<basic-functions>
The `function` keyword defines a named block of code. Call it by name.

```powershell
function Get-Greeting {
    param(
        [string]$Name = 'World'
    )
    "Hello, $Name!"
}

Get-Greeting              # Hello, World!
Get-Greeting -Name 'Sam'  # Hello, Sam!
```

=== Return Values: The Output Stream
<return-values-the-output-stream>
Here is the most important thing PowerShell beginners get wrong about functions: #strong[everything you write to the output stream is returned]. The `return` keyword just exits the function early – it does not define what the function "returns" in the traditional sense.

```powershell
function Get-Numbers {
    1      # Written to output stream
    2      # Also written to output stream
    return 3  # Written to output stream AND exits
    4      # Never reached
}

$result = Get-Numbers
$result  # 1, 2, 3 -- all three values
```

This trips up everyone who comes from Python or Bash. In PowerShell, think of the output stream as a pipe, not a return slot. Any expression that produces a value – and isn’t assigned or redirected – flows into that pipe automatically.

```powershell
function Get-ServerReport {
    param([string]$Name)

    # This WRITES to output stream (returns the object)
    [PSCustomObject]@{ Server = $Name; Checked = (Get-Date) }

    # This DOES NOT write to output stream (assigned to a variable)
    $internalState = "temporary data"

    # This DOES NOT write to output stream (redirected to host)
    Write-Host "Processing $Name..." -ForegroundColor Cyan
}
```

`Write-Host` goes to the host (your terminal), not the output stream. Your callers never see it. `Write-Output` (or just a bare expression) goes into the stream. Know the difference and you’ll never accidentally contaminate a pipeline.

#horizontalrule

== 3. The `param()` Block
<the-param-block>
Parameters are the function’s contract with its callers. PowerShell’s parameter system is remarkably powerful – it handles type conversion, validation, and pipeline binding automatically.

```powershell
function Invoke-Deployment {
    param(
        [string]$AppName,       # Optional string
        [string]$Environment,   # Optional string
        [int]$TimeoutSeconds = 300,  # With default value
        [switch]$WhatIf         # Switch parameter (flag)
    )

    if ($WhatIf) {
        Write-Host "Would deploy $AppName to $Environment (dry run)"
        return
    }

    Write-Host "Deploying $AppName to $Environment (timeout: ${TimeoutSeconds}s)"
}

Invoke-Deployment -AppName 'api' -Environment 'staging' -WhatIf
Invoke-Deployment -AppName 'api' -Environment 'prod' -TimeoutSeconds 600
```

=== Positional Parameters
<positional-parameters>
By default, parameters are positional in the order they’re declared. Specify `[Parameter(Position=0)]` to be explicit:

```powershell
function Get-StatusCode {
    param(
        [Parameter(Position=0)]
        [string]$Url,
        [Parameter(Position=1)]
        [int]$Timeout = 30
    )
    # Invoke-WebRequest $Url -TimeoutSec $Timeout
    "Checking $Url with ${Timeout}s timeout"
}

Get-StatusCode 'https://example.com' 10  # Positional works
Get-StatusCode -Url 'https://example.com' -Timeout 10  # Named also works
```

#horizontalrule

== 4. Advanced Functions with `[CmdletBinding()]`
<advanced-functions-with-cmdletbinding>
Adding `[CmdletBinding()]` to a function promotes it from a basic function to an #strong[advanced function] – effectively a first-class cmdlet. This single decoration unlocks:

- Automatic `-Verbose`, `-Debug`, `-ErrorAction`, `-WhatIf`, `-Confirm` support
- `$PSCmdlet` variable for accessing the cmdlet runtime
- `Write-Verbose` and `Write-Debug` output controlled by preference variables
- Full parameter attribute support

#figure([#image("images/ch-07-anatomy.png")],
  caption: [
    advanced-function-anatomy
  ]
)

```powershell
function Get-DiskUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Path,

        [ValidateSet('GB', 'MB', 'KB')]
        [string]$Unit = 'GB'
    )

    Write-Verbose "Scanning path: $Path"

    $bytes = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum).Sum

    $divisor = switch ($Unit) {
        'GB' { 1GB }
        'MB' { 1MB }
        'KB' { 1KB }
    }

    [PSCustomObject]@{
        Path  = $Path
        Size  = [math]::Round($bytes / $divisor, 2)
        Unit  = $Unit
    }
}

Get-DiskUsage -Path 'C:\Logs' -Unit 'MB'
Get-DiskUsage -Path 'C:\Logs' -Unit 'MB' -Verbose  # Shows verbose messages
```

=== Mandatory Parameters
<mandatory-parameters>
`[Parameter(Mandatory)]` forces the caller to provide a value. If they forget, PowerShell prompts interactively – no null checks required:

```powershell
function Remove-OldLogs {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [Parameter(Mandatory)]
        [ValidateRange(1, 365)]
        [int]$OlderThanDays
    )

    $cutoff = (Get-Date).AddDays(-$OlderThanDays)
    $files = Get-ChildItem $LogPath -Filter '*.log' |
             Where-Object { $_.LastWriteTime -lt $cutoff }

    foreach ($file in $files) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Remove")) {
            Remove-Item $file.FullName
        }
    }
}

Remove-OldLogs -LogPath 'C:\Logs' -OlderThanDays 30
Remove-OldLogs -LogPath 'C:\Logs' -OlderThanDays 30 -WhatIf  # Preview only
```

#horizontalrule

== 5. Validation Attributes
<validation-attributes>
Validation attributes run automatically before your function body executes. If a value fails validation, PowerShell throws a descriptive error – no manual validation code needed.

```powershell
function Set-ServerConfig {
    [CmdletBinding()]
    param(
        # Only these exact values are accepted
        [ValidateSet('Web', 'Database', 'App', 'Cache')]
        [string]$Role = 'Web',

        # Must be between 1 and 65535
        [ValidateRange(1, 65535)]
        [int]$Port = 80,

        # Must match this regex pattern
        [ValidatePattern('^[a-z][a-z0-9\-]{2,}$')]
        [string]$Hostname,

        # Custom validation logic
        [ValidateScript({
            if (Test-Path $_) { $true }
            else { throw "Config file '$_' does not exist." }
        })]
        [string]$ConfigFile
    )

    Write-Host "Configuring $Hostname as $Role on port $Port"
}

Set-ServerConfig -Role 'Web' -Port 8080 -Hostname 'web-01'
Set-ServerConfig -Role 'Invalid'  # ERROR: ValidateSet rejects this immediately
Set-ServerConfig -Port 99999      # ERROR: ValidateRange rejects this immediately
```

#blockquote[
`ValidateScript` receives the parameter value as `$_`. Return `$true` to accept or `throw` a descriptive message to reject. This is the escape hatch for anything `ValidateSet`, `ValidateRange`, and `ValidatePattern` cannot express – file existence checks, API calls, database lookups. Keep it cheap: this code runs on every invocation.
]

#horizontalrule

== 6. Pipeline Functions: `begin`, `process`, `end`
<pipeline-functions-begin-process-end>
This is where PowerShell functions go from useful to genuinely powerful. A function that accepts pipeline input can process thousands of objects with minimal memory overhead – one at a time, as they arrive, rather than buffering the whole collection.

```powershell
function ConvertTo-ServerReport {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$ServerName
    )

    begin {
        # Runs ONCE before any pipeline input arrives
        Write-Verbose "Starting server report batch"
        $startTime = Get-Date
        $processed = 0
    }

    process {
        # Runs ONCE PER OBJECT in the pipeline
        $processed++
        Write-Verbose "Processing: $ServerName"

        [PSCustomObject]@{
            Server  = $ServerName
            Online  = Test-Connection $ServerName -Count 1 -Quiet
            Checked = Get-Date
        }
    }

    end {
        # Runs ONCE after all pipeline input is consumed
        $duration = (Get-Date) - $startTime
        Write-Verbose "Processed $processed servers in $($duration.TotalSeconds)s"
    }
}

# Use it as a pipeline stage
'web-01', 'db-01', 'app-01' | ConvertTo-ServerReport
Get-Content servers.txt | ConvertTo-ServerReport | Export-Csv report.csv
```

=== Why `begin`/`process`/`end` Matters
<why-beginprocessend-matters>
Without these blocks, a function that takes `ValueFromPipeline` only processes the #emph[last] object. The `process` block is what makes it iterate. Compare:

```powershell
# BAD: Only processes last item
function Bad-UpperCase {
    param([Parameter(ValueFromPipeline)][string]$Text)
    $Text.ToUpper()  # Only runs for the last piped value
}

# GOOD: Processes every item
function ConvertTo-Upper {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)][string]$Text)
    process { $Text.ToUpper() }
}

'hello', 'world' | Bad-UpperCase   # WORLD  (only last item)
'hello', 'world' | ConvertTo-Upper # HELLO, WORLD  (both items)
```

Rina learned this one the hard way. Three hours of debugging a "broken" pipeline that was working perfectly – just silently discarding 99% of its input.

#horizontalrule

== 7. Scope Rules
<scope-rules>
PowerShell variables live in scopes. Functions create their own local scope. Changes to variables inside a function don’t affect the caller’s scope unless you use scope modifiers.

```powershell
$counter = 0  # Script scope

function Increment-Counter {
    $counter = 99  # Creates a LOCAL variable -- does NOT affect the outer $counter
    Write-Host "Inside function: $counter"
}

Increment-Counter
Write-Host "Outside function: $counter"
# Inside function: 99
# Outside function: 0  <-- unchanged!
```

=== Scope Modifiers
<scope-modifiers>
Use explicit scope prefixes to break through the default scope boundary:

```powershell
$script:deployCount = 0  # Script-scoped variable

function Register-Deployment {
    param([string]$AppName)
    $script:deployCount++  # Modifies the script-scoped variable
    Write-Host "Deployed $AppName. Total deployments: $script:deployCount"
}

Register-Deployment 'api'    # Deployed api. Total deployments: 1
Register-Deployment 'worker' # Deployed worker. Total deployments: 2

Write-Host "Final count: $script:deployCount"  # 2
```

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Scope], [Modifier], [Visibility],
  [Local],
  [(none)],
  [Current function/script only],
  [Script],
  [`$script:`],
  [Current `.ps1` file and all its functions],
  [Global],
  [`$global:`],
  [Entire PowerShell session],
  [Private],
  [`$private:`],
  [Current scope only (blocks child scope access)],
)
]

#blockquote[
#strong[Global scope is a code smell.] If you find yourself reaching for `$global:` in a function, step back and ask whether you should be returning a value instead. Global mutations are invisible side effects that make functions untestable. `$script:` is acceptable for module-internal state. `$global:` is for session-level settings and very little else.
]

#horizontalrule

== 8. Scripts vs. Functions, and `#Requires`
<scripts-vs.-functions-and-requires>
A `.ps1` file is a script. A `function` block inside a file is a function. You can have both, and they interact the way you’d expect: the script body runs top-to-bottom, and functions defined in the script are callable within it.

The `#Requires` directive lives at the top of a `.ps1` file and enforces prerequisites before a single line runs:

```powershell
#Requires -Version 7.2
#Requires -Modules ActiveDirectory, @{ ModuleName = 'Az'; ModuleVersion = '10.0' }
#Requires -RunAsAdministrator

# If any requirement fails, PowerShell stops here with a clear error.
# Your script never runs in a broken environment.

param(
    [Parameter(Mandatory)]
    [string]$OUPath
)

function Get-InactiveAccounts {
    param(
        [string]$OUPath,
        [int]$DaysInactive = 90
    )
    $cutoff = (Get-Date).AddDays(-$DaysInactive)
    Get-ADUser -Filter { LastLogonDate -lt $cutoff } -SearchBase $OUPath
}

Get-InactiveAccounts -OUPath $OUPath | Export-Csv inactive-accounts.csv
```

#horizontalrule

== 9. Comment-Based Help
<comment-based-help>
PowerShell has a built-in documentation system that makes your functions first-class citizens alongside system cmdlets. Add a comment block before the function, and `Get-Help` picks it up automatically.

```powershell
function Send-AlertEmail {
    <#
    .SYNOPSIS
        Sends an HTML alert email to the operations team.

    .DESCRIPTION
        Builds a formatted HTML email with the alert details and sends it via
        SMTP. Supports multiple recipients and optional attachment paths.
        All timestamps are normalized to UTC.

    .PARAMETER Subject
        The email subject line. Required. Keep it under 100 characters.

    .PARAMETER Body
        The plain-text body. Automatically converted to basic HTML.

    .PARAMETER Recipients
        One or more recipient email addresses. Mandatory.

    .PARAMETER Attachments
        Optional array of file paths to attach to the message.

    .EXAMPLE
        Send-AlertEmail -Subject 'Disk 90% full' -Body 'C:\ on WEB-01' -Recipients 'ops@company.com'

    .EXAMPLE
        Send-AlertEmail -Subject 'Deploy failed' -Body $errorLog -Recipients 'dev@company.com','ops@company.com' -Attachments 'deploy.log'

    .NOTES
        Requires SMTP relay access. Set $env:ALERT_SMTP_SERVER before calling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Subject,

        [Parameter(Mandatory)]
        [string]$Body,

        [Parameter(Mandatory)]
        [string[]]$Recipients,

        [string[]]$Attachments = @()
    )

    # ... implementation ...
}

Get-Help Send-AlertEmail -Full    # Full help output
Get-Help Send-AlertEmail -Examples  # Just the examples
```

The six most useful comment-based help keywords: `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER <name>`, `.EXAMPLE`, `.NOTES`, `.OUTPUTS`.

#horizontalrule

== 10. Splatting
<splatting>
Splatting lets you pass a hashtable of parameter values to a function, instead of listing them all inline. It keeps long calls readable and makes parameter sets programmable.

```powershell
function Deploy-Application {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$AppName,
        [Parameter(Mandatory)] [string]$Environment,
        [int]$TimeoutSeconds = 300,
        [string]$ConfigFile,
        [switch]$WhatIf
    )
    Write-Host "Deploying $AppName to $Environment"
}

# Without splatting -- one long, fragile line
Deploy-Application -AppName 'api-service' -Environment 'production' -TimeoutSeconds 600 -ConfigFile 'prod.json' -WhatIf

# With splatting -- readable and maintainable
$deployParams = @{
    AppName        = 'api-service'
    Environment    = 'production'
    TimeoutSeconds = 600
    ConfigFile     = 'prod.json'
    WhatIf         = $true
}
Deploy-Application @deployParams

# Splatting shines when parameters are conditional
$deployParams = @{
    AppName     = $AppName
    Environment = $TargetEnv
}

if ($Verbose) { $deployParams['Verbose'] = $true }
if ($ConfigOverride) { $deployParams['ConfigFile'] = $ConfigOverride }

Deploy-Application @deployParams
```

Note the `@` sigil when calling: `Deploy-Application @deployParams`. The `$` sigil reads the hashtable as a variable; the `@` sigil splats it as parameters.

#blockquote[
#strong[Splatting for proxy functions.] When you write a wrapper around an existing cmdlet, use `$PSBoundParameters` – which is automatically populated with all parameters the caller explicitly passed – and splat it to the inner command. This passes through every parameter without you having to enumerate them:

```powershell
function Invoke-SafeRemoveItem {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path,
        [switch]$Recurse
    )
    process {
        Write-Verbose "Validated: $Path exists before removing"
        if (Test-Path $Path) {
            Remove-Item @PSBoundParameters
        }
    }
}
```
]

#horizontalrule

== Exercises
<exercises-6>
=== \[Ch-07, Ex-1\] Simple: A Greeting Function
<ch-07-ex-1-simple-a-greeting-function>
Write a function named `Get-Greeting` that accepts a `[string]$Name` parameter and returns the string `"Hello, <Name>!"`. Call it with two different names.

```powershell
function Get-Greeting {
    param([string]$Name)
    # Your code here
}

Get-Greeting -Name 'World'      # Hello, World!
Get-Greeting -Name 'PowerShell' # Hello, PowerShell!
```

=== \[Ch-07, Ex-2\] Normal: An Advanced Server Info Function
<ch-07-ex-2-normal-an-advanced-server-info-function>
Write a function named `Get-ServerInfo` with `[CmdletBinding()]` that:

- Requires a `[string]$Name` parameter (Mandatory)
- Accepts a `[string]$Role` parameter with `ValidateSet` for `'Web'`, `'Database'`, `'App'`
- Defaults `$Role` to `'Web'`
- Returns a `PSCustomObject` with `Name` and `Role` properties

Test that passing an invalid role throws an error.

```powershell
function Get-ServerInfo {
    [CmdletBinding()]
    param(
        # Your parameters here
    )
    # Your code here
}

$result = Get-ServerInfo -Name 'srv01' -Role 'Database'
$result.Name  # srv01
$result.Role  # Database

Get-ServerInfo -Name 'srv02' -Role 'Invalid'  # Should throw
```

=== \[Ch-07, Ex-3\] Advanced: A Pipeline Processing Function
<ch-07-ex-3-advanced-a-pipeline-processing-function>
#blockquote[
Write a function named `ConvertTo-Upper` that:

- Has `[CmdletBinding()]`
- Accepts `[string]$Text` from the pipeline via `[Parameter(ValueFromPipeline)]`
- Uses a `process` block to convert each input string to uppercase
- Returns the uppercase string

Test it by piping an array of strings: `'hello', 'world' | ConvertTo-Upper`

```powershell
function ConvertTo-Upper {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Text
    )
    # Your begin/process/end blocks here
}

'hello', 'world' | ConvertTo-Upper  # HELLO, WORLD
```
]

=== \[Ch-07, Ex-4\] Extreme: A Structured Logging Function
<ch-07-ex-4-extreme-a-structured-logging-function>
#blockquote[
Build a function named `Write-Log` that:

- Has `[CmdletBinding()]`
- Accepts `[string]$Message` as Mandatory, from the pipeline
- Accepts `[string]$Level` with `ValidateSet('INFO', 'WARN', 'ERROR')`, defaulting to `'INFO'`
- Uses `begin` to initialize a `$entries` array
- Uses `process` to append a `PSCustomObject` with `Timestamp`, `Level`, and `Message` to `$entries`
- Uses `end` to output `$entries` (the complete log batch)
- Add comment-based help with `.SYNOPSIS` and at least one `.EXAMPLE`

```powershell
function Write-Log {
    <#
    .SYNOPSIS
        # Your synopsis here
    .EXAMPLE
        # Your example here
    #>
    [CmdletBinding()]
    param(
        # Your parameters here
    )
    begin { }
    process { }
    end { }
}

$logs = 'Test1', 'Test2' | Write-Log -Level 'WARN'
$logs.Count    # 2
$logs[0].Level # WARN
```
]

#horizontalrule

== Summary
<summary-3>
Functions are the architecture of a PowerShell codebase. `function` defines one; `param()` gives it a typed interface; `[CmdletBinding()]` promotes it to a full cmdlet with automatic `-Verbose`, `-Debug`, and error handling; `begin`/`process`/`end` makes it a first-class pipeline citizen. Scope rules keep variables from leaking; `#Requires` enforces prerequisites; comment-based help makes your functions self-documenting; splatting with `@params` keeps call sites clean.

Max’s rule: every script longer than 30 lines needs at least one function. Every function needs at least one comment. Every pipeline function needs a `process` block. Follow these three rules and 2 AM pages become 2-minute fixes.

#horizontalrule

#emph[Next: #link("08-modules.md")[Chapter 08 – Modules]]

= Chapter 08: The Pipeline Deep Dive
<chapter-08-the-pipeline-deep-dive>
Sam has achieved something remarkable. Nobody is quite sure if it’s art or a cry for help.

#figure([#image("images/ch-08-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== How the Pipeline Actually Works
<how-the-pipeline-actually-works>
You’ve been using the pipeline since Chapter 03. Now we go under the hood.

When you write `Get-Process | Where-Object { $_.CPU -gt 10 }`, PowerShell does something that surprises most people coming from Bash: it does #strong[not] wait for `Get-Process` to finish before starting `Where-Object`. The two cmdlets run #strong[concurrently], connected by an object queue. As soon as `Get-Process` produces the first process object, it drops it on the queue and `Where-Object` picks it up immediately.

This is called #strong[streaming execution], and it has two practical consequences:

+ #strong[Memory efficiency] – you never have all objects in RAM at once (unless you force it by assigning to a variable).
+ #strong[Early termination] – `Select-Object -First 5` can stop the pipeline the moment it has enough data. `Get-Process` never needs to enumerate everything.

The visual model is a conveyor belt – but it’s a #emph[live] belt, not a batch loader.

#figure([#image("images/ch-08-conveyor.png")],
  caption: [
    pipeline-conveyor
  ]
)

=== The Pipeline Variable: `$_` and `$PSItem`
<the-pipeline-variable-_-and-psitem>
Inside a script block in a pipeline, the current object is always available as `$_`. Its formal alias is `$PSItem` – they are identical, and `$_` wins on brevity in every practical scenario.

```powershell
# $_ is the object currently flowing through the pipe
Get-Process | Where-Object { $_.CPU -gt 5 }

# $PSItem is exactly the same thing, just more readable for beginners
Get-Process | Where-Object { $PSItem.CPU -gt 5 }
```

Use `$PSItem` in teaching contexts or shared code where clarity matters. Use `$_` in everything else, because you will be typing it five hundred times a day.

#horizontalrule

== Where-Object: The Gatekeeper
<where-object-the-gatekeeper>
`Where-Object` (alias: `?`) filters objects from the pipeline. Only objects for which the condition evaluates to `$true` continue downstream.

```powershell
# Verbose syntax -- explicit script block with $_
Get-Process | Where-Object { $_.WorkingSet64 -gt 100MB }

# Comparison syntax -- cleaner for simple property comparisons
Get-Process | Where-Object WorkingSet64 -gt 100MB

# Alias: ? (the question mark asks "does this pass?")
Get-Process | ? { $_.WorkingSet64 -gt 100MB }
```

The comparison syntax (without braces) is syntactic sugar introduced in PowerShell 3.0. It only works for simple one-property comparisons. The moment you need `and`, `or`, or any expression, you go back to the script block form.

```powershell
# Compound condition -- needs the script block
Get-Process | Where-Object { $_.WorkingSet64 -gt 100MB -and $_.CPU -gt 10 }

# String match with -like
Get-Service | Where-Object { $_.DisplayName -like '*Windows*' }

# Null check -- filter out empty properties
Get-Process | Where-Object { $null -ne $_.MainWindowTitle }
```

#blockquote[
#strong[Performance rule: filter left.] Put `Where-Object` as early in the pipeline as possible. Every object that doesn’t make it past the filter saves all downstream cmdlets from doing unnecessary work. On large datasets, this matters enormously.
]

#horizontalrule

== ForEach-Object: The Worker
<foreach-object-the-worker>
`ForEach-Object` (alias: `%`) runs a script block against every object in the pipeline. Unlike assigning to a variable and using a `foreach` loop, `ForEach-Object` maintains streaming – it processes one object at a time.

```powershell
# Basic usage: restart every stopped service (careful with this one)
Get-Service | Where-Object Status -eq 'Stopped' | ForEach-Object {
    Write-Host "Would restart: $($_.Name)"
}

# Alias: %
1..5 | % { $_ * $_ }   # Squares: 1, 4, 9, 16, 25

# Three-block form: Begin / Process / End
Get-Process | ForEach-Object `
    -Begin   { $total = 0 } `
    -Process { $total += $_.WorkingSet64 } `
    -End     { "Total memory: $([math]::Round($total/1MB)) MB" }
```

The `-Begin` block runs once before any objects arrive. The `-Process` block runs once per object. The `-End` block runs once after all objects are consumed. This is how you accumulate state across a streaming pipeline without breaking the stream.

#horizontalrule

== Select-Object: The Sculptor
<select-object-the-sculptor>
`Select-Object` does three distinct things, and knowing all three is what separates pipeline users from pipeline artists.

=== 1. Choose Properties
<choose-properties>
```powershell
# Only return Name and CPU from each process object
Get-Process | Select-Object Name, CPU, WorkingSet64
```

This does not filter rows – it shapes columns. The resulting objects have only the properties you named.

=== 2. First, Last, Skip, Unique
<first-last-skip-unique>
```powershell
# First N objects (can short-circuit the pipeline)
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Last N objects
Get-EventLog -LogName System -Newest 100 | Select-Object -Last 5

# Skip the first N, take the rest
Get-ChildItem | Select-Object -Skip 10

# Skip AND take
Get-ChildItem | Select-Object -Skip 5 -First 10  # items 6-15

# Deduplicate by value
'Alpha','Beta','Alpha','Gamma' | Select-Object -Unique
```

=== 3. Calculated Properties
<calculated-properties>
This is the feature that makes people realize PowerShell is genuinely powerful. A calculated property is a hashtable with a `Name` (or `N`) key and an `Expression` (or `E`) key. The expression is a script block evaluated against each object.

```powershell
# Convert WorkingSet64 bytes to megabytes, rounded to 2 decimal places
Get-Process | Select-Object Name, @{
    Name       = 'MemoryMB'
    Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) }
}
```

```powershell
# Combine two properties into one
Get-Process | Select-Object @{
    N = 'Label'
    E = { "$($_.Name) (PID $($_.Id))" }
}, CPU
```

```powershell
# Short form: N= and E= work as aliases for Name= and Expression=
Get-ChildItem | Select-Object Name, @{N='SizeKB'; E={[math]::Round($_.Length/1KB,1)}}
```

Calculated properties are how you reshape data mid-pipeline without writing to a variable, creating a function, or breaking the stream. They are used constantly in real-world automation.

#horizontalrule

== Sort-Object: Ordering the Chaos
<sort-object-ordering-the-chaos>
`Sort-Object` sorts by one or more properties. By default, ascending. Add `-Descending` to flip it.

```powershell
# Sort processes by working set, largest first
Get-Process | Sort-Object WorkingSet64 -Descending

# Sort by multiple keys: primary descending, secondary ascending
Get-Process | Sort-Object @{E='CPU'; D=$true}, @{E='Name'; D=$false}

# Sort strings case-insensitively (default) vs case-sensitively
'banana','Apple','cherry' | Sort-Object
'banana','Apple','cherry' | Sort-Object -CaseSensitive

# Remove duplicates while sorting
1,3,2,3,1 | Sort-Object -Unique
```

Multi-key sorting uses an array of hashtables. Each hashtable has an `E` (expression) key and a `D` (descending) key. This looks awkward but it reads well once you accept it: "sort by CPU descending, then by Name ascending."

#horizontalrule

== Group-Object: The Analyst
<group-object-the-analyst>
`Group-Object` groups pipeline objects by the value of a property (or expression). Each group becomes a `GroupInfo` object with a `Name`, a `Count`, and a `Group` array containing the original objects.

```powershell
# Group services by status
Get-Service | Group-Object Status

# Group processes by their first letter (using a script block)
Get-Process | Group-Object { $_.Name.Substring(0,1).ToUpper() }

# Count files by extension
Get-ChildItem -File | Group-Object Extension | Sort-Object Count -Descending

# Access the grouped objects themselves
$byStatus = Get-Service | Group-Object Status
$byStatus | ForEach-Object {
    "Status: $($_.Name) | Count: $($_.Count)"
}
```

`Group-Object` is your go-to for any "how many of each" question. Combine it with `Measure-Object` (next section) to answer "how many, and what are the aggregate stats per group."

#horizontalrule

== Measure-Object: The Statistician
<measure-object-the-statistician>
`Measure-Object` computes aggregate statistics across a collection of objects. It can count, sum, average, find the minimum, and find the maximum.

```powershell
# Count objects (the simplest use)
Get-Process | Measure-Object

# Sum and average a numeric property
Get-Process | Measure-Object CPU -Sum -Average -Maximum -Minimum

# Count lines/words/characters in text
Get-Content ./README.md | Measure-Object -Line -Word -Character
```

`Measure-Object` returns a `GenericMeasureInfo` object with properties like `Count`, `Sum`, `Average`, `Maximum`, `Minimum`. You access these via dot notation:

```powershell
$stats = Get-Process | Measure-Object CPU -Sum -Average
"Total CPU:   $($stats.Sum)"
"Average CPU: $([math]::Round($stats.Average, 2))"
```

=== Group + Measure Pattern
<group-measure-pattern>
This combination answers "what are the stats per category?" and you will use it constantly:

```powershell
# Average CPU per process group (by first character of name)
Get-Process | Group-Object { $_.Name[0].ToString().ToUpper() } | ForEach-Object {
    [PSCustomObject]@{
        Group      = $_.Name
        Count      = $_.Count
        AvgCPU     = [math]::Round(($_.Group | Measure-Object CPU -Average).Average, 3)
        TotalMemMB = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 1)
    }
} | Sort-Object TotalMemMB -Descending
```

This is a complete mini-analytics pipeline: group, measure each group, build a shaped result object, sort. Four conceptual stages, one expression.

#horizontalrule

== Tee-Object: The Wiretap
<tee-object-the-wiretap>
`Tee-Object` is named after the T-shaped pipe fitting. It passes objects through unchanged #emph[and simultaneously] captures them to a variable or a file. It lets you inspect what’s flowing through a pipeline without breaking the flow.

```powershell
# Capture to a variable while continuing the pipeline
Get-Process |
    Tee-Object -Variable allProcs |
    Where-Object { $_.WorkingSet64 -gt 100MB }

# $allProcs now holds ALL processes; the pipeline continues with filtered ones
"Total processes: $($allProcs.Count)"

# Capture to a file (appends one object per line as text)
Get-Process | Tee-Object -FilePath ./process-snapshot.txt | Select-Object -First 5
```

`Tee-Object` is invaluable for debugging long pipelines. Insert it between two stages to capture the intermediate state:

```powershell
Get-Service |
    Tee-Object -Variable beforeFilter |
    Where-Object Status -eq 'Running' |
    Tee-Object -Variable afterFilter |
    Sort-Object DisplayName
```

Now `$beforeFilter` and `$afterFilter` both exist after the pipeline completes, and you can inspect them to see exactly where objects dropped out.

#horizontalrule

== Pipeline Performance: The Two Golden Rules
<pipeline-performance-the-two-golden-rules>
=== Rule 1: Filter Left
<rule-1-filter-left>
Every object that doesn’t pass a filter saves all downstream cmdlets from processing it. The earlier you filter, the less work everything else does.

```powershell
# Slow: fetches all 10,000 events, THEN filters
Get-EventLog -LogName Application -Newest 10000 | Where-Object EntryType -eq 'Error'

# Fast: filters at the source, only fetches what you need
Get-EventLog -LogName Application -Newest 10000 -EntryType Error
```

When a cmdlet has native parameters that do the filtering (like `-EntryType`, `-Filter`, `-Include`, `-Exclude`), use those instead of `Where-Object`. The cmdlet does the filtering before objects even enter the pipeline.

=== Rule 2: Format Right
<rule-2-format-right>
`Format-Table`, `Format-List`, and `Format-Wide` produce #strong[formatting directive objects], not data objects. Once you call them, the pipeline contains presentation instructions, not your original data. Nothing useful can process those downstream.

```powershell
# Wrong: Format-Table kills the pipeline data
Get-Process | Format-Table Name, CPU | Export-Csv ./out.csv  # Export-Csv gets garbage

# Right: Format-Table goes last, only for display
Get-Process | Export-Csv ./out.csv  # Save real data first
Get-Process | Format-Table Name, CPU  # Then display if you want to see it
```

The rule is simple: `Format-*` is always the last thing in the pipeline. Always. No exceptions.

#horizontalrule

== Putting It All Together
<putting-it-all-together>
Here is the shape of a complete analytics pipeline that uses every concept from this chapter:

```powershell
Get-Process |
    Where-Object { $_.WorkingSet64 -gt 10MB } |          # filter left
    Select-Object Name, CPU, @{                           # calculated property
        N = 'MemMB'
        E = { [math]::Round($_.WorkingSet64 / 1MB, 1) }
    } |
    Group-Object { if ($_.MemMB -gt 200) { 'Heavy' } else { 'Normal' } } |
    ForEach-Object {
        [PSCustomObject]@{
            Tier    = $_.Name
            Count   = $_.Count
            AvgMem  = [math]::Round(($_.Group | Measure-Object MemMB -Average).Average, 1)
            TotalMem = ($_.Group | Measure-Object MemMB -Sum).Sum
        }
    } |
    Sort-Object TotalMem -Descending |
    Tee-Object -Variable tierSummary |
    Format-Table -AutoSize                                # format right
```

After this runs, `$tierSummary` holds the data objects, and the terminal shows a formatted table. Data and display are both available.

#horizontalrule

== Exercises
<exercises-7>
=== \[Ch-08, Ex-1\] Simple: Filter Heavy Processes
<ch-08-ex-1-simple-filter-heavy-processes>
Use `Where-Object` to find all processes currently using more than 100MB of working memory. Display only the `Name`, `Id`, and `WorkingSet64` properties.

=== \[Ch-08, Ex-2\] Normal: Average CPU Per Group
<ch-08-ex-2-normal-average-cpu-per-group>
Use `Group-Object` combined with `Measure-Object` to calculate the average CPU time per process-name group. Output a `PSCustomObject` per group containing `Category` and `Average`. Sort by average descending.

=== \[Ch-08, Ex-3\] Advanced: Calculated Property in Select-Object
<ch-08-ex-3-advanced-calculated-property-in-select-object>
#blockquote[
]

Build a `Select-Object` pipeline against `Get-Process` that adds a calculated property `MemoryMB` which is `WorkingSet64` converted to megabytes and rounded to 2 decimal places. The result should include `Name`, `Id`, and `MemoryMB`. Verify via `Get-Member` that `MemoryMB` is a `NoteProperty` on the result objects.

=== \[Ch-08, Ex-4\] Extreme: Event Pipeline to CSV
<ch-08-ex-4-extreme-event-pipeline-to-csv>
#blockquote[
]

Write a single pipeline expression (no intermediate variables, except an optional `$tempCsv` for the output path) that:

+ Sources data (use a synthetic array of `[PSCustomObject]` if live event logs are not available in your environment)
+ Groups by `Source`
+ Calculates `Count` and `AvgDuration` per group via `Measure-Object`
+ Exports the result to a CSV file
+ Re-imports the CSV and verifies the row count matches the number of groups

#horizontalrule

== Key Takeaways
<key-takeaways-2>
- The pipeline is #strong[streaming] – objects flow through concurrently, not in batches. Early termination and memory efficiency follow from this.
- `$_` / `$PSItem` is the current object inside any pipeline script block.
- #strong[Filter left with `Where-Object`], or better: use source cmdlet parameters.
- #strong[Format right] – `Format-*` cmdlets always go last or not at all.
- `Where-Object` gates objects; `ForEach-Object` transforms them; `Select-Object` shapes them; `Sort-Object` orders them; `Group-Object` buckets them; `Measure-Object` aggregates them; `Tee-Object` taps them.
- Calculated properties in `Select-Object` let you reshape data mid-stream using `@{Name='...'; Expression={...}}`.
- `Group-Object` + `Measure-Object` inside a `ForEach-Object` is the canonical pattern for per-group statistics.

#horizontalrule

#emph[Next up: #link("09-functions-and-script-blocks.md")[Chapter 09 – Functions and Script Blocks], where we learn to stop writing the same pipeline twelve times and start writing it once.]

= Chapter 09: Working with Files
<chapter-09-working-with-files>
Sam is on file 347. This chapter is for Sam.

#figure([#image("images/ch-09-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== The File Operations You’ll Use Every Day
<the-file-operations-youll-use-every-day>
PowerShell treats the filesystem like any other provider: consistent verbs, objects all the way down, and enough cmdlets to make any sysadmin’s shell script jealous. Once you stop reaching for Windows Explorer for bulk operations, you don’t go back.

Here’s the mental map you need:

#figure([#image("images/ch-09-decision-tree.png")],
  caption: [
    file-decision-tree
  ]
)

#horizontalrule

== Reading and Writing Files
<reading-and-writing-files>
=== Get-Content
<get-content-1>
`Get-Content` reads a file and returns each line as a string object in an array. That last part matters: you get a collection, not a wall of text.

```powershell
# Read the whole file
Get-Content ./server.log

# Last 20 lines -- the real tail
Get-Content ./server.log -Tail 20

# Follow in real time (tail -f)
Get-Content ./server.log -Wait -Tail 5

# Read as a single string (the -Raw switch)
$text = Get-Content ./config.json -Raw

# Specify encoding (UTF-8 without BOM is the sane default)
Get-Content ./legacy.txt -Encoding UTF8
```

The `-Raw` switch is your best friend when feeding file content to `ConvertFrom-Json`, `[xml]`, or any cmdlet that expects a single string rather than an array of lines.

=== Set-Content vs Out-File
<set-content-vs-out-file>
Two cmdlets write text to a file. They are not the same, and mixing them up will ruin your Tuesday.

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [], [`Set-Content`], [`Out-File`],
  [Input type],
  [Strings / objects via `.ToString()`],
  [Anything (uses formatter)],
  [Default encoding],
  [UTF-8 (no BOM)],
  [UTF-16LE (BOM)],
  [Use for],
  [Data files, scripts, configs],
  [Formatted text output],
  [Overwrites?],
  [Yes],
  [Yes (default)],
)
]

```powershell
# Write a string to a file
Set-Content -Path ./output.txt -Value "Hello, PowerShell"

# Append a line without overwriting
Add-Content -Path ./output.txt -Value "Line two"

# Redirect formatted output (table as text)
Get-Process | Format-Table | Out-File ./process-report.txt

# Append with Out-File
Get-Process | Out-File ./process-report.txt -Append
```

Rule of thumb: use `Set-Content` when writing data you want to process again later (CSV, JSON, config files). Use `Out-File` when writing output you want a human to read once and never pipe through anything again.

=== Add-Content
<add-content>
`Add-Content` appends to an existing file without reading it into memory first. This is useful for log files and incremental writes where loading the whole file would be wasteful.

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path ./app.log -Value "[$timestamp] Deployment complete"
```

#horizontalrule

== Navigating and Listing Files
<navigating-and-listing-files>
=== Get-ChildItem: The Swiss Army Knife
<get-childitem-the-swiss-army-knife>
`Get-ChildItem` (alias: `ls`, `dir`, `gci`) lists directory contents and does a lot more than that. Filters, recursion, hidden files, and attribute-based selection are all built in.

```powershell
# List current directory
Get-ChildItem

# Include hidden and system files
Get-ChildItem -Force

# Filter by extension
Get-ChildItem -Path C:\Logs -Filter *.log

# Recursive -- descend into all subdirectories
Get-ChildItem -Path C:\Logs -Filter *.log -Recurse -ErrorAction SilentlyContinue

# Directories only
Get-ChildItem -Directory

# Files only
Get-ChildItem -File

# Files modified in the last 7 days
Get-ChildItem -File | Where-Object LastWriteTime -gt (Get-Date).AddDays(-7)
```

The `-ErrorAction SilentlyContinue` on recursive searches is not laziness – it’s pragmatism. System directories and access-protected paths will throw permission errors that drown your output. Silence them unless you’re auditing access failures specifically.

```powershell
# Find large log files (> 100 MB)
Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object Length -gt 100MB |
    Sort-Object Length -Descending |
    Select-Object FullName, @{N='SizeMB'; E={[math]::Round($_.Length/1MB, 1)}}
```

Note: `100MB` is a PowerShell numeric literal, not a string. The runtime converts it to bytes automatically. Same applies to `1KB`, `1GB`, `1TB`.

#horizontalrule

== Creating, Removing, Moving, Copying
<creating-removing-moving-copying>
=== New-Item
<new-item>
Creates files, directories, symbolic links – anything the filesystem provider supports.

```powershell
# Create a directory
New-Item -Path ./logs -ItemType Directory

# Create a file (empty)
New-Item -Path ./logs/app.log -ItemType File

# Create with content
New-Item -Path ./config.txt -ItemType File -Value "debug=false"

# -Force creates parent directories if they don't exist and
# doesn't throw if the item already exists
New-Item -Path ./deep/nested/path -ItemType Directory -Force | Out-Null
```

Piping to `| Out-Null` suppresses the verbose object output that `New-Item` returns. It doesn’t suppress errors, just the success echo.

=== Remove-Item
<remove-item>
```powershell
# Delete a file
Remove-Item ./old-report.csv

# Delete a directory and everything in it
Remove-Item ./old-logs -Recurse -Force

# Delete all .tmp files in a directory
Get-ChildItem ./temp -Filter *.tmp | Remove-Item

# WhatIf: dry run -- shows what would be deleted without deleting
Remove-Item ./old-logs -Recurse -WhatIf
```

Always use `-WhatIf` before any `Remove-Item -Recurse` in production. It takes two extra seconds and costs nothing. Your future self will thank you.

=== Copy-Item and Move-Item
<copy-item-and-move-item>
```powershell
# Copy a file
Copy-Item ./report.csv ./backup/report-backup.csv

# Copy a directory recursively
Copy-Item ./configs ./configs-backup -Recurse

# Move (rename across directories)
Move-Item ./report.csv ./archive/2026-report.csv

# Move all .log files to an archive folder
Get-ChildItem ./logs -Filter *.log |
    Move-Item -Destination ./logs/archive/
```

=== Rename-Item
<rename-item>
This is the cmdlet Sam needed on file 347.

```powershell
# Rename a single file
Rename-Item -Path ./report.csv -NewName report-final.csv

# Bulk rename: add a date prefix to every .log file
Get-ChildItem ./logs -Filter *.log |
    Rename-Item -NewName { "2026-01-$($_.Name)" }

# Replace a string in all filenames
Get-ChildItem ./reports -Filter *draft* |
    Rename-Item -NewName { $_.Name -replace 'draft', 'final' }
```

The scriptblock syntax in `-NewName { ... }` is one of PowerShell’s most useful patterns. `$_` refers to the current pipeline object, so you can derive the new name from the old one without a loop.

#horizontalrule

== Path Operations
<path-operations>
Working with paths as strings is fragile – backslashes on Windows, forward slashes on Linux, different roots everywhere. Use the path cmdlets and let PowerShell handle the platform details.

=== Join-Path
<join-path>
```powershell
# Safe cross-platform path construction
$logFile = Join-Path $env:TEMP "myapp" "run.log"
# Result: C:\Users\sam\AppData\Local\Temp\myapp\run.log

# Useful in scripts that need to run on both Windows and Linux
$config = Join-Path $PSScriptRoot "config" "settings.json"
```

=== Split-Path
<split-path>
```powershell
# Get the directory part
Split-Path "C:\Logs\app\error.log"
# Result: C:\Logs\app

# Get the filename
Split-Path "C:\Logs\app\error.log" -Leaf
# Result: error.log

# Get the drive root
Split-Path "C:\Logs\app\error.log" -Qualifier
# Result: C:
```

=== Test-Path
<test-path>
```powershell
# Does this path exist?
if (Test-Path ./config.json) {
    $config = Get-Content ./config.json -Raw | ConvertFrom-Json
} else {
    Write-Warning "Config file not found -- using defaults"
}

# Check for a specific type
Test-Path ./output -PathType Container   # Directory only
Test-Path ./report.csv -PathType Leaf    # File only
```

=== Resolve-Path
<resolve-path>
```powershell
# Convert relative path to absolute
Resolve-Path ../configs
# Result: /home/rina/projects/configs (on Linux) or C:\Users\rina\... (Windows)

# Useful in scripts to anchor yourself
$scriptDir = Resolve-Path (Split-Path $MyInvocation.MyCommand.Path)
```

#horizontalrule

== Structured Data: CSV, JSON, and XML
<structured-data-csv-json-and-xml>
=== CSV
<csv>
PowerShell’s CSV support is excellent. Import gives you objects. Export gives you CSV. The pipeline does the rest.

```powershell
# Import CSV -- each row becomes a PSCustomObject
$servers = Import-Csv ./servers.csv
$servers[0].Name       # Access a column by header name
$servers[0].CPU        # Type is always [string] -- cast if needed

# Add a calculated column
$report = $servers | Select-Object Name, CPU, Memory,
    @{
        Name       = 'MemoryGB'
        Expression = { [math]::Round([int]$_.Memory / 1024, 1) }
    }

# Export -- -NoTypeInformation suppresses the ugly #TYPE header line
$report | Export-Csv ./server-report.csv -NoTypeInformation

# Append rows to an existing CSV
$newRow | Export-Csv ./server-report.csv -NoTypeInformation -Append
```

The `@{Name='...'; Expression={...}}` pattern is a #strong[calculated property]. You’ll use it constantly. Read it as: "create a new column called X whose value is computed from the current object."

=== JSON
<json>
```powershell
# Read JSON config
$config = Get-Content ./config.json -Raw | ConvertFrom-Json

# Access properties
$config.AppName
$config.Settings.Port

# Modify and write back
$config.Settings.Port = 9090
$config | ConvertTo-Json -Depth 10 | Set-Content ./config.json

# -Depth matters: default is 2. Nested objects beyond depth 2
# get serialized as their type name, not their actual content.
# Always use -Depth 5 or higher for real configs.
```

```powershell
# Convert a hashtable to JSON (useful for API calls)
$payload = @{
    name    = "web01"
    tags    = @("production", "web")
    enabled = $true
}
$payload | ConvertTo-Json
```

=== XML
<xml>
```powershell
# Load an XML file -- the [xml] cast is the simplest way
[xml]$doc = Get-Content ./config.xml

# Navigate with dot-notation (the XmlDocument accelerator makes this natural)
$doc.configuration.appSettings.add

# Modify a node value
$node = $doc.SelectSingleNode("//add[@key='port']")
$node.value = "9090"

# Save back to file
$doc.Save("./config.xml")
```

XML in PowerShell is one of those things that’s either delightful or maddening depending on the schema you’re dealing with. For anything more complex than reading config nodes, reach for `Select-Xml` which gives you XPath support without the `.Save()` foot guns.

#horizontalrule

== File Encoding
<file-encoding>
Encoding is the invisible source of half of all "why does this look broken" file bugs. PowerShell 7 defaults to UTF-8 without BOM everywhere (a massive improvement over PowerShell 5’s UTF-16 defaults). Still worth knowing:

```powershell
# Specify encoding explicitly when writing
Set-Content ./output.txt -Value $data -Encoding UTF8

# Read a file that's actually Latin-1 (legacy systems)
Get-Content ./legacy-export.csv -Encoding Latin1

# UTF-8 with BOM (required by some older tools)
Set-Content ./output.txt -Value $data -Encoding UTF8BOM

# Check what encoding a file uses (heuristic -- not foolproof)
$bytes = [System.IO.File]::ReadAllBytes('./mystery.txt')
$bytes[0..3] | ForEach-Object { '{0:X2}' -f $_ }
# EF BB BF = UTF-8 BOM
# FF FE    = UTF-16 LE BOM
```

When sharing files between Windows and Linux PowerShell: always specify `-Encoding UTF8`. The default is the same on both platforms in PS7, but explicit beats implicit in production scripts.

#horizontalrule

== Practical Pattern: The Deletion Report
<practical-pattern-the-deletion-report>
#blockquote[
Before deleting anything in bulk, generate a report. This pattern – find, report, confirm, delete – will save your job at least once in your career.
]

```powershell
$cutoff   = (Get-Date).AddDays(-30)
$target   = "C:\Logs\old"
$report   = Join-Path $env:TEMP "deletion-report-$(Get-Date -Format yyyyMMdd).csv"

# Find candidates and write report first
Get-ChildItem $target -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object LastWriteTime -lt $cutoff |
    Select-Object FullName, LastWriteTime,
        @{N='SizeMB'; E={[math]::Round($_.Length/1MB, 2)}} |
    Export-Csv $report -NoTypeInformation

Write-Host "Report written to $report"
Write-Host "Found $((Import-Csv $report).Count) files for deletion"
Write-Host "Review the CSV, then run with -Delete to proceed"
```

#horizontalrule

== Exercises
<exercises-8>
=== \[Ch-09, Ex-1\] Simple: Create, Write, Read, Verify
<ch-09-ex-1-simple-create-write-read-verify>
Create a text file in your temp directory. Write a line of content to it. Read it back and verify the content matches what you wrote. Clean up after.

=== \[Ch-09, Ex-2\] Normal: CSV Import, Transform, Export
<ch-09-ex-2-normal-csv-import-transform-export>
Given a CSV of server names with CPU and Memory columns, import it, add a calculated `MemoryGB` column (Memory in MB divided by 1024, rounded to one decimal), and export the result to a new file.

=== \[Ch-09, Ex-3\] Advanced: Stale File Report
<ch-09-ex-3-advanced-stale-file-report>
#blockquote[
]

Recursively search a directory for files older than 30 days. Generate a CSV deletion report including `FullName`, `LastWriteTime`, and `SizeMB`. Do not delete anything – report only.

=== \[Ch-09, Ex-4\] Extreme: JSON Config Manager
<ch-09-ex-4-extreme-json-config-manager>
#blockquote[
]

Build a config file manager that reads a JSON file, validates that required keys are present (`AppName`, `Version`, `Settings.Port`, `Settings.Debug`), allows updating values, and writes the result back with proper depth. Throw a meaningful error if a required key is missing.

#horizontalrule

== Key Takeaways
<key-takeaways-3>
- `Get-Content` returns an array of lines; add `-Raw` when you need a single string.
- `Set-Content` is for data; `Out-File` is for human-readable output. Default encodings differ.
- `Add-Content` appends without reading the whole file into memory.
- `Get-ChildItem -Recurse -Filter *.ext` is how you find files at scale. Add `-ErrorAction SilentlyContinue` in production.
- `Join-Path`, `Split-Path`, and `Test-Path` make path handling portable and safe.
- `Import-Csv` / `Export-Csv` turn tabular data into objects and back. Always use `-NoTypeInformation`.
- `ConvertFrom-Json` / `ConvertTo-Json` work the same way. Use `-Depth 5+` on nested objects.
- `-WhatIf` on destructive operations is not optional in production. Use it.

#horizontalrule

#emph[Next up: #link("10-regex-and-strings.md")[Chapter 10 – Regular Expressions and String Manipulation], where we learn that text is just an object that hasn’t been structured yet.]

= Chapter 10: Error Handling
<chapter-10-error-handling>
#blockquote[
#emph["It’s non-terminating. That means it’s not a real error, right?"] #emph[— Sam, five minutes before the server goes down]
]

#figure([#image("images/ch-10-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== What You’ll Learn
<what-youll-learn-5>
- The difference between terminating and non-terminating errors
- How `$ErrorActionPreference` and `-ErrorAction` control error behavior
- How to use `try`/`catch`/`finally` blocks
- How to inspect errors with `$_`, `$Error`, and `ErrorRecord`
- How to write functions that support `-ErrorAction` and `-ErrorVariable`
- How to signal errors with `Write-Error` vs `throw`
- What `trap` is and why you probably shouldn’t use it

#horizontalrule

== 1. Two Kinds of Errors
<two-kinds-of-errors>
PowerShell has a split personality when it comes to errors. Understanding this is the single most important concept in this chapter.

=== Non-Terminating Errors
<non-terminating-errors>
A #strong[non-terminating error] is PowerShell’s way of saying: "Something went wrong for this item, but I’m going to keep going." The cmdlet reports the problem, the red text appears, and execution continues to the next item in the pipeline.

```powershell
# Non-terminating: errors on individual items, but the pipeline keeps running
Get-Item 'C:\DoesNotExist', 'C:\Windows' -ErrorAction Continue
```

```
Get-Item: Cannot find path 'C:\DoesNotExist' because it does not exist.

    Directory: C:\

Mode                 LastWriteTime         Length Name
----                 -------------         ------
d-r--          3/15/2026  10:22 AM                Windows
```

The first path failed. The second succeeded. The pipeline continued. Sam would call this "fine." Max would not.

=== Terminating Errors
<terminating-errors>
A #strong[terminating error] stops the current scope immediately. The command that generated it stops, and if it’s inside a function, that function stops too. These are the errors that `try`/`catch` can intercept.

```powershell
# Terminating: the whole thing stops
try {
    [int]'not a number'   # throws a terminating parse error
} catch {
    "Caught it: $_"
}
```

```
Caught it: Cannot convert value "not a number" to type "System.Int32".
```

=== Promoting Non-Terminating to Terminating
<promoting-non-terminating-to-terminating>
Here’s the trick that makes `try`/`catch` useful for cmdlets: `-ErrorAction Stop` promotes a non-terminating error into a terminating one.

```powershell
try {
    Get-Item 'C:\DoesNotExist' -ErrorAction Stop
} catch {
    "Caught it: $_"
}
```

Without `-ErrorAction Stop`, the `catch` block would never run. This is the most common mistake beginners make with `try`/`catch` and PowerShell cmdlets.

#horizontalrule

== 2. Controlling Error Behavior
<controlling-error-behavior>
#figure([#image("images/ch-10-error-preference.png")],
  caption: [
    error-preference
  ]
)

=== `$ErrorActionPreference`
<erroractionpreference>
This global variable sets the default behavior for all error-generating cmdlets in the current session.

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Value], [Behavior],
  [`Continue`],
  [Report the error and keep running. #strong[Default.]],
  [`Stop`],
  [Treat all non-terminating errors as terminating.],
  [`SilentlyContinue`],
  [Suppress the error and keep running. No red text.],
  [`Inquire`],
  [Prompt the user for every error. Useful for interactive scripts.],
  [`Ignore`],
  [Suppress the error and don’t record it in `$Error`.],
)
]

```powershell
# Set for the entire session (or script scope)
$ErrorActionPreference = 'Stop'

# Now every cmdlet error terminates
Get-Item 'C:\DoesNotExist'  # throws; no -ErrorAction needed
```

#blockquote[
#strong[Rule of thumb for scripts:] Set `$ErrorActionPreference = 'Stop'` at the top of production scripts. It turns subtle silent failures into loud, catchable errors. Rina came from Python, where exceptions are the default. In PowerShell, you have to opt in. One line at the top is all it takes.
]

=== `-ErrorAction` (Per-Cmdlet Override)
<erroraction-per-cmdlet-override>
`-ErrorAction` (alias: `-EA`) overrides `$ErrorActionPreference` for a single cmdlet call.

```powershell
$ErrorActionPreference = 'Stop'

# This one cmdlet should be allowed to fail silently
$result = Get-Item 'C:\MightNotExist' -ErrorAction SilentlyContinue

if ($null -eq $result) {
    Write-Host "File not found, using defaults."
}
```

This pattern – script-wide `Stop` with selective `SilentlyContinue` – is the professional approach. You get loud failures by default and explicit opt-out for the cases you’ve consciously decided to ignore.

#horizontalrule

== 3. `try` / `catch` / `finally`
<try-catch-finally>
The classic structure. If you’ve written Python or C\#, this is familiar. The PowerShell flavor has a few twists.

```powershell
try {
    # Code that might fail
    $value = [int]'abc'
}
catch {
    # Runs if a terminating error occurs in the try block
    Write-Host "Something went wrong: $_"
}
finally {
    # Runs no matter what -- error or no error
    Write-Host "Cleanup runs here."
}
```

```
Something went wrong: Cannot convert value "abc" to type "System.Int32".
Cleanup runs here.
```

=== The `$_` Variable in `catch`
<the-_-variable-in-catch>
Inside a `catch` block, `$_` is automatically bound to the `ErrorRecord` object – the full structured description of what went wrong. Calling `"$_"` converts it to a string (the error message). But you have access to the whole object.

```powershell
try {
    Get-Item 'C:\NoSuchFile' -ErrorAction Stop
}
catch {
    Write-Host "Message:   $($_.Exception.Message)"
    Write-Host "Category:  $($_.CategoryInfo.Category)"
    Write-Host "Script:    $($_.InvocationInfo.ScriptName)"
    Write-Host "Line:      $($_.InvocationInfo.ScriptLineNumber)"
}
```

```
Message:   Cannot find path 'C:\NoSuchFile' because it does not exist.
Category:  ObjectNotFound
Script:
Line:      2
```

=== Catching Specific Exception Types
<catching-specific-exception-types>
You can have multiple `catch` blocks, each targeting a different .NET exception type. PowerShell walks them in order and runs the first match.

```powershell
try {
    Get-Content 'C:\Secret\File.txt' -ErrorAction Stop
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "File not found. Check the path."
}
catch [System.UnauthorizedAccessException] {
    Write-Host "Access denied. Try running as Administrator."
}
catch {
    Write-Host "Unexpected error: $_"
}
```

The unqualified `catch` at the end is the catch-all. Always put it last.

#blockquote[
How do you know what exception type was thrown? Check `$_.Exception.GetType().FullName` in the catch block. That’s your answer every time.
]

```powershell
try {
    Get-Content 'C:\NoSuchFile' -ErrorAction Stop
}
catch {
    $_.Exception.GetType().FullName
    # System.Management.Automation.ItemNotFoundException
}
```

=== `finally`: The Cleanup Guarantee
<finally-the-cleanup-guarantee>
`finally` runs regardless of success or failure. It’s the right place for cleanup that must happen: closing file handles, removing temp files, resetting state.

```powershell
$stream = $null
try {
    $stream = [System.IO.File]::OpenRead('C:\data.bin')
    # ... process the stream
}
catch {
    Write-Error "Failed to read file: $_"
}
finally {
    if ($null -ne $stream) {
        $stream.Dispose()
    }
}
```

Even if `OpenRead` throws, `finally` runs and the stream is disposed. No resource leak.

#horizontalrule

== 4. The `$Error` Automatic Variable
<the-error-automatic-variable>
PowerShell maintains a global list of the last errors in `$Error`. It’s a fixed-size circular buffer – by default, the 256 most recent errors.

```powershell
# Clear the history (useful at the start of a script)
$Error.Clear()

# Trigger a couple of errors
Get-Item 'C:\NoSuchA' -ErrorAction SilentlyContinue
Get-Item 'C:\NoSuchB' -ErrorAction SilentlyContinue

# Most recent error is $Error[0]
$Error[0].Exception.Message    # Cannot find path 'C:\NoSuchB'...
$Error[1].Exception.Message    # Cannot find path 'C:\NoSuchA'...

# Count of errors since last clear
$Error.Count                   # 2
```

#figure([#image("images/ch-10-error-variable.png")],
  caption: [
    error-variable
  ]
)

`$Error` is useful for post-hoc debugging – checking what went wrong after a block ran with `SilentlyContinue`. It’s not a substitute for proper error handling, but it’s valuable in interactive sessions and diagnostic scripts.

#horizontalrule

== 5. `-ErrorVariable`: Capture Per-Command
<errorvariable-capture-per-command>
If you want to capture errors from a specific cmdlet without changing `$ErrorActionPreference`, use `-ErrorVariable`.

```powershell
# Capture errors into $myErrors (note: no $ in the parameter value)
Get-Item 'C:\NoSuchA', 'C:\Windows' -ErrorAction SilentlyContinue -ErrorVariable myErrors

Write-Host "Errors captured: $($myErrors.Count)"
Write-Host "First error: $($myErrors[0].Exception.Message)"
```

```
Errors captured: 1
First error: Cannot find path 'C:\NoSuchA' because it does not exist.
```

Key rules for `-ErrorVariable`: - Pass the variable #strong[name without the `$`] sign - Prefix with `+` to #strong[append] rather than replace: `-ErrorVariable +myErrors` - The variable is populated even with `-ErrorAction SilentlyContinue`

#horizontalrule

== 6. `Write-Error` vs `throw`
<write-error-vs-throw>
These both signal errors, but they behave very differently.

=== `Write-Error`
<write-error>
`Write-Error` generates a #strong[non-terminating error]. Execution continues after it. It’s the right tool for functions that should follow the same contract as built-in cmdlets.

```powershell
function Get-SafeFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return
    }
    Get-Content $Path
}

# Caller can decide what to do with the error
Get-SafeFile -Path 'C:\NoSuchFile' -ErrorAction SilentlyContinue
Get-SafeFile -Path 'C:\NoSuchFile' -ErrorAction Stop    # now terminating
```

The function respects `-ErrorAction` because `Write-Error` is a cmdlet that honors `$ErrorActionPreference`. This is what makes it the professional choice for `[CmdletBinding()]` functions.

=== `throw`
<throw>
`throw` generates a #strong[terminating error] immediately. Execution stops. It cannot be silenced with `-ErrorAction`.

```powershell
function Assert-ValidPort {
    param([int]$Port)
    if ($Port -lt 1 -or $Port -gt 65535) {
        throw "Invalid port number: $Port. Must be 1-65535."
    }
    $Port
}

try {
    Assert-ValidPort -Port 99999
}
catch {
    Write-Host "Validation failed: $_"
}
```

```
Validation failed: Invalid port number: 99999. Must be 1-65535.
```

Use `throw` when the error is genuinely unrecoverable in the current context – invalid input that would corrupt the operation, a prerequisite that simply isn’t met, a contract violation.

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [], [`Write-Error`], [`throw`],
  [#strong[Error type]],
  [Non-terminating (by default)],
  [Terminating],
  [#strong[Respects `-ErrorAction`]],
  [Yes],
  [No],
  [#strong[Caller can suppress]],
  [With `SilentlyContinue`],
  [Only with `try`/`catch`],
  [#strong[Use for]],
  [Cmdlet-style functions],
  [Fatal conditions, validation],
)
]

#horizontalrule

== 7. The `ErrorRecord` Object
<the-errorrecord-object>
When an error occurs, PowerShell wraps the exception in an `ErrorRecord`. This is what lives in `$Error[0]` and `$_` inside `catch`. Understanding its structure helps you write useful error messages and diagnostic logs.

```powershell
try {
    1 / 0
}
catch {
    $record = $_

    # The .NET exception that caused this
    $record.Exception.Message
    $record.Exception.GetType().FullName

    # Category information
    $record.CategoryInfo.Category
    $record.CategoryInfo.TargetName

    # Where the error happened
    $record.InvocationInfo.ScriptName
    $record.InvocationInfo.ScriptLineNumber
    $record.InvocationInfo.Line

    # A friendly one-liner
    $record.ToString()
}
```

```
Attempted to divide by zero.
System.DivideByZeroException
NotSpecified

<line contents here>
```

#horizontalrule

== 8. `trap`: The Legacy Approach
<trap-the-legacy-approach>
Before `try`/`catch`, PowerShell had `trap`. You’ll find it in old scripts. You do not need to write new code with it.

```powershell
# Legacy style -- don't do this in new scripts
trap {
    Write-Host "Trapped: $_"
    continue   # or 'break' to propagate
}

1 / 0          # trap fires
Write-Host "Execution continued"
```

`trap` is a statement-level error handler that applies to the entire scope. It’s harder to reason about than `try`/`catch` and mixes control flow in confusing ways. The only reason to know it: you will encounter it in scripts written before 2012.

#horizontalrule

== Boss Level
<boss-level-2>
#blockquote[
#strong[Build a retry wrapper function] that executes a given scriptblock up to N times with exponential back-off between attempts. It should: - Accept a scriptblock, a `MaxAttempts` count, and a `BaseDelayMs` - Catch all terminating errors and retry - On final failure, re-throw the last error as a terminating error - Log each attempt with timestamp, attempt number, and error message - Support `-Verbose` output for each retry
]

```powershell
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [ValidateRange(1, 10)]
        [int]$MaxAttempts = 3,

        [int]$BaseDelayMs = 500
    )

    $attempt    = 0
    $lastError  = $null

    while ($attempt -lt $MaxAttempts) {
        $attempt++
        try {
            Write-Verbose "[$(Get-Date -Format 'HH:mm:ss.fff')] Attempt $attempt of $MaxAttempts"
            $result = & $ScriptBlock
            Write-Verbose "[$(Get-Date -Format 'HH:mm:ss.fff')] Succeeded on attempt $attempt"
            return $result
        }
        catch {
            $lastError = $_
            $delay     = $BaseDelayMs * [math]::Pow(2, $attempt - 1)
            Write-Verbose "[$(Get-Date -Format 'HH:mm:ss.fff')] Attempt $attempt failed: $($_.Exception.Message)"

            if ($attempt -lt $MaxAttempts) {
                Write-Verbose "[$(Get-Date -Format 'HH:mm:ss.fff')] Waiting ${delay}ms before retry..."
                Start-Sleep -Milliseconds $delay
            }
        }
    }

    # All attempts exhausted -- re-throw the last error
    throw $lastError
}

# Usage
try {
    $i = 0
    Invoke-WithRetry -MaxAttempts 4 -BaseDelayMs 100 -Verbose -ScriptBlock {
        $i++
        if ($i -lt 4) { throw "Simulated transient failure (attempt $i)" }
        "Success on attempt $i"
    }
}
catch {
    Write-Host "All retries exhausted: $_" -ForegroundColor Red
}
```

#horizontalrule

== Exercises
<exercises-9>
=== \[Ch-10, Ex-1\] Simple: Catch a Divide-by-Zero
<ch-10-ex-1-simple-catch-a-divide-by-zero>
Write a `try`/`catch` block that attempts to divide 1 by 0 and catches the error. Print `"caught"` if the error is caught.

```powershell
$result = try { 1 / 0 } catch { 'caught' }
$result
```

=== \[Ch-10, Ex-2\] Normal: Handle Specific Exception Types
<ch-10-ex-2-normal-handle-specific-exception-types>
Write a function `Test-SpecificCatch` that takes a `[string]$Path` parameter and tries to read the file with `Get-Content -ErrorAction Stop`. Catch `[System.Management.Automation.ItemNotFoundException]` and return `'NotFound'`. Catch everything else and return `'OtherError'`.

#blockquote[
]

=== \[Ch-10, Ex-3\] Advanced: Cmdlet-Style Error Handling
<ch-10-ex-3-advanced-cmdlet-style-error-handling>
#blockquote[
Build a function `Get-SafeContent` with `[CmdletBinding()]` that accepts a mandatory `[string]$Path`. If the path does not exist, use `Write-Error` to report the problem and return `$null`. Otherwise return `Get-Content $Path`.

Verify the function correctly populates `-ErrorVariable` when the file is missing and `-ErrorAction SilentlyContinue` is used.
]

=== \[Ch-10, Ex-4\] Extreme: Structured Error Logger
<ch-10-ex-4-extreme-structured-error-logger>
#blockquote[
Build a function `Write-ErrorLog` that accepts an `[ErrorRecord]` and a `[string]$LogPath`, then appends a JSON entry to the log file containing: `Timestamp`, `Message`, `Category`, `Script`, and `Line`.

Call it from a `catch` block after a deliberate error and verify the log file contains valid JSON with the correct fields.
]

#horizontalrule

== Summary
<summary-4>
PowerShell’s error handling model rewards the people who actually read the manual. Non-terminating errors keep going until you tell them to stop. Terminating errors can be caught – but only if you know they’re terminating. `$ErrorActionPreference = 'Stop'` is the cheat code that makes the whole system behave the way you’d expect coming from any other language.

The hierarchy: `throw` for fatal conditions, `Write-Error` for cmdlet-style functions, `-ErrorAction Stop` to make cmdlets catchable, `try`/`catch`/`finally` for structured recovery, and `$Error`/`-ErrorVariable` for diagnostics.

Max has one rule: every script that touches production has `$ErrorActionPreference = 'Stop'` on line one. He’s been burned enough times by silent failures to have that rule tattooed on his brain. Now you know why.

#horizontalrule

#emph[Next: #link("11-functions-and-modules.md")[Chapter 11 – Functions and Modules]]

= Chapter 11: Regex and Text Processing
<chapter-11-regex-and-text-processing>
Sam is on line 347 of a log file. He’s using `IndexOf`. This chapter is for Sam.

#figure([#image("images/ch-11-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== Why Regex Exists and Why You Will Use It
<why-regex-exists-and-why-you-will-use-it>
Every sysadmin eventually reaches the point where log files, config data, or API responses arrive in a format that is "almost structured." Timestamps in slightly different positions. IPs buried in prose. Severity words sprinkled between other words. You could split on spaces and count fields – and you will, the first time. The second time you’ll reach for regex.

Regular expressions are a pattern language for text. They don’t replace good data structures; they’re the tool you use to extract them from chaos. PowerShell bakes regex into the language itself via the `-match` and `-replace` operators, making common tasks a single expression rather than a function call.

#figure([#image("images/ch-11-mental-model.png")],
  caption: [
    regex-mental-model
  ]
)

#horizontalrule

== The `-match` Operator and `$Matches`
<the--match-operator-and-matches>
`-match` tests whether a string contains a pattern. It returns `$true` or `$false`, and as a side effect it populates `$Matches`, an automatic variable that holds the matched text and any capture groups.

```powershell
# Basic match -- does the string contain this pattern?
'PowerShell 7.4.1' -match '\d+\.\d+'
# True

# After a successful match, $Matches is populated
$Matches[0]
# 7.4

# $Matches[0] is always the full match
# $Matches[1], [2], ... are numbered capture groups
'2024-01-15' -match '(\d{4})-(\d{2})-(\d{2})'
$Matches[0]   # 2024-01-15
$Matches[1]   # 2024
$Matches[2]   # 01
$Matches[3]   # 15
```

A few things worth burning into memory:

- `-match` is #strong[case-insensitive by default]. Use `-cmatch` for case-sensitive matching.
- `$Matches` is only valid #strong[after the most recent `-match`] in the current scope. It gets overwritten on every call.
- `-match` tests for #strong[containment], not full-string equality. The pattern `'\d+'` matches `'abc123def'` because the digits appear somewhere in it. Anchor with `^` and `$` when you need full-string validation.

```powershell
# Case-insensitive (default)
'ERROR' -match 'error'   # True

# Case-sensitive
'ERROR' -cmatch 'error'  # False

# Anchored full-string match
'192.168.1.1' -match '^\d{1,3}(\.\d{1,3}){3}$'  # True
'not an IP'   -match '^\d{1,3}(\.\d{1,3}){3}$'  # False
```

#horizontalrule

== Named Capture Groups
<named-capture-groups>
Numbered groups (`$Matches[1]`, `$Matches[2]`) work fine until you have six of them and can’t remember which index is which. Named captures solve that.

```powershell
# Syntax: (?<name>pattern)
$line = '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout'

$line -match '(?<date>\d{4}-\d{2}-\d{2})\s(?<time>\d{2}:\d{2}:\d{2})\s(?<level>\w+)\s\[(?<source>\w+)\]'

$Matches.date    # 2024-01-15
$Matches.time    # 14:30:22
$Matches.level   # ERROR
$Matches.source  # WebServer
```

Named groups appear in `$Matches` by their name as well as by number. You can mix named and unnamed groups in the same pattern, though it’s rarely a good idea for readability.

```powershell
# Practical: parse an Apache-style access log entry
$entry = '192.168.1.50 - admin [15/Jan/2024:14:30:22] "GET /api/status HTTP/1.1" 200 1042'

$entry -match '(?<ip>[\d.]+)\s+-\s+(?<user>\S+)\s+\[(?<ts>[^\]]+)\]\s+"(?<method>\w+)\s+(?<path>\S+)'

$Matches.ip     # 192.168.1.50
$Matches.user   # admin
$Matches.method # GET
$Matches.path   # /api/status
```

#horizontalrule

== The `-replace` Operator
<the--replace-operator>
`-replace` substitutes matches with replacement text. The replacement string can reference capture groups using `$1`, `$2`, or `${name}` syntax.

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

Note the escaped `\$` in the last example. In regex, `$` anchors to end-of-line. To match a literal dollar sign, escape it with `\`. Inside the replacement string, `$` introduces back-references – which is why you’ll sometimes see `$$` to produce a literal `$` in output.

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

When you apply a string operator like `-replace` or `-match` to an array, PowerShell runs it against each element and returns a new array. This is not magic – it’s the same scalar operator applied via pipeline semantics.

#horizontalrule

== `-split` with Regex
<split-with-regex>
You know `-split` from basic string work. Fed a regex pattern, it becomes a proper tokenizer.

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

The last example uses a #strong[zero-width lookahead] – `(?=[A-Z])` matches the position immediately before an uppercase letter without consuming it. The split happens at the boundary without removing any characters.

#horizontalrule

== `Select-String`: Grep for PowerShell
<select-string-grep-for-powershell>
`Select-String` searches files or strings for pattern matches and returns `MatchInfo` objects – not just lines, but structured result objects with file, line number, and match context.

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

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Property], [Content],
  [`Filename`],
  [Name of the file],
  [`LineNumber`],
  [Line number of the match],
  [`Line`],
  [Full text of the matched line],
  [`Matches`],
  [Collection of `[System.Text.RegularExpressions.Match]` objects],
  [`Context`],
  [Lines before/after (when `-Context` is specified)],
)
]

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

#horizontalrule

== The `[regex]` Class
<the-regex-class>
For repeated use of the same pattern – or for operations that operators don’t expose directly – compile the pattern with the `[regex]` type accelerator.

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

The scriptblock replacement form is only available on the `[regex]` class, not on the `-replace` operator. Use it when your replacement logic depends on the matched content in a non-trivial way.

#horizontalrule

== Lookahead and Lookbehind
<lookahead-and-lookbehind>
Zero-width assertions match positions in the string without consuming characters. They let you write patterns that say "this pattern, but only when it’s followed by / preceded by something else."

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

Lookaheads and lookbehinds are the difference between "replace a number" and "replace a number that appears in a specific context." They’re worth learning even if you only use them occasionally – the patterns that require them have no clean alternative.

#horizontalrule

== Common Patterns Reference
<common-patterns-reference>
These patterns cover 80% of real-world text extraction work.

#figure([#image("images/ch-11-patterns.png")],
  caption: [
    common-patterns
  ]
)

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

#horizontalrule

== Practical Pattern: Log Classifier
<practical-pattern-log-classifier>
Here’s the shape of a real-world log analysis script, putting everything together.

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

#horizontalrule

== Exercises
<exercises-10>
=== \[Ch-11, Ex-1\] Simple: Validate Email Addresses with `-match`
<ch-11-ex-1-simple-validate-email-addresses-with--match>
Write a validation check using `-match` that returns `$true` for a valid email address and `$false` for an invalid one. Test at least one valid and one invalid case.

=== \[Ch-11, Ex-2\] Normal: Extract IPs from Log Lines
<ch-11-ex-2-normal-extract-ips-from-log-lines>
Given an array of log lines (some containing IP addresses, some not), use `-match` and `$Matches` to extract every IP address found. Return only the lines that contained an IP.

=== \[Ch-11, Ex-3\] Advanced: Named Captures on Structured Log Lines
<ch-11-ex-3-advanced-named-captures-on-structured-log-lines>
#blockquote[
]

Parse a structured log line using named capture groups to extract the date, time, severity level, and source component into separate properties on a `PSCustomObject`.

=== \[Ch-11, Ex-4\] Extreme: Multi-Pattern Log Analyzer
<ch-11-ex-4-extreme-multi-pattern-log-analyzer>
#blockquote[
]

Given an array of log lines with mixed severity levels (`FATAL`, `CRITICAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`), classify each line into a `Severity` category (`Critical`, `Error`, `Warning`, `Info`, `Debug`) using a cascading `-match` strategy. Return structured objects with both the original line and the assigned severity.

#horizontalrule

== Key Takeaways
<key-takeaways-4>
- `-match` tests containment; anchor with `^` and `$` for full-string validation.
- `$Matches[0]` is always the full match; `$Matches[1]` onward are capture groups.
- Named captures (`(?<name>pattern)`) turn `$Matches.name` into self-documenting code.
- `-replace` supports back-references (`$1`, `${name}`) in the replacement string.
- `-match` and `-replace` are vectorized: apply them to an array and they run per element.
- `Select-String` returns `MatchInfo` objects with file, line number, and match context – not raw strings.
- `[regex]` compiles patterns for reuse and unlocks scriptblock replacements and `Matches()` (all matches, not just first).
- Lookaheads/lookbehinds match positions without consuming characters – use them for context-sensitive substitution.
- Regex validates shape, not semantics. `999.999.999.999` passes most IP patterns. Validate ranges separately.

#horizontalrule

#emph[Next up: #link("12-error-handling.md")[Chapter 12 – Error Handling and Debugging], where we learn that errors are objects too, and `$Error[0]` is your new best friend.]

= Chapter 12: Modules and Packages
<chapter-12-modules-and-packages>
Max has a module from 2018. This is Sam’s problem now.

#figure([#image("images/ch-12-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== What Is a Module?
<what-is-a-module>
A #strong[module] is a self-contained package of PowerShell functionality: functions, variables, aliases, and cmdlets bundled together so you can load them once and use them everywhere. The moment your `functions.ps1` gets dot-sourced in more than two scripts, it’s time to turn it into a module.

PowerShell ships with modules. Your session already has some loaded. The PowerShell Gallery hosts thousands more. And you can write your own in about ten minutes – with a manifest that doesn’t shame you in front of Rina.

Here’s the mental map:

#figure([#image("images/ch-12-module-types.png")],
  caption: [
    module-types
  ]
)

#horizontalrule

== Exploring Loaded Modules
<exploring-loaded-modules>
=== Get-Module
<get-module>
`Get-Module` shows you what’s currently loaded in your session and what’s available to load.

```powershell
# What's loaded right now?
Get-Module

# What's available on disk (not yet loaded)?
Get-Module -ListAvailable

# Find a specific module by name (wildcard supported)
Get-Module -ListAvailable -Name 'Microsoft.PowerShell.*'

# Look at a loaded module's exported commands
Get-Module Microsoft.PowerShell.Utility | Select-Object -ExpandProperty ExportedFunctions
```

The difference between `Get-Module` and `Get-Module -ListAvailable` is the difference between "what’s in memory right now" and "what’s on the PSModulePath disk search path." You’ll use `-ListAvailable` far more often in practice.

=== \$env:PSModulePath
<envpsmodulepath>
This environment variable is the colon-separated (Linux/macOS) or semicolon-separated (Windows) list of directories where PowerShell looks for modules.

```powershell
# View the module search path
$env:PSModulePath -split [System.IO.Path]::PathSeparator

# Typical Windows output:
# C:\Users\sam\Documents\PowerShell\Modules
# C:\Program Files\PowerShell\Modules
# C:\Program Files\PowerShell\7\Modules

# Add a custom directory for the current session
$env:PSModulePath += [System.IO.Path]::PathSeparator + 'C:\MyModules'
```

Any directory on `PSModulePath` that contains a subfolder named after a module (e.g., `MyModule/MyModule.psm1` or `MyModule/MyModule.psd1`) will be auto-discovered by `Get-Module -ListAvailable` and auto-imported on first use in PowerShell 3+.

The user-scoped modules folder (`~/Documents/PowerShell/Modules` on Windows, `~/.local/share/powershell/Modules` on Linux) is where `Install-Module` puts things by default and where your own modules should live during development.

#horizontalrule

== Loading and Unloading Modules
<loading-and-unloading-modules>
=== Import-Module
<import-module>
```powershell
# Load a module by name (searches PSModulePath)
Import-Module Pester

# Load from an explicit path (useful during development)
Import-Module ./MyModule/MyModule.psm1

# Force re-import (picks up changes to the .psm1 file)
Import-Module ./MyModule -Force

# Load a specific version
Import-Module Pester -RequiredVersion 5.6.1

# Import and suppress the "already imported" noise
Import-Module Pester -ErrorAction SilentlyContinue
```

The `-Force` flag is your best friend during module development. Without it, `Import-Module` is a no-op if the module is already in memory – meaning your code changes don’t take effect. Always use `-Force` when iterating.

=== Remove-Module
<remove-module>
```powershell
# Unload a module from the current session
Remove-Module Pester

# Unload by pipeline
Get-Module | Where-Object Name -like 'My*' | Remove-Module

# Force-remove (even if other modules depend on it)
Remove-Module Pester -Force
```

`Remove-Module` doesn’t delete files – it only removes the module from the current session’s memory. The files on disk are untouched. This matters in tests and development workflows where you want a clean slate without restarting the shell.

#horizontalrule

== The PowerShell Gallery
<the-powershell-gallery>
PSGallery is the official public repository for PowerShell modules, scripts, and DSC resources. It’s backed by NuGet and maintained by Microsoft.

#figure([#image("images/ch-12-gallery-flow.png")],
  caption: [
    gallery-flow
  ]
)

=== Finding Modules
<finding-modules>
```powershell
# Search for modules by keyword
Find-Module -Name '*aws*'
Find-Module -Tag 'Azure'
Find-Module -Name 'PSReadLine' -Repository PSGallery

# See all versions of a module
Find-Module -Name Pester -AllVersions

# Find modules matching a keyword in description
Find-Module -Filter 'DNS management'
```

=== Installing Modules
<installing-modules>
```powershell
# Install for the current user only (no admin required)
Install-Module -Name PSReadLine -Scope CurrentUser

# Install a specific version
Install-Module -Name Pester -RequiredVersion 5.6.1 -Scope CurrentUser

# Install and trust PSGallery without prompting (useful in scripts)
Install-Module -Name ImportExcel -Scope CurrentUser -Force

# Update an installed module to the latest version
Update-Module -Name PSReadLine

# Remove an installed module from disk
Uninstall-Module -Name OldModule
```

The `-Scope CurrentUser` flag installs into your user-scoped modules directory and requires no elevation. `-Scope AllUsers` installs system-wide but needs admin rights. Use `CurrentUser` by default – it’s safer, reversible, and doesn’t require a UAC prompt.

=== Checking Gallery Trust
<checking-gallery-trust>
The first time you install from PSGallery, PowerShell asks you to confirm you trust the repository. In automated pipelines, pre-trust it explicitly:

```powershell
# Register the gallery as trusted (run once, or in pipeline setup)
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Verify
Get-PSRepository
```

#horizontalrule

== Script Modules (.psm1)
<script-modules-.psm1>
A script module is a `.psm1` file. That’s it. Any `.ps1` file renamed to `.psm1` is technically a script module. The difference is what you #emph[choose to export].

=== A Minimal Module
<a-minimal-module>
```powershell
# File: MyGreeter/MyGreeter.psm1

function Get-Greeting {
    param([string]$Name = 'World')
    "Hello, $Name!"
}

function Get-Farewell {
    param([string]$Name = 'World')
    "Goodbye, $Name!"
}

# Private helper -- NOT exported
function _FormatName {
    param([string]$Name)
    $Name.Trim().ToTitleCase()
}

# Explicitly export only the public functions
Export-ModuleMember -Function Get-Greeting, Get-Farewell
```

Save this as `~/Documents/PowerShell/Modules/MyGreeter/MyGreeter.psm1` and PowerShell will find it automatically:

```powershell
Import-Module MyGreeter
Get-Greeting -Name 'Rina'   # Hello, Rina!
Get-Farewell -Name 'Sam'    # Goodbye, Sam!
_FormatName -Name 'test'    # Error: not recognized (private)
```

=== Export-ModuleMember
<export-modulemember>
`Export-ModuleMember` controls the public API surface of your module. Without it, #strong[all functions defined at module scope are exported by default] – which is rarely what you want.

```powershell
# Export specific functions
Export-ModuleMember -Function Get-Greeting, Get-Farewell

# Export functions matching a pattern
Export-ModuleMember -Function 'Get-*', 'Set-*'

# Export functions AND aliases AND variables
Export-ModuleMember -Function Get-Greeting -Alias greet -Variable ModuleVersion

# Export nothing (lock down the entire module -- useful for modules that
# only operate via side effects or dot-sourcing)
Export-ModuleMember -Function @()
```

The best practice: always call `Export-ModuleMember` explicitly at the bottom of your `.psm1`. It serves as documentation and prevents accidental leakage of internal helpers.

#horizontalrule

== Module Manifests (.psd1)
<module-manifests-.psd1>
A manifest is a PowerShell data file (hashtable syntax) that describes your module. It’s the difference between "a file Max wrote in 2018" and "a proper versioned package."

#figure([#image("images/ch-12-manifest-anatomy.png")],
  caption: [
    manifest-anatomy
  ]
)

=== Creating a Manifest
<creating-a-manifest>
Never write a manifest by hand. Use `New-ModuleManifest`:

```powershell
New-ModuleManifest -Path ./MyGreeter/MyGreeter.psd1 `
    -RootModule        'MyGreeter.psm1' `
    -ModuleVersion     '1.0.0' `
    -Author            'Rina DevOps' `
    -Description       'Greeting utilities for the team portal' `
    -PowerShellVersion '7.4' `
    -FunctionsToExport @('Get-Greeting', 'Get-Farewell') `
    -Tags              @('utility', 'greeting')
```

This creates a fully-commented `.psd1` you can open and edit. Most fields are optional, but these are the ones you should always fill in:

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Field], [Why it matters],
  [`ModuleVersion`],
  [Enables side-by-side installs and `RequiredVersion` pinning],
  [`RootModule`],
  [Points to your `.psm1` – without this, the manifest does nothing],
  [`FunctionsToExport`],
  [Defines the public API for tab-completion and discovery],
  [`PowerShellVersion`],
  [Guards against running on incompatible PS versions],
  [`Description`],
  [Required for PSGallery; shows up in `Find-Module` results],
)
]

=== Validating a Manifest
<validating-a-manifest>
```powershell
# Test-ModuleManifest returns a ModuleInfo object or throws on error
$info = Test-ModuleManifest ./MyGreeter/MyGreeter.psd1

$info.Name            # MyGreeter
$info.Version         # 1.0.0
$info.Author          # Rina DevOps
$info.ExportedFunctions.Keys  # Get-Greeting, Get-Farewell
```

Run `Test-ModuleManifest` in your CI pipeline. It catches common mistakes – missing `.psm1` file, malformed version strings, undefined functions in `FunctionsToExport` – before they blow up in production.

#horizontalrule

== Module Versioning
<module-versioning>
PowerShell supports multiple installed versions of the same module side-by-side. The directory structure encodes the version:

```
~/Documents/PowerShell/Modules/
└── MyGreeter/
    ├── 1.0.0/
    │   ├── MyGreeter.psm1
    │   └── MyGreeter.psd1
    └── 2.0.0/
        ├── MyGreeter.psm1
        └── MyGreeter.psd1
```

```powershell
# Load a specific version
Import-Module MyGreeter -RequiredVersion 1.0.0

# Load the newest available version (default behavior)
Import-Module MyGreeter

# See all installed versions
Get-Module -ListAvailable MyGreeter | Select-Object Name, Version, Path
```

SemVer convention for PowerShell modules:

- #strong[MAJOR] version: breaking changes (cmdlet renamed, parameter removed)
- #strong[MINOR] version: new functions added (backward compatible)
- #strong[PATCH] version: bug fixes (no API changes)

#horizontalrule

== The \#Requires Statement
<the-requires-statement>
`#Requires` is a preprocessor guard that runs before any code in your script or module. If the requirements aren’t met, the script refuses to execute.

```powershell
# Minimum PowerShell version
#Requires -Version 7.4

# Specific modules must be installed
#Requires -Modules Pester
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

# Must run as Administrator (Windows only)
#Requires -RunAsAdministrator

# Multiple requirements (one per line or comma-separated modules)
#Requires -Version 7.2
#Requires -Modules @{ ModuleName = 'Az.Accounts'; ModuleVersion = '2.0' }
```

`#Requires` must appear at the top of the file, before any code. It’s not a comment – PowerShell parses it specially. If the requirement fails, you get a clear, actionable error message rather than a cryptic runtime failure three functions deep.

Use `#Requires` in: - Any script that depends on non-default modules - Any script that needs elevation - Any module that requires a specific PS version for a language feature

#horizontalrule

== Practical Pattern: The Team Utilities Module
<practical-pattern-the-team-utilities-module>
Here’s a realistic module structure for a small team:

```
TeamUtils/
├── TeamUtils.psd1          # Manifest
├── TeamUtils.psm1          # Entry point (dot-sources the public files)
├── Public/
│   ├── Get-ServerHealth.ps1
│   ├── Send-AlertEmail.ps1
│   └── Invoke-Deployment.ps1
└── Private/
    ├── _ValidateServerName.ps1
    └── _BuildEmailBody.ps1
```

```powershell
# TeamUtils.psm1 -- loads all public and private functions
$Public  = Get-ChildItem (Join-Path $PSScriptRoot 'Public')  -Filter *.ps1
$Private = Get-ChildItem (Join-Path $PSScriptRoot 'Private') -Filter *.ps1

foreach ($file in $Private) { . $file.FullName }
foreach ($file in $Public)  { . $file.FullName }

Export-ModuleMember -Function ($Public.BaseName)
```

This pattern scales cleanly: add a file to `Public/` and it’s automatically exported. Add a file to `Private/` and it stays internal. No manual list to keep in sync.

```powershell
# TeamUtils.psd1 (generated by New-ModuleManifest, key fields shown)
@{
    RootModule        = 'TeamUtils.psm1'
    ModuleVersion     = '1.3.0'
    Author            = 'Rina DevOps'
    Description       = 'Internal team automation utilities'
    PowerShellVersion = '7.4'
    FunctionsToExport = @('Get-ServerHealth', 'Send-AlertEmail', 'Invoke-Deployment')
}
```

#horizontalrule

== Exercises
<exercises-11>
=== \[Ch-12, Ex-1\] Simple: Explore Loaded and Available Modules
<ch-12-ex-1-simple-explore-loaded-and-available-modules>
List all modules currently loaded in your session. Then list all modules available via `Get-Module -ListAvailable`. Find one module whose source path looks like it came from PSGallery (hint: look for the user modules directory in its `Path` property). Show its name and version.

=== \[Ch-12, Ex-2\] Normal: Create a Script Module with Three Exported Functions
<ch-12-ex-2-normal-create-a-script-module-with-three-exported-functions>
Create a script module called `TimeUtils` in a temp directory. The module should export exactly three functions:

- `Get-Greeting` – returns `"Hello, <name>!"`
- `Get-Farewell` – returns `"Goodbye, <name>!"`
- `Get-TimeOfDay` – returns `"Morning"`, `"Afternoon"`, or `"Evening"` based on the current hour (before 12, before 17, otherwise)

Use `Export-ModuleMember` explicitly. Import it with `-Force`, verify that all three functions work, and that calling a non-exported private helper throws a "not recognized" error.

=== \[Ch-12, Ex-3\] Advanced: Create a Module with a .psd1 Manifest
<ch-12-ex-3-advanced-create-a-module-with-a-.psd1-manifest>
Extend the `TimeUtils` exercise by adding a `.psd1` manifest. Use `New-ModuleManifest` with at minimum: `RootModule`, `ModuleVersion` (`1.0.0`), `Author`, and `FunctionsToExport`. Validate the manifest with `Test-ModuleManifest` and confirm the returned object has the correct `Version` and `Author` values.

=== \[Ch-12, Ex-4\] Extreme: Public/Private Module with Pester Tests
<ch-12-ex-4-extreme-publicprivate-module-with-pester-tests>
Build a module called `DataUtils` with a clear public/private separation:

- #strong[Private helper:] `_ValidateInput` – returns `$true` if the string is non-null and non-whitespace, `$false` otherwise. Not exported.
- #strong[Public function:] `Get-ProcessedData` – accepts a mandatory `[string]$Data` parameter, calls `_ValidateInput` internally, throws `"Invalid input"` if validation fails, and returns the trimmed, uppercased string if valid.
- Verify via Pester that `Get-ProcessedData -Data '  hello  '` returns `'HELLO'`.
- Verify that `_ValidateInput` is #emph[not] accessible from outside the module (the `Get-Command _ValidateInput` call should throw).

#horizontalrule

== Key Takeaways
<key-takeaways-5>
- `Get-Module` shows what’s loaded; `Get-Module -ListAvailable` shows what’s on `$env:PSModulePath`. Know the difference.
- `Import-Module -Force` is mandatory during development. Without it, your edits don’t take effect.
- `Export-ModuleMember` is not optional – call it explicitly to define your public API and keep private helpers private.
- A `.psd1` manifest adds versioning, dependency declarations, and discoverability. Write one for every module you share.
- Use `New-ModuleManifest` to generate the manifest. Use `Test-ModuleManifest` to validate it in CI.
- PSGallery is the public module registry. `Find-Module` / `Install-Module` / `Update-Module` are your interface to it. Use `-Scope CurrentUser` unless you specifically need system-wide installation.
- `#Requires` runs before your code. Use it to gate on PS version, required modules, and admin rights.
- The Public/Private folder pattern scales cleanly and makes your module’s API surface self-documenting.

#horizontalrule

#emph[Next up: #link("13-remoting.md")[Chapter 13 – Remoting and Remote Management], where we learn that every server is just a local session you haven’t authenticated to yet.]

= Chapter 13: Objects and .NET
<chapter-13-objects-and-.net>
Sam discovers that strings have been lying to him this whole time.

#figure([#image("images/ch-13-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== Everything Is an Object
<everything-is-an-object>
You have been using objects since page one. Strings, integers, files, processes, services – every value in PowerShell is a .NET object. What you haven’t done yet is #emph[talk to those objects directly]. That changes now.

The mental shift is simple: a value is not just data. It is data #strong[plus] a set of methods and properties attached to it. A string is not just characters. It is a `System.String` object with `.Length`, `.ToUpper()`, `.Replace()`, `.Split()`, and about fifty other members waiting to be called.

#figure([#image("images/ch-13-objects-diagram.png")],
  caption: [
    objects-diagram
  ]
)

#horizontalrule

== Get-Member: The Magnifying Glass
<get-member-the-magnifying-glass>
Before you can use an object’s members, you need to know what it has. `Get-Member` (alias `gm`) is the command that shows you everything attached to an object.

```powershell
# What members does a string have?
'Hello' | Get-Member

# What members does a process object have?
Get-Process | Get-Member

# What members does a file have?
Get-Item ./README.md | Get-Member
```

The output is a table of `Name`, `MemberType`, and `Definition`. The `MemberType` column tells you what kind of member it is:

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [MemberType], [What it means],
  [`Property`],
  [A value you can read (and sometimes set)],
  [`Method`],
  [A function you can call with `()`],
  [`ScriptProperty`],
  [A computed property added by PowerShell],
  [`AliasProperty`],
  [A friendly name for another property],
  [`NoteProperty`],
  [A property added at runtime (common on PSCustomObjects)],
)
]

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

This is not special syntax. These are genuine .NET `System.String` method calls. PowerShell just makes them look natural.

#horizontalrule

== PSCustomObject: Roll Your Own
<pscustomobject-roll-your-own>
The `[PSCustomObject]` type accelerator lets you create a lightweight object with whatever properties you define. It is the workhorse of PowerShell data modelling – lean, pipeline-friendly, and needs no class definition.

=== Hash Table Cast (the idiomatic way)
<hash-table-cast-the-idiomatic-way>
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

The `[PSCustomObject]@{}` cast preserves property order, which a plain hashtable does not. That matters when you pipe to `Format-Table` and want consistent columns.

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

PSCustomObject plugs into the entire pipeline ecosystem immediately. It works with `Where-Object`, `Sort-Object`, `Select-Object`, `Export-Csv`, `ConvertTo-Json` – anything that speaks objects, which is everything.

=== Add-Member: Extend at Runtime
<add-member-extend-at-runtime>
Already have an object but need to bolt on an extra property or method? `Add-Member` handles that without rebuilding the object.

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

`$this` inside a `ScriptMethod` refers to the object the method was called on. It behaves exactly like `$this` in a class – because under the hood, it is.

#horizontalrule

== .NET Type Accelerators
<net-type-accelerators>
Type accelerators are shorthand aliases for .NET types. They let you reach directly into the .NET class library without writing fully-qualified names.

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

=== Static Methods: The `::` Operator
<static-methods-the-operator>
Static methods belong to the #emph[type], not to an instance. You call them with `::`.

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

#figure([#image("images/ch-13-static-vs-instance.png")],
  caption: [
    static-vs-instance
  ]
)

=== \[datetime\]: Date and Time Manipulation
<datetime-date-and-time-manipulation>
The `[datetime]` type accelerator gives you full access to .NET’s date/time system. In PowerShell, `Get-Date` returns a `[datetime]` object, so these methods work on anything the pipeline gives you too.

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

=== \[regex\]: Regular Expressions the .NET Way
<regex-regular-expressions-the-.net-way>
PowerShell’s `-match` operator uses .NET regex under the hood. For more control – named captures, compiled patterns, global replace – reach for `[regex]` directly.

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

#horizontalrule

== PowerShell Classes (PS 5+)
<powershell-classes-ps-5>
When `PSCustomObject` is not enough – when you need encapsulation, methods with real logic, constructors, or reuse across scripts – PowerShell classes step in.

Classes in PowerShell are .NET classes with PowerShell syntax. They compile to actual `System.Object` descendants. This is not duck-typing or a scripting shortcut.

=== Anatomy of a Class
<anatomy-of-a-class>
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

=== Enums
<enums>
Enums constrain a property to a fixed set of named values. They prevent the classic "is it 'running', 'Running', or 'RUNNING'?" problem.

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

#horizontalrule

== Inheritance
<inheritance>
A derived class inherits all properties and methods of its base class, and can override methods to change behaviour. The `: base()` call in the constructor passes arguments up to the parent constructor.

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

The `-is` operator tests the full inheritance chain. `$dog -is [Animal]` is `$true` because `Dog` inherits from `Animal`. This is genuine polymorphism, not PowerShell smoke and mirrors.

#figure([#image("images/ch-13-class-hierarchy.png")],
  caption: [
    class-hierarchy
  ]
)

#horizontalrule

== Practical Pattern: Enriched Objects from the Pipeline
<practical-pattern-enriched-objects-from-the-pipeline>
The real power of objects in PowerShell is building pipelines that transform plain data into rich, typed results. Here is a pattern that combines everything in this chapter:

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

This pattern – define a class, produce a collection, pipe it through standard cmdlets – is the PowerShell object model working exactly as designed. The class does the encapsulation; the pipeline does the data processing.

#horizontalrule

== Exercises
<exercises-12>
=== \[Ch-13, Ex-1\] Simple: Your First PSCustomObject
<ch-13-ex-1-simple-your-first-pscustomobject>
Create a `[PSCustomObject]` representing a server with four properties: `Name`, `IP`, `Role`, and `Status`. Pipe it to `Format-Table`. Then create a second object representing a different server and combine both into an array. Pipe the array to `Format-Table -AutoSize`.

=== \[Ch-13, Ex-2\] Normal: .NET Static Methods in Practice
<ch-13-ex-2-normal-.net-static-methods-in-practice>
Use `[datetime]` and `[math]` static methods to build a small "uptime report" script. Given a `$startDate` string in `'yyyy-MM-dd'` format, calculate: - The number of days the system has been running - The elapsed time expressed as full weeks and remaining days - Round the total uptime in hours to 1 decimal place

=== \[Ch-13, Ex-3\] Advanced: PowerShell Class with Constructor and Methods
<ch-13-ex-3-advanced-powershell-class-with-constructor-and-methods>
Write a PowerShell class called `ServerInfo` with the following spec: - Properties: `[string]$Name`, `[string]$IP`, `[int]$Port` - Constructor that sets all three properties - Method `GetEndpoint()` that returns `"IP:Port"` as a string - Method `IsDefaultPort()` that returns `$true` if the port is 80 or 443

Instantiate the class and verify all methods return correct values.

=== \[Ch-13, Ex-4\] Extreme: A Class Hierarchy
<ch-13-ex-4-extreme-a-class-hierarchy>
Build a class hierarchy with a base class `Animal` and two derived classes `Dog` and `Cat`. Requirements: - `Animal` has `[string]$Name`, `[int]$Age`, a constructor, a `Speak()` method (returns `"..."`) and a `Describe()` method that returns `"Name (age N): <speak result>"` - `Dog` adds `[string]$Breed` and overrides `Speak()` to return `"Woof!"` - `Cat` adds `[bool]$Indoor` and overrides `Speak()` to return `"Meow!"` - Both derived constructors call `: base($name, $age)`

Verify that `$dog -is [Animal]` is `$true`, that `Describe()` uses the overridden `Speak()`, and that `Cat.Indoor` is settable through the constructor.

#horizontalrule

== Key Takeaways
<key-takeaways-6>
- Every value in PowerShell is a .NET object. Strings, numbers, files – all objects.
- `Get-Member` (or `gm`) shows you every property and method available on any object.
- `[PSCustomObject]@{}` creates lightweight objects that plug into the whole pipeline ecosystem.
- `Add-Member` bolts properties and methods onto existing objects at runtime.
- Type accelerators like `[datetime]`, `[math]`, and `[regex]` expose .NET’s class library directly.
- Static methods are called with `::` on the type name, not on an instance.
- `class` defines a real .NET type with typed properties, constructors, and methods (PS 5+).
- Inheritance uses `: BaseClass` syntax; call the parent constructor with `: base(...)`.
- The `-is` operator checks the full inheritance chain, enabling genuine polymorphism.
- Enums constrain values to a fixed set of names – use them to eliminate string-matching bugs.

#horizontalrule

#emph[Next up: #link("14-error-handling.md")[Chapter 14 – Error Handling], where we learn that `-ErrorAction SilentlyContinue` is not a legitimate error handling strategy.]

= Chapter 14: Remoting and Background Jobs
<chapter-14-remoting-and-background-jobs>
Rina is logged into 50 servers simultaneously. Her terminal looks like the opening credits of a spy thriller.

#figure([#image("images/ch-14-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== Why This Chapter Matters
<why-this-chapter-matters>
Everything up to this point has been PowerShell talking to the local machine. That’s useful. What’s more useful is PowerShell talking to #emph[all] your machines simultaneously, or doing five expensive things at once while you drink coffee.

Remoting and background jobs are the infrastructure engineer’s force multiplier. One well-written script replaces an afternoon of SSH tab-switching. One parallel pipeline replaces a sequential loop that takes three minutes.

Here’s the terrain we’re covering:

#figure([#image("images/ch-14-overview.png")],
  caption: [
    remoting-overview
  ]
)

#horizontalrule

== Part 1: PowerShell Remoting
<part-1-powershell-remoting>
PowerShell Remoting (PSRemoting) lets you run commands on remote machines as if you were sitting at their keyboard. Under the hood it uses WS-Management (WSMan) over HTTP/HTTPS on Windows, or SSH on Linux/macOS/cross-platform.

=== Enabling Remoting
<enabling-remoting>
On Windows (run as Administrator):

```powershell
# Enable PSRemoting on the target machine
Enable-PSRemoting -Force

# Verify the WinRM service is running
Get-Service WinRM
```

On Linux/macOS or for SSH-based remoting (covered below), no separate enabling step is needed beyond having an SSH server running.

#blockquote[
#strong[Note for this chapter:] All examples and tests use `localhost` as the target. Real-world remoting to other machines requires network access, firewall rules, and (on Windows) either domain trust or explicit credential configuration. The mechanics are identical; only the target changes.
]

#horizontalrule

=== Invoke-Command: The One-Shot Remote Call
<invoke-command-the-one-shot-remote-call>
`Invoke-Command` is the workhorse of PowerShell remoting. You give it a ScriptBlock and a target; it runs the block there and returns the results here.

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

When you target multiple machines, `Invoke-Command` fans out in parallel automatically (up to 32 concurrent connections by default, controlled by `-ThrottleLimit`). The results come back as objects with a `PSComputerName` property added automatically, so you always know which machine produced which result.

```powershell
# Throttle to 5 concurrent connections
Invoke-Command -ComputerName $servers -ScriptBlock { Get-Process } -ThrottleLimit 5
```

#strong[The `-ScriptBlock` scope trap:] Variables from your local session are #emph[not] automatically available inside the ScriptBlock. The block runs in a fresh remote session.

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

The `$using:` scope modifier is the key. Any local variable can be projected into a remote ScriptBlock this way. It serializes the value and deserializes it on the other side, so complex objects may lose their methods – stick to primitive types, arrays, and simple hashtables when passing values across the wire.

#horizontalrule

=== Enter-PSSession: Interactive Remoting
<enter-pssession-interactive-remoting>
`Enter-PSSession` opens an interactive shell on a remote machine. Your prompt changes to reflect the remote host. Everything you type runs there.

```powershell
# Connect interactively
Enter-PSSession -ComputerName web01

# Your prompt becomes:
# [web01]: PS C:\Users\sam\Documents>

# Exit when done
Exit-PSSession
```

This is the PowerShell equivalent of SSH for interactive work. It’s useful for ad-hoc investigation, but if you catch yourself typing the same commands on five boxes in sequence, stop and use `Invoke-Command` instead.

#horizontalrule

=== New-PSSession: Persistent Sessions
<new-pssession-persistent-sessions>
Every `Invoke-Command -ComputerName` call creates a new session, authenticates, runs, and tears down. That overhead adds up. `New-PSSession` creates a #emph[reusable] session object you can pass to multiple commands.

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

Sessions also preserve state between calls. A variable set in one `Invoke-Command -Session` is still there in the next one, because it’s the same runspace. This is useful for complex multi-step workflows.

```powershell
# State persists within a session
Invoke-Command -Session $session -ScriptBlock { $deployPath = "C:\Deploy\v2.1" }
Invoke-Command -Session $session -ScriptBlock { Get-ChildItem $deployPath }  # Works
```

#horizontalrule

=== SSH-Based Remoting
<ssh-based-remoting>
PowerShell 7 supports SSH as a transport, which means cross-platform remoting works natively: Windows to Linux, Linux to Windows, anything to anything that runs an SSH server and PowerShell 7.

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

Key differences from WSMan remoting: - Uses SSH key authentication by default (add `-KeyFilePath` for a specific key) - No `Enable-PSRemoting` required on the target – just OpenSSH server + PowerShell 7 - Works through firewalls that already allow port 22 - Does not support `-ComputerName` on `Invoke-Command`; use `-HostName` instead

#figure([#image("images/ch-14-ssh-vs-wsrman.png")],
  caption: [
    ssh-vs-wsrman
  ]
)

#horizontalrule

=== Session Configuration
<session-configuration>
PowerShell remoting uses #emph[session configurations] (also called endpoints) on the server side. The default endpoint is named `microsoft.powershell`. You can create custom endpoints to constrain what callers can do.

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

Session configurations are how serious shops implement Just Enough Administration (JEA): operators get a remoting endpoint that only exposes the specific cmdlets they need, with no path to a full shell. The topic is its own chapter in any security-focused guide; the above is enough to know it exists and where to look.

#horizontalrule

== Part 2: Background Jobs
<part-2-background-jobs>
Background jobs let PowerShell start work in a separate process or thread and return control to you immediately. You check back later when you want the results.

#figure([#image("images/ch-14-jobs-flow.png")],
  caption: [
    jobs-flow
  ]
)

#horizontalrule

=== Start-Job / Get-Job / Receive-Job
<start-job-get-job-receive-job>
`Start-Job` launches a ScriptBlock in a #emph[child PowerShell process]. It’s fully isolated: separate runspace, separate memory, separate module imports.

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

`Receive-Job` #emph[consumes] output: call it twice and the second call returns nothing unless you use `-Keep`. The job object remembers its state, but the output stream is a queue that empties as you read it.

```powershell
# Keep output in the buffer for multiple reads
Receive-Job $job -Keep

# One-liner: wait, receive, clean up
$result = $job | Wait-Job | Receive-Job
Remove-Job $job
```

#strong[The process isolation cost:] Because `Start-Job` spawns a full child PowerShell process, each job carries ~50-100ms startup overhead and uses its own memory. For CPU-bound work that takes seconds or longer, this is negligible. For launching 100 tiny jobs that each take 10ms, the overhead dominates. Use thread jobs for that case (below).

```powershell
# Jobs run in a child process -- modules must be imported there
$job = Start-Job -ScriptBlock {
    # This may fail if the module isn't auto-imported in the child session
    Import-Module ActiveDirectory
    Get-ADUser -Filter { Name -like 'sam*' }
}
```

#horizontalrule

=== Start-ThreadJob: Lightweight Concurrent Work
<start-threadjob-lightweight-concurrent-work>
`Start-ThreadJob` (from the `ThreadJob` module, included in PS7) runs the ScriptBlock in a #emph[thread] within the current process rather than a child process. Faster startup, lower overhead, shared process memory.

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

The API is identical to `Start-Job`. Swap one for the other without changing anything else. Use `Start-ThreadJob` when: - You need many short-lived concurrent tasks - Your work is I/O-bound (waiting on network calls, file reads) - You want lower memory overhead

Use `Start-Job` when: - Your work genuinely needs process isolation (security boundary) - You’re concerned about runspace pollution from badly-behaved modules - You need the job to outlive the current session

#horizontalrule

=== ForEach-Object -Parallel: Inline Parallelism
<foreach-object--parallel-inline-parallelism>
PowerShell 7 added `-Parallel` to `ForEach-Object`. It runs the ScriptBlock for each input object concurrently using thread jobs under the hood, but the syntax is a clean inline pipeline stage – no `Start-Job`, no `Wait-Job`, no `Receive-Job` boilerplate.

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

Notice the `Thread` column will show different thread IDs – the items really are running concurrently. The results arrive in #emph[completion order], not input order. If you need input order, sort afterward.

#strong[`$using:` is required here too:]

```powershell
$multiplier = 7

# Wrong -- $multiplier is not in scope inside -Parallel
1..5 | ForEach-Object -Parallel { $_ * $multiplier }

# Right
1..5 | ForEach-Object -Parallel { $_ * $using:multiplier }
```

#strong[`-ThrottleLimit`:] The default is 5 concurrent threads. More is not always better. CPU-bound work should match your core count. I/O-bound work can go higher. Start with 5-10 and measure; don’t just crank it to 100 and wonder why the server is unresponsive.

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

#horizontalrule

=== Comparing the Three Parallelism Approaches
<comparing-the-three-parallelism-approaches>
#align(center)[#table(
  columns: 4,
  align: (col, row) => (auto,auto,auto,auto,).at(col),
  inset: 6pt,
  [], [`Start-Job`], [`Start-ThreadJob`], [`ForEach-Object -Parallel`],
  [Isolation],
  [Full process],
  [Thread],
  [Thread],
  [Startup cost],
  [High (~100ms)],
  [Low (~1ms)],
  [Low (~1ms)],
  [Syntax],
  [Explicit lifecycle],
  [Explicit lifecycle],
  [Inline pipeline],
  [Best for],
  [Long tasks, isolation],
  [Many short tasks],
  [Batch processing],
  [`$using:` required],
  [Yes],
  [Yes],
  [Yes],
  [Output ordering],
  [Any],
  [Any],
  [Completion order],
)
]

#horizontalrule

== Part 3: The Fan-Out Pattern
<part-3-the-fan-out-pattern>
The highest-leverage use of remoting and jobs together is the #emph[fan-out]: send work to many targets in parallel, collect and aggregate the results.

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

The try/catch inside the parallel block is critical. Without it, one unreachable server terminates the entire block with an error. Wrap the per-target work in try/catch, return a structured error object, and handle failures in the aggregation pass.

#figure([#image("images/ch-14-fan-out.png")],
  caption: [
    fan-out-pattern
  ]
)

#horizontalrule

== Exercises
<exercises-13>
=== \[Ch-14, Ex-1\] Simple: Invoke-Command Locally
<ch-14-ex-1-simple-invoke-command-locally>
Use `Invoke-Command` with only a `-ScriptBlock` parameter (no `-ComputerName`) to run a block of code and return the computer name or hostname. Verify the result is not null or empty.

#strong[Stretch goal:] Pass a local variable into the ScriptBlock using `$using:`.

=== \[Ch-14, Ex-2\] Normal: Background Job Lifecycle
<ch-14-ex-2-normal-background-job-lifecycle>
Start a background job that computes `1..5 | ForEach-Object { $_ * 2 }`. Wait for it to complete (with a sensible timeout), receive the results, and remove the job. Verify the output is `@(2, 4, 6, 8, 10)`.

#strong[Stretch goal:] Add error handling for the case where the job fails or times out.

=== \[Ch-14, Ex-3\] Advanced: Parallel Processing with ForEach-Object
<ch-14-ex-3-advanced-parallel-processing-with-foreach-object>
Use `ForEach-Object -Parallel` to process the integers 1 through 5, producing a custom object for each with `Input` and `Squared` properties. Set `-ThrottleLimit 3`. Verify you get 5 results back and that the item with `Input -eq 3` has `Squared -eq 9`.

#strong[Stretch goal:] Add a `ThreadId` property and confirm more than one distinct thread was used (proving actual concurrency).

=== \[Ch-14, Ex-4\] Extreme: Fan-Out with Throttling and Aggregation
<ch-14-ex-4-extreme-fan-out-with-throttling-and-aggregation>
Given a list of five named tasks (`task-A` through `task-E`), simulate a fan-out where each task runs in parallel with a random simulated duration (50-200ms). Collect the results and verify: - All 5 results are returned - All have `Status -eq 'Success'` - Every `Target` value appears in your original list

Use `-ThrottleLimit 2` to throttle. Include structured error handling inside the parallel block so a single failure does not abort the others.

#horizontalrule

== Key Takeaways
<key-takeaways-7>
- `Invoke-Command -ScriptBlock` runs code remotely (or locally); add `-ComputerName` for remote targets, `-Session` for reuse.
- `$using:` is how local variables enter a remote ScriptBlock or a `-Parallel` block. Without it, your variables are invisible.
- `New-PSSession` creates a persistent, reusable connection that preserves state between calls and avoids per-call authentication overhead.
- SSH remoting works cross-platform with `-HostName` and `-SSHTransport`; no `Enable-PSRemoting` needed on the target.
- `Start-Job` is process-isolated and heavy; `Start-ThreadJob` and `ForEach-Object -Parallel` are thread-based and lightweight.
- `-ThrottleLimit` is not decorative. Tune it to your workload – more threads are not always better.
- The fan-out pattern (parallel dispatch + result aggregation) is the core infrastructure automation pattern. Always wrap per-target work in try/catch and return structured error objects.
- Results from parallel operations arrive in completion order, not input order. Sort explicitly if order matters.

#horizontalrule

#emph[Next up: #link("15-modules-and-gallery.md")[Chapter 15 – Modules and the PowerShell Gallery], where we learn that sharing is caring, and publishing is terrifying.]

= Chapter 15: Active Directory
<chapter-15-active-directory>
Sam has 200 users to create. Max has a CSV template. ADUC has a mouse.

#figure([#image("images/ch-15-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== The ActiveDirectory Module
<the-activedirectory-module>
Before you can do anything, you need the module. It ships with the #strong[Remote Server Administration Tools (RSAT)] on Windows, or via the `ActiveDirectory` module on a Domain Controller.

```powershell
# Check if it's available
Get-Module -ListAvailable -Name ActiveDirectory

# Import it (usually auto-imported on first use)
Import-Module ActiveDirectory

# Confirm the cmdlets are there
Get-Command -Module ActiveDirectory | Measure-Object
```

If `Get-Module` returns nothing, install RSAT:

```powershell
# Windows 10/11 — as admin
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

Once imported, you have about 150 cmdlets. The ones you’ll use 90% of the time:

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Cmdlet], [Purpose],
  [`Get-ADUser`],
  [Query user accounts],
  [`Get-ADGroup`],
  [Query security and distribution groups],
  [`Get-ADComputer`],
  [Query computer accounts],
  [`New-ADUser`],
  [Create a user account],
  [`Set-ADUser`],
  [Modify a user account],
  [`Add-ADGroupMember`],
  [Add objects to a group],
  [`Remove-ADGroupMember`],
  [Remove objects from a group],
  [`Move-ADObject`],
  [Move an object to a different OU],
  [`Disable-ADAccount`],
  [Disable a user or computer account],
)
]

#figure([#image("images/ch-15-module-overview.png")],
  caption: [
    module-overview
  ]
)

#horizontalrule

== Querying Users
<querying-users>
=== The -Filter Parameter
<the--filter-parameter>
`Get-ADUser` requires either `-Filter` or `-Identity`. `-Identity` is for when you know exactly who you want. `-Filter` is for everything else.

```powershell
# Get a specific user by SAM account name
Get-ADUser -Identity jsmith

# Get all users (use carefully in large domains)
Get-ADUser -Filter *

# Filter by department
Get-ADUser -Filter { Department -eq 'Engineering' }

# Filter by enabled state
Get-ADUser -Filter { Enabled -eq $true }

# Combine conditions
Get-ADUser -Filter { Department -eq 'HR' -and Enabled -eq $true }
```

The filter syntax inside `{ }` is #strong[not] standard PowerShell — it’s an LDAP-ish DSL that gets translated server-side. The golden rule: if the property is an AD attribute, use `-Filter`. If you need complex logic that AD can’t handle, pipe to `Where-Object`.

```powershell
# AD handles this (fast, server-side)
Get-ADUser -Filter { Department -eq 'IT' }

# Where-Object handles this (slow, client-side -- fetches everything first)
Get-ADUser -Filter * | Where-Object { $_.Description -match 'temp' }
```

=== The -Properties Parameter
<the--properties-parameter>
By default, `Get-ADUser` returns a small set of attributes. To get more, you must ask explicitly:

```powershell
# Default properties only (Name, SamAccountName, Enabled, DistinguishedName, etc.)
Get-ADUser -Identity jsmith

# Request additional properties
Get-ADUser -Identity jsmith -Properties Department, Title, Manager, EmailAddress

# Request everything (use sparingly -- slow and noisy)
Get-ADUser -Identity jsmith -Properties *
```

This is intentional. Fetching all properties for 50,000 users would be painful. Ask for what you need.

```powershell
# Practical pattern: filter + select specific properties
Get-ADUser -Filter { Enabled -eq $true } -Properties Department, Title |
    Select-Object Name, SamAccountName, Department, Title |
    Sort-Object Department, Name
```

=== The -SearchBase Parameter
<the--searchbase-parameter>
Scoping your query to an Organisational Unit (OU) makes it faster and more predictable:

```powershell
# Search only in the London OU
Get-ADUser -Filter * -SearchBase 'OU=London,OU=Users,DC=corp,DC=local'

# The SearchScope controls depth: Base, OneLevel, Subtree (default)
Get-ADUser -Filter * -SearchBase 'OU=Users,DC=corp,DC=local' -SearchScope OneLevel
```

`Subtree` (the default) searches the OU and all child OUs. `OneLevel` searches only the immediate OU. `Base` searches a single object — mostly useful for confirming existence.

#figure([#image("images/ch-15-ldap-searchbase.png")],
  caption: [
    ldap-searchbase
  ]
)

#horizontalrule

== LDAP Filters vs -Filter
<ldap-filters-vs--filter>
For power users, the raw LDAP filter syntax is available via `-LDAPFilter`. It’s more expressive and sometimes faster:

```powershell
# -Filter syntax
Get-ADUser -Filter { Department -eq 'IT' -and Enabled -eq $true }

# Equivalent LDAP filter
Get-ADUser -LDAPFilter '(&(department=IT)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'
```

Stick with `-Filter` until you hit its limits. You’ll know when: either it throws an error or the query is so nested that only raw LDAP can express it.

#horizontalrule

== Modifying Users
<modifying-users>
`Set-ADUser` takes an `-Identity` (SAM, DN, GUID, or UPN) and any number of attribute parameters:

```powershell
# Update a single attribute
Set-ADUser -Identity jsmith -Department 'Platform Engineering'

# Update multiple attributes at once
Set-ADUser -Identity jsmith `
    -Department 'Platform Engineering' `
    -Title 'Senior Engineer' `
    -Office 'London'

# Clear an attribute by setting it to $null
Set-ADUser -Identity jsmith -Description $null

# Use -Replace for multi-valued attributes or raw LDAP attribute names
Set-ADUser -Identity jsmith -Replace @{ telephoneNumber = '+44 20 1234 5678' }
```

Pipeline pattern for bulk updates:

```powershell
# Disable all users in the Contractors OU
Get-ADUser -Filter * -SearchBase 'OU=Contractors,DC=corp,DC=local' |
    Disable-ADAccount
```

#horizontalrule

== Creating Users
<creating-users>
`New-ADUser` has a lot of parameters. The important ones:

```powershell
New-ADUser `
    -Name           'Jane Smith' `
    -GivenName      'Jane' `
    -Surname        'Smith' `
    -SamAccountName 'jsmith' `
    -UserPrincipalName 'jsmith@corp.local' `
    -Path           'OU=Users,DC=corp,DC=local' `
    -AccountPassword (ConvertTo-SecureString 'P@ssw0rd123!' -AsPlainText -Force) `
    -Enabled        $true `
    -Department     'Engineering' `
    -Title          'Software Engineer'
```

A few things worth knowing:

- `-Path` is the DN of the #strong[parent OU], not the user itself.
- `-AccountPassword` requires a `SecureString`. Never pass a plain string.
- `-Enabled $false` is the default. Forgetting `-Enabled $true` means the account is created but locked out. You will do this once. Everyone does.
- The `-PassThru` switch returns the new AD object, useful for piping immediately to `Add-ADGroupMember`.

```powershell
# Create and immediately add to a group
New-ADUser -Name 'Bob Jones' -SamAccountName 'bjones' `
    -Path 'OU=Users,DC=corp,DC=local' `
    -AccountPassword (ConvertTo-SecureString 'P@ssw0rd123!' -AsPlainText -Force) `
    -Enabled $true -PassThru |
    Add-ADGroupMember -Identity 'AllEmployees' -Members { $_ }
```

#horizontalrule

== Group Membership
<group-membership>
```powershell
# Add a single user to a group
Add-ADGroupMember -Identity 'VPN-Users' -Members 'jsmith'

# Add multiple users
Add-ADGroupMember -Identity 'VPN-Users' -Members 'jsmith', 'bjones', 'adavis'

# Add all users from a pipeline
Get-ADUser -Filter { Department -eq 'Engineering' } |
    ForEach-Object { Add-ADGroupMember -Identity 'Engineering-All' -Members $_ }

# Check current membership
Get-ADGroupMember -Identity 'VPN-Users' | Select-Object Name, SamAccountName

# Remove a member
Remove-ADGroupMember -Identity 'VPN-Users' -Members 'jsmith' -Confirm:$false
```

#horizontalrule

== Bulk Operations with CSV Import
<bulk-operations-with-csv-import>
This is what Max had in mind when Sam started clicking.

```powershell
# users.csv:
# FirstName,LastName,Department,Title,OU
# Alice,Brown,IT,Analyst,OU=IT,OU=Users,DC=corp,DC=local
# Bob,Green,HR,Coordinator,OU=HR,OU=Users,DC=corp,DC=local

$users = Import-Csv './users.csv'

foreach ($user in $users) {
    $sam  = "$($user.FirstName.Substring(0,1).ToLower())$($user.LastName.ToLower())"
    $upn  = "$sam@corp.local"
    $pass = ConvertTo-SecureString 'Welcome1!' -AsPlainText -Force

    $params = @{
        Name               = "$($user.FirstName) $($user.LastName)"
        GivenName          = $user.FirstName
        Surname            = $user.LastName
        SamAccountName     = $sam
        UserPrincipalName  = $upn
        Path               = $user.OU
        AccountPassword    = $pass
        Department         = $user.Department
        Title              = $user.Title
        Enabled            = $true
    }

    try {
        New-ADUser @params
        Write-Host "Created: $sam" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to create $sam : $_"
    }
}
```

Splatting (`@params`) keeps the loop body readable. Always wrap `New-ADUser` in a `try/catch` in bulk scripts — one duplicate SAM account name would otherwise abort the entire run.

#figure([#image("images/ch-15-bulk-create-flow.png")],
  caption: [
    bulk-create-flow
  ]
)

#horizontalrule

== OU Management
<ou-management>
```powershell
# List all OUs
Get-ADOrganizationalUnit -Filter *

# Create a new OU
New-ADOrganizationalUnit -Name 'Contractors' -Path 'OU=Users,DC=corp,DC=local'

# Move a user to a different OU
Move-ADObject -Identity 'CN=Jane Smith,OU=NewHires,DC=corp,DC=local' `
              -TargetPath 'OU=Engineering,OU=Users,DC=corp,DC=local'

# Get the DN of an object (useful for Move-ADObject targeting)
(Get-ADUser -Identity jsmith).DistinguishedName
```

#horizontalrule

== Automated Onboarding: Putting It Together
<automated-onboarding-putting-it-together>
Real onboarding scripts combine everything: create user, set attributes, assign groups, maybe trigger an email. Here’s a production-grade function:

```powershell
function New-UserOnboarding {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $FirstName,
        [Parameter(Mandatory)] [string] $LastName,
        [Parameter(Mandatory)] [string] $Department,
        [Parameter(Mandatory)] [string] $Title,
        [string] $Manager,
        [string] $BasePath = 'OU=Users,DC=corp,DC=local'
    )

    $sam  = "$($FirstName.Substring(0,1).ToLower())$($LastName.ToLower())"
    $upn  = "$sam@corp.local"
    $ouPath = "OU=$Department,$BasePath"

    # Derive a temp password -- in real life, use a vault
    $pass = ConvertTo-SecureString 'Welcome1!' -AsPlainText -Force

    if ($PSCmdlet.ShouldProcess($sam, 'Create AD user and assign groups')) {
        New-ADUser `
            -Name              "$FirstName $LastName" `
            -GivenName         $FirstName `
            -Surname           $LastName `
            -SamAccountName    $sam `
            -UserPrincipalName $upn `
            -Path              $ouPath `
            -AccountPassword   $pass `
            -Department        $Department `
            -Title             $Title `
            -Enabled           $true

        # Standard groups every employee needs
        Add-ADGroupMember -Identity 'AllEmployees'  -Members $sam
        Add-ADGroupMember -Identity $Department     -Members $sam

        if ($Manager) {
            $managerDN = (Get-ADUser -Identity $Manager).DistinguishedName
            Set-ADUser -Identity $sam -Manager $managerDN
        }

        Write-Verbose "Onboarding complete for $sam ($upn)"

        [PSCustomObject]@{
            SAM        = $sam
            UPN        = $upn
            Department = $Department
            Groups     = @('AllEmployees', $Department)
        }
    }
}

# Usage
New-UserOnboarding -FirstName 'Charlie' -LastName 'Davis' `
                   -Department 'Engineering' -Title 'Developer' `
                   -Manager 'rina'
```

`SupportsShouldProcess` gives you `-WhatIf` for free. Run it with `-WhatIf` first in any environment you value.

#horizontalrule

== Quick Reference
<quick-reference>
```powershell
# Find all users in an OU
Get-ADUser -Filter * -SearchBase 'OU=Users,DC=corp,DC=local' -Properties *

# Find disabled accounts
Get-ADUser -Filter { Enabled -eq $false } -Properties LastLogonDate |
    Select-Object Name, SamAccountName, LastLogonDate | Sort-Object LastLogonDate

# Find users not logged in for 90 days
$cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter { LastLogonDate -lt $cutoff -and Enabled -eq $true } `
           -Properties LastLogonDate

# List members of a group
Get-ADGroupMember -Identity 'VPN-Users' -Recursive

# Find a user's group memberships
(Get-ADUser -Identity jsmith -Properties MemberOf).MemberOf
```

#horizontalrule

== Exercises
<exercises-14>
=== \[Ch-15, Ex-1\] List Users in an OU (Simple)
<ch-15-ex-1-list-users-in-an-ou-simple>
Write a script that retrieves all enabled users from `OU=Users,DC=corp,DC=local` and displays their `Name` and `SamAccountName`. Use a mock in your test so no AD connection is required.

#strong[Constraints:] - Use `Get-ADUser -Filter` (not `-Identity`) - Use `-SearchBase` to scope the query - Output must include at least two users

#horizontalrule

=== \[Ch-15, Ex-2\] Find Disabled Accounts (Normal)
<ch-15-ex-2-find-disabled-accounts-normal>
Query all users (no SearchBase restriction) and return only those where `Enabled -eq $false`. Your script should output the count of disabled accounts and list their SAM account names.

#strong[Constraints:] - Use `Get-ADUser -Filter *` then `Where-Object` - Return a count and a list - Handle the case where zero disabled accounts exist gracefully

#horizontalrule

=== \[Ch-15, Ex-3\] Bulk Create Users from CSV (Advanced)
<ch-15-ex-3-bulk-create-users-from-csv-advanced>
Given an in-memory array of user data (simulating `Import-Csv`), write a loop that creates each user with `New-ADUser`. Build the `SamAccountName` as first initial + lowercase surname. Return a summary object per user.

#strong[Constraints:] - SAM format: `"$($user.FirstName[0].ToString().ToLower())$($user.LastName.ToLower())"` - Wrap each `New-ADUser` call in `try/catch` - Return `[PSCustomObject]` with `Name` and `SAM` properties per user - All `New-ADUser` calls must be mocked in tests

#horizontalrule

=== \[Ch-15, Ex-4\] Automated Onboarding Script (Extreme)
<ch-15-ex-4-automated-onboarding-script-extreme>
Write a `New-UserOnboarding` function that: 1. Accepts `FirstName`, `LastName`, `Department`, `Title` as mandatory parameters 2. Derives `SamAccountName` and `UserPrincipalName` from the name 3. Calls `New-ADUser` to create the account (enabled, with a temp password) 4. Calls `Set-ADUser` to set `Department` and `Title` 5. Calls `Add-ADGroupMember` twice: once for `'AllEmployees'` and once for the department group 6. Returns a `[PSCustomObject]` with `SAM`, `UPN`, and `Groups` properties

#strong[Constraints:] - All AD cmdlets mocked in Pester - `Groups` property must be an array containing both group names - `Should -Invoke` assertions on all three AD cmdlets

= Chapter 16: Automation Recipes
<chapter-16-automation-recipes>
Sam has been doing this manually for six months. This chapter ends that.

#figure([#image("images/ch-16-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== Why Automation Recipes?
<why-automation-recipes>
Theory is how you learn to drive. Recipes are how you survive rush hour.

This chapter is a collection of real-world automation patterns that show up in nearly every IT environment: cleaning up old files, backing up directories, generating system reports, scheduling tasks, and watching for problems before they become incidents. Each recipe is a self-contained script you can adapt and deploy.

The goal is not to teach new syntax – you have all the tools from earlier chapters. The goal is to show how those tools combine into scripts that are reliable, observable, and maintainable by someone other than you at 2 AM.

#figure([#image("images/ch-16-recipe-map.png")],
  caption: [
    recipe-map
  ]
)

#horizontalrule

== Recipe 1: Log Rotation and Cleanup
<recipe-1-log-rotation-and-cleanup>
The most common sysadmin automation task. Logs grow until they eat the disk, then someone pages you at midnight. Prevention is a script.

=== The Pattern
<the-pattern>
```powershell
<#
.SYNOPSIS
    Remove log files older than a specified number of days.
.PARAMETER LogDir
    Directory to clean.
.PARAMETER DaysOld
    Files older than this many days are deleted. Default: 30.
.PARAMETER WhatIf
    Inherited from CmdletBinding -- shows what would be deleted without deleting.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$LogDir,
    [int]$DaysOld = 30
)

$cutoff = (Get-Date).AddDays(-$DaysOld)
$candidates = Get-ChildItem -Path $LogDir -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff }

if ($candidates.Count -eq 0) {
    Write-Host "No files older than $DaysOld days found in $LogDir"
    return
}

$totalMB = [math]::Round(($candidates | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Host "Found $($candidates.Count) files ($totalMB MB) eligible for removal"

foreach ($file in $candidates) {
    if ($PSCmdlet.ShouldProcess($file.FullName, 'Remove-Item')) {
        Remove-Item $file.FullName -Force -ErrorAction Continue
        Write-Verbose "Deleted: $($file.FullName)"
    }
}
```

=== Key Points
<key-points>
`SupportsShouldProcess` wires up `-WhatIf` and `-Confirm` automatically. When you call your script with `-WhatIf`, nothing gets deleted – you see exactly what #emph[would] happen. Run with `-WhatIf` first. Always.

`-ErrorAction Continue` on `Remove-Item` means a locked file won’t abort the whole cleanup. You lose that one file, but the rest of the run completes. Log the failures separately if they matter.

=== Running It
<running-it>
```powershell
# Dry run -- see what would be deleted
.\Invoke-LogCleanup.ps1 -LogDir C:\IIS\Logs -DaysOld 7 -WhatIf

# Real run with verbose output
.\Invoke-LogCleanup.ps1 -LogDir C:\IIS\Logs -DaysOld 7 -Verbose
```

#horizontalrule

== Recipe 2: File Backup with Retention
<recipe-2-file-backup-with-retention>
Backup without retention is just slow disk death. The pattern: copy to a date-stamped folder, then prune backups older than your retention window.

```powershell
<#
.SYNOPSIS
    Back up a source directory to a date-stamped folder, then prune old backups.
.PARAMETER SourceDir
    The directory to back up.
.PARAMETER BackupRoot
    Root folder where dated backup folders are created.
.PARAMETER RetainDays
    Delete backup folders older than this many days. Default: 14.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$SourceDir,
    [Parameter(Mandatory)][string]$BackupRoot,
    [int]$RetainDays = 14
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Create the backup ---
$stamp     = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupDir = Join-Path $BackupRoot $stamp

Write-Host "Backing up '$SourceDir' -> '$backupDir'"
Copy-Item -Path $SourceDir -Destination $backupDir -Recurse -Force
Write-Host "Backup complete."

# --- Prune old backups ---
$cutoff = (Get-Date).AddDays(-$RetainDays)
$old = Get-ChildItem -Path $BackupRoot -Directory |
    Where-Object { $_.CreationTime -lt $cutoff }

if ($old.Count -gt 0) {
    Write-Host "Pruning $($old.Count) backup(s) older than $RetainDays days..."
    foreach ($dir in $old) {
        if ($PSCmdlet.ShouldProcess($dir.FullName, 'Remove backup')) {
            Remove-Item $dir.FullName -Recurse -Force
            Write-Verbose "Pruned: $($dir.FullName)"
        }
    }
} else {
    Write-Host "No backups to prune."
}
```

=== Self-Documenting with Comment-Based Help
<self-documenting-with-comment-based-help>
Notice the `<# .SYNOPSIS ... #>` block. This is #strong[comment-based help]. Run `Get-Help .\Invoke-Backup.ps1` and PowerShell renders it as a proper help page – parameters, synopsis, everything. It costs you thirty seconds to write and saves ten minutes of "what does this script do again?" every time someone else touches it.

```powershell
# What you get for free:
Get-Help .\Invoke-Backup.ps1 -Full
Get-Help .\Invoke-Backup.ps1 -Examples
```

`Set-StrictMode -Version Latest` catches use of uninitialized variables and other sloppy habits at script start. Pair it with `$ErrorActionPreference = 'Stop'` so any cmdlet failure becomes a terminating error rather than a warning you might miss. These two lines at the top of every production script are the lowest-cost reliability improvement available.

#horizontalrule

== Recipe 3: System Inventory Report
<recipe-3-system-inventory-report>
One of the most-requested scripts in any IT team: "give me a snapshot of what’s running on this box." Useful for baseline documentation, incident response, and compliance audits.

#figure([#image("images/ch-16-inventory-report.png")],
  caption: [
    inventory-report
  ]
)

```powershell
<#
.SYNOPSIS
    Generate an HTML system inventory report.
.PARAMETER OutputPath
    Where to write the HTML file. Defaults to Desktop.
#>
param(
    [string]$OutputPath = (Join-Path ([Environment]::GetFolderPath('Desktop'))
        "inventory-$(hostname)-$(Get-Date -Format yyyyMMdd).html")
)

$ErrorActionPreference = 'Stop'

# --- Gather data ---
$os       = Get-CimInstance Win32_OperatingSystem
$cpu      = Get-CimInstance Win32_Processor | Select-Object -First 1
$disks    = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$services = Get-Service | Where-Object Status -eq 'Running' |
                Sort-Object DisplayName
$topProcs = Get-Process | Sort-Object WorkingSet64 -Descending |
                Select-Object -First 15 Name,
                    @{N='MemMB';  E={[math]::Round($_.WorkingSet64/1MB,1)}},
                    @{N='CPU';    E={[math]::Round($_.CPU,1)}},
                    Id

$inventory = [PSCustomObject]@{
    Hostname    = $env:COMPUTERNAME
    OS          = $os.Caption
    OSBuild     = $os.BuildNumber
    Architecture= $os.OSArchitecture
    CPU         = $cpu.Name
    TotalMemGB  = [math]::Round($os.TotalVisibleMemorySizeKB / 1MB, 1)
    FreeMemGB   = [math]::Round($os.FreePhysicalMemoryKB / 1MB, 1)
    Uptime      = [math]::Round((New-TimeSpan $os.LastBootUpTime (Get-Date)).TotalHours, 1)
    PSVersion   = $PSVersionTable.PSVersion.ToString()
    ReportTime  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

# --- Build HTML ---
$cssStyle = @"
<style>
  body { font-family: Segoe UI, sans-serif; background: #f0f2f5; color: #1a1a2e; }
  h1   { background: #012456; color: white; padding: 16px 24px; margin: 0; }
  h2   { color: #012456; border-bottom: 2px solid #012456; padding-bottom: 4px; }
  .container { max-width: 1100px; margin: 24px auto; padding: 0 16px; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 24px; }
  th    { background: #012456; color: white; padding: 8px 12px; text-align: left; }
  td    { padding: 8px 12px; border-bottom: 1px solid #d0d0d0; }
  tr:nth-child(even) td { background: #eef0f4; }
</style>
"@

$sysInfoHtml = $inventory.PSObject.Properties |
    Select-Object Name, Value |
    ConvertTo-Html -Fragment -As List

$topProcsHtml  = $topProcs  | ConvertTo-Html -Fragment
$servicesHtml  = $services  | Select-Object DisplayName, Status, StartType |
                              ConvertTo-Html -Fragment

$html = ConvertTo-Html -Title "Inventory: $($inventory.Hostname)" `
    -Head $cssStyle `
    -PreContent "<h1>System Inventory -- $($inventory.Hostname)</h1>
                 <div class='container'>
                 <h2>System Information</h2>$sysInfoHtml
                 <h2>Top 15 Processes by Memory</h2>$topProcsHtml
                 <h2>Running Services ($($services.Count))</h2>$servicesHtml
                 </div>" `
    -PostContent "<p style='color:#888;font-size:0.8em;padding:0 24px'>
                  Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') by
                  PowerShell Automation Guide Ch. 16</p>" |
    Out-String

Set-Content -Path $OutputPath -Value $html -Encoding UTF8
Write-Host "Report written to: $OutputPath"
Invoke-Item $OutputPath   # open in browser
```

`ConvertTo-Html -Fragment` is the workhorse here: it renders any object collection as an HTML table snippet without full `<html>` boilerplate. Combine multiple fragments with `ConvertTo-Html -PreContent` for full reports. This pattern requires zero HTML knowledge and produces something a manager will actually read.

#horizontalrule

== Recipe 4: Scheduled Tasks
<recipe-4-scheduled-tasks>
A script that runs manually is a ceremony. A script in a scheduled task is infrastructure.

```powershell
# Register a daily cleanup task (run as current user)
$action  = New-ScheduledTaskAction `
    -Execute 'pwsh.exe' `
    -Argument '-NonInteractive -NoProfile -File "C:\Scripts\Invoke-LogCleanup.ps1" -LogDir "C:\IIS\Logs" -DaysOld 7'

$trigger = New-ScheduledTaskTrigger -Daily -At '02:00'

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false

Register-ScheduledTask `
    -TaskName   'PS-LogCleanup-Daily' `
    -TaskPath   '\PowerShellGuide\' `
    -Action     $action `
    -Trigger    $trigger `
    -Settings   $settings `
    -RunLevel   Highest `
    -Description 'Daily IIS log cleanup, managed by PowerShell automation scripts' `
    -Force
```

=== Useful Task Management Commands
<useful-task-management-commands>
```powershell
# List your tasks
Get-ScheduledTask -TaskPath '\PowerShellGuide\*'

# Run immediately (don't wait for the trigger)
Start-ScheduledTask -TaskName 'PS-LogCleanup-Daily' -TaskPath '\PowerShellGuide\'

# Check the last run result
Get-ScheduledTaskInfo -TaskName 'PS-LogCleanup-Daily' -TaskPath '\PowerShellGuide\' |
    Select-Object LastRunTime, LastTaskResult, NextRunTime

# LastTaskResult 0 = success. Anything else: check Event Viewer -> Task Scheduler.

# Remove a task
Unregister-ScheduledTask -TaskName 'PS-LogCleanup-Daily' -TaskPath '\PowerShellGuide\' -Confirm:$false
```

The `-TaskPath` parameter organises tasks in a virtual folder. Using `\PowerShellGuide\` (or your company prefix) keeps your tasks separate from Windows built-in tasks in Task Scheduler’s tree view. It costs nothing and saves confusion during audits.

#horizontalrule

== Recipe 5: Email Alerts (Pattern)
<recipe-5-email-alerts-pattern>
Sending email from a script turns reactive monitoring into proactive alerting. The pattern is the same whether you’re checking disk space, service health, or backup completion.

```powershell
function Send-Alert {
    <#
    .SYNOPSIS
        Send a plain-text alert email via SMTP.
    #>
    param(
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$Body,
        [string]$To       = 'ops-alerts@company.com',
        [string]$From     = 'monitoring@company.com',
        [string]$SmtpHost = 'smtp.company.com',
        [int]   $SmtpPort = 587,
        [switch]$UseSsl
    )

    $mailParams = @{
        To         = $To
        From       = $From
        Subject    = "[ALERT] $Subject"
        Body       = $Body
        SmtpServer = $SmtpHost
        Port       = $SmtpPort
        UseSsl     = $UseSsl.IsPresent
    }

    try {
        Send-MailMessage @mailParams
        Write-Verbose "Alert sent: $Subject"
    } catch {
        Write-Warning "Failed to send alert '$Subject': $_"
        # Log but don't rethrow -- alert failure shouldn't abort the monitoring script
    }
}

# Usage pattern: disk space check with alert
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freePercent = [math]::Round($disk.FreeSpace / $disk.Size * 100, 1)

if ($freePercent -lt 15) {
    $body = @"
WARNING: Low disk space on $env:COMPUTERNAME

Drive:      C:\
Free Space: $([math]::Round($disk.FreeSpace/1GB, 1)) GB
Total:      $([math]::Round($disk.Size/1GB, 1)) GB
Free:       $freePercent%

This alert was generated by: $PSCommandPath
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    Send-Alert -Subject "Low disk on $env:COMPUTERNAME (C: $freePercent% free)" -Body $body
}
```

`Send-MailMessage` is deprecated in PS7 (Microsoft recommends the community `Send-MgMail` module for Microsoft 365, or the `MailKit` .NET library for modern SMTP). The pattern above works fine for traditional on-premises SMTP relays, which still exist in the majority of enterprise environments. Wrap the actual transport in your `Send-Alert` function and swap it out when you migrate – the rest of your scripts don’t change.

#horizontalrule

== Recipe 6: Service Monitor with Drift Detection
<recipe-6-service-monitor-with-drift-detection>
Alerts are reactive. Drift detection is proactive: you define what "healthy" looks like (the baseline), and your monitor flags deviations automatically.

```powershell
<#
.SYNOPSIS
    Compare current service state against a saved baseline.
    Save a new baseline with -SaveBaseline.
.PARAMETER BaselinePath
    Path to the baseline JSON file.
.PARAMETER SaveBaseline
    Capture current state as the new baseline.
.PARAMETER AlertThreshold
    Number of drifted services before sending an alert. Default: 1.
#>
[CmdletBinding()]
param(
    [string]$BaselinePath    = (Join-Path $PSScriptRoot 'service-baseline.json'),
    [switch]$SaveBaseline,
    [int]   $AlertThreshold  = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Services we care about -- adjust to your environment
$watchList = @(
    'wuauserv',   # Windows Update
    'WinRM',      # Windows Remote Management
    'EventLog',   # Windows Event Log
    'Spooler',    # Print Spooler
    'BITS'        # Background Intelligent Transfer
)

function Get-ServiceSnapshot {
    Get-Service -Name $watchList -ErrorAction SilentlyContinue |
        Select-Object Name,
            @{N='Status'; E={$_.Status.ToString()}},
            @{N='StartType'; E={$_.StartType.ToString()}}
}

# --- Save baseline ---
if ($SaveBaseline) {
    $snapshot = Get-ServiceSnapshot
    $snapshot | ConvertTo-Json -Depth 5 | Set-Content $BaselinePath -Encoding UTF8
    Write-Host "Baseline saved to: $BaselinePath ($($snapshot.Count) services)"
    return
}

# --- Load baseline ---
if (-not (Test-Path $BaselinePath)) {
    Write-Warning "No baseline found at $BaselinePath. Run with -SaveBaseline first."
    return
}

$baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
$current  = Get-ServiceSnapshot

# --- Detect drift ---
$drift = foreach ($expected in $baseline) {
    $actual = $current | Where-Object Name -eq $expected.Name
    if (-not $actual) {
        [PSCustomObject]@{
            Name      = $expected.Name
            Type      = 'Missing'
            Expected  = $expected.Status
            Actual    = 'NOT FOUND'
        }
    } elseif ($actual.Status -ne $expected.Status) {
        [PSCustomObject]@{
            Name      = $expected.Name
            Type      = 'StatusDrift'
            Expected  = $expected.Status
            Actual    = $actual.Status
        }
    }
}

if ($drift.Count -eq 0) {
    Write-Host "[OK] All $($baseline.Count) monitored services match baseline."
    return
}

Write-Warning "Drift detected: $($drift.Count) service(s) out of expected state"
$drift | Format-Table -AutoSize

if ($drift.Count -ge $AlertThreshold) {
    $alertBody = $drift |
        ForEach-Object { "  $($_.Name): expected=$($_.Expected), actual=$($_.Actual)" } |
        Out-String

    # Send-Alert -Subject "Service drift on $env:COMPUTERNAME" -Body $alertBody
    Write-Host "Alert body (would be emailed):`n$alertBody"
}
```

=== Saving and Running
<saving-and-running>
```powershell
# One-time: save today's state as the baseline
.\Invoke-ServiceMonitor.ps1 -SaveBaseline

# Daily (scheduled task or manual): check for drift
.\Invoke-ServiceMonitor.ps1

# Output when everything is fine:
# [OK] All 5 monitored services match baseline.

# Output when something drifted:
# WARNING: Drift detected: 1 service(s) out of expected state
# Name     Type        Expected  Actual
# ----     ----        --------  ------
# Spooler  StatusDrift Running   Stopped
```

#horizontalrule

== Self-Documenting Scripts: The Minimum Standard
<self-documenting-scripts-the-minimum-standard>
A script that works is useful. A script that documents itself is an asset.

#figure([#image("images/ch-16-self-documenting.png")],
  caption: [
    self-documenting
  ]
)

```powershell
<#
.SYNOPSIS
    One sentence. What does this script do?

.DESCRIPTION
    A paragraph. Why does it exist, what problem does it solve?

.PARAMETER ParameterName
    What does this parameter control? Required? Default?

.EXAMPLE
    .\Script.ps1 -Param Value
    What does this example do?

.NOTES
    Author:  Sam Chen
    Version: 1.0.0
    Updated: 2026-03-17
    Requires: PowerShell 7.4+, Windows Server 2019+
#>
```

Beyond the help block, apply these three rules to every script you write:

+ #strong[Name things for what they are, not what they are made of.] `$cutoff` tells you the intent. `$datetime1` tells you the type. One of these is useful at 2 AM.

+ #strong[Log what you do.] `Write-Verbose` for normal operations, `Write-Warning` for recoverable problems, `Write-Error` for failures. Users who need detail run with `-Verbose`. Users who don’t, get clean output.

+ #strong[Leave breadcrumbs.] At the start of every script run, log: who ran it, from where, with what parameters. At the end, log: what changed, what was skipped, how long it took. Operational logs are your alibi.

```powershell
# Standard script preamble (add to every production script)
$scriptStart = Get-Date
Write-Verbose "[$($MyInvocation.MyCommand.Name)] Started by $env:USERNAME on $env:COMPUTERNAME"
Write-Verbose "[$($MyInvocation.MyCommand.Name)] Parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"

# ... script body ...

$elapsed = [math]::Round((New-TimeSpan $scriptStart (Get-Date)).TotalSeconds, 1)
Write-Verbose "[$($MyInvocation.MyCommand.Name)] Completed in ${elapsed}s"
```

#horizontalrule

== Exercises
<exercises-15>
=== \[Ch-16, Ex-1\] Simple: Temp File Cleanup
<ch-16-ex-1-simple-temp-file-cleanup>
Write a script that finds all files in a given directory whose `LastWriteTime` is older than 7 days and removes them. Test it by creating a file, backdating its timestamp to 10 days ago, and verifying it gets removed while a fresh file in the same directory is left alone.

=== \[Ch-16, Ex-2\] Normal: Backup with Date-Stamped Folder and Retention
<ch-16-ex-2-normal-backup-with-date-stamped-folder-and-retention>
Write a backup script that: - Copies a source directory into a date-stamped subfolder under a backup root (folder name format: `yyyy-MM-dd_HHmmss`) - After copying, prunes any backup folders whose `CreationTime` is older than a configurable retention period (default: 14 days)

Verify that the backup folder is created and that the files it contains match the source.

=== \[Ch-16, Ex-3\] Advanced: System Inventory HTML Report
<ch-16-ex-3-advanced-system-inventory-html-report>
Build a script that collects the following inventory data and produces a structured `PSCustomObject`: - Hostname, OS, PowerShell version - Total running process count - Total running service count - System uptime in hours (rounded to 1 decimal) - Total working set of all processes in MB

The object must have at least 5 properties and `Processes` must be greater than 0.

=== \[Ch-16, Ex-4\] Extreme: Service Monitor with Drift Detection
<ch-16-ex-4-extreme-service-monitor-with-drift-detection>
Build a service drift detector. Given a #strong[baseline] list of services with expected statuses, and a #strong[current snapshot] of the same services, produce a list of services whose current status differs from the baseline. Verify that when `ServiceB` is `Running` in the baseline but `Stopped` in the current state, your drift list contains exactly one entry for `ServiceB` with the correct expected and actual values.

#horizontalrule

== Key Takeaways
<key-takeaways-8>
- `SupportsShouldProcess` + `-WhatIf` is mandatory for any script that deletes or modifies files. It costs one line and saves your job.
- `Set-StrictMode -Version Latest` + `$ErrorActionPreference = 'Stop'` at the top of every production script. No exceptions.
- Date-stamp your backup folders (`yyyy-MM-dd_HHmmss`). Prune with `CreationTime -lt $cutoff`. Retention policy is not optional.
- `ConvertTo-Html -Fragment` turns any object collection into an HTML table. Combine fragments for full reports with zero HTML knowledge required.
- `Get-Service` + `ConvertTo-Json` gives you a baseline. Compare against it with `Where-Object` to detect drift. This pattern scales to disks, firewall rules, installed software, registry keys – anything you can enumerate.
- Comment-based help is not documentation overhead. It is the minimum viable act of respect for whoever runs your script at 2 AM. Which might be you.

#horizontalrule

#emph[Next up: #link("17-remoting.md")[Chapter 17 – Remoting and Remote Management], where we learn that PowerShell can run your automation recipes on every server in the fleet simultaneously, from one terminal.]

= Chapter 17: DevOps & CI/CD
<chapter-17-devops-cicd>
Sam deployed to production with `Copy-Item`. Rina watched it happen. This chapter is about what comes after that conversation.

#figure([#image("images/ch-17-opener.png")],
  caption: [
    chapter-opener
  ]
)

#horizontalrule

== Why CI/CD Exists
<why-cicd-exists>
Every team has a version of Sam’s deploy script. Sometimes it’s `robocopy`. Sometimes it’s a Word document titled "HOW TO DEPLOY (DO NOT DELETE)". Sometimes it’s tribal knowledge held by the one person who’s on vacation when production breaks at 3 AM.

Continuous Integration / Continuous Delivery (CI/CD) replaces that with a pipeline: a reproducible, automated sequence of lint → test → build → deploy that runs every time someone pushes code. The machine does the ceremony. Humans review the results.

#figure([#image("images/ch-17-pipeline-overview.png")],
  caption: [
    cicd-pipeline-overview
  ]
)

#horizontalrule

== Pester: PowerShell’s Testing Framework
<pester-powershells-testing-framework>
Pester is the de-facto testing framework for PowerShell. It ships with Windows and is available on all platforms. If you write PowerShell professionally and you’re not writing Pester tests, you’re one bad refactor away from a very interesting incident report.

=== The Anatomy of a Pester Test
<the-anatomy-of-a-pester-test>
```powershell
Describe "Get-Square" {
    It "squares positive numbers" {
        function Get-Square { param([int]$n) $n * $n }
        Get-Square 5 | Should -Be 25
    }

    It "handles zero" {
        Get-Square 0 | Should -Be 0
    }

    It "squares negative numbers" {
        Get-Square -3 | Should -Be 9
    }
}
```

The three building blocks:

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Block], [Purpose],
  [`Describe`],
  [Top-level grouping — usually one per function or module],
  [`Context`],
  [Sub-grouping within a Describe — use for scenarios],
  [`It`],
  [A single test case — must assert at least one thing],
)
]

=== Should Assertions
<should-assertions>
`Should` is the assertion engine. It reads like English and throws on failure:

```powershell
# Equality
$result | Should -Be 42
$result | Should -Not -Be 0

# Type checking
$result | Should -BeOfType [int]

# String matching
$msg | Should -BeLike '*error*'
$msg | Should -Match '^\d{4}-\d{2}-\d{2}'   # regex

# Null / existence
$obj | Should -Not -BeNullOrEmpty
$obj | Should -BeNull

# Boolean shortcuts
$flag | Should -BeTrue
$flag | Should -BeFalse

# Collections
$list | Should -Contain 'web01'
$list | Should -HaveCount 3

# Exceptions
{ Invoke-Risky -BadParam } | Should -Throw
{ Invoke-Risky -BadParam } | Should -Throw '*required*'
```

The `{ ... } | Should -Throw` pattern wraps a scriptblock so Pester can catch the exception and assert against it. If you call the function directly (without the braces), the exception propagates and the test errors rather than fails – a subtle but important distinction.

=== Context Blocks and BeforeEach / AfterEach
<context-blocks-and-beforeeach-aftereach>
```powershell
Describe "Invoke-Deploy" {
    BeforeAll {
        # Runs once before all tests in this Describe
        $testEnv = 'staging'
    }

    Context "when target is reachable" {
        BeforeEach {
            # Runs before each It in this Context
            $mockResult = [PSCustomObject]@{ Success = $true; Message = 'OK' }
        }

        It "returns success object" {
            $mockResult.Success | Should -BeTrue
        }
    }

    Context "when target is unreachable" {
        It "throws a meaningful error" {
            { throw 'Host unreachable: db01' } | Should -Throw '*unreachable*'
        }
    }

    AfterAll {
        # Runs once after all tests in this Describe
        Remove-Variable testEnv -ErrorAction SilentlyContinue
    }
}
```

=== Mocking
<mocking>
Mocking replaces a real command with a fake one for the duration of a test. It’s how you test network calls, file writes, or anything with side effects without actually doing the thing.

```powershell
Describe "Send-Alert" {
    It "calls Send-MailMessage when alert level is Critical" {
        Mock Send-MailMessage { }   # Do nothing, capture the call

        function Send-Alert {
            param([string]$Level, [string]$Message)
            if ($Level -eq 'Critical') {
                Send-MailMessage -To 'ops@example.com' -Subject $Message -From 'alerts@example.com'
            }
        }

        Send-Alert -Level 'Critical' -Message 'Disk 95% full'

        Should -Invoke Send-MailMessage -Times 1 -Exactly
    }

    It "does not email for Warning level" {
        Mock Send-MailMessage { }

        Send-Alert -Level 'Warning' -Message 'Disk 70% full'

        Should -Invoke Send-MailMessage -Times 0
    }
}
```

`Mock` must be called inside a `Describe` block. The mock is scoped to that `Describe` and cleaned up automatically. `Should -Invoke` (Pester 5+) asserts how many times the mock was called.

=== Running Pester
<running-pester>
```powershell
# Run all tests in the current directory tree
Invoke-Pester

# Run a specific file
Invoke-Pester ./tests/MyModule.Tests.ps1

# Run with detailed output
Invoke-Pester -Output Detailed

# CI mode: exit code reflects pass/fail, produces NUnit XML
Invoke-Pester -CI

# Code coverage
Invoke-Pester -CodeCoverage ./src/MyModule.psm1 -CodeCoverageOutputFile coverage.xml
```

The `-CI` switch is the one you use in pipelines. It sets `$LASTEXITCODE` to a non-zero value on failure, which is what build agents look for.

=== Code Coverage
<code-coverage>
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './src/*.ps1'
$config.CodeCoverage.CoveragePercentTarget = 80   # Fail below 80%
$config.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $config
```

A coverage target of 80% is a pragmatic floor. 100% is a vanity metric – it measures lines executed, not logic branches validated. Aim to cover the paths that matter: happy path, error conditions, and edge cases.

#horizontalrule

== PSScriptAnalyzer: The Linter
<psscriptanalyzer-the-linter>
PSScriptAnalyzer is to PowerShell what ESLint is to JavaScript: a static analysis tool that catches bad practices before they reach production. It ships with VS Code’s PowerShell extension and runs in CI.

```powershell
# Install (if not already present)
Install-Module PSScriptAnalyzer -Force

# Analyze a single file
Invoke-ScriptAnalyzer -Path ./Deploy-Service.ps1

# Analyze an entire directory, recursively
Invoke-ScriptAnalyzer -Path ./src -Recurse

# Analyze with specific severity threshold
Invoke-ScriptAnalyzer -Path ./src -Recurse -Severity Error, Warning

# Exit with non-zero code if issues found (for CI)
$issues = Invoke-ScriptAnalyzer -Path ./src -Recurse -Severity Error
if ($issues.Count -gt 0) {
    $issues | Format-Table -AutoSize
    exit 1
}
```

=== Common Rules You’ll Hit
<common-rules-youll-hit>
#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Rule], [What It Catches], [Why It Matters],
  [`AvoidUsingWriteHost`],
  [`Write-Host` in scripts],
  [Breaks pipeline; use `Write-Output` or `Write-Verbose`],
  [`PSUseDeclaredVarsMoreThanAssignments`],
  [Variables assigned but never used],
  [Probably a typo in the variable name],
  [`AvoidUsingInvokeExpression`],
  [`Invoke-Expression`],
  [Code injection vector],
  [`UseShouldProcessForStateChangingFunctions`],
  [Mutating functions without `-WhatIf`],
  [Makes scripts unauditable],
  [`AvoidUsingPlainTextForPassword`],
  [Password params typed as `[string]`],
  [Use `[SecureString]`],
  [`PSUseApprovedVerbs`],
  [Functions with non-standard verbs],
  [Breaks discoverability conventions],
)
]

```powershell
# Suppress a specific rule inline (use sparingly)
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Interactive installer -- Write-Host intentional'
)]
param()

Write-Host "Welcome to the installer" -ForegroundColor Cyan
```

The inline suppression attribute is not a "get out of jail free" card. Every suppression is a decision that should be documented with a `Justification`. In code review, an unexplained suppression is a red flag.

#horizontalrule

== `#Requires` Statements
<requires-statements>
`#Requires` is a declaration at the top of a script that tells PowerShell what it needs to run. If the requirements aren’t met, the script stops immediately with a clear error – before executing a single line of your code.

```powershell
#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator
#Requires -PSEdition Core
```

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Directive], [Validates],
  [`-Version 7.4`],
  [PowerShell version \>\= 7.4],
  [`-Modules ModuleName`],
  [Module is installed and importable],
  [`-Modules @{ModuleName='X'; ModuleVersion='5.0'}`],
  [Specific minimum version],
  [`-RunAsAdministrator`],
  [Script is running elevated],
  [`-PSEdition Core`],
  [Running on PS Core (not Windows PowerShell 5.x)],
)
]

Multiple `#Requires` lines are allowed and all are checked. The check happens at parse time, not at runtime, so you can’t conditionally bypass it. That’s the feature: it’s a hard contract, not a suggestion.

```powershell
#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'SqlServer'; ModuleVersion = '22.0' }
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Automated database backup script.
    Run as administrator with SqlServer module >= 22.0 on PS 7.4+.
#>
param(
    [Parameter(Mandatory)]
    [string]$ServerInstance,

    [string]$BackupPath = 'D:\Backups'
)
```

Use `#Requires` on every script that has real prerequisites. The two minutes it takes to add these lines saves the next person from discovering the prerequisites the hard way at 2 AM.

#horizontalrule

== Build Scripts: The `build.ps1` Pattern
<build-scripts-the-build.ps1-pattern>
A build script is a PowerShell script that orchestrates all the steps to go from source code to a deployable artifact. It replaces the mental model of "run these five commands in the right order" with one command: `./build.ps1`.

#figure([#image("images/ch-17-build-flow.png")],
  caption: [
    build-script-flow
  ]
)

```powershell
#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Version   = '1.0.0',
    [string]$OutputDir = './dist',
    [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Assert-Clean {
    param([int]$ExitCode, [string]$Step)
    if ($ExitCode -ne 0) {
        Write-Error "$Step failed (exit $ExitCode). Stopping build."
        exit $ExitCode
    }
}

# ── Step 1: Lint ──────────────────────────────────────────────────────────────

Write-Step "Linting source files"
$lintIssues = Invoke-ScriptAnalyzer -Path ./src -Recurse -Severity Error, Warning
if ($lintIssues.Count -gt 0) {
    $lintIssues | Format-Table RuleName, Severity, ScriptName, Line -AutoSize
    Write-Error "Lint failed: $($lintIssues.Count) issue(s) found."
    exit 1
}
Write-Host "Lint: clean" -ForegroundColor Green

# ── Step 2: Test ──────────────────────────────────────────────────────────────

if (-not $SkipTests) {
    Write-Step "Running Pester tests"
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = './tests'
    $pesterConfig.Run.Exit = $true          # exit 1 on failure
    $pesterConfig.Output.Verbosity = 'Minimal'
    $pesterResult = Invoke-Pester -Configuration $pesterConfig -PassThru
    if ($pesterResult.FailedCount -gt 0) {
        Write-Error "Tests failed: $($pesterResult.FailedCount) failure(s)."
        exit 1
    }
    Write-Host "Tests: $($pesterResult.PassedCount) passed" -ForegroundColor Green
}

# ── Step 3: Build ─────────────────────────────────────────────────────────────

Write-Step "Building module to $OutputDir"
if ($PSCmdlet.ShouldProcess($OutputDir, "Copy module files")) {
    if (Test-Path $OutputDir) { Remove-Item $OutputDir -Recurse -Force }
    New-Item $OutputDir -ItemType Directory -Force | Out-Null
    Copy-Item ./src/* $OutputDir -Recurse

    # Patch version in the module manifest
    $manifest = Join-Path $OutputDir 'MyModule.psd1'
    if (Test-Path $manifest) {
        (Get-Content $manifest) -replace "ModuleVersion\s*=\s*'[^']*'",
            "ModuleVersion = '$Version'" |
            Set-Content $manifest
    }

    Write-Host "Build: MyModule v$Version -> $OutputDir" -ForegroundColor Green
}
```

Key design decisions in this pattern:

+ `Set-StrictMode -Version Latest` – catches undeclared variables and other loose-PowerShell traps at build time, not production time.
+ `$ErrorActionPreference = 'Stop'` – any non-terminating error becomes terminating. The build fails loudly.
+ `SupportsShouldProcess` on the script itself – lets you dry-run the build step (`./build.ps1 -WhatIf`) without actually copying files.
+ Each phase writes a clear status line so the build log is readable at a glance.

#horizontalrule

== GitHub Actions for PowerShell
<github-actions-for-powershell>
GitHub Actions uses YAML to define workflows. A workflow is a collection of jobs; each job is a collection of steps. PowerShell runs in steps via the `pwsh` shell.

```yaml
# .github/workflows/ci.yml
name: PowerShell CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest   # pwsh is pre-installed on GitHub-hosted runners

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Pester
        shell: pwsh
        run: |
          Install-Module Pester -MinimumVersion 5.5 -Force -Scope CurrentUser

      - name: Lint
        shell: pwsh
        run: |
          Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
          $issues = Invoke-ScriptAnalyzer -Path ./src -Recurse -Severity Error
          if ($issues.Count -gt 0) {
            $issues | Format-Table -AutoSize
            exit 1
          }

      - name: Test
        shell: pwsh
        run: |
          Invoke-Pester -CI -Output Detailed

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: pester-results
          path: testResults.xml
```

=== Multi-Platform Matrix
<multi-platform-matrix>
One of the best features of GitHub Actions for PowerShell shops is cross-platform testing in one workflow:

```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [ ubuntu-latest, windows-latest, macos-latest ]
        ps-version: [ '7.4', '7.5' ]

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup PowerShell ${{ matrix.ps-version }}
        uses: bjompen/UpdatePWSHAction@v1
        with:
          ReleaseVersion: ${{ matrix.ps-version }}

      - name: Test
        shell: pwsh
        run: Invoke-Pester -CI
```

=== Caching Modules
<caching-modules>
Module installation on every run adds 30-90 seconds. Cache them:

```yaml
      - name: Cache PowerShell modules
        uses: actions/cache@v4
        with:
          path: ~/.local/share/powershell/Modules
          key: ${{ runner.os }}-psmodules-${{ hashFiles('requirements.psd1') }}
          restore-keys: |
            ${{ runner.os }}-psmodules-

      - name: Install modules from requirements
        shell: pwsh
        run: |
          if (Test-Path ./requirements.psd1) {
              Install-Module PSDepend -Force -Scope CurrentUser
              Invoke-PSDepend ./requirements.psd1 -Force
          }
```

#horizontalrule

== Azure DevOps Pipelines
<azure-devops-pipelines>
Azure DevOps uses the same concept as GitHub Actions but with different YAML syntax. The PowerShell step uses the built-in `PowerShell@2` task (for Windows PowerShell) or `pwsh` shell on `script` tasks (for PS Core).

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: ubuntu-latest

stages:
  - stage: CI
    displayName: 'Lint, Test, Build'
    jobs:
      - job: Build
        steps:
          - task: PowerShell@2
            displayName: 'Install dependencies'
            inputs:
              targetType: inline
              pwsh: true
              script: |
                Install-Module Pester -MinimumVersion 5.5 -Force -Scope CurrentUser
                Install-Module PSScriptAnalyzer -Force -Scope CurrentUser

          - task: PowerShell@2
            displayName: 'Lint'
            inputs:
              targetType: inline
              pwsh: true
              script: |
                $issues = Invoke-ScriptAnalyzer -Path '$(Build.SourcesDirectory)/src' `
                    -Recurse -Severity Error
                if ($issues.Count -gt 0) {
                    $issues | Format-Table -AutoSize
                    Write-Error "Lint failed"
                    exit 1
                }

          - task: PowerShell@2
            displayName: 'Pester Tests'
            inputs:
              targetType: inline
              pwsh: true
              script: |
                $config = New-PesterConfiguration
                $config.Run.Path = '$(Build.SourcesDirectory)/tests'
                $config.TestResult.Enabled = $true
                $config.TestResult.OutputPath = '$(Build.ArtifactStagingDirectory)/test-results.xml'
                $config.TestResult.OutputFormat = 'NUnitXml'
                Invoke-Pester -Configuration $config

          - task: PublishTestResults@2
            displayName: 'Publish test results'
            condition: always()
            inputs:
              testResultsFormat: NUnit
              testResultsFiles: '$(Build.ArtifactStagingDirectory)/test-results.xml'
```

The `PublishTestResults@2` task ingests the NUnit XML and shows pass/fail counts in the Azure DevOps build summary UI – no log-scraping required.

=== Key Differences: GitHub Actions vs Azure DevOps
<key-differences-github-actions-vs-azure-devops>
#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [], [GitHub Actions], [Azure DevOps],
  [PowerShell shell],
  [`shell: pwsh` on any step],
  [`pwsh: true` on `PowerShell@2` task],
  [Variables],
  [`${{ env.VAR }}`],
  [`$(VAR)`],
  [Artifacts],
  [`upload-artifact@v4`],
  [`PublishBuildArtifacts@1`],
  [Test results],
  [Third-party action],
  [`PublishTestResults@2` built-in],
  [Free tier],
  [2000 min/month (public repos: unlimited)],
  [1800 min/month],
)
]

#horizontalrule

== Release Automation
<release-automation>
Once the pipeline is green, release automation handles versioning, changelog generation, and publishing – without a human clicking buttons.

=== Semantic Versioning with `Update-ModuleManifest`
<semantic-versioning-with-update-modulemanifest>
```powershell
function Step-ModuleVersion {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$Component = 'Patch'
    )

    $manifest = Import-PowerShellDataFile $ManifestPath
    $current  = [version]$manifest.ModuleVersion

    $newVersion = switch ($Component) {
        'Major' { [version]::new($current.Major + 1, 0, 0) }
        'Minor' { [version]::new($current.Major, $current.Minor + 1, 0) }
        'Patch' { [version]::new($current.Major, $current.Minor, $current.Build + 1) }
    }

    if ($PSCmdlet.ShouldProcess($ManifestPath, "Bump $Component version to $newVersion")) {
        Update-ModuleManifest -Path $ManifestPath -ModuleVersion $newVersion
        Write-Host "Version: $current -> $newVersion"
    }

    return $newVersion
}
```

=== Publishing to a Repository
<publishing-to-a-repository>
```powershell
# Publish to PSGallery (requires API key in $env:PSGALLERY_API_KEY)
function Publish-ModuleToGallery {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [string]$Repository = 'PSGallery'
    )

    if ($PSCmdlet.ShouldProcess($ModulePath, "Publish to $Repository")) {
        $apiKey = $env:PSGALLERY_API_KEY
        if (-not $apiKey) { throw "PSGALLERY_API_KEY environment variable not set" }

        Publish-Module -Path $ModulePath -Repository $Repository -NuGetApiKey $apiKey
        Write-Host "Published: $(Split-Path $ModulePath -Leaf) -> $Repository" -ForegroundColor Green
    }
}
```

In CI, the API key comes from a secret/variable in the pipeline configuration, never from a checked-in file. The `-WhatIf` support means you can dry-run the full release pipeline in a pull request job without actually publishing anything.

#horizontalrule

== Putting It Together: A Full Pipeline View
<putting-it-together-a-full-pipeline-view>
```
Developer pushes to feature branch
    |
    v
GitHub Actions / Azure DevOps triggers
    |
    +-- Lint (PSScriptAnalyzer)       <-- fails fast on code quality
    |
    +-- Test (Pester -CI)             <-- fails fast on correctness
    |
    +-- Build (build.ps1)             <-- packages module to dist/
    |
    +-- [on merge to main only]
         |
         +-- Version bump (Step-ModuleVersion -Component Patch)
         |
         +-- Publish (Publish-Module to PSGallery)
         |
         +-- Create GitHub Release (gh release create)
```

Max walks over to Sam’s desk two weeks after the initial conversation. Sam’s CI dashboard is green. "I see your pipeline passed," Max says. Sam nods: "48 tests, zero lint issues, published to the gallery in 90 seconds." Max: "Good. Now write the rollback procedure." Some things never change.

#figure([#image("images/ch-17-green-pipeline.png")],
  caption: [
    green-pipeline
  ]
)

#horizontalrule

== Exercises
<exercises-16>
=== \[Ch-17, Ex-1\] Simple: Write a Pester Test for a Function
<ch-17-ex-1-simple-write-a-pester-test-for-a-function>
Write a Pester `Describe` block that tests a `Get-Square` function. The function takes an integer parameter and returns its square. Cover: a positive number, zero, and a negative number.

=== \[Ch-17, Ex-2\] Normal: Add PSScriptAnalyzer to a Build Script
<ch-17-ex-2-normal-add-psscriptanalyzer-to-a-build-script>
Write an `Invoke-BuildLint` function that: - Accepts a `-Path` parameter pointing to a directory - Uses `Get-ChildItem` to find all `.ps1` files recursively - Simulates a lint check: flag any file containing `Write-Host` as a `Warning` with rule `AvoidUsingWriteHost` - Returns a collection of issue objects with `File`, `Rule`, and `Severity` properties

Test it against a directory containing one "bad" file (`Write-Host`) and one "good" file (`Write-Output`). Verify exactly one issue is returned.

=== \[Ch-17, Ex-3\] Advanced: Create a GitHub Actions Workflow
<ch-17-ex-3-advanced-create-a-github-actions-workflow>
Build a hashtable that represents a valid GitHub Actions CI workflow for PowerShell: - Name: `PowerShell CI` - Triggers: `push` and `pull_request` on `main` - One job named `test` running on `ubuntu-latest` - Two steps: `actions/checkout@v4`, then a `pwsh` step that runs `Invoke-Pester -CI`

Validate the structure with assertions: workflow name, runner OS, and step count.

=== \[Ch-17, Ex-4\] Extreme: Full CI/CD Pipeline (Dry-Run)
<ch-17-ex-4-extreme-full-cicd-pipeline-dry-run>
Write an `Invoke-CIPipeline` function that: - Accepts `-ModulePath` and `-Version` parameters - Supports `-WhatIf` via `SupportsShouldProcess` - Runs three phases in order: Lint (always passes in this exercise), Test (always passes), Build - During the Build phase, uses `$PSCmdlet.ShouldProcess` to gate the actual work - Returns a `[PSCustomObject]` with `Lint`, `Test`, `Build`, and `Version` properties - When run with `-WhatIf`: `Build` should be `'DryRun'` instead of `'Built'`

Invoke it with `-WhatIf` and assert the dry-run behavior.

#horizontalrule

== Key Takeaways
<key-takeaways-9>
- Pester’s `Describe / Context / It / Should` hierarchy maps directly to how you think about behavior. Write tests that read like specifications.
- `Should -Throw` requires a scriptblock: `{ Risky-Call } | Should -Throw`. Without braces the exception escapes.
- PSScriptAnalyzer’s `AvoidUsingWriteHost` is not pedantic – `Write-Host` bypasses the pipeline and makes output untestable.
- `#Requires` is a hard contract enforced at parse time. Use it on every script with real prerequisites.
- `build.ps1` with `Set-StrictMode` and `$ErrorActionPreference = 'Stop'` turns loose scripts into auditable build artifacts.
- GitHub Actions uses `shell: pwsh`. Azure DevOps uses `pwsh: true` on `PowerShell@2`. Both run cross-platform.
- `SupportsShouldProcess` + `$PSCmdlet.ShouldProcess(...)` enables `-WhatIf` on any mutating function. Use it. CI pipelines can dry-run before merging.
- The publish step belongs on `main` merges only, behind a secret API key, never in PR jobs.

#horizontalrule

#emph[Next up: #link("18-module-development.md")[Chapter 18 – Module Development and Distribution], where Sam finally learns that a folder full of `.ps1` files is not a module.]

= Appendices
<appendices>
= Appendix A: PowerShell Cheat Sheet
<appendix-a-powershell-cheat-sheet>
#blockquote[
#emph[The card you tape to your monitor until the cmdlets are burned into your hippocampus.]
]

#figure([#image("images/app-A-cmdlet-quickref.png")],
  caption: [
    app-a-cmdlet-quickref
  ]
)

#horizontalrule

== Top 30 Cmdlets
<top-30-cmdlets>
#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Cmdlet], [What it does],
  [`Get-Help`],
  [Displays help for any cmdlet, function, or concept — your first stop, every time],
  [`Get-Command`],
  [Lists all available commands; filter with `-Verb`, `-Noun`, or `-Name` wildcards],
  [`Get-Member`],
  [Shows the properties and methods of whatever object is piped in],
  [`Get-Process`],
  [Returns running processes as rich `System.Diagnostics.Process` objects],
  [`Get-Service`],
  [Lists Windows services with status, start type, and display name],
  [`Get-ChildItem`],
  [Lists files and directories (aliased `ls`/`dir`); use `-Recurse` and `-Filter`],
  [`Get-Content`],
  [Reads a file line by line into an array of strings],
  [`Set-Content`],
  [Writes (overwrites) a file with the supplied value],
  [`Add-Content`],
  [Appends to a file without overwriting it],
  [`Copy-Item`],
  [Copies files, directories, or registry keys],
  [`Move-Item`],
  [Moves (renames) files, directories, or registry keys],
  [`Remove-Item`],
  [Deletes files, directories, or registry keys; add `-Recurse -Force` with care],
  [`New-Item`],
  [Creates a new file, directory, symlink, or registry key],
  [`Rename-Item`],
  [Renames a file or directory in place],
  [`Test-Path`],
  [Returns `$true`/`$false` — the civilised way to check existence before acting],
  [`Where-Object`],
  [Filters pipeline objects by a condition (alias `where` or `?`)],
  [`Select-Object`],
  [Picks specific properties, limits results, or adds calculated columns],
  [`Sort-Object`],
  [Sorts pipeline objects by one or more properties],
  [`Group-Object`],
  [Groups objects by property value and returns count + members],
  [`Measure-Object`],
  [Computes count, sum, min, max, average on numeric properties],
  [`ForEach-Object`],
  [Runs a script block once per pipeline object (alias `foreach` or `%`)],
  [`Format-Table`],
  [Renders output as a table (for display — never pipe this into further processing)],
  [`Format-List`],
  [Renders output as property: value pairs; great for wide objects],
  [`Out-File`],
  [Redirects pipeline output to a text file],
  [`Export-Csv`],
  [Serialises objects to CSV with a header row],
  [`Import-Csv`],
  [Reads a CSV and returns `PSCustomObject` rows — headers become properties],
  [`ConvertTo-Json`],
  [Converts objects to a JSON string],
  [`ConvertFrom-Json`],
  [Parses a JSON string into `PSCustomObject` objects],
  [`Invoke-RestMethod`],
  [Sends HTTP requests and auto-deserialises JSON/XML responses],
  [`Write-Host`],
  [Writes directly to the console (bypasses the pipeline — use sparingly)],
)
]

#horizontalrule

== Operator Comparison Table
<operator-comparison-table>
#figure([#image("images/app-A-operator-grid.png")],
  caption: [
    app-a-operator-grid
  ]
)

#align(center)[#table(
  columns: 5,
  align: (col, row) => (auto,auto,auto,auto,auto,).at(col),
  inset: 6pt,
  [Operation], [PowerShell], [Python], [Bash], [C\#],
  [Equal],
  [`-eq`],
  [`==`],
  [`==` (inside `[[ ]]`)],
  [`==`],
  [Not equal],
  [`-ne`],
  [`!=`],
  [`!=`],
  [`!=`],
  [Greater than],
  [`-gt`],
  [`>`],
  [`-gt`],
  [`>`],
  [Less than],
  [`-lt`],
  [`<`],
  [`-lt`],
  [`<`],
  [Greater or equal],
  [`-ge`],
  [`>=`],
  [`-ge`],
  [`>=`],
  [Less or equal],
  [`-le`],
  [`<=`],
  [`-le`],
  [`<=`],
  [Logical AND],
  [`-and`],
  [`and`],
  [`&&`],
  [`&&`],
  [Logical OR],
  [`-or`],
  [`or`],
  [`\|\|`],
  [`\|\|`],
  [Logical NOT],
  [`-not` / `!`],
  [`not` / `!`],
  [`!`],
  [`!`],
  [Bitwise AND],
  [`-band`],
  [`&`],
  [`&`],
  [`&`],
  [Bitwise OR],
  [`-bor`],
  [`\|`],
  [`\|`],
  [`\|`],
  [String contains],
  [`-like '*x*'`],
  [`'x' in s`],
  [`[[ $s == *x* ]]`],
  [`s.Contains("x")`],
  [Regex match],
  [`-match 'pattern'`],
  [`re.search(...)`],
  [`[[ $s =~ pattern ]]`],
  [`Regex.IsMatch(...)`],
  [Case-insensitive eq],
  [`-eq` (default)],
  [`s.lower()==...`],
  [n/a],
  [`StringComparison.OrdinalIgnoreCase`],
  [Case-sensitive eq],
  [`-ceq`],
  [`==`],
  [`==`],
  [`==`],
  [Null / empty check],
  [`$x -eq $null`],
  [`x is None`],
  [`[ -z "$x" ]`],
  [`x == null`],
  [Range],
  [`1..10`],
  [`range(1, 11)`],
  [`{1..10}`],
  [`Enumerable.Range(1,10)`],
)
]

#horizontalrule

== Pipeline Patterns
<pipeline-patterns>
One-liners that do the heavy lifting. Study them; they are the grammar of PowerShell.

```powershell
# Filter: keep only what matches
Get-Process | Where-Object { $_.CPU -gt 10 }

# Short form (alias ?)
Get-Process | ? CPU -gt 10

# Sort ascending / descending
Get-ChildItem | Sort-Object Length -Descending

# Sort by multiple properties
Get-Process | Sort-Object -Property CPU, WorkingSet -Descending

# Group and count
Get-Service | Group-Object Status

# Measure: count, sum, avg
Get-ChildItem -Recurse | Measure-Object -Property Length -Sum -Average

# Select specific properties + calculated column
Get-Process | Select-Object Name, Id, @{N='MB'; E={ [math]::Round($_.WorkingSet/1MB, 1) }}

# Select first / last N
Get-ChildItem | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# Export to CSV
Get-Process | Select-Object Name, Id, CPU | Export-Csv -Path .\procs.csv -NoTypeInformation

# Export to JSON
Get-Process | Select-Object Name, Id, CPU | ConvertTo-Json | Out-File .\procs.json

# Unique values only
Get-Process | Select-Object -ExpandProperty Company | Sort-Object -Unique

# Pipeline with ForEach
1..5 | ForEach-Object { "Item $_" }

# Nested pipeline: find large log files and report size in MB
Get-ChildItem C:\Logs -Recurse -Filter *.log |
    Where-Object { $_.Length -gt 10MB } |
    Select-Object FullName, @{N='SizeMB'; E={ [math]::Round($_.Length/1MB,2) }} |
    Sort-Object SizeMB -Descending
```

#horizontalrule

== String Operations Cheat Table
<string-operations-cheat-table>
#align(center)[#table(
  columns: 4,
  align: (col, row) => (auto,auto,auto,auto,).at(col),
  inset: 6pt,
  [Operation], [Syntax], [Example], [Result],
  [Interpolation],
  [`"$var"`],
  [`"Hello $name"`],
  [`Hello Sam`],
  [Expression interpolation],
  [`"$(expr)"`],
  [`"$(1+1) items"`],
  [`2 items`],
  [No interpolation],
  [`'literal'`],
  [`'Hello $name'`],
  [`Hello $name`],
  [Replace (literal)],
  [`-replace 'old','new'`],
  [`'foo bar' -replace 'bar','baz'`],
  [`foo baz`],
  [Replace (regex)],
  [`-replace 'pattern','new'`],
  [`'a1b2' -replace '\d',''`],
  [`ab`],
  [Case-sensitive replace],
  [`-creplace`],
  [`'FooFoo' -creplace 'Foo','X'`],
  [`XX`],
  [Split on character],
  [`-split ','`],
  [`'a,b,c' -split ','`],
  [`@('a','b','c')`],
  [Split with limit],
  [`-split ',', 2`],
  [`'a,b,c' -split ',', 2`],
  [`@('a','b,c')`],
  [Split on regex],
  [`-split '\s+'`],
  [`'a  b   c' -split '\s+'`],
  [`@('a','b','c')`],
  [Join array],
  [`-join ','`],
  [`'a','b','c' -join ','`],
  [`a,b,c`],
  [Join with Join-String],
  [`\| Join-String -Sep '; '`],
  [`1,2,3 \| Join-String -Sep '; '`],
  [`1; 2; 3`],
  [Format string],
  [`-f` operator],
  [`"Hi {0}, you are {1}" -f 'Sam', 30`],
  [`Hi Sam, you are 30`],
  [Uppercase],
  [`.ToUpper()`],
  [`'hello'.ToUpper()`],
  [`HELLO`],
  [Lowercase],
  [`.ToLower()`],
  [`'HELLO'.ToLower()`],
  [`hello`],
  [Trim whitespace],
  [`.Trim()`],
  [`'  hi  '.Trim()`],
  [`hi`],
  [Starts with],
  [`.StartsWith('x')`],
  [`'xbox'.StartsWith('x')`],
  [`True`],
  [Ends with],
  [`.EndsWith('x')`],
  [`'xbox'.EndsWith('x')`],
  [`False`],
  [Length],
  [`.Length`],
  [`'hello'.Length`],
  [`5`],
  [Substring],
  [`.Substring(start, len)`],
  [`'PowerShell'.Substring(0, 5)`],
  [`Power`],
  [Index of],
  [`.IndexOf('x')`],
  [`'fox'.IndexOf('x')`],
  [`2`],
  [Contains (case-insens.)],
  [`-like '*x*'`],
  [`'PowerShell' -like '*Shell*'`],
  [`True`],
  [Contains (case-sens.)],
  [`-clike '*x*'`],
  [`'PowerShell' -clike '*shell*'`],
  [`False`],
  [Matches regex],
  [`-match`],
  [`'abc123' -match '\d+'`],
  [`True` (sets `$Matches`)],
  [Here-string],
  [`@" ... "@`],
  [Multi-line string literal],
  [—],
)
]

#horizontalrule

== File I/O One-Liners
<file-io-one-liners>
```powershell
# Read entire file as a single string
$text = Get-Content .\file.txt -Raw

# Read file as array of lines
$lines = Get-Content .\file.txt

# Read a specific number of lines
Get-Content .\huge.log -TotalCount 100

# Read last N lines (tail equivalent)
Get-Content .\app.log -Tail 50

# Write (overwrite) a file
"Hello, World!" | Set-Content .\out.txt

# Append a line
"Another line" | Add-Content .\out.txt

# Write multiple lines
$lines | Set-Content .\out.txt

# Find files by name pattern (recursive)
Get-ChildItem -Path . -Recurse -Filter '*.log'

# Find files modified in the last 24 hours
Get-ChildItem -Recurse | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }

# Find files larger than 100 MB
Get-ChildItem -Recurse | Where-Object { $_.Length -gt 100MB }

# Read CSV into objects
$data = Import-Csv .\users.csv

# Write objects to CSV
$data | Export-Csv .\output.csv -NoTypeInformation

# Read JSON
$cfg = Get-Content .\config.json -Raw | ConvertFrom-Json

# Write JSON (pretty-printed, depth 5)
$cfg | ConvertTo-Json -Depth 5 | Set-Content .\config.json

# Count lines in a file
(Get-Content .\file.txt).Count

# Search file contents (grep equivalent)
Select-String -Pattern 'ERROR' -Path .\app.log

# Recursive content search
Get-ChildItem -Recurse -Filter '*.ps1' | Select-String -Pattern 'TODO'

# Delete files older than 30 days
Get-ChildItem -Recurse |
    Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -WhatIf   # Remove -WhatIf to actually delete
```

#horizontalrule

#blockquote[
#strong[Quick tip:] When in doubt, pipe to `Get-Member`. When still in doubt, pipe to `Select-Object *`. When completely lost, pipe to `Out-GridView` and click around until it makes sense.
]

= Appendix B: Common Errors and How to Fix Them
<appendix-b-common-errors-and-how-to-fix-them>
#blockquote[
#emph[Everyone’s PowerShell journey is paved with red text. Here’s a map of the potholes.]
]

#figure([#image("images/app-B-error-anatomy.png")],
  caption: [
    app-b-error-anatomy
  ]
)

#horizontalrule

Each error below includes the exact message (as it appears in the terminal), the most common cause, a concrete fix, and a one-sentence prevention tip. Bookmark this page; you will be back.

#horizontalrule

== Error 1: The term 'X' is not recognized
<error-1-the-term-x-is-not-recognized>
```
The term 'Get-Thingo' is not recognized as a name of a cmdlet, function, script
file, or operable program. Check the spelling of the name, or if a path was
included, verify that the path is correct and try again.
```

#strong[Common cause:] Typo in the cmdlet name, a required module is not imported, or the command only exists in a newer version of PowerShell.

#strong[Fix:]

```powershell
# Check spelling with a wildcard search
Get-Command *Thingo*

# If it's in a module, import it first
Import-Module ActiveDirectory
Get-ADUser -Filter *

# Check your PowerShell version
$PSVersionTable.PSVersion
```

#strong[Prevention tip:] Use tab-completion — if PowerShell won’t complete it, it doesn’t exist in your current session.

#horizontalrule

== Error 2: Cannot bind argument to parameter 'X' because it is null
<error-2-cannot-bind-argument-to-parameter-x-because-it-is-null>
```
Cannot bind argument to parameter 'Path' because it is null.
```

#strong[Common cause:] A variable you’re passing to a cmdlet is `$null`, usually because a previous step returned nothing or a property doesn’t exist on the object.

#strong[Fix:]

```powershell
# Check before using
$file = Get-Item 'missing.txt' -ErrorAction SilentlyContinue
if ($null -ne $file) {
    Get-Content $file.FullName
}

# Or use the null-coalescing operator (PS 7+)
$path = $file?.FullName ?? 'C:\default.txt'
Get-Content $path
```

#strong[Prevention tip:] Treat every variable that comes from a function or pipeline as potentially null until proven otherwise with `$null -ne $x`.

#horizontalrule

== Error 3: Access is denied
<error-3-access-is-denied>
```
Access to the path 'C:\Windows\System32\drivers\etc\hosts' is denied.
```

#strong[Common cause:] Your PowerShell session does not have the required privileges. On Windows, many system paths require an elevated (Administrator) session.

#strong[Fix:]

```powershell
# Check if you are elevated
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Run PowerShell as Administrator, then retry
# Or use -Credential with appropriate rights
Get-Content 'C:\restricted.txt' -ErrorAction Stop
```

#strong[Prevention tip:] Open a new "Run as Administrator" terminal for anything touching system paths, services, or registry hives under `HKLM`.

#horizontalrule

== Error 4: The RPC server is unavailable
<error-4-the-rpc-server-is-unavailable>
```
[server01] Connecting to remote server server01 failed with the following error
message : The RPC server is unavailable.
```

#strong[Common cause:] WinRM is not running on the remote machine, the machine is unreachable, or a firewall is blocking TCP port 5985 (HTTP) or 5986 (HTTPS).

#strong[Fix:]

```powershell
# Test connectivity first
Test-NetConnection -ComputerName server01 -Port 5985

# On the remote machine (requires local access or GPO):
Enable-PSRemoting -Force

# If the machine is in a workgroup, add it to TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'server01' -Force
```

#strong[Prevention tip:] Run `Test-WSMan server01` before any `Invoke-Command` — it’s a fast sanity check that costs nothing.

#horizontalrule

== Error 5: Cannot convert value 'X' to type 'System.Int32'
<error-5-cannot-convert-value-x-to-type-system.int32>
```
Cannot convert value "abc" to type "System.Int32". Error: "Input string was
not in a correct format."
```

#strong[Common cause:] You are assigning or passing a string where an integer is expected — often when reading from CSV, JSON, or user input (which is always a string).

#strong[Fix:]

```powershell
# Explicit cast
[int]"42"            # 42
[int]"abc"           # throws — don't do this blindly

# Safe parse
$val = 0
if ([int]::TryParse($input, [ref]$val)) {
    "Valid: $val"
} else {
    "Not a number"
}

# When reading CSVs, cast in calculated properties
Import-Csv .\data.csv | Select-Object Name, @{N='Age'; E={ [int]$_.Age }}
```

#strong[Prevention tip:] After `Import-Csv`, always cast numeric columns — everything arrives as a string.

#horizontalrule

== Error 6: A positional parameter cannot be found
<error-6-a-positional-parameter-cannot-be-found>
```
A positional parameter cannot be found that accepts argument 'SomeValue'.
```

#strong[Common cause:] You passed a positional argument that the cmdlet doesn’t accept at that position, or you accidentally included an extra bare value.

#strong[Fix:]

```powershell
# Wrong (extra positional arg)
Get-ChildItem C:\Temp 'more stuff'

# Right: use named parameters
Get-ChildItem -Path C:\Temp -Filter '*.txt'

# Use Get-Help to see which parameters are positional
Get-Help Get-ChildItem -Parameter *
```

#strong[Prevention tip:] Name your parameters explicitly; positional arguments are convenient until they aren’t.

#horizontalrule

== Error 7: Missing closing '}' in statement block
<error-7-missing-closing-in-statement-block>
```
Missing closing '}' in statement block or type definition.
```

#strong[Common cause:] Mismatched braces in a script block, function, `if`, `foreach`, or pipeline. PowerShell counts every `{` and `}` and won’t execute until they balance.

#strong[Fix:]

```powershell
# Wrong
Get-Process | Where-Object { $_.CPU -gt 10

# Right
Get-Process | Where-Object { $_.CPU -gt 10 }

# For complex scripts, use an IDE (VS Code + PS extension) to spot mismatches
# Or test with: $null = [scriptblock]::Create($code)
```

#strong[Prevention tip:] Use VS Code with the PowerShell extension — it highlights unmatched braces in real time, before you even press Enter.

#horizontalrule

== Error 8: The variable '\$X' cannot be retrieved because it has not been set
<error-8-the-variable-x-cannot-be-retrieved-because-it-has-not-been-set>
```
The variable '$config' cannot be retrieved because it has not been set.
```

#strong[Common cause:] You are using `Set-StrictMode -Version Latest` (or a calling script is), which disallows reading undefined variables. Without strict mode this silently returns `$null`.

#strong[Fix:]

```powershell
# Initialise before use
$config = $null

# Or check first
if (Test-Path variable:config) {
    "Config is: $config"
}

# Or use -ErrorAction
$val = $undefined -as [string]   # returns $null without throwing
```

#strong[Prevention tip:] Use `Set-StrictMode -Version Latest` in all your scripts — catching uninitialised variables at development time beats debugging production surprises.

#horizontalrule

== Error 9: Cannot index into a null array
<error-9-cannot-index-into-a-null-array>
```
Cannot index into a null array.
```

#strong[Common cause:] You are doing `$array[0]` (or similar) on a variable that is `$null` rather than an empty array. This often happens when a cmdlet returns nothing.

#strong[Fix:]

```powershell
# Guard before indexing
$results = Get-ChildItem -Filter '*.xyz' -ErrorAction SilentlyContinue
if ($results -and $results.Count -gt 0) {
    $first = $results[0]
}

# Force array result even for single/zero items
$results = @(Get-ChildItem -Filter '*.xyz')
$first = $results[0]   # now safely returns $null instead of throwing
```

#strong[Prevention tip:] Wrap cmdlet calls that might return nothing in `@()` when you intend to index into the result.

#horizontalrule

== Error 10: The input object cannot be bound to any parameters
<error-10-the-input-object-cannot-be-bound-to-any-parameters>
```
The input object cannot be bound to any parameters for the command either
because the command does not take pipeline input or the value and its type
cannot be converted to a parameter type.
```

#strong[Common cause:] You piped an object to a cmdlet that doesn’t accept that type via the pipeline, or the cmdlet has no `ValueFromPipeline` parameter matching the object type.

#strong[Fix:]

```powershell
# Instead of piping the object directly, expand the property you need
Get-Process | Select-Object -ExpandProperty Name | Stop-Process -Name  # still wrong

# Use ForEach-Object to call the cmdlet explicitly
Get-Process | ForEach-Object { Stop-Process -Id $_.Id -WhatIf }

# Or use pipeline-aware alternative cmdlets
Get-ChildItem *.tmp | Remove-Item   # Remove-Item accepts pipeline input
```

#strong[Prevention tip:] Check `Get-Help <Cmdlet> -Parameter *` for parameters marked `Accept pipeline input: True` before assuming a cmdlet is pipeline-friendly.

#horizontalrule

== Error 11: Running scripts is disabled on this system
<error-11-running-scripts-is-disabled-on-this-system>
```
File C:\scripts\deploy.ps1 cannot be loaded because running scripts is
disabled on this system. For more information, see about_Execution_Policies.
```

#strong[Common cause:] The PowerShell execution policy is set to `Restricted` (the Windows default) or `AllSigned`, and your script is not signed.

#strong[Fix:]

```powershell
# Check current policy
Get-ExecutionPolicy -List

# Set for current user (recommended for dev machines)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Run a single script bypassing policy (for one-off use)
PowerShell.exe -ExecutionPolicy Bypass -File .\deploy.ps1

# In CI/CD pipelines
$env:PSExecutionPolicyPreference = 'Bypass'
```

#strong[Prevention tip:] Use `RemoteSigned` rather than `Unrestricted` — it still requires internet-downloaded scripts to be signed, which is a sensible safety net.

#horizontalrule

== Error 12: Cannot find path 'X' because it does not exist
<error-12-cannot-find-path-x-because-it-does-not-exist>
```
Cannot find path 'C:\Reports\output.csv' because it does not exist.
```

#strong[Common cause:] The file or directory path doesn’t exist — either a wrong path, an incorrect drive letter, a missing directory, or a network share that isn’t mounted.

#strong[Fix:]

```powershell
# Test before acting
if (Test-Path 'C:\Reports\output.csv') {
    Import-Csv 'C:\Reports\output.csv'
} else {
    Write-Warning "File not found — creating directory"
    New-Item -ItemType Directory -Path 'C:\Reports' -Force
}

# Resolve path to catch symlink / relative path issues
Resolve-Path '.\output.csv'
```

#strong[Prevention tip:] Build paths with `Join-Path` instead of string concatenation — it handles trailing slashes and platform separators automatically.

#horizontalrule

== Error 13: A command that prompts the user failed because the host program or the command type does not support user interaction
<error-13-a-command-that-prompts-the-user-failed-because-the-host-program-or-the-command-type-does-not-support-user-interaction>
```
A command that prompts the user failed because the host program or the command
type does not support user interaction.
```

#strong[Common cause:] A cmdlet called `Read-Host`, `Get-Credential`, or a similar interactive prompt inside a non-interactive context: a background job, a scheduled task, or a remoting session.

#strong[Fix:]

```powershell
# Pass credentials as a parameter instead of prompting
$cred = Get-Credential   # do this in an interactive session first
Invoke-Command -ComputerName server01 -Credential $cred -ScriptBlock { ... }

# In automated scripts, build a credential object from secure strings
$pwd  = ConvertTo-SecureString 'P@ssword' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('user', $pwd)

# Better yet: use a secrets manager or environment variables
$cred = [PSCredential]::new($env:SVC_USER,
        (ConvertTo-SecureString $env:SVC_PASS -AsPlainText -Force))
```

#strong[Prevention tip:] Any script that will run unattended must never call `Read-Host` — parameterise everything, then call it with those parameters from your scheduler.

#horizontalrule

== Error 14: Method invocation failed because \[null-valued expression\]
<error-14-method-invocation-failed-because-null-valued-expression>
```
You cannot call a method on a null-valued expression.
At line:5 char:1
+     $result.Trim()
```

#strong[Common cause:] Calling a .NET method (`.Trim()`, `.Length`, `.Split()`, etc.) on a variable that is `$null`. The variable was either never set or the previous step returned nothing.

#strong[Fix:]

```powershell
# Guard with null check
if ($null -ne $result) {
    $result.Trim()
}

# Use null-conditional operator (PS 7.1+)
$result?.Trim()

# Provide a default value
($result ?? '').Trim()
```

#strong[Prevention tip:] Use `$result?.Method()` null-conditional syntax in PS 7+ — it silently returns `$null` instead of throwing, and makes intent clear.

#horizontalrule

== Error 15: The module 'X' could not be loaded
<error-15-the-module-x-could-not-be-loaded>
```
The module 'Az' could not be loaded. For more information, run
'Import-Module Az'.
```

#strong[Common cause:] The module is not installed in any path listed in `$env:PSModulePath`, or it was installed for a different user/version of PowerShell.

#strong[Fix:]

```powershell
# Find if the module exists anywhere
Find-Module Az   # searches PSGallery

# Install it (current user, no admin required)
Install-Module Az -Scope CurrentUser -Force

# Check where modules are loaded from
$env:PSModulePath -split [IO.Path]::PathSeparator

# Import explicitly from a custom path
Import-Module 'C:\MyModules\MyModule.psm1'
```

#strong[Prevention tip:] Pin module versions in `#Requires -Modules @{ ModuleName='Az'; ModuleVersion='12.0.0' }` at the top of scripts that depend on specific APIs.

#horizontalrule

== Error 16: Cannot process argument transformation on parameter
<error-16-cannot-process-argument-transformation-on-parameter>
```
Cannot process argument transformation on parameter 'InputObject'. Cannot
convert value "System.String" to type "System.IO.FileInfo".
```

#strong[Common cause:] You passed a string (usually a file path) where the cmdlet expects an object of a specific .NET type, such as `FileInfo`, `DirectoryInfo`, or `PSCredential`.

#strong[Fix:]

```powershell
# Wrong: passing a string path where FileInfo is expected
$file = 'C:\log.txt'
$file.LastWriteTime   # string has no LastWriteTime

# Right: get the object first
$file = Get-Item 'C:\log.txt'
$file.LastWriteTime   # now it works

# Or cast inline
([System.IO.FileInfo]'C:\log.txt').LastWriteTime
```

#strong[Prevention tip:] When a cmdlet wants an object type, retrieve that object with `Get-Item`, `Get-Process`, etc. rather than constructing string paths yourself.

#horizontalrule

== Error 17: You cannot call a method on a null-valued expression (array variant)
<error-17-you-cannot-call-a-method-on-a-null-valued-expression-array-variant>
```
You cannot call a method on a null-valued expression.
At line:3 char:1
+     $services.Where({ $_.Status -eq 'Running' })
```

#strong[Common cause:] Using a `.Where()` or `.ForEach()` intrinsic method (the "magic" array methods) on a variable that is `$null` rather than an empty array. This is the array-flavoured cousin of Error 14.

#strong[Fix:]

```powershell
# Always initialise collection variables as arrays
$services = @(Get-Service -ErrorAction SilentlyContinue)
$running  = $services.Where({ $_.Status -eq 'Running' })

# Or use the pipeline equivalent, which handles $null gracefully
Get-Service | Where-Object { $_.Status -eq 'Running' }
```

#strong[Prevention tip:] Prefer pipeline `Where-Object` over the `.Where()` method unless you’re in a hot loop and need the performance; the pipeline version degrades gracefully when input is empty.

#horizontalrule

== Error 18: Connecting to remote server X failed
<error-18-connecting-to-remote-server-x-failed>
```
[webserver02] Connecting to remote server webserver02 failed with the
following error message: WinRM cannot complete the operation.
```

#strong[Common cause:] WinRM is enabled but the target machine name cannot be resolved by DNS, the machine is in a different domain, or the credentials don’t have permission to create a remote session.

#strong[Fix:]

```powershell
# Step-by-step diagnosis
Test-Connection webserver02 -Count 1                  # basic ping
Test-NetConnection webserver02 -Port 5985             # WinRM HTTP
Test-WSMan webserver02                                 # WinRM handshake

# Try with explicit credentials
$cred = Get-Credential
Enter-PSSession -ComputerName webserver02 -Credential $cred

# Cross-domain: specify authentication mechanism
New-PSSession -ComputerName webserver02 -Credential $cred -Authentication Negotiate
```

#strong[Prevention tip:] Build a standard `Test-WinRMReady` function that runs `Test-Connection` + `Test-WSMan` and call it before any remoting block in automated scripts.

#horizontalrule

== Error 19: Format-Table: The pipeline has been stopped
<error-19-format-table-the-pipeline-has-been-stopped>
```
Format-Table : The pipeline has been stopped.
```

#strong[Common cause:] You piped the output of `Format-Table` (or any `Format-*` cmdlet) into another processing cmdlet. `Format-*` outputs formatting directives, not objects — further processing fails.

#strong[Fix:]

```powershell
# Wrong: piping Format-Table output into Export-Csv
Get-Process | Format-Table Name, CPU | Export-Csv .\procs.csv   # broken

# Right: Select-Object, then export
Get-Process | Select-Object Name, CPU | Export-Csv .\procs.csv -NoTypeInformation

# Format-* is always the LAST thing in a pipeline
Get-Process | Select-Object Name, CPU | Format-Table
```

#strong[Prevention tip:] Treat `Format-Table`, `Format-List`, and `Format-Wide` as terminal cmdlets — nothing useful should come after them in a pipeline.

#horizontalrule

== Error 20: Cannot overwrite variable X because it is read-only
<error-20-cannot-overwrite-variable-x-because-it-is-read-only>
```
Cannot overwrite variable PSVersionTable because it is read-only or constant.
```

#strong[Common cause:] You tried to assign a value to a built-in read-only variable (`$PSVersionTable`, `$true`, `$false`, `$null`, `$PID`, etc.) or a variable your script marked as constant with `Set-Variable -Option Constant`.

#strong[Fix:]

```powershell
# Check variable options
Get-Variable PSVersionTable | Select-Object -ExpandProperty Options
# Output: ReadOnly

# If you declared it as constant/readonly by mistake:
Set-Variable -Name MyVar -Value 'original' -Option None   # remove readonly

# For built-ins: don't try to overwrite them. Use a different name.
$psVersion = $PSVersionTable.PSVersion   # copy the value you need
```

#strong[Prevention tip:] Avoid variable names that shadow built-ins (`$error`, `$input`, `$args`, `$_`, `$null`, `$true`, `$false`) — even the ones that aren’t read-only can cause confusing behaviour.

#horizontalrule

#figure([#image("images/app-B-erroraction-flowchart.png")],
  caption: [
    app-b-erroraction-flowchart
  ]
)

#horizontalrule

== ErrorAction Quick Reference
<erroraction-quick-reference>
#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [Value], [Behaviour],
  [`Continue`],
  [Print error and keep going (default)],
  [`SilentlyContinue`],
  [Suppress error, keep going],
  [`Stop`],
  [Convert to terminating error (catchable with `try/catch`)],
  [`Inquire`],
  [Ask the user what to do (interactive sessions only)],
  [`Ignore`],
  [Suppress error and don’t populate `$Error`],
  [`Suspend`],
  [Suspend the workflow (workflows only)],
)
]

```powershell
# Set default for a script
$ErrorActionPreference = 'Stop'   # makes ALL errors terminating in this scope

# Per-command override
Get-Item 'missing.txt' -ErrorAction SilentlyContinue

# Capture the error object
Get-Item 'missing.txt' -ErrorAction SilentlyContinue -ErrorVariable myErr
if ($myErr) { Write-Warning $myErr[0].Exception.Message }
```

#horizontalrule

#figure([#image("images/app-B-fix-patterns.png")],
  caption: [
    app-b-fix-patterns
  ]
)

#horizontalrule

== The Universal Debug Workflow
<the-universal-debug-workflow>
When all else fails:

```powershell
# 1. Read the last error in full
$Error[0] | Format-List * -Force

# 2. Find the inner exception
$Error[0].Exception.InnerException

# 3. Get the full stack trace
$Error[0].ScriptStackTrace

# 4. Run the failing command with -Verbose and -Debug
Get-SomeCmdlet -Parameter value -Verbose -Debug

# 5. Set a breakpoint (VS Code) or use Wait-Debugger
Wait-Debugger   # drops you into the debugger at that line

# 6. Use transcript to capture everything
Start-Transcript .\debug.log
# ... reproduce the issue ...
Stop-Transcript
```

#figure([#image("images/app-B-debug-workflow.png")],
  caption: [
    app-b-debug-workflow
  ]
)

#horizontalrule

#blockquote[
#strong[Survival tip:] PowerShell error messages are verbose for a reason — read the whole thing before Googling. The last line almost always tells you exactly what went wrong, if you give it the chance.
]

= Appendix C: From Bash to PowerShell
<appendix-c-from-bash-to-powershell>
#blockquote[
#emph[You already speak shell. PowerShell is the same language with an object-oriented accent.]
]

#figure([#image("images/app-C-command-comparison.png")],
  caption: [
    app-c-command-comparison
  ]
)

#horizontalrule

== Command Translation Table
<command-translation-table>
Thirty-plus operations, side by side. The "Notes" column is where the real education happens.

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Bash], [PowerShell], [Notes],
  [`ls`],
  [`Get-ChildItem`],
  [PS returns `FileInfo`/`DirectoryInfo` objects, not text],
  [`ls -la`],
  [`Get-ChildItem -Force`],
  [`-Force` shows hidden files; `-la` style via `Format-List`],
  [`ls -lh *.log`],
  [`Get-ChildItem *.log \| Select-Object Name, Length`],
  [Filter then project properties],
  [`cd /tmp`],
  [`Set-Location /tmp`],
  [`cd` also works — it’s a built-in alias],
  [`pwd`],
  [`Get-Location`],
  [Returns a `PathInfo` object; `.Path` gives you the string],
  [`mkdir -p a/b/c`],
  [`New-Item -ItemType Directory -Path a/b/c -Force`],
  [`-Force` creates parents, no error if exists],
  [`rm file`],
  [`Remove-Item file`],
  [],
  [`rm -rf dir/`],
  [`Remove-Item -Recurse -Force dir/`],
  [Same semantics, safer defaults without `-Force`],
  [`cp src dst`],
  [`Copy-Item src dst`],
  [],
  [`cp -r src/ dst/`],
  [`Copy-Item -Recurse src/ dst/`],
  [],
  [`mv old new`],
  [`Move-Item old new`],
  [Also renames],
  [`touch file.txt`],
  [`New-Item file.txt -ItemType File`],
  [Or `'' \| Set-Content file.txt`],
  [`cat file`],
  [`Get-Content file`],
  [Returns array of strings (one per line)],
  [`cat file \| head -n 20`],
  [`Get-Content file -TotalCount 20`],
  [],
  [`tail -f app.log`],
  [`Get-Content app.log -Wait -Tail 20`],
  [`-Wait` follows live writes (tail -f equivalent)],
  [`cat file \| wc -l`],
  [`(Get-Content file).Count`],
  [Or `Get-Content file \| Measure-Object -Line`],
  [`grep "pattern" file`],
  [`Select-String -Pattern "pattern" -Path file`],
  [Returns `MatchInfo` objects with line, line number, path],
  [`grep -r "pattern" .`],
  [`Get-ChildItem -Recurse \| Select-String "pattern"`],
  [Searches file contents recursively],
  [`grep -v "pattern" file`],
  [`Get-Content file \| Where-Object { $_ -notmatch "pattern" }`],
  [Negate with `-notmatch`],
  [`grep -i "pattern" file`],
  [`Select-String -Pattern "pattern" -Path file`],
  [PS regex is case-insensitive by default],
  [`sed 's/old/new/g' file`],
  [`(Get-Content file) -replace 'old','new' \| Set-Content file`],
  [In-place replace (no `-i` flag needed)],
  [`awk '{print $1}' file`],
  [`Get-Content file \| ForEach-Object { ($_ -split '\s+')[0] }`],
  [Or use `Import-Csv` if the file is structured],
  [`cat a b \| sort \| uniq`],
  [`Get-Content a,b \| Sort-Object -Unique`],
  [Object-aware; works on any property],
  [`sort file`],
  [`Get-Content file \| Sort-Object`],
  [],
  [`find . -name "*.log"`],
  [`Get-ChildItem -Recurse -Filter *.log`],
  [Returns objects, not paths],
  [`find . -mtime -1`],
  [`Get-ChildItem -Recurse \| Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }`],
  [],
  [`find . -size +100M`],
  [`Get-ChildItem -Recurse \| Where-Object { $_.Length -gt 100MB }`],
  [`100MB` is a PS numeric literal],
  [`ps aux`],
  [`Get-Process`],
  [Full typed objects with CPU, Memory, Handle count],
  [`ps aux \| grep nginx`],
  [`Get-Process nginx`],
  [Or `Get-Process \| Where-Object { $_.Name -like '*nginx*' }`],
  [`kill -9 1234`],
  [`Stop-Process -Id 1234 -Force`],
  [],
  [`killall nginx`],
  [`Get-Process nginx \| Stop-Process -Force`],
  [],
  [`top`],
  [`Get-Process \| Sort-Object CPU -Descending \| Select-Object -First 20`],
  [Or install `btop` / use Task Manager],
  [`df -h`],
  [`Get-PSDrive`],
  [Or `Get-Volume` on Windows for disk usage],
  [`du -sh dir/`],
  [`(Get-ChildItem dir/ -Recurse \| Measure-Object Length -Sum).Sum / 1MB`],
  [Result in MB],
  [`free -h`],
  [`Get-CimInstance Win32_OperatingSystem \| Select-Object FreePhysicalMemory`],
  [],
  [`uname -a`],
  [`$PSVersionTable`],
  [Includes OS, PS version, .NET version],
  [`hostname`],
  [`$env:COMPUTERNAME`],
  [Or `hostname` — it still works],
  [`whoami`],
  [`$env:USERNAME`],
  [Or `[Security.Principal.WindowsIdentity]::GetCurrent().Name`],
  [`id`],
  [`[Security.Principal.WindowsIdentity]::GetCurrent()`],
  [Returns groups, SIDs, etc.],
  [`echo "text"`],
  [`Write-Output "text"`],
  [`echo` is an alias for `Write-Output` in PS],
  [`printf “%s\\n” “$var”`],
  [Format string with backtick-n for newline],
  [Or just `”$var”` with double-quoted string],
  [```export VAR=value```],
  [```$env:VAR = 'value'```],
  [Affects child processes; ```$VAR``` is a local PS variable],
  [`unset VAR`],
  [`Remove-Item Env:\\VAR`],
  [],
  [`env`],
  [`Get-ChildItem Env:`],
  [Lists all environment variables as objects],
  [`source script.sh`],
  [`. .\\script.ps1`],
  [Dot-sourcing runs in current scope (same concept)],
  [`which python`],
  [`Get-Command python`],
  [Returns `CommandInfo` object with `Source` path],
  [`type -a ls`],
  [`Get-Command ls -All`],
  [Shows all definitions (alias, function, cmdlet)],
  [`history`],
  [`Get-History`],
  [Or `(Get-PSReadLineOption).HistorySavePath` for persistent history],
  [`!!`],
  [Press #strong[Up] then #strong[Enter]],
  [No `!!` operator; use `Invoke-History` or the up arrow],
  [`Ctrl+R`],
  [`Ctrl+R`],
  [PSReadLine supports interactive history search],
  [`alias ll='ls -la'`],
  [`Set-Alias ll Get-ChildItem`],
  [Or `function ll \{ Get-ChildItem -Force \}` with splatting],
  [`if [ -f file ]`],
  [`if (Test-Path file -PathType Leaf)`],
  [],
  [`if [ -d dir ]`],
  [`if (Test-Path dir -PathType Container)`],
  [],
  [`if [ condition ]`],
  [`if ($condition)`],
  [PS uses `$true`/`$false`; no `[ ]` brackets],
  [`for i in \{1..10\}`],
  [`foreach ($i in 1..10)`],
  [Or `1..10 | ForEach-Object \{ ... \}`],
  [`while [ true ]`],
  [`while ($true)`],
  [],
  [`exit 0`],
  [`exit 0`],
  [Same syntax],
  [`$?`],
  [`$?`],
  [`$true` = last command succeeded (same concept)],
  [`$!`],
  [---],
  [PS jobs use `Start-Job`; no `$!` equivalent],
  [`$0`],
  [`$MyInvocation.MyCommand.Name`],
  [Script name],
  [`$\@` / `$\*`],
  [`$args`],
  [Array of unbound arguments],
  [`$1`, `$2`],
  [#raw("param($First, $Second)")],
  [PS uses named parameters, not positional `$1`],
  [`command &`],
  [`Start-Job \{ command \}`],
  [Background jobs; `Receive-Job` for output],
  [`wait`],
  [`Wait-Job -Job $job`],
  [Wait for background job],
  [`nohup command`],
  [`Start-Process -NoNewWindow command`],
  [Or use `Start-Job`],
  [`curl https://...`],
  [`Invoke-RestMethod https://...`],
  [Auto-parses JSON; or `Invoke-WebRequest` for raw],
  [`wget url -O file`],
  [`Invoke-WebRequest url -OutFile file`],
  [],
  [`tar -czf out.tar.gz dir/`],
  [`Compress-Archive -Path dir/ -DestinationPath out.zip`],
  [PS uses ZIP, not tar.gz natively],
  [`tar -xzf file.tar.gz`],
  [`Expand-Archive -Path file.zip -DestinationPath .`],
  [],
  [`ssh user\@host`],
  [`Enter-PSSession -ComputerName host -Credential user`],
  [WinRM-based; or use `ssh` (available on Windows 10+)],
  [`scp file user\@host:/path`],
  [`Copy-Item -Path file -Destination \\\\host\\path`],
  [Or use `ssh`/`scp` (both available on modern Windows)],
  [`cron`],
  [`Register-ScheduledTask`],
  [Full Task Scheduler integration],
  [`apt install pkg`],
  [`Install-Module pkg`],
  [For PS modules from PSGallery],
  [`apt install tool`],
  [`winget install tool`],
  [For system tools (Windows Package Manager)],
  [`pip install pkg`],
  [`Install-Package pkg`],
  [Via PackageManagement (NuGet, Chocolatey, etc.)],
)
]

#horizontalrule

== Conceptual Differences
<conceptual-differences>
The table above covers syntax. These sections cover the ideas that separate PS fluency from PS frustration.

#horizontalrule

=== Text Streams vs. Object Streams
<text-streams-vs.-object-streams>
This is the single most important difference.

```bash
# Bash: everything is text
ps aux | grep nginx | awk '{print $2}' | xargs kill
# Parse text → parse text → parse text → act
```

```powershell
# PowerShell: everything is objects
Get-Process | Where-Object { $_.Name -eq 'nginx' } | Stop-Process
# Filter objects → act on objects — no parsing required
```

In Bash, piping gives the next command a string to parse. In PowerShell, piping gives the next cmdlet a live .NET object with properties and methods. The payoff is that you can do `$proc.CPU` instead of writing a regex to extract a column.

#horizontalrule

=== Exit Codes vs. Exceptions
<exit-codes-vs.-exceptions>
```bash
# Bash: exit codes
cp src.txt dst.txt
if [ $? -ne 0 ]; then
    echo "Failed"
fi
```

```powershell
# PowerShell: exceptions (and $?)
try {
    Copy-Item src.txt dst.txt -ErrorAction Stop
} catch {
    Write-Warning "Failed: $_"
}

# $? still exists and works
Copy-Item src.txt dst.txt
if (-not $?) { Write-Warning "Failed" }

# $LASTEXITCODE for external programs
git status
$LASTEXITCODE   # 0 = success
```

Non-terminating errors in PowerShell write to the error stream but don’t throw. Use `-ErrorAction Stop` to convert them into catchable exceptions.

#horizontalrule

=== Single vs. Double Quotes
<single-vs.-double-quotes>
This is one place where PowerShell and Bash agree — sort of.

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [], [Bash], [PowerShell],
  [Double quotes `"..."`],
  [Variable expansion + subshell `$(...)`],
  [Variable interpolation `$var`, expression `$(...)`],
  [Single quotes `'...'`],
  [No expansion — literal string],
  [No interpolation — literal string],
)
]

```powershell
$name = 'World'
"Hello $name"    # Hello World    (interpolated)
'Hello $name'    # Hello $name    (literal)
"Today: $(Get-Date -Format 'yyyy-MM-dd')"   # Today: 2026-03-17
```

The difference from Bash: in PowerShell, single quotes are truly literal — no command substitution, no escaping tricks. Backtick (#raw("`")) is the PowerShell escape character, not backslash.

#horizontalrule

=== Pipes: Text Streams vs. Object Streams (Under the Hood)
<pipes-text-streams-vs.-object-streams-under-the-hood>
```bash
# Bash pipe: connect stdout of left to stdin of right
ls | grep '\.txt' | wc -l
# Each command sees a byte stream
```

```powershell
# PS pipe: connect output objects of left to input of right
Get-ChildItem | Where-Object { $_.Extension -eq '.txt' } | Measure-Object
# Each cmdlet receives typed .NET objects
```

This means `Sort-Object` in PowerShell sorts by object property values (integers sort numerically, dates sort chronologically) without you having to tell it anything about types. Bash’s `sort` sorts lexicographically unless you pass `-n`, `-h`, or `-V`.

#horizontalrule

=== Variable Scoping
<variable-scoping>
#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Concept], [Bash], [PowerShell],
  [Local variable],
  [`var=value`],
  [`$var = 'value'`],
  [Environment variable],
  [`export VAR=value`],
  [`$env:VAR = 'value'`],
  [Subshell scope],
  [New shell \= no access to parent vars],
  [`Start-Job` runs in a new runspace; use `$using:var`],
  [Function scope],
  [Inherits parent scope by default],
  [New scope by default; use `$script:` or `$global:` to escape],
  [Dot-source scope],
  [`source script.sh` pollutes current scope],
  [`. .\script.ps1` pollutes current scope (same!)],
)
]

```powershell
# Scope qualifiers
$local:x   = 'only here'
$script:y  = 'visible in this .ps1 file'
$global:z  = 'visible everywhere in the session'
$env:PATH  = $env:PATH + ':/new/path'   # environment variable

# Access parent scope variable in a Start-Job
$data = 'hello'
Start-Job { $using:data }   # $using: prefix bridges the runspace boundary
```

#horizontalrule

=== Package Management
<package-management>
#align(center)[#table(
  columns: 4,
  align: (col, row) => (auto,auto,auto,auto,).at(col),
  inset: 6pt,
  [Need], [Bash (Debian/Ubuntu)], [Bash (macOS)], [PowerShell],
  [Install system tool],
  [`apt install htop`],
  [`brew install htop`],
  [`winget install htop`],
  [Install PS module],
  [—],
  [—],
  [`Install-Module Az -Scope CurrentUser`],
  [Install any package],
  [`apt install pkg`],
  [`brew install pkg`],
  [`Install-Package pkg` (PackageManagement)],
  [Search packages],
  [`apt search term`],
  [`brew search term`],
  [`Find-Module term` / `Find-Package term`],
  [List installed],
  [`dpkg -l`],
  [`brew list`],
  [`Get-InstalledModule` / `Get-Package`],
  [Update everything],
  [`apt upgrade`],
  [`brew upgrade`],
  [`Update-Module` / `winget upgrade --all`],
  [Repository],
  [apt repos],
  [Homebrew taps],
  [PSGallery (default) + NuGet + Chocolatey],
)
]

```powershell
# Register an additional repository
Register-PSRepository -Name 'MyInternalRepo' -SourceLocation 'https://repo.company.com/nuget'

# Install from specific repo
Install-Module -Name MyModule -Repository MyInternalRepo

# Trust a repository so you're not prompted every time
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```

#horizontalrule

#figure([#image("images/app-C-concept-mapping.png")],
  caption: [
    app-c-concept-mapping
  ]
)

#horizontalrule

== Quick Mental Model Shift
<quick-mental-model-shift>
When you catch yourself reaching for `grep`, `awk`, or `sed` in PowerShell, pause and ask:

+ #strong[What object am I working with?] (Use `Get-Member` to find out.)
+ #strong[Which property holds the data I want?] (Use `Select-Object *` to see all properties.)
+ #strong[Can I filter/sort/group directly on that property?] (Almost certainly yes.)

```powershell
# Bash instinct: parse text
Get-Content .\access.log | ForEach-Object { ($_ -split ' ')[0] } | Sort-Object -Unique

# PS way: work with objects
Import-Csv .\access.log -Header IP,Date,Method,Path,Status |
    Select-Object -ExpandProperty IP |
    Sort-Object -Unique
```

The first version works. The second is idiomatic, more readable, and more robust to format changes.

#horizontalrule

== The Five Commands Every Bash User Needs First
<the-five-commands-every-bash-user-needs-first>
If you remember nothing else from this appendix, remember these:

```powershell
# 1. What does this object look like?
Get-Process | Get-Member

# 2. Show me ALL properties (not just the default view)
Get-Process | Select-Object *

# 3. Find the cmdlet I need
Get-Command *log*           # search by name
Get-Command -Verb Get       # search by verb

# 4. Get help with examples
Get-Help Get-ChildItem -Examples

# 5. What is this object's type?
(Get-Process)[0].GetType().FullName
```

These five patterns answer 90% of "how do I do X in PowerShell" questions. The object model is the API documentation — it’s right there inside the objects themselves.

#horizontalrule

#blockquote[
#strong[Final thought:] Bash makes you think like a text processor. PowerShell makes you think like a programmer. Neither is better — they’re optimised for different problems. The good news is that PowerShell runs on Linux and macOS, and you can always drop to `bash -c '...'` when you need to. You don’t have to choose; you just have to know which tool to reach for.
]
