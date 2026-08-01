#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 17 - DevOps & CI/CD" {
    It "Ex-1 (Simple): Pester test validates function output" {
        function Get-Square { param([int]$Number) $Number * $Number }
        Get-Square -Number 5 | Should -Be 25
        Get-Square -Number 0 | Should -Be 0
        Get-Square -Number -3 | Should -Be 9
    }

    It "Ex-2 (Normal): build script runs lint check" {
        function Invoke-BuildLint {
            param([string]$Path)
            # Simulate PSScriptAnalyzer check
            $issues = @()
            $files = Get-ChildItem $Path -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match 'Write-Host') {
                    $issues += [PSCustomObject]@{
                        File = $file.Name
                        Rule = 'AvoidUsingWriteHost'
                        Severity = 'Warning'
                    }
                }
            }
            $issues
        }
        # Create a test file with Write-Host
        $testDir = Join-Path $env:TEMP "ps-lint-$(Get-Random)"
        New-Item $testDir -ItemType Directory -Force | Out-Null
        try {
            'Write-Host "bad practice"' | Set-Content (Join-Path $testDir 'bad.ps1')
            'Write-Output "good practice"' | Set-Content (Join-Path $testDir 'good.ps1')
            $results = Invoke-BuildLint -Path $testDir
            $results.Count | Should -Be 1
            $results[0].Rule | Should -Be 'AvoidUsingWriteHost'
        } finally {
            Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Ex-3 (Advanced): GitHub Actions workflow structure is valid" {
        $workflow = @{
            name = 'PowerShell CI'
            on = @{ push = @{ branches = @('main') }; pull_request = @{ branches = @('main') } }
            jobs = @{
                test = @{
                    'runs-on' = 'ubuntu-latest'
                    steps = @(
                        @{ uses = 'actions/checkout@v4' },
                        @{ name = 'Run Pester'; shell = 'pwsh'; run = 'Invoke-Pester -CI' }
                    )
                }
            }
        }
        $workflow.name | Should -Be 'PowerShell CI'
        $workflow.jobs.test.'runs-on' | Should -Be 'ubuntu-latest'
        $workflow.jobs.test.steps.Count | Should -Be 2
    }

    It "Ex-4 (Extreme): full CI/CD pipeline dry-run" {
        function Invoke-CIPipeline {
            [CmdletBinding(SupportsShouldProcess)]
            param([string]$ModulePath, [string]$Version = '1.0.0')
            $results = [ordered]@{
                Lint = 'Pending'; Test = 'Pending'; Build = 'Pending'; Version = $Version
            }
            # Lint phase
            $results.Lint = 'Passed'
            # Test phase
            $results.Test = 'Passed'
            # Build phase
            if ($PSCmdlet.ShouldProcess($ModulePath, "Build module v$Version")) {
                $results.Build = 'Built'
            } else {
                $results.Build = 'DryRun'
            }
            [PSCustomObject]$results
        }
        $result = Invoke-CIPipeline -ModulePath './src' -Version '2.0.0' -WhatIf
        $result.Lint | Should -Be 'Passed'
        $result.Test | Should -Be 'Passed'
        $result.Build | Should -Be 'DryRun'
        $result.Version | Should -Be '2.0.0'
    }
}
