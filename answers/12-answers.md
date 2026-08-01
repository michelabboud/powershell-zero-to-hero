# Chapter 12 -- Answers

---

## Ch-12, Ex-1 (Simple)

**Task:** List all modules currently loaded in your session. Then list all
available modules via `Get-Module -ListAvailable`. Find one module whose `Path`
property indicates it came from the user-scoped PSGallery install location.
Show its name and version.

### Solution

```powershell
# Step 1: see what's loaded right now
$loaded = Get-Module
$loaded | Format-Table Name, Version, ModuleType -AutoSize

# Step 2: see everything available on disk
$available = Get-Module -ListAvailable
$available | Format-Table Name, Version, Path -AutoSize | Out-Host -Paging

# Step 3: find a PSGallery-installed module
# On Windows the user module path is ~/Documents/PowerShell/Modules
# On Linux/macOS it's ~/.local/share/powershell/Modules
$userModulesPath = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) `
    'PowerShell' 'Modules'

$galleryModule = Get-Module -ListAvailable |
    Where-Object { $_.Path -like "$userModulesPath*" } |
    Select-Object -First 1

if ($galleryModule) {
    "Found PSGallery module: $($galleryModule.Name) v$($galleryModule.Version)"
    "Path: $($galleryModule.Path)"
} else {
    "No user-scope modules found. Try: Install-Module -Name Pester -Scope CurrentUser"
}
```

### Expected Output

```
Loaded modules (example):
Name                                 Version  ModuleType
----                                 -------  ----------
Microsoft.PowerShell.Utility         7.0.0.0  Manifest
Microsoft.PowerShell.Management      7.0.0.0  Manifest
PSReadLine                           2.3.5    Script

Found PSGallery module: Pester v5.6.1
Path: /home/rina/.local/share/powershell/Modules/Pester/5.6.1/Pester.psd1
```

### What to notice

`Get-Module` with no arguments only shows modules **loaded in the current
session** -- it's a live snapshot of what's in memory. `Get-Module
-ListAvailable` scans every directory on `$env:PSModulePath` and returns
`ModuleInfo` objects for everything it finds, whether loaded or not. The `Path`
property on each object tells you exactly where on disk the module lives. This
is useful for diagnosing "why is the wrong version loading" problems, which
happen more often than anyone would like to admit -- especially after a system
`Install-Module` drops a module in a location that shadows your user-scoped
version.

---

## Ch-12, Ex-2 (Normal)

**Task:** Create a script module called `TimeUtils` in a temp directory with
three exported functions: `Get-Greeting`, `Get-Farewell`, and `Get-TimeOfDay`.
Use `Export-ModuleMember` explicitly. Import with `-Force`, verify the
functions work, and confirm that a private helper is not accessible externally.

### Solution

```powershell
# Create module directory
$modulePath = Join-Path $env:TEMP 'TimeUtils'
New-Item $modulePath -ItemType Directory -Force | Out-Null

# Write the .psm1 file
$psm1Content = @'
function Get-Greeting {
    param([string]$Name = 'World')
    "Hello, $Name!"
}

function Get-Farewell {
    param([string]$Name = 'World')
    "Goodbye, $Name!"
}

function Get-TimeOfDay {
    $hour = (Get-Date).Hour
    if ($hour -lt 12)      { 'Morning' }
    elseif ($hour -lt 17)  { 'Afternoon' }
    else                   { 'Evening' }
}

# Private helper -- intentionally NOT in Export-ModuleMember
function _FormatInternal {
    param([string]$Text)
    $Text.ToUpper()
}

Export-ModuleMember -Function Get-Greeting, Get-Farewell, Get-TimeOfDay
'@

$psm1Content | Set-Content (Join-Path $modulePath 'TimeUtils.psm1')

# Import with -Force to pick up any changes
Import-Module $modulePath -Force

# Verify exported functions work
Get-Greeting -Name 'Sam'     # Hello, Sam!
Get-Farewell -Name 'Max'     # Goodbye, Max!
Get-TimeOfDay                # Morning / Afternoon / Evening

# Confirm private helper is not accessible
try {
    Get-Command _FormatInternal -ErrorAction Stop
    Write-Warning "UNEXPECTED: private function is visible!"
} catch {
    Write-Host "Confirmed: _FormatInternal is not accessible outside the module."
}

# Clean up
Remove-Module TimeUtils -ErrorAction SilentlyContinue
Remove-Item $modulePath -Recurse -Force
```

### Expected Output

```
Hello, Sam!
Goodbye, Max!
Afternoon
Confirmed: _FormatInternal is not accessible outside the module.
```

### What to notice

Three things are worth studying here:

1. **Export-ModuleMember is your public API contract.** Without it, every
   function defined at module scope is exported. That's rarely what you want.
   With it, you get a clean separation: `_FormatInternal` exists in the
   module's scope and works fine when called by other functions inside the
   module -- it just can't be called from outside. This is PowerShell's
   equivalent of `private` visibility.

2. **Import-Module -Force.** Without `-Force`, if `TimeUtils` is already in
   session memory, `Import-Module` is a no-op. Your changes to the `.psm1`
   are invisible until you force a reload. During development, always use
   `-Force`. In production scripts, omit it -- you don't want to re-import
   on every run.

3. **Module path vs. module name.** When you pass a path to `Import-Module`,
   PowerShell loads from that path directly. When you pass a name,
   PowerShell searches `$env:PSModulePath`. To make `Import-Module TimeUtils`
   work without an explicit path, move the directory to a location on
   `$env:PSModulePath` -- typically `~/Documents/PowerShell/Modules/TimeUtils/`.

---

## Ch-12, Ex-3 (Advanced)

**Task:** Add a `.psd1` manifest to the `TimeUtils` module using
`New-ModuleManifest`. Include at minimum `RootModule`, `ModuleVersion`
(`1.0.0`), `Author`, and `FunctionsToExport`. Validate with
`Test-ModuleManifest` and confirm the returned object reflects the correct
version and author.

### Solution

```powershell
# Create module directory
$modulePath = Join-Path $env:TEMP 'TimeUtils'
New-Item $modulePath -ItemType Directory -Force | Out-Null

# Write the .psm1
@'
function Get-Greeting { param([string]$Name = 'World') "Hello, $Name!" }
function Get-Farewell { param([string]$Name = 'World') "Goodbye, $Name!" }
function Get-TimeOfDay {
    $h = (Get-Date).Hour
    if ($h -lt 12) { 'Morning' } elseif ($h -lt 17) { 'Afternoon' } else { 'Evening' }
}
Export-ModuleMember -Function Get-Greeting, Get-Farewell, Get-TimeOfDay
'@ | Set-Content (Join-Path $modulePath 'TimeUtils.psm1')

# Generate the manifest
$psd1Path = Join-Path $modulePath 'TimeUtils.psd1'
New-ModuleManifest `
    -Path              $psd1Path `
    -RootModule        'TimeUtils.psm1' `
    -ModuleVersion     '1.0.0' `
    -Author            'Rina DevOps' `
    -Description       'Time-of-day greeting utilities' `
    -PowerShellVersion '7.4' `
    -FunctionsToExport @('Get-Greeting', 'Get-Farewell', 'Get-TimeOfDay')

# Validate
$manifest = Test-ModuleManifest $psd1Path

"Name:    $($manifest.Name)"
"Version: $($manifest.Version)"
"Author:  $($manifest.Author)"
"Exports: $($manifest.ExportedFunctions.Keys -join ', ')"

# Assertions
if ($manifest.Version -ne '1.0.0')       { throw "Version mismatch" }
if ($manifest.Author  -ne 'Rina DevOps') { throw "Author mismatch" }

Write-Host "Manifest validated successfully."

# Load the full module via the manifest and confirm it works
Import-Module $modulePath -Force
Get-Greeting -Name 'World'

# Clean up
Remove-Module TimeUtils -ErrorAction SilentlyContinue
Remove-Item $modulePath -Recurse -Force
```

### Expected Output

```
Name:    TimeUtils
Version: 1.0.0
Author:  Rina DevOps
Exports: Get-Greeting, Get-Farewell, Get-TimeOfDay
Manifest validated successfully.
Hello, World!
```

### What to notice

1. **`Test-ModuleManifest` returns a real `ModuleInfo` object.** This is the
   same type that `Get-Module` returns -- you can inspect `ExportedFunctions`,
   `RequiredModules`, `PowerShellVersion`, and everything else through it.
   Using it in CI is the right call: it validates that the `.psm1` file
   referenced by `RootModule` actually exists, that `FunctionsToExport` lists
   functions that are actually defined, and that the version string is valid
   SemVer. These are exactly the things that get silently wrong when you
   edit the manifest by hand.

2. **`FunctionsToExport` in the manifest takes precedence over
   `Export-ModuleMember` in the `.psm1`.** Both can coexist, but the manifest
   wins for tab-completion and discovery. If your manifest says `@('Get-Greeting')`
   but your `.psm1` exports three functions, users won't get tab-completion
   for the two unlisted ones. Keep both in sync -- or pick one mechanism and
   use it consistently. The Public/Private folder pattern (described in the
   chapter) solves this by deriving `FunctionsToExport` programmatically.

3. **Module versioning via directory structure.** Once you have a manifest,
   you can install multiple versions side-by-side:
   `~/Documents/PowerShell/Modules/TimeUtils/1.0.0/` and
   `~/Documents/PowerShell/Modules/TimeUtils/2.0.0/`. PowerShell auto-selects
   the latest unless you specify `-RequiredVersion`. This is how `Install-Module`
   manages updates without breaking scripts that pin older versions.

---

## Ch-12, Ex-4 (Extreme)

**Task:** Build a module called `DataUtils` with a private `_ValidateInput`
helper and a public `Get-ProcessedData` function. `Get-ProcessedData` must use
the private helper internally, throw `"Invalid input"` on blank/null input, and
return the trimmed uppercase string on valid input. Verify via Pester that the
public function works and the private helper is not accessible externally.

### Solution

```powershell
# Create module directory
$modulePath = Join-Path $env:TEMP "DataUtils-$(Get-Random)"
New-Item $modulePath -ItemType Directory -Force | Out-Null

try {
    # Write the .psm1 with clear public/private separation
    $psm1Content = @'
#region Private

function _ValidateInput {
    param([string]$Input)
    # Returns $true only if the string has meaningful content
    -not [string]::IsNullOrWhiteSpace($Input)
}

#endregion Private

#region Public

function Get-ProcessedData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Data
    )

    if (-not (_ValidateInput $Data)) {
        throw "Invalid input"
    }

    $Data.ToUpper().Trim()
}

#endregion Public

Export-ModuleMember -Function Get-ProcessedData
'@

    $psm1Content | Set-Content (Join-Path $modulePath 'DataUtils.psm1')

    # Import the module
    Import-Module $modulePath -Force

    # --- Inline Pester-style verification ---

    # Test 1: valid input gets processed correctly
    $result = Get-ProcessedData -Data '  hello  '
    if ($result -ne 'HELLO') {
        throw "Test 1 FAILED: expected 'HELLO', got '$result'"
    }
    Write-Host "PASS: Get-ProcessedData -Data '  hello  ' => '$result'"

    # Test 2: blank input throws
    $threwOnBlank = $false
    try {
        Get-ProcessedData -Data '   ' | Out-Null
    } catch {
        $threwOnBlank = $true
        Write-Host "PASS: blank input throws as expected ('$($_.Exception.Message)')"
    }
    if (-not $threwOnBlank) {
        throw "Test 2 FAILED: blank input should have thrown"
    }

    # Test 3: null input throws (Mandatory catches this before our code does,
    # but verify the contract holds)
    $threwOnEmpty = $false
    try {
        Get-ProcessedData -Data '' | Out-Null
    } catch {
        $threwOnEmpty = $true
        Write-Host "PASS: empty string throws as expected"
    }
    if (-not $threwOnEmpty) {
        throw "Test 3 FAILED: empty string should have thrown"
    }

    # Test 4: private helper is not visible outside the module
    $privateVisible = $false
    try {
        Get-Command _ValidateInput -ErrorAction Stop | Out-Null
        $privateVisible = $true
    } catch {
        Write-Host "PASS: _ValidateInput is not accessible outside the module"
    }
    if ($privateVisible) {
        throw "Test 4 FAILED: _ValidateInput should not be accessible externally"
    }

    Write-Host "`nAll tests passed."

} finally {
    Remove-Module DataUtils -ErrorAction SilentlyContinue
    Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
}
```

### Running as a Proper Pester Test

The test file `tests/ch-12.tests.ps1` covers this exercise. To run it directly:

```powershell
Invoke-Pester ./tests/ch-12.tests.ps1 -Output Detailed
```

### Expected Output

```
PASS: Get-ProcessedData -Data '  hello  ' => 'HELLO'
PASS: blank input throws as expected ('Invalid input')
PASS: empty string throws as expected
PASS: _ValidateInput is not accessible outside the module

All tests passed.
```

### What to notice

1. **Private functions work inside the module, invisibly outside.** When
   `Get-ProcessedData` calls `_ValidateInput $Data`, it's calling a function
   that exists in the module's private scope. The call works perfectly. But
   from outside the module -- including in the calling script, in Pester, in
   the interactive shell -- `_ValidateInput` doesn't exist. `Get-Command
   _ValidateInput` throws because PowerShell's command lookup only scans the
   public surface. This is the entire point of `Export-ModuleMember`.

2. **`[Parameter(Mandatory)]` is your first line of defense.** Before your
   validation code even runs, PowerShell rejects calls that omit `$Data`
   entirely. The `_ValidateInput` check handles the subtler case: a string
   that *is* provided but is blank or whitespace. Layering these two checks --
   Mandatory for presence, custom logic for content -- is the clean production
   pattern.

3. **`try/finally` for test cleanup.** The `finally` block runs whether the
   tests pass, fail, or throw. This guarantees the temp directory and loaded
   module get cleaned up even if assertion 2 unexpectedly passes when it
   shouldn't. Pester handles this for you automatically with `AfterEach`/
   `AfterAll` -- but in ad-hoc scripts, `try/finally` is the equivalent
   discipline.

4. **Naming conventions for private functions.** The `_` prefix is a community
   convention (borrowed from Python), not a PowerShell language rule. Any name
   works for a private function -- the privacy comes from `Export-ModuleMember`,
   not the name. The prefix is a signal to the human reader. Some teams use
   `Private\` subdirectories (the Public/Private folder pattern) instead.
   Either approach is fine; pick one and be consistent within a module.

5. **This pattern is your module architecture foundation.** Real team modules
   follow exactly this shape: a thin exported public layer that validates
   inputs and calls private helpers that do the actual work. The public layer
   is stable (changing it breaks callers); the private layer can be refactored
   freely. Once you internalize this split, writing testable, maintainable
   PowerShell modules becomes mechanical.
