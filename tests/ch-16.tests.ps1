#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 16 - Automation Recipes" {
    BeforeAll {
        $testDir = Join-Path $env:TEMP "ps-ch16-test-$(Get-Random)"
        New-Item $testDir -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Ex-1 (Simple): clean files older than 7 days" {
        # Create test files
        $old = Join-Path $testDir 'old-temp.log'
        $new = Join-Path $testDir 'new-temp.log'
        Set-Content $old 'old'; Set-Content $new 'new'
        (Get-Item $old).LastWriteTime = (Get-Date).AddDays(-10)

        # Run cleanup
        Get-ChildItem $testDir -File | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-7)
        } | Remove-Item -Force

        Test-Path $old | Should -BeFalse
        Test-Path $new | Should -BeTrue
    }

    It "Ex-2 (Normal): backup with date-stamped folder" {
        $sourceDir  = Join-Path $testDir 'source'
        $backupRoot = Join-Path $testDir 'backups'
        New-Item $sourceDir -ItemType Directory -Force | Out-Null
        Set-Content (Join-Path $sourceDir 'data.txt') 'important data'

        $stamp     = Get-Date -Format 'yyyy-MM-dd_HHmmss'
        $backupDir = Join-Path $backupRoot $stamp
        Copy-Item $sourceDir $backupDir -Recurse -Force

        Test-Path $backupDir | Should -BeTrue
        Test-Path (Join-Path $backupDir 'data.txt') | Should -BeTrue
    }

    It "Ex-3 (Advanced): system inventory produces structured report" {
        $inventory = [PSCustomObject]@{
            Hostname  = (hostname)
            OS        = $PSVersionTable.OS
            PSVersion = $PSVersionTable.PSVersion.ToString()
            Processes = (Get-Process).Count
            Services  = (Get-Service).Count
            Uptime    = [math]::Round((Get-Uptime).TotalHours, 1)
            MemoryMB  = [math]::Round((Get-Process | Measure-Object WorkingSet64 -Sum).Sum / 1MB)
        }
        $inventory.Hostname | Should -Not -BeNullOrEmpty
        $inventory.PSObject.Properties.Count | Should -BeGreaterOrEqual 5
        $inventory.Processes | Should -BeGreaterThan 0
    }

    It "Ex-4 (Extreme): service monitor detects drift from baseline" {
        # Create a mock baseline and current state
        $baseline = @(
            [PSCustomObject]@{ Name = 'ServiceA'; Status = 'Running' },
            [PSCustomObject]@{ Name = 'ServiceB'; Status = 'Running' },
            [PSCustomObject]@{ Name = 'ServiceC'; Status = 'Running' }
        )
        $current = @(
            [PSCustomObject]@{ Name = 'ServiceA'; Status = 'Running' },
            [PSCustomObject]@{ Name = 'ServiceB'; Status = 'Stopped' },
            [PSCustomObject]@{ Name = 'ServiceC'; Status = 'Running' }
        )

        $drift = foreach ($svc in $baseline) {
            $now = $current | Where-Object Name -eq $svc.Name
            if ($now.Status -ne $svc.Status) {
                [PSCustomObject]@{
                    Name     = $svc.Name
                    Expected = $svc.Status
                    Actual   = $now.Status
                }
            }
        }
        $drift.Count | Should -Be 1
        $drift[0].Name | Should -Be 'ServiceB'
        $drift[0].Expected | Should -Be 'Running'
        $drift[0].Actual | Should -Be 'Stopped'
    }
}
