# Appendix C: From Bash to PowerShell

> *You already speak shell. PowerShell is the same language with an object-oriented accent.*

![app-c-command-comparison](assets/images/app-C-command-comparison.png)

---

## Command Translation Table

Thirty-plus operations, side by side. The "Notes" column is where the real education happens.

| Bash | PowerShell | Notes |
|---|---|---|
| `ls` | `Get-ChildItem` | PS returns `FileInfo`/`DirectoryInfo` objects, not text |
| `ls -la` | `Get-ChildItem -Force` | `-Force` shows hidden files; `-la` style via `Format-List` |
| `ls -lh *.log` | `Get-ChildItem *.log \| Select-Object Name, Length` | Filter then project properties |
| `cd /tmp` | `Set-Location /tmp` | `cd` also works — it's a built-in alias |
| `pwd` | `Get-Location` | Returns a `PathInfo` object; `.Path` gives you the string |
| `mkdir -p a/b/c` | `New-Item -ItemType Directory -Path a/b/c -Force` | `-Force` creates parents, no error if exists |
| `rm file` | `Remove-Item file` | |
| `rm -rf dir/` | `Remove-Item -Recurse -Force dir/` | Same semantics, safer defaults without `-Force` |
| `cp src dst` | `Copy-Item src dst` | |
| `cp -r src/ dst/` | `Copy-Item -Recurse src/ dst/` | |
| `mv old new` | `Move-Item old new` | Also renames |
| `touch file.txt` | `New-Item file.txt -ItemType File` | Or `'' \| Set-Content file.txt` |
| `cat file` | `Get-Content file` | Returns array of strings (one per line) |
| `cat file \| head -n 20` | `Get-Content file -TotalCount 20` | |
| `tail -f app.log` | `Get-Content app.log -Wait -Tail 20` | `-Wait` follows live writes (tail -f equivalent) |
| `cat file \| wc -l` | `(Get-Content file).Count` | Or `Get-Content file \| Measure-Object -Line` |
| `grep "pattern" file` | `Select-String -Pattern "pattern" -Path file` | Returns `MatchInfo` objects with line, line number, path |
| `grep -r "pattern" .` | `Get-ChildItem -Recurse \| Select-String "pattern"` | Searches file contents recursively |
| `grep -v "pattern" file` | `Get-Content file \| Where-Object { $_ -notmatch "pattern" }` | Negate with `-notmatch` |
| `grep -i "pattern" file` | `Select-String -Pattern "pattern" -Path file` | PS regex is case-insensitive by default |
| `sed 's/old/new/g' file` | `(Get-Content file) -replace 'old','new' \| Set-Content file` | In-place replace (no `-i` flag needed) |
| `awk '{print $1}' file` | `Get-Content file \| ForEach-Object { ($_ -split '\s+')[0] }` | Or use `Import-Csv` if the file is structured |
| `cat a b \| sort \| uniq` | `Get-Content a,b \| Sort-Object -Unique` | Object-aware; works on any property |
| `sort file` | `Get-Content file \| Sort-Object` | |
| `find . -name "*.log"` | `Get-ChildItem -Recurse -Filter *.log` | Returns objects, not paths |
| `find . -mtime -1` | `Get-ChildItem -Recurse \| Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }` | |
| `find . -size +100M` | `Get-ChildItem -Recurse \| Where-Object { $_.Length -gt 100MB }` | `100MB` is a PS numeric literal |
| `ps aux` | `Get-Process` | Full typed objects with CPU, Memory, Handle count |
| `ps aux \| grep nginx` | `Get-Process nginx` | Or `Get-Process \| Where-Object { $_.Name -like '*nginx*' }` |
| `kill -9 1234` | `Stop-Process -Id 1234 -Force` | |
| `killall nginx` | `Get-Process nginx \| Stop-Process -Force` | |
| `top` | `Get-Process \| Sort-Object CPU -Descending \| Select-Object -First 20` | Or install `btop` / use Task Manager |
| `df -h` | `Get-PSDrive` | Or `Get-Volume` on Windows for disk usage |
| `du -sh dir/` | `(Get-ChildItem dir/ -Recurse \| Measure-Object Length -Sum).Sum / 1MB` | Result in MB |
| `free -h` | `Get-CimInstance Win32_OperatingSystem \| Select-Object FreePhysicalMemory` | Windows-only CIM class; use `free` on Linux |
| `uname -a` | `$PSVersionTable` | Includes OS, PS version, .NET version |
| `hostname` | `[Environment]::MachineName` | Cross-platform; native `hostname` also works |
| `whoami` | `[Environment]::UserName` | Cross-platform username; native `whoami` includes platform identity details |
| `id` | `id` | Use the native command on Unix; `WindowsIdentity` is Windows-only |
| `echo "text"` | `Write-Output "text"` | `echo` is an alias for `Write-Output` in PS |
| `printf "%s\n" "$var"` | `"{0}`n" -f $var` | Or just `"$var"` with double-quoted string |
| `export VAR=value` | `$env:VAR = 'value'` | Affects child processes; `$VAR` is a local PS variable |
| `unset VAR` | `Remove-Item Env:\VAR` | |
| `env` | `Get-ChildItem Env:` | Lists all environment variables as objects |
| `source script.sh` | `. .\script.ps1` | Dot-sourcing runs in current scope (same concept) |
| `which python` | `Get-Command python` | Returns `CommandInfo` object with `Source` path |
| `type -a ls` | `Get-Command ls -All` | Shows all definitions (alias, function, cmdlet) |
| `history` | `Get-History` | Or `(Get-PSReadLineOption).HistorySavePath` for persistent history |
| `!!` | Press **Up** then **Enter** | No `!!` operator; use `Invoke-History` or the up arrow |
| `Ctrl+R` | `Ctrl+R` | PSReadLine supports interactive history search |
| `alias ll='ls -la'` | `Set-Alias ll Get-ChildItem` | Or `function ll { Get-ChildItem -Force @args }` |
| `if [ -f file ]` | `if (Test-Path file -PathType Leaf)` | |
| `if [ -d dir ]` | `if (Test-Path dir -PathType Container)` | |
| `if [ condition ]` | `if ($condition)` | PS uses `$true`/`$false`; no `[ ]` brackets |
| `for i in {1..10}` | `foreach ($i in 1..10)` | Or `1..10 \| ForEach-Object { ... }` |
| `while [ true ]` | `while ($true)` | |
| `exit 0` | `exit 0` | Same syntax |
| `$?` | `$?` | `$true` = last command succeeded (same concept) |
| `$!` | — | PS jobs use `Start-Job`; no `$!` equivalent |
| `$0` | `$MyInvocation.MyCommand.Name` | Script name |
| `$@` / `$*` | `$args` | Array of unbound arguments |
| `$1`, `$2` | `param($First, $Second)` | PS uses named parameters, not positional `$1` |
| `command &` | `Start-Job { command }` | Out-of-process background job; `Receive-Job` for output |
| `wait` | `Wait-Job -Job $job` | Wait for background job |
| `nohup command` | No direct durable equivalent | Use the platform service/process manager for work that must survive the shell |
| `curl https://...` | `Invoke-RestMethod https://...` | Auto-parses JSON; or `Invoke-WebRequest` for raw |
| `wget url -O file` | `Invoke-WebRequest url -OutFile file` | |
| `tar -czf out.tar.gz dir/` | `Compress-Archive -Path dir/ -DestinationPath out.zip` | PS uses ZIP, not tar.gz natively |
| `tar -xzf file.tar.gz` | `Expand-Archive -Path file.zip -DestinationPath .` | |
| `ssh user@host` | `Enter-PSSession -HostName host -UserName user` | PowerShell remoting over SSH; native `ssh` remains available |
| `scp file user@host:/path` | `scp file user@host:/path` | Use the native OpenSSH client; an SMB path is a different transport |
| `cron` | `Register-ScheduledTask` | Windows-only; keep cron/systemd timers on Unix |
| `apt install pkg` | `Install-PSResource pkg` | Only for PowerShell resources from a registered repository, not OS packages |
| `apt install tool` | `winget install tool` | Windows-only; use the host OS package manager elsewhere |
| `pip install pkg` | No direct equivalent | Python packages and PowerShell resources have different managers |

---

## Conceptual Differences

The table above covers syntax. These sections cover the ideas that separate PS fluency from PS frustration.

---

### Text Streams vs. Object Streams

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

---

### Exit Codes vs. Exceptions

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

Non-terminating errors in PowerShell write to the error stream but don't throw. Use `-ErrorAction Stop` to convert them into catchable exceptions.

---

### Single vs. Double Quotes

This is one place where PowerShell and Bash agree — sort of.

| | Bash | PowerShell |
|---|---|---|
| Double quotes `"..."` | Variable expansion + subshell `$(...)` | Variable interpolation `$var`, expression `$(...)` |
| Single quotes `'...'` | No expansion — literal string | No interpolation — literal string |

```powershell
$name = 'World'
"Hello $name"    # Hello World    (interpolated)
'Hello $name'    # Hello $name    (literal)
"Today: $(Get-Date -Format 'yyyy-MM-dd')"   # Today: 2026-03-17
```

The difference from Bash: in PowerShell, single quotes are truly literal — no command substitution, no escaping tricks. Backtick (`` ` ``) is the PowerShell escape character, not backslash.

---

### Pipes: Text Streams vs. Object Streams (Under the Hood)

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

This means `Sort-Object` in PowerShell sorts by object property values (integers sort numerically, dates sort chronologically) without you having to tell it anything about types. Bash's `sort` sorts lexicographically unless you pass `-n`, `-h`, or `-V`.

---

### Variable Scoping

| Concept | Bash | PowerShell |
|---|---|---|
| Local variable | `var=value` | `$var = 'value'` |
| Environment variable | `export VAR=value` | `$env:VAR = 'value'` |
| Subshell scope | New shell = no access to parent vars | `Start-Job` runs in a separate process; use `$using:var` |
| Function scope | Inherits parent scope by default | New scope by default; use `$script:` or `$global:` to escape |
| Dot-source scope | `source script.sh` pollutes current scope | `. .\script.ps1` pollutes current scope (same!) |

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

---

### Package Management

| Need | Bash (Debian/Ubuntu) | Bash (macOS) | PowerShell |
|---|---|---|---|
| Install system tool | `apt install htop` | `brew install htop` | `winget install htop` |
| Install PS resource | — | — | `Install-PSResource Az -Scope CurrentUser` |
| Install system package | `apt install pkg` | `brew install pkg` | Use the host OS manager (`winget` on Windows) |
| Search PS resources | — | — | `Find-PSResource term` |
| List installed PS resources | — | — | `Get-InstalledPSResource` |
| Update PS resource | — | — | `Update-PSResource Name` |
| Repository | apt repos | Homebrew taps | PSGallery plus registered PSResource repositories |

```powershell
# Register an additional repository
Register-PSResourceRepository -Name 'MyInternalRepo' -Uri 'https://repo.company.com/nuget'

# Install from specific repo
Install-PSResource -Name MyModule -Repository MyInternalRepo -Scope CurrentUser

# Trust a repository so you're not prompted every time
Set-PSResourceRepository -Name PSGallery -Trusted
```

`Microsoft.PowerShell.PSResourceGet` is the current resource-management
module. The older `Find-Module`, `Install-Module`, and `*-PSRepository`
commands remain common in Windows PowerShell and existing automation.

---

![app-c-concept-mapping](assets/images/app-C-concept-mapping.png)

---

## Quick Mental Model Shift

When you catch yourself reaching for `grep`, `awk`, or `sed` in PowerShell, pause and ask:

1. **What object am I working with?** (Use `Get-Member` to find out.)
2. **Which property holds the data I want?** (Use `Select-Object *` to see all properties.)
3. **Can I filter/sort/group directly on that property?** (Almost certainly yes.)

```powershell
# Bash instinct: parse text
Get-Content .\access.log | ForEach-Object { ($_ -split ' ')[0] } | Sort-Object -Unique

# PS way: work with objects
Import-Csv .\access.log -Header IP,Date,Method,Path,Status |
    Select-Object -ExpandProperty IP |
    Sort-Object -Unique
```

The first version works. The second is idiomatic, more readable, and more robust to format changes.

---

## The Five Commands Every Bash User Needs First

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

These five patterns answer 90% of "how do I do X in PowerShell" questions. The object model is the API documentation — it's right there inside the objects themselves.

---

> **Final thought:** Bash makes you think like a text processor. PowerShell makes you think like a programmer.
> Neither is better — they're optimised for different problems. The good news is that PowerShell
> runs on Linux and macOS, and you can always drop to `bash -c '...'` when you need to.
> You don't have to choose; you just have to know which tool to reach for.
