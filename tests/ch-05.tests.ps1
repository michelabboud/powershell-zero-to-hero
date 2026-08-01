#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 05 - Operators & Expressions" {
    It "Ex-1 (Simple): -eq is case-insensitive, -ceq is case-sensitive" {
        'Hello' -eq 'hello' | Should -BeTrue
        'Hello' -ceq 'hello' | Should -BeFalse
    }

    It "Ex-2 (Normal): filter array with comparison operators" {
        $nums = 1..20
        $filtered = $nums | Where-Object { $_ -gt 5 -and $_ -le 15 }
        $filtered.Count | Should -Be 10
        $filtered | ForEach-Object { $_ | Should -BeGreaterThan 5; $_ | Should -BeLessOrEqual 15 }
    }

    It "Ex-3 (Advanced): regex extraction from log line" {
        $log = '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout after 30s'
        $log -match '(\d{4}-\d{2}-\d{2})\s(\d{2}:\d{2}:\d{2})\s(\w+)\s\[(\w+)\]' | Should -BeTrue
        $Matches[1] | Should -Be '2024-01-15'
        $Matches[3] | Should -Be 'ERROR'
        $Matches[4] | Should -Be 'WebServer'
    }

    It "Ex-4 (Extreme): splatted query builder produces valid filter" {
        function Get-FilteredProcess {
            param([hashtable]$Criteria)
            $splat = @{}
            if ($Criteria.Name) { $splat['Name'] = $Criteria.Name }
            Get-Process @splat | Where-Object {
                (-not $Criteria.MinCPU -or $_.CPU -ge $Criteria.MinCPU)
            }
        }
        $result = Get-FilteredProcess -Criteria @{ Name = 'pwsh'; MinCPU = 0 }
        $result | Should -Not -BeNullOrEmpty
    }
}
