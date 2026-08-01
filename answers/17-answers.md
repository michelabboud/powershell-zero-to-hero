# Chapter 17 -- Answers

---

## Ch-17, Ex-1 (Simple)

**Task:** Write a Pester `Describe` block testing a `Get-Square` function. Cover a positive
number, zero, and a negative number.

### Solution

```powershell
Describe "Get-Square" {
    BeforeAll {
        function Get-Square {
            param([int]$Number)
            $Number * $Number
        }
    }

    It "squares a positive number" {
        Get-Square -Number 5 | Should -Be 25
    }

    It "returns zero for zero input" {
        Get-Square -Number 0 | Should -Be 0
    }

    It "squares a negative number (result is positive)" {
        Get-Square -Number -3 | Should -Be 9
    }
}
```

Or as three assertions in a single `It` block (valid for tightly related cases):

```powershell
Describe "Get-Square" {
    It "returns the square of any integer" {
        function Get-Square { param([int]$Number) $Number * $Number }
        Get-Square -Number 5  | Should -Be 25
        Get-Square -Number 0  | Should -Be 0
        Get-Square -Number -3 | Should -Be 9
    }
}
```

### Expected Output

```
Starting discovery in 1 files.
Discovery found 1 tests in 9ms.

Running tests.
  [+] returns the square of any integer 12ms (9ms|3ms)

Tests completed in 88ms
Tests Passed: 1, Failed: 0, Skipped: 0
```

### What to notice

**Multiplication commutes over sign.** `-3 * -3 = 9` is mathematically obvious, but
it's the test case that catches accidental use of `[Math]::Abs($Number) * $Number` or
similar sign-stripping bugs. The "obvious" test cases are often the ones that expose the
non-obvious assumptions.

**`BeforeAll` vs inline function definition.** Defining the function in `BeforeAll`
makes it available to all `It` blocks in the `Describe` without being redefined on every
test run. Defining it inline in a single `It` works when you're testing the function
itself (as in the one-`It` version above) but doesn't scale to multiple isolated test
cases. For module functions, you'd import the module in `BeforeAll` instead.

**Pester 5's `BeforeAll` scoping rule.** Variables and functions defined in `BeforeAll`
are available throughout the enclosing `Describe`. Variables defined directly in a
`Describe` block (outside `BeforeAll`) are not reliably available in `It` blocks in
Pester 5. When in doubt, put setup code in `BeforeAll`.

---

## Ch-17, Ex-2 (Normal)

**Task:** Write `Invoke-BuildLint` that scans a directory for `.ps1` files, flags any
containing `Write-Host` with rule `AvoidUsingWriteHost`, and returns issue objects.
Verify one issue against a two-file test directory.

### Solution

```powershell
function Invoke-BuildLint {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $issues = [System.Collections.Generic.List[PSCustomObject]]::new()

    $files = Get-ChildItem $Path -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match 'Write-Host') {
            $issues.Add([PSCustomObject]@{
                File     = $file.Name
                Rule     = 'AvoidUsingWriteHost'
                Severity = 'Warning'
            })
        }
    }

    return $issues
}

# --- Test it manually ---
$testDir = Join-Path ([System.IO.Path]::GetTempPath()) "ps-lint-$(Get-Random)"
New-Item $testDir -ItemType Directory -Force | Out-Null

try {
    # "Bad" file -- uses Write-Host
    'Write-Host "Hello from bad script"' | Set-Content (Join-Path $testDir 'bad.ps1')

    # "Good" file -- uses Write-Output
    'Write-Output "Hello from good script"' | Set-Content (Join-Path $testDir 'good.ps1')

    $results = Invoke-BuildLint -Path $testDir

    Write-Host "Issues found: $($results.Count)"   # 1
    $results | Format-Table File, Rule, Severity -AutoSize
} finally {
    Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
```

### Expected Output

```
Issues found: 1

File     Rule                  Severity
----     ----                  --------
bad.ps1  AvoidUsingWriteHost   Warning
```

### What to notice

**Why `Write-Host` is flagged.** Since PowerShell 5, `Write-Host` writes to the
information stream, but its intent remains host-oriented display rather than
pipeline data. In a module or reusable script function, it is usually wrong for
results that callers need to capture or compose. Return objects for data, use
`Write-Verbose` for diagnostic messages
(enabled with `-Verbose`), `Write-Warning` for warnings, and `Write-Error` for errors.
`Write-Host` has one legitimate home: interactive scripts that explicitly target the
console (installers, menus, colorful status displays). Everywhere else, it's a code smell.

**`Get-ChildItem -ErrorAction SilentlyContinue`.** On directories with mixed permissions,
`Get-ChildItem -Recurse` will throw non-terminating errors for folders it can't enter.
`SilentlyContinue` swallows those so your lint run doesn't drown in noise. The real
`Invoke-ScriptAnalyzer` does this internally too.

**Production version.** In a real build, replace the `Write-Host` check with a call to
the actual `PSScriptAnalyzer`:

```powershell
$issues = Invoke-ScriptAnalyzer -Path $Path -Recurse -Severity Error, Warning
```

This simulation is purely for the exercise so the test can run without requiring
`PSScriptAnalyzer` to be installed.

---

## Ch-17, Ex-3 (Advanced)

**Task:** Build a hashtable representing a valid GitHub Actions CI workflow for
PowerShell. Validate workflow name, runner OS, and step count.

### Solution

```powershell
$workflow = @{
    name = 'PowerShell CI'
    on   = @{
        push         = @{ branches = @('main') }
        pull_request = @{ branches = @('main') }
    }
    jobs = @{
        test = @{
            'runs-on' = 'ubuntu-latest'
            steps     = @(
                @{ uses = 'actions/checkout@v7' },
                @{
                    name  = 'Run Pester'
                    shell = 'pwsh'
                    run   = 'Invoke-Pester -CI'
                }
            )
        }
    }
}

# Validate the structure
$workflow.name                         # PowerShell CI
$workflow.jobs.test.'runs-on'          # ubuntu-latest
$workflow.jobs.test.steps.Count        # 2
$workflow.jobs.test.steps[0].uses      # actions/checkout@v7
$workflow.jobs.test.steps[1].shell     # pwsh

# Treat this as an object-model exercise. Maintain production workflow YAML
# directly so the reviewed file is exactly what GitHub interprets.
```

For a real repository, write and review `.github/workflows/ci.yml` directly.
Generic YAML serializers can change quoting or scalar interpretation; always
validate the resulting workflow with GitHub's tooling before relying on it.

### Expected Output

```
PowerShell CI
ubuntu-latest
2
actions/checkout@v7
pwsh
```

### What to notice

**Hashtable keys with hyphens.** `'runs-on'` must be quoted because the hyphen is not
valid in a bare PowerShell identifier. Quoting a key in a hashtable literal is always
valid -- `@{ 'name' = 'test' }` is identical to `@{ name = 'test' }` -- but hyphens
in keys force the quotes. This trips up almost everyone the first time they try to
build GitHub Actions YAML from PowerShell.

**The `on` key.** In PowerShell, `on` is not a reserved word, but it is in YAML (it's a
boolean synonym for `true` in YAML 1.1). Most YAML parsers in the GitHub Actions
infrastructure use YAML 1.2 where this is not an issue, but if you serialize this
hashtable and see `'on': true` in the output, your YAML library is quoting the key as
a safety measure. That's fine -- GitHub Actions handles it correctly.

**`actions/checkout@v7`.** A major-version tag is easier to maintain than
`@main` or `@latest`, but it can still move. For the strongest supply-chain
control, pin a reviewed full commit SHA and use dependency automation to
propose updates.

**Cross-platform `pwsh`.** Specifying `shell: pwsh` on a GitHub Actions step uses the
PowerShell 7 binary (`pwsh`) regardless of the runner OS. On `ubuntu-latest` and
`macos-latest`, `pwsh` is pre-installed. On `windows-latest`, both `pwsh` (PS7) and
`powershell` (Windows PowerShell 5.1) are available. If you use just `shell: pwsh`,
you're always on PS7. If you need Windows PowerShell 5.1 specifically, use
`shell: powershell`.

---

## Ch-17, Ex-4 (Extreme)

**Task:** Write `Invoke-CIPipeline` with `SupportsShouldProcess`. It runs Lint, Test,
and Build phases, returns a status object, and uses `$PSCmdlet.ShouldProcess` to gate
the Build phase. Running with `-WhatIf` must produce `Build = 'DryRun'`.

### Solution

```powershell
function Invoke-CIPipeline {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [string]$Version = '1.0.0'
    )

    $results = [ordered]@{
        Lint    = 'Pending'
        Test    = 'Pending'
        Build   = 'Pending'
        Version = $Version
    }

    # Phase 1: Lint
    Write-Verbose "Phase 1: Lint"
    # In production: Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Severity Error
    $results.Lint = 'Passed'

    # Phase 2: Test
    Write-Verbose "Phase 2: Test"
    # In production: Invoke-Pester -CI
    $results.Test = 'Passed'

    # Phase 3: Build (gated by ShouldProcess / -WhatIf)
    Write-Verbose "Phase 3: Build"
    if ($PSCmdlet.ShouldProcess($ModulePath, "Build module v$Version")) {
        # In production: Copy-Item, Update-ModuleManifest, etc.
        $results.Build = 'Built'
    } else {
        $results.Build = 'DryRun'
    }

    return [PSCustomObject]$results
}

# --- Dry run (what CI does in a PR job) ---
$result = Invoke-CIPipeline -ModulePath './src' -Version '2.0.0' -WhatIf
$result | Format-List

# --- Real run (what CI does on merge to main) ---
# $result = Invoke-CIPipeline -ModulePath './src' -Version '2.0.0'
```

### Expected Output

```
What if: Performing the operation "Build module v2.0.0" on target "./src".

Lint    : Passed
Test    : Passed
Build   : DryRun
Version : 2.0.0
```

### What to notice

**`SupportsShouldProcess` propagation.** When you add `[CmdletBinding(SupportsShouldProcess)]`
to a function, PowerShell activates the `-WhatIf` and `-Confirm` common parameters for
that function. But it only gates execution at the point where you explicitly call
`$PSCmdlet.ShouldProcess(...)`. Everything before that call -- your Lint and Test phases
here -- runs unconditionally, even under `-WhatIf`. This is the correct behavior: you
want the pipeline to validate everything right up to the point of actual mutation (the
build/deploy), then stop. Audit logs and dry-run summaries are most useful when they
reflect as much real work as possible.

**`[ordered]@{}`.** An `[ordered]` hashtable preserves insertion order when iterated
and when cast to `[PSCustomObject]`. Without `[ordered]`, hashtable key order is
non-deterministic in PowerShell (it uses a hash bucket internally). For status objects
that will be displayed or tested in order, `[ordered]` makes the output predictable.

**`$PSCmdlet.ShouldProcess(target, operation)`.** The two-argument form is the standard:
first argument is the object being operated on (shown as "on target"), second is the
verb or operation description. The single-argument form (`ShouldProcess($target)`) uses
a default operation string. Always prefer the two-argument form in build tools -- it
makes the `-WhatIf` output readable in CI logs without decoding variable names.

**`-WhatIf` in CI pull request jobs.** A common pattern is to run the full pipeline
with `-WhatIf` in PR jobs to validate that the pipeline script itself is syntactically
and logically correct, without publishing or deploying anything. On merge to `main`,
the same pipeline runs without `-WhatIf`. This gives you a cheap "pre-flight check"
on every PR.

**`[PSCustomObject]$results`.** Casting `[ordered]@{}` to `[PSCustomObject]` converts
the ordered hashtable into an object whose properties appear in insertion order in
`Format-List`, `Format-Table`, and `ConvertTo-Json`. If you return the raw hashtable,
`Format-List` displays the keys in a system-determined order that varies by PowerShell
version. Always cast to `[PSCustomObject]` for return values from pipeline functions.
