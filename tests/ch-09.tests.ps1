#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 09 - Working with Files" {
    BeforeAll {
        $testDir = Join-Path $env:TEMP "ps-ch09-test-$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Ex-1 (Simple): create, write, read file" {
        $file = Join-Path $testDir 'test.txt'
        'Hello PowerShell' | Set-Content $file
        Test-Path $file | Should -BeTrue
        Get-Content $file | Should -Be 'Hello PowerShell'
    }

    It "Ex-2 (Normal): CSV import, transform, export" {
        $csvIn = Join-Path $testDir 'servers.csv'
        $csvOut = Join-Path $testDir 'servers-report.csv'
        @"
Name,CPU,Memory
web01,45,2048
db01,80,8192
app01,30,4096
"@ | Set-Content $csvIn

        Import-Csv $csvIn |
            Select-Object Name, CPU, Memory, @{
                Name = 'MemoryGB'
                Expression = { [math]::Round([int]$_.Memory / 1024, 1) }
            } |
            Export-Csv $csvOut -NoTypeInformation

        $result = Import-Csv $csvOut
        $result.Count | Should -Be 3
        $result[0].PSObject.Properties.Name | Should -Contain 'MemoryGB'
    }

    It "Ex-3 (Advanced): find files by age" {
        # Create test files with different timestamps
        $old = Join-Path $testDir 'old.log'
        $new = Join-Path $testDir 'new.log'
        Set-Content $old 'old content'
        Set-Content $new 'new content'
        (Get-Item $old).LastWriteTime = (Get-Date).AddDays(-60)

        $stale = Get-ChildItem $testDir -File | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-30)
        }
        $stale.Count | Should -Be 1
        $stale.Name | Should -Be 'old.log'
    }

    It "Ex-4 (Extreme): JSON config read/write with validation" {
        $configPath = Join-Path $testDir 'config.json'
        $config = @{
            AppName = 'MyApp'
            Version = '1.0.0'
            Settings = @{
                Port = 8080
                Debug = $false
            }
        }
        $config | ConvertTo-Json -Depth 5 | Set-Content $configPath

        $loaded = Get-Content $configPath -Raw | ConvertFrom-Json
        $loaded.AppName | Should -Be 'MyApp'
        $loaded.Settings.Port | Should -Be 8080
        $loaded.Settings.Debug | Should -BeFalse
    }
}
