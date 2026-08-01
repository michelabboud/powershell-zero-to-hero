# Chapter 12: Modules and Packages

Max has a module from 2018. This is Sam's problem now.

![chapter-opener](assets/images/ch-12-opener.png)

---

## What Is a Module?

A **module** is a self-contained package of PowerShell functionality: functions,
variables, aliases, and cmdlets bundled together so you can load them once and
use them everywhere. The moment your `functions.ps1` gets dot-sourced in more
than two scripts, it's time to turn it into a module.

PowerShell ships with modules. Your session already has some loaded. The
PowerShell Gallery hosts thousands more. And you can write your own in about
ten minutes -- with a manifest that doesn't shame you in front of Rina.

Here's the mental map:

![module-types](assets/images/ch-12-module-types.png)

---

## Exploring Loaded Modules

### Get-Module

`Get-Module` shows you what's currently loaded in your session and what's
available to load.

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

The difference between `Get-Module` and `Get-Module -ListAvailable` is the
difference between "what's in memory right now" and "what's on the PSModulePath
disk search path." You'll use `-ListAvailable` far more often in practice.

### $env:PSModulePath

This environment variable is the colon-separated (Linux/macOS) or
semicolon-separated (Windows) list of directories where PowerShell looks for
modules.

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

Any directory on `PSModulePath` that contains a subfolder named after a module
(e.g., `MyModule/MyModule.psm1` or `MyModule/MyModule.psd1`) will be
auto-discovered by `Get-Module -ListAvailable` and auto-imported on first use
in PowerShell 3+.

The user-scoped modules folder (`~/Documents/PowerShell/Modules` on Windows,
`~/.local/share/powershell/Modules` on Linux) is where `Install-Module` puts
things by default and where your own modules should live during development.

---

## Loading and Unloading Modules

### Import-Module

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

The `-Force` flag is your best friend during module development. Without it,
`Import-Module` is a no-op if the module is already in memory -- meaning your
code changes don't take effect. Always use `-Force` when iterating.

### Remove-Module

```powershell
# Unload a module from the current session
Remove-Module Pester

# Unload by pipeline
Get-Module | Where-Object Name -like 'My*' | Remove-Module

# Force-remove (even if other modules depend on it)
Remove-Module Pester -Force
```

`Remove-Module` doesn't delete files -- it only removes the module from the
current session's memory. The files on disk are untouched. This matters in
tests and development workflows where you want a clean slate without restarting
the shell.

---

## The PowerShell Gallery

PSGallery is the official public repository for PowerShell modules, scripts,
and DSC resources. It's backed by NuGet and maintained by Microsoft.

![gallery-flow](assets/images/ch-12-gallery-flow.png)

### Finding Modules

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

### Installing Modules

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

The `-Scope CurrentUser` flag installs into your user-scoped modules directory
and requires no elevation. `-Scope AllUsers` installs system-wide but needs
admin rights. Use `CurrentUser` by default -- it's safer, reversible, and
doesn't require a UAC prompt.

### Checking Gallery Trust

The first time you install from PSGallery, PowerShell asks you to confirm you
trust the repository. In automated pipelines, pre-trust it explicitly:

```powershell
# Register the gallery as trusted (run once, or in pipeline setup)
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Verify
Get-PSRepository
```

---

## Script Modules (.psm1)

A script module is a `.psm1` file. That's it. Any `.ps1` file renamed to
`.psm1` is technically a script module. The difference is what you
*choose to export*.

### A Minimal Module

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

Save this as `~/Documents/PowerShell/Modules/MyGreeter/MyGreeter.psm1` and
PowerShell will find it automatically:

```powershell
Import-Module MyGreeter
Get-Greeting -Name 'Rina'   # Hello, Rina!
Get-Farewell -Name 'Sam'    # Goodbye, Sam!
_FormatName -Name 'test'    # Error: not recognized (private)
```

### Export-ModuleMember

`Export-ModuleMember` controls the public API surface of your module. Without
it, **all functions defined at module scope are exported by default** -- which
is rarely what you want.

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

The best practice: always call `Export-ModuleMember` explicitly at the bottom
of your `.psm1`. It serves as documentation and prevents accidental leakage of
internal helpers.

---

## Module Manifests (.psd1)

A manifest is a PowerShell data file (hashtable syntax) that describes your
module. It's the difference between "a file Max wrote in 2018" and "a proper
versioned package."

![manifest-anatomy](assets/images/ch-12-manifest-anatomy.png)

### Creating a Manifest

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

This creates a fully-commented `.psd1` you can open and edit. Most fields are
optional, but these are the ones you should always fill in:

| Field | Why it matters |
|---|---|
| `ModuleVersion` | Enables side-by-side installs and `RequiredVersion` pinning |
| `RootModule` | Points to your `.psm1` -- without this, the manifest does nothing |
| `FunctionsToExport` | Defines the public API for tab-completion and discovery |
| `PowerShellVersion` | Guards against running on incompatible PS versions |
| `Description` | Required for PSGallery; shows up in `Find-Module` results |

### Validating a Manifest

```powershell
# Test-ModuleManifest returns a ModuleInfo object or throws on error
$info = Test-ModuleManifest ./MyGreeter/MyGreeter.psd1

$info.Name            # MyGreeter
$info.Version         # 1.0.0
$info.Author          # Rina DevOps
$info.ExportedFunctions.Keys  # Get-Greeting, Get-Farewell
```

Run `Test-ModuleManifest` in your CI pipeline. It catches common mistakes --
missing `.psm1` file, malformed version strings, undefined functions in
`FunctionsToExport` -- before they blow up in production.

---

## Module Versioning

PowerShell supports multiple installed versions of the same module
side-by-side. The directory structure encodes the version:

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

- **MAJOR** version: breaking changes (cmdlet renamed, parameter removed)
- **MINOR** version: new functions added (backward compatible)
- **PATCH** version: bug fixes (no API changes)

---

## The #Requires Statement

`#Requires` is a preprocessor guard that runs before any code in your script
or module. If the requirements aren't met, the script refuses to execute.

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

`#Requires` must appear at the top of the file, before any code. It's not a
comment -- PowerShell parses it specially. If the requirement fails, you get a
clear, actionable error message rather than a cryptic runtime failure three
functions deep.

Use `#Requires` in:
- Any script that depends on non-default modules
- Any script that needs elevation
- Any module that requires a specific PS version for a language feature

---

## Practical Pattern: The Team Utilities Module

Here's a realistic module structure for a small team:

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

This pattern scales cleanly: add a file to `Public/` and it's automatically
exported. Add a file to `Private/` and it stays internal. No manual list
to keep in sync.

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

---

## Exercises

### [Ch-12, Ex-1] Simple: Explore Loaded and Available Modules

List all modules currently loaded in your session. Then list all modules
available via `Get-Module -ListAvailable`. Find one module whose source
path looks like it came from PSGallery (hint: look for the user modules
directory in its `Path` property). Show its name and version.

### [Ch-12, Ex-2] Normal: Create a Script Module with Three Exported Functions

Create a script module called `TimeUtils` in a temp directory. The module
should export exactly three functions:

- `Get-Greeting` -- returns `"Hello, <name>!"`
- `Get-Farewell` -- returns `"Goodbye, <name>!"`
- `Get-TimeOfDay` -- returns `"Morning"`, `"Afternoon"`, or `"Evening"` based
  on the current hour (before 12, before 17, otherwise)

Use `Export-ModuleMember` explicitly. Import it with `-Force`, verify that all
three functions work, and that calling a non-exported private helper throws a
"not recognized" error.

### [Ch-12, Ex-3] Advanced: Create a Module with a .psd1 Manifest

Extend the `TimeUtils` exercise by adding a `.psd1` manifest. Use
`New-ModuleManifest` with at minimum: `RootModule`, `ModuleVersion` (`1.0.0`),
`Author`, and `FunctionsToExport`. Validate the manifest with
`Test-ModuleManifest` and confirm the returned object has the correct
`Version` and `Author` values.

### [Ch-12, Ex-4] Extreme: Public/Private Module with Pester Tests

Build a module called `DataUtils` with a clear public/private separation:

- **Private helper:** `_ValidateInput` -- returns `$true` if the string is
  non-null and non-whitespace, `$false` otherwise. Not exported.
- **Public function:** `Get-ProcessedData` -- accepts a mandatory `[string]$Data`
  parameter, calls `_ValidateInput` internally, throws `"Invalid input"` if
  validation fails, and returns the trimmed, uppercased string if valid.
- Verify via Pester that `Get-ProcessedData -Data '  hello  '` returns `'HELLO'`.
- Verify that `_ValidateInput` is *not* accessible from outside the module
  (the `Get-Command _ValidateInput` call should throw).

---

## Key Takeaways

- `Get-Module` shows what's loaded; `Get-Module -ListAvailable` shows what's
  on `$env:PSModulePath`. Know the difference.
- `Import-Module -Force` is mandatory during development. Without it, your
  edits don't take effect.
- `Export-ModuleMember` is not optional -- call it explicitly to define your
  public API and keep private helpers private.
- A `.psd1` manifest adds versioning, dependency declarations, and
  discoverability. Write one for every module you share.
- Use `New-ModuleManifest` to generate the manifest. Use `Test-ModuleManifest`
  to validate it in CI.
- PSGallery is the public module registry. `Find-Module` / `Install-Module` /
  `Update-Module` are your interface to it. Use `-Scope CurrentUser` unless
  you specifically need system-wide installation.
- `#Requires` runs before your code. Use it to gate on PS version, required
  modules, and admin rights.
- The Public/Private folder pattern scales cleanly and makes your module's
  API surface self-documenting.

---

*Next up: [Chapter 13 -- Objects and .NET](13-objects-and-dotnet.md), where we
look beneath cmdlets at the object system that powers them.*
