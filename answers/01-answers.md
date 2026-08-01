# Chapter 01 -- Answers

## Ch-01, Ex-1 (Simple)

**Task:** Run `$PSVersionTable` and identify your PS version, edition, and OS.

```powershell
# Tested -- PowerShell 7.4+ / Windows & Linux
$PSVersionTable
# Look for: PSVersion (e.g. 7.4.x), PSEdition (Core), OS (your OS string)
```

**Expected Output:**
```
Name                           Value
----                           -----
PSVersion                      7.4.6
PSEdition                      Core
OS                             Microsoft Windows 10...
...
```

**What to notice:** `PSEdition` says `Core` (not `Desktop`). That confirms you're on PS 7+, not Windows PowerShell 5.1.

---

## Ch-01, Ex-2 (Normal)

**Task:** Use `Get-Command` to find all cmdlets with verb "Get" in `Microsoft.PowerShell.Utility`.

```powershell
Get-Command -Verb Get -Module Microsoft.PowerShell.Utility
```

**Expected Output:**
```
CommandType     Name                    Version    Source
-----------     ----                    -------    ------
Cmdlet          Get-Date                7.0.0.0    Microsoft.PowerShell.Utility
...
```

**What to notice:** Every result has Verb = `Get`. The `-Verb` parameter filters without wildcards.

---

## Ch-01, Ex-3 (Advanced)

**Task:** Find the total number of available cmdlets, functions, and aliases on your system.

```powershell
Get-Command | Group-Object CommandType | Select-Object Name, Count
```

**Expected Output (varies by system):**
```
Name        Count
----        -----
Alias         150
Function      300
Cmdlet        800
Application   1200
```

**What to notice:** `Application` includes all executables on your PATH. Cmdlet count depends on installed modules.

---

## Ch-01, Ex-4 (Extreme)

**Task:** One-liner that outputs a formatted table of command counts per type.

```powershell
Get-Command | Group-Object CommandType | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize
```

**What to notice:** `Group-Object` + `Select-Object` + `Sort-Object` is a pipeline pattern you'll use constantly. `Format-Table` is for display only -- never pipe its output further.
