# Appendix A: PowerShell Cheat Sheet

> *The card you tape to your monitor until the cmdlets are burned into your hippocampus.*

![app-a-cmdlet-quickref](assets/images/app-A-cmdlet-quickref.png)

---

## Top 30 Cmdlets

| Cmdlet | What it does |
|---|---|
| `Get-Help` | Displays help for any cmdlet, function, or concept — your first stop, every time |
| `Get-Command` | Lists all available commands; filter with `-Verb`, `-Noun`, or `-Name` wildcards |
| `Get-Member` | Shows the properties and methods of whatever object is piped in |
| `Get-Process` | Returns running processes as rich `System.Diagnostics.Process` objects |
| `Get-Service` | Lists Windows services with status, start type, and display name |
| `Get-ChildItem` | Lists files and directories (aliased `ls`/`dir`); use `-Recurse` and `-Filter` |
| `Get-Content` | Reads a file line by line into an array of strings |
| `Set-Content` | Writes (overwrites) a file with the supplied value |
| `Add-Content` | Appends to a file without overwriting it |
| `Copy-Item` | Copies files, directories, or registry keys |
| `Move-Item` | Moves (renames) files, directories, or registry keys |
| `Remove-Item` | Deletes files, directories, or registry keys; add `-Recurse -Force` with care |
| `New-Item` | Creates a new file, directory, symlink, or registry key |
| `Rename-Item` | Renames a file or directory in place |
| `Test-Path` | Returns `$true`/`$false` — the civilised way to check existence before acting |
| `Where-Object` | Filters pipeline objects by a condition (alias `where` or `?`) |
| `Select-Object` | Picks specific properties, limits results, or adds calculated columns |
| `Sort-Object` | Sorts pipeline objects by one or more properties |
| `Group-Object` | Groups objects by property value and returns count + members |
| `Measure-Object` | Computes count, sum, min, max, average on numeric properties |
| `ForEach-Object` | Runs a script block once per pipeline object (alias `foreach` or `%`) |
| `Format-Table` | Renders output as a table (for display — never pipe this into further processing) |
| `Format-List` | Renders output as property: value pairs; great for wide objects |
| `Out-File` | Redirects pipeline output to a text file |
| `Export-Csv` | Serialises objects to CSV with a header row |
| `Import-Csv` | Reads a CSV and returns `PSCustomObject` rows — headers become properties |
| `ConvertTo-Json` | Converts objects to a JSON string |
| `ConvertFrom-Json` | Parses a JSON string into `PSCustomObject` objects |
| `Invoke-RestMethod` | Sends HTTP requests and auto-deserialises JSON/XML responses |
| `Write-Host` | Writes directly to the console (bypasses the pipeline — use sparingly) |

---

## Operator Comparison Table

![app-a-operator-grid](assets/images/app-A-operator-grid.png)

| Operation | PowerShell | Python | Bash | C# |
|---|---|---|---|---|
| Equal | `-eq` | `==` | `==` (inside `[[ ]]`) | `==` |
| Not equal | `-ne` | `!=` | `!=` | `!=` |
| Greater than | `-gt` | `>` | `-gt` | `>` |
| Less than | `-lt` | `<` | `-lt` | `<` |
| Greater or equal | `-ge` | `>=` | `-ge` | `>=` |
| Less or equal | `-le` | `<=` | `-le` | `<=` |
| Logical AND | `-and` | `and` | `&&` | `&&` |
| Logical OR | `-or` | `or` | `\|\|` | `\|\|` |
| Logical NOT | `-not` / `!` | `not` / `!` | `!` | `!` |
| Bitwise AND | `-band` | `&` | `&` | `&` |
| Bitwise OR | `-bor` | `\|` | `\|` | `\|` |
| String contains | `-like '*x*'` | `'x' in s` | `[[ $s == *x* ]]` | `s.Contains("x")` |
| Regex match | `-match 'pattern'` | `re.search(...)` | `[[ $s =~ pattern ]]` | `Regex.IsMatch(...)` |
| Case-insensitive eq | `-eq` (default) | `s.lower()==...` | n/a | `StringComparison.OrdinalIgnoreCase` |
| Case-sensitive eq | `-ceq` | `==` | `==` | `==` |
| Null / empty check | `$x -eq $null` | `x is None` | `[ -z "$x" ]` | `x == null` |
| Range | `1..10` | `range(1, 11)` | `{1..10}` | `Enumerable.Range(1,10)` |

---

## Pipeline Patterns

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

---

## String Operations Cheat Table

| Operation | Syntax | Example | Result |
|---|---|---|---|
| Interpolation | `"$var"` | `"Hello $name"` | `Hello Sam` |
| Expression interpolation | `"$(expr)"` | `"$(1+1) items"` | `2 items` |
| No interpolation | `'literal'` | `'Hello $name'` | `Hello $name` |
| Replace (literal) | `-replace 'old','new'` | `'foo bar' -replace 'bar','baz'` | `foo baz` |
| Replace (regex) | `-replace 'pattern','new'` | `'a1b2' -replace '\d',''` | `ab` |
| Case-sensitive replace | `-creplace` | `'FooFoo' -creplace 'Foo','X'` | `XX` |
| Split on character | `-split ','` | `'a,b,c' -split ','` | `@('a','b','c')` |
| Split with limit | `-split ',', 2` | `'a,b,c' -split ',', 2` | `@('a','b,c')` |
| Split on regex | `-split '\s+'` | `'a  b   c' -split '\s+'` | `@('a','b','c')` |
| Join array | `-join ','` | `'a','b','c' -join ','` | `a,b,c` |
| Join with Join-String | `\| Join-String -Sep '; '` | `1,2,3 \| Join-String -Sep '; '` | `1; 2; 3` |
| Format string | `-f` operator | `"Hi {0}, you are {1}" -f 'Sam', 30` | `Hi Sam, you are 30` |
| Uppercase | `.ToUpper()` | `'hello'.ToUpper()` | `HELLO` |
| Lowercase | `.ToLower()` | `'HELLO'.ToLower()` | `hello` |
| Trim whitespace | `.Trim()` | `'  hi  '.Trim()` | `hi` |
| Starts with | `.StartsWith('x')` | `'xbox'.StartsWith('x')` | `True` |
| Ends with | `.EndsWith('x')` | `'xbox'.EndsWith('x')` | `False` |
| Length | `.Length` | `'hello'.Length` | `5` |
| Substring | `.Substring(start, len)` | `'PowerShell'.Substring(0, 5)` | `Power` |
| Index of | `.IndexOf('x')` | `'fox'.IndexOf('x')` | `2` |
| Contains (case-insens.) | `-like '*x*'` | `'PowerShell' -like '*Shell*'` | `True` |
| Contains (case-sens.) | `-clike '*x*'` | `'PowerShell' -clike '*shell*'` | `False` |
| Matches regex | `-match` | `'abc123' -match '\d+'` | `True` (sets `$Matches`) |
| Here-string | `@" ... "@` | Multi-line string literal | — |

---

## File I/O One-Liners

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

---

> **Quick tip:** When in doubt, pipe to `Get-Member`. When still in doubt, pipe to `Select-Object *`.
> When completely lost, pipe to `Out-GridView` and click around until it makes sense.
