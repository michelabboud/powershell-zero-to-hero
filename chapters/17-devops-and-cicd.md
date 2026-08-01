# Chapter 17: DevOps & CI/CD

Sam deployed to production with `Copy-Item`. Rina watched it happen. This chapter is about what comes after that conversation.

![chapter-opener](assets/images/ch-17-opener.png)

---

## Why CI/CD Exists

Every team has a version of Sam's deploy script. Sometimes it's `robocopy`. Sometimes it's a Word document titled "HOW TO DEPLOY (DO NOT DELETE)". Sometimes it's tribal knowledge held by the one person who's on vacation when production breaks at 3 AM.

Continuous Integration / Continuous Delivery (CI/CD) replaces that with a pipeline: a reproducible, automated sequence of lint → test → build → deploy that runs every time someone pushes code. The machine does the ceremony. Humans review the results.

![cicd-pipeline-overview](assets/images/ch-17-pipeline-overview.png)

---

## Pester: PowerShell's Testing Framework

Pester is the de-facto testing framework for PowerShell. It ships with Windows and is available on all platforms. If you write PowerShell professionally and you're not writing Pester tests, you're one bad refactor away from a very interesting incident report.

### The Anatomy of a Pester Test

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

| Block | Purpose |
|---|---|
| `Describe` | Top-level grouping — usually one per function or module |
| `Context` | Sub-grouping within a Describe — use for scenarios |
| `It` | A single test case — must assert at least one thing |

### Should Assertions

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

The `{ ... } | Should -Throw` pattern wraps a scriptblock so Pester can catch the exception and assert against it. If you call the function directly (without the braces), the exception propagates and the test errors rather than fails -- a subtle but important distinction.

### Context Blocks and BeforeEach / AfterEach

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

### Mocking

Mocking replaces a real command with a fake one for the duration of a test. It's how you test network calls, file writes, or anything with side effects without actually doing the thing.

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

### Running Pester

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

### Code Coverage

```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './src/*.ps1'
$config.CodeCoverage.CoveragePercentTarget = 80   # Fail below 80%
$config.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $config
```

A coverage target of 80% is a pragmatic floor. 100% is a vanity metric -- it measures lines executed, not logic branches validated. Aim to cover the paths that matter: happy path, error conditions, and edge cases.

---

## PSScriptAnalyzer: The Linter

PSScriptAnalyzer is to PowerShell what ESLint is to JavaScript: a static analysis tool that catches bad practices before they reach production. It ships with VS Code's PowerShell extension and runs in CI.

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

### Common Rules You'll Hit

| Rule | What It Catches | Why It Matters |
|---|---|---|
| `AvoidUsingWriteHost` | `Write-Host` in scripts | Breaks pipeline; use `Write-Output` or `Write-Verbose` |
| `PSUseDeclaredVarsMoreThanAssignments` | Variables assigned but never used | Probably a typo in the variable name |
| `AvoidUsingInvokeExpression` | `Invoke-Expression` | Code injection vector |
| `UseShouldProcessForStateChangingFunctions` | Mutating functions without `-WhatIf` | Makes scripts unauditable |
| `AvoidUsingPlainTextForPassword` | Password params typed as `[string]` | Use `[SecureString]` |
| `PSUseApprovedVerbs` | Functions with non-standard verbs | Breaks discoverability conventions |

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

---

## `#Requires` Statements

`#Requires` is a declaration at the top of a script that tells PowerShell what it needs to run. If the requirements aren't met, the script stops immediately with a clear error -- before executing a single line of your code.

```powershell
#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator
#Requires -PSEdition Core
```

| Directive | Validates |
|---|---|
| `-Version 7.4` | PowerShell version >= 7.4 |
| `-Modules ModuleName` | Module is installed and importable |
| `-Modules @{ModuleName='X'; ModuleVersion='5.0'}` | Specific minimum version |
| `-RunAsAdministrator` | Script is running elevated |
| `-PSEdition Core` | Running on PS Core (not Windows PowerShell 5.x) |

Multiple `#Requires` lines are allowed and all are checked. The check happens at parse time, not at runtime, so you can't conditionally bypass it. That's the feature: it's a hard contract, not a suggestion.

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

---

## Build Scripts: The `build.ps1` Pattern

A build script is a PowerShell script that orchestrates all the steps to go from source code to a deployable artifact. It replaces the mental model of "run these five commands in the right order" with one command: `./build.ps1`.

![build-script-flow](assets/images/ch-17-build-flow.png)

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

1. `Set-StrictMode -Version Latest` -- catches undeclared variables and other loose-PowerShell traps at build time, not production time.
2. `$ErrorActionPreference = 'Stop'` -- any non-terminating error becomes terminating. The build fails loudly.
3. `SupportsShouldProcess` on the script itself -- lets you dry-run the build step (`./build.ps1 -WhatIf`) without actually copying files.
4. Each phase writes a clear status line so the build log is readable at a glance.

---

## GitHub Actions for PowerShell

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

### Multi-Platform Matrix

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

### Caching Modules

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

---

## Azure DevOps Pipelines

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

The `PublishTestResults@2` task ingests the NUnit XML and shows pass/fail counts in the Azure DevOps build summary UI -- no log-scraping required.

### Key Differences: GitHub Actions vs Azure DevOps

| | GitHub Actions | Azure DevOps |
|---|---|---|
| PowerShell shell | `shell: pwsh` on any step | `pwsh: true` on `PowerShell@2` task |
| Variables | `${{ env.VAR }}` | `$(VAR)` |
| Artifacts | `upload-artifact@v4` | `PublishBuildArtifacts@1` |
| Test results | Third-party action | `PublishTestResults@2` built-in |
| Free tier | 2000 min/month (public repos: unlimited) | 1800 min/month |

---

## Release Automation

Once the pipeline is green, release automation handles versioning, changelog generation, and publishing -- without a human clicking buttons.

### Semantic Versioning with `Update-ModuleManifest`

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

### Publishing to a Repository

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

---

## Putting It Together: A Full Pipeline View

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

Max walks over to Sam's desk two weeks after the initial conversation. Sam's CI dashboard is green. "I see your pipeline passed," Max says. Sam nods: "48 tests, zero lint issues, published to the gallery in 90 seconds." Max: "Good. Now write the rollback procedure." Some things never change.

![green-pipeline](assets/images/ch-17-green-pipeline.png)

---

## Exercises

### [Ch-17, Ex-1] Simple: Write a Pester Test for a Function

Write a Pester `Describe` block that tests a `Get-Square` function.
The function takes an integer parameter and returns its square.
Cover: a positive number, zero, and a negative number.

### [Ch-17, Ex-2] Normal: Add PSScriptAnalyzer to a Build Script

Write an `Invoke-BuildLint` function that:
- Accepts a `-Path` parameter pointing to a directory
- Uses `Get-ChildItem` to find all `.ps1` files recursively
- Simulates a lint check: flag any file containing `Write-Host` as a `Warning` with rule `AvoidUsingWriteHost`
- Returns a collection of issue objects with `File`, `Rule`, and `Severity` properties

Test it against a directory containing one "bad" file (`Write-Host`) and one "good" file (`Write-Output`). Verify exactly one issue is returned.

### [Ch-17, Ex-3] Advanced: Create a GitHub Actions Workflow

Build a hashtable that represents a valid GitHub Actions CI workflow for PowerShell:
- Name: `PowerShell CI`
- Triggers: `push` and `pull_request` on `main`
- One job named `test` running on `ubuntu-latest`
- Two steps: `actions/checkout@v4`, then a `pwsh` step that runs `Invoke-Pester -CI`

Validate the structure with assertions: workflow name, runner OS, and step count.

### [Ch-17, Ex-4] Extreme: Full CI/CD Pipeline (Dry-Run)

Write an `Invoke-CIPipeline` function that:
- Accepts `-ModulePath` and `-Version` parameters
- Supports `-WhatIf` via `SupportsShouldProcess`
- Runs three phases in order: Lint (always passes in this exercise), Test (always passes), Build
- During the Build phase, uses `$PSCmdlet.ShouldProcess` to gate the actual work
- Returns a `[PSCustomObject]` with `Lint`, `Test`, `Build`, and `Version` properties
- When run with `-WhatIf`: `Build` should be `'DryRun'` instead of `'Built'`

Invoke it with `-WhatIf` and assert the dry-run behavior.

---

## Key Takeaways

- Pester's `Describe / Context / It / Should` hierarchy maps directly to how you think about behavior. Write tests that read like specifications.
- `Should -Throw` requires a scriptblock: `{ Risky-Call } | Should -Throw`. Without braces the exception escapes.
- PSScriptAnalyzer's `AvoidUsingWriteHost` is not pedantic -- `Write-Host` bypasses the pipeline and makes output untestable.
- `#Requires` is a hard contract enforced at parse time. Use it on every script with real prerequisites.
- `build.ps1` with `Set-StrictMode` and `$ErrorActionPreference = 'Stop'` turns loose scripts into auditable build artifacts.
- GitHub Actions uses `shell: pwsh`. Azure DevOps uses `pwsh: true` on `PowerShell@2`. Both run cross-platform.
- `SupportsShouldProcess` + `$PSCmdlet.ShouldProcess(...)` enables `-WhatIf` on any mutating function. Use it. CI pipelines can dry-run before merging.
- The publish step belongs on `main` merges only, behind a secret API key, never in PR jobs.

---

*Next up: [Chapter 18 -- Module Development and Distribution](18-module-development.md), where
Sam finally learns that a folder full of `.ps1` files is not a module.*
