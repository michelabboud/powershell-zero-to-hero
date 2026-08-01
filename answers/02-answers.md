# Chapter 02 -- Answers

---

## Ch-02, Ex-1 (Simple)

**Task:** Find your profile path and check whether the file exists.

```powershell
# Display the profile path
$PROFILE

# Check if the file exists
Test-Path $PROFILE
```

**Expected Output:**

```
C:\Users\YourName\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
False
```

(The exact path depends on your OS and host. On Linux it will be something
like `/home/yourname/.config/powershell/Microsoft.PowerShell_profile.ps1`.
The second line is `False` if you haven't created a profile yet, `True` if
you have.)

**What to notice:**
- `$PROFILE` is a string, not a command. It's a built-in automatic variable
  that PowerShell populates at startup.
- `$PROFILE` actually has four sub-properties (`AllUsersAllHosts`,
  `AllUsersCurrentHost`, `CurrentUserAllHosts`, `CurrentUserCurrentHost`).
  When you call `$PROFILE` alone, you get the `CurrentUserCurrentHost` path.
- `Test-Path` returns a boolean (`True` / `False`). Get used to it -- you'll
  use this cmdlet hundreds of times to check for files, directories, and
  registry keys.

---

## Ch-02, Ex-2 (Normal)

**Task:** Create a profile that sets two aliases and displays a greeting.

```powershell
# Create the profile file if it doesn't exist
if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force
}

# Write the profile content
@'
# --- Cross-platform aliases ---
Set-Alias -Name ll -Value Get-ChildItem
$editor = if (Get-Command code -ErrorAction SilentlyContinue) {
    'code'
} else {
    'Get-Content'
}
Set-Alias -Name edit -Value $editor

# --- Greeting ---
$user = $env:USERNAME ?? $env:USER
Write-Host ""
Write-Host "  Welcome back, $user." -ForegroundColor Cyan
Write-Host "  PowerShell $($PSVersionTable.PSVersion) | $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
Write-Host ""
'@ | Set-Content -Path $PROFILE
```

**Expected Output (on next shell launch):**

```
  Welcome back, Sam.
  PowerShell 7.6.4 | 2026-08-01 09:15
```

After that, `ll` lists directory contents. `edit` launches VS Code when the
`code` command is available; otherwise it falls back to displaying a file with
`Get-Content`. Replace the fallback with another editor command you have installed.

**What to notice:**
- `Set-Alias` creates a simple name-to-command mapping. It does not support
  parameters -- if you need `ll -la` behavior, you'll need a function
  instead of an alias. We cover that in Chapter 07.
- The `??` operator is the null-coalescing operator. On Windows,
  `$env:USERNAME` is populated. On Linux/macOS, `$env:USER` is the
  equivalent. Using `??` handles both without an `if` statement.
- Here-strings (`@' ... '@`) are the cleanest way to write multi-line
  content to a file. The single-quote variant avoids variable expansion so
  the `$PROFILE` content is written literally, not evaluated at write time.

---

## Ch-02, Ex-3 (Advanced)

**Task:** Add PSReadLine configuration with ListView prediction and a
Ctrl+d key binding.

```powershell
# Add this block to your $PROFILE

# --- PSReadLine Configuration ---
if (Get-Module PSReadLine -ListAvailable) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows

    # Ctrl+d: delete character under cursor, or exit if line is empty
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

    # Ctrl+r: reverse history search
    Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory

    # F2: toggle between inline and list prediction views
    Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView
}
```

**Expected Output:**

No visible output on load. The effects are interactive:
- Start typing a command you've run before, and a dropdown list of
  suggestions appears below the cursor.
- Press `Ctrl+d` on an empty line to exit the shell.
- Press `F2` to toggle between ghost-text and list views.

**What to notice:**
- We wrap the configuration in a `Get-Module -ListAvailable` check. This
  prevents errors if someone runs the profile in a minimal environment
  where PSReadLine isn't installed (e.g., a Docker container).
- `DeleteCharOrExit` is a compound function: it deletes a character when
  text is present and exits the shell when the line is empty. This matches
  the behavior of `Ctrl+d` in Bash, which is a nice consistency win for
  people who work on both platforms.
- `PredictionViewStyle ListView` is a game-changer for discoverability.
  The dropdown shows your most relevant history entries, ranked by
  frequency and recency. It's like autocomplete for your muscle memory.

---

## Ch-02, Ex-4 (Extreme)

**Task:** Detect admin/root status and change the prompt color accordingly.

```powershell
# Add this to your $PROFILE

function Test-IsAdmin {
    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    }
    # Linux / macOS: check effective user ID
    return (id -u) -eq '0'
}

# Cache the result -- no need to recheck on every prompt render
$script:IsAdmin = Test-IsAdmin

function prompt {
    $color = if ($script:IsAdmin) { 'Red' } else { 'Green' }
    $marker = if ($script:IsAdmin) { '#' } else { '>' }

    $path = Split-Path (Get-Location) -Leaf
    if ((Get-Location).Path -eq (Get-Location).Drive.Root) {
        $path = (Get-Location).Path
    }

    Write-Host $path -ForegroundColor $color -NoNewline
    return " $marker "
}
```

**Expected Output (normal user):**

```
Projects>
```

(in green)

**Expected Output (admin/root):**

```
Projects#
```

(in red)

**What to notice:**
- On Windows, admin detection uses .NET's `WindowsPrincipal` class. On
  Linux/macOS, `id -u` returns `0` for root. The `$IsWindows` automatic
  variable (available in PowerShell 7+) makes the platform check clean.
- We cache the admin check in `$script:IsAdmin` instead of calling
  `Test-IsAdmin` inside the prompt function. The prompt runs on every
  keystroke that produces a new line -- calling .NET reflection or shelling
  out to `id` on every prompt render is wasteful. Admin status doesn't
  change mid-session.
- The prompt changes both color and character (`>` vs `#`). This is a
  double visual indicator: color for quick recognition, character for
  accessibility (not everyone can distinguish red from green). Good UX
  never relies on color alone.
- We handle the edge case where the current location is a drive root
  (`C:\` or `/`). Without it, `Split-Path -Leaf` returns an empty string
  for root paths, giving you an invisible prompt. Small things like this
  separate a profile that works from a profile that works everywhere.
