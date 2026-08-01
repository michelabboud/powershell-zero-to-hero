# Chapter 02: The Console

> Your terminal is your workbench. Time to set it up right.

![chapter-opener](assets/images/ch-02-opener.png)

---

You can write PowerShell in Notepad and run it from `cmd.exe`. You can also
eat soup with a fork. Both technically work, and both say something
unflattering about your decision-making. This chapter is about choosing
proper tools so that every minute you spend in the shell is productive
instead of painful.

## Terminal Options

PowerShell is an engine. The terminal is the car you bolt it into. Pick the
right chassis and the driving experience improves dramatically.

| Terminal | Platform | Best For |
|----------|----------|----------|
| **Windows Terminal** | Windows | Daily driving -- tabs, splits, GPU rendering |
| **VS Code Integrated** | Cross-platform | Scripting -- IntelliSense, debugging, git |
| **ISE** | Windows only | Legacy scripts -- do not start new work here |
| **macOS Terminal / iTerm2** | macOS | Native feel, good enough for most tasks |
| **GNOME Terminal / Konsole** | Linux | Solid defaults, integrates with your DE |

> ISE shipped its last update with Windows PowerShell 5.1. Microsoft has
> officially told it to enjoy retirement. If someone at work insists on
> ISE, smile politely and update your resume.

## Windows Terminal

Windows Terminal is the recommended host on Windows. If you don't have it
yet, install it from the Microsoft Store or with:

```powershell
winget install Microsoft.WindowsTerminal
```

### Why it matters

- **Tabs and split panes** -- run PowerShell 7 and Windows PowerShell 5.1
  side by side to test compatibility.
- **GPU-accelerated rendering** -- smooth scrolling even when dumping 50,000
  log lines (you'll do this more than you think).
- **Profiles** -- one click to launch PowerShell, cmd, WSL, or Azure Cloud
  Shell.
- **Customization** -- themes, fonts, background images, and opacity. Your
  terminal, your rules.

### Key shortcuts

| Action | Shortcut |
|--------|----------|
| New tab | `Ctrl+Shift+T` |
| Split pane right | `Alt+Shift+Plus` |
| Split pane down | `Alt+Shift+Minus` |
| Switch pane | `Alt+Arrow` |
| Close pane | `Ctrl+Shift+W` |

Spend five minutes memorizing these. You'll recoup that time investment
before lunch.

## VS Code + The PowerShell Extension

For anything longer than a one-liner, VS Code is the environment you want.
Install the **PowerShell extension** (`ms-vscode.powershell`) and you get:

- **IntelliSense** -- tab completion that actually knows the parameter
  names, types, and valid values.
- **Integrated debugging** -- set breakpoints, inspect variables, step
  through code. No more `Write-Host "got here 3"`.
- **Integrated terminal** -- runs PowerShell right inside the editor. One
  window, everything accessible.
- **Script analysis** -- PSScriptAnalyzer runs in the background and
  highlights questionable code before you embarrass yourself in a PR.

```powershell
# Install the extension from the command line
code --install-extension ms-vscode.powershell
```

> VS Code is where you write scripts. Windows Terminal is where you run
> them interactively. Most professionals keep both open all day.

## PowerShell Profiles

A profile is a `.ps1` script that runs automatically every time PowerShell
starts. Think of it as your shell's morning routine -- it loads your
aliases, sets your prompt, imports your favorite modules, and generally
makes the environment feel like home.

### The $PROFILE variable

PowerShell exposes the path to your profile as a built-in variable:

```powershell
$PROFILE
```

This returns the path for the **CurrentUser, CurrentHost** profile -- the
one you'll use 99% of the time.

### The four profile paths

PowerShell actually supports four profiles, loaded in a specific order:

![profile-paths](assets/images/ch-02-profiles.png)

| # | Scope | Path Variable | When to Use |
|---|-------|---------------|-------------|
| 1 | All Users, All Hosts | `$PROFILE.AllUsersAllHosts` | Machine-wide defaults (rare) |
| 2 | All Users, Current Host | `$PROFILE.AllUsersCurrentHost` | Terminal-specific machine defaults |
| 3 | Current User, All Hosts | `$PROFILE.CurrentUserAllHosts` | Your personal cross-host settings |
| 4 | Current User, Current Host | `$PROFILE.CurrentUserCurrentHost` | Your personal, terminal-specific settings |

They load top to bottom. If the same alias is defined in profile 1 and
profile 4, profile 4 wins because it loads last.

### Creating your first profile

Check if the file exists, then create it if it doesn't:

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

Save, close, and open a new PowerShell window. Your greeting should appear.
If it doesn't, check that your execution policy allows scripts:

```powershell
Get-ExecutionPolicy
# If "Restricted":
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## PSReadLine

PSReadLine is the module that makes PowerShell's interactive experience
tolerable. It ships with PowerShell 7 and handles syntax highlighting,
history, key bindings, and predictive IntelliSense. You've been using it
this whole time -- you just didn't know it had a name.

### Syntax highlighting

Type a valid cmdlet and it appears in one color. Mistype it and the color
changes. This alone prevents a staggering number of typos.

### Predictive IntelliSense

PowerShell can suggest completions based on your command history:

```powershell
# Enable inline prediction (ghost text after your cursor)
Set-PSReadLineOption -PredictionSource History

# Or use ListView for a dropdown of suggestions
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
```

The `ListView` style shows a dropdown below your cursor with the top
matches from your history. Press `DownArrow` to select, `Enter` to accept.
Once you've used it for a day, you'll wonder how you lived without it.

### History search

Press `Ctrl+R` and start typing. PSReadLine searches backward through your
history for matching commands. This is faster than pressing `UpArrow` forty
times to find that `Invoke-RestMethod` call from last Tuesday.

```powershell
# Bind Ctrl+R to reverse history search (usually default)
Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
```

### Useful key bindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Reverse search history |
| `Ctrl+S` | Forward search history |
| `Tab` | Complete command/parameter |
| `Ctrl+Space` | Show all completions |
| `F2` | Toggle between inline and list prediction |
| `Ctrl+d` | Delete character (or exit if line is empty) |

## Customizing Your Prompt

The prompt is controlled by a function literally named `prompt`. Override it
in your profile and PowerShell will call your version every time it draws a
new line.

### Basic custom prompt

```powershell
function prompt {
    $location = Get-Location
    $time = Get-Date -Format "HH:mm"
    "[$time] $location> "
}
```

This gives you something like `[14:32] C:\Projects>` instead of the
default `PS C:\Projects>`.

### Adding color

```powershell
function prompt {
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time]" -ForegroundColor DarkGray -NoNewline
    Write-Host " $(Get-Location)" -ForegroundColor Cyan -NoNewline
    return "> "
}
```

> The `prompt` function must return a string. If it returns nothing,
> PowerShell falls back to `"PS> "`. The `Write-Host` calls handle the
> colorful parts, and the returned `"> "` is the actual prompt character.

### Adding git status

If you work with git repositories (and you will), showing the current
branch in your prompt saves constant `git status` checks:

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

For a more polished experience, look into **Oh My Posh** or **Starship** --
prompt frameworks that handle themes, git status, execution time, and more
with minimal configuration. We'll revisit those in later chapters.

---

## Exercises

### [Ch-02, Ex-1] Find Your Profile Path (Simple)

Use the `$PROFILE` variable to display your profile path. Then check
whether the file actually exists using `Test-Path`.

### [Ch-02, Ex-2] Create a Profile with Aliases and Greeting (Normal)

Create a profile script that:
1. Sets an alias `ll` that maps to `Get-ChildItem`
2. Sets an alias `np` that maps to `notepad`
3. Displays a greeting message when the shell starts

### [Ch-02, Ex-3] Configure PSReadLine (Advanced)

<!-- tier: advanced -->

> **Advanced exercise.** Add PSReadLine configuration to your profile:
> set prediction to `ListView` style and bind `Ctrl+d` to
> `DeleteCharOrExit`.

### [Ch-02, Ex-4] Admin-Aware Prompt (Extreme)

<!-- tier: extreme -->

> **Extreme exercise.** Build a profile that detects whether you're running
> as an administrator (or root on Linux). Change the prompt color to red
> for admin sessions and green for normal user sessions. The detection
> logic must work on both Windows and Linux.

---

## Challenge: PSReadLine Power User

<!-- tier: advanced -->

> Configure PSReadLine with `ListView` prediction, custom key bindings for
> `UpArrow` and `DownArrow` history navigation, and a custom color scheme
> for the prediction list. Your configuration should be clean enough to
> drop into any colleague's profile without modification.

## Boss Level: The Universal Profile

<!-- tier: extreme -->

> Build a profile that:
>
> 1. Detects the environment -- admin vs. standard user, VS Code terminal
>    vs. Windows Terminal vs. other, Windows vs. Linux vs. macOS.
> 2. Conditionally loads modules (e.g., `posh-git` only if installed).
> 3. Sets different prompt colors per context (admin = red, VS Code = blue,
>    default = green).
> 4. Measures and displays its own load time so you know when the profile
>    is getting bloated.
>
> The entire profile should load in under 500ms on a cold start. Profile
> performance matters -- a 3-second profile startup is a 3-second tax on
> every terminal you open, every day, forever.

---

> **Next up:** [Chapter 03 -- Commands and Cmdlets](03-commands-and-cmdlets.md),
> where you'll learn the Verb-Noun pattern that makes PowerShell
> discoverable without a cheat sheet.
