#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 03 - Commands & Cmdlets" {
    It "Ex-1 (Simple): Get-Help returns help for Get-ChildItem" {
        $help = Get-Help Get-ChildItem
        $help.Name | Should -Be 'Get-ChildItem'
    }

    It "Ex-2 (Normal): top 5 processes by CPU" {
        $top5 = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
        $top5.Count | Should -Be 5
        $top5[0].CPU | Should -BeGreaterOrEqual $top5[4].CPU
    }

    It "Ex-3 (Advanced): find all Stop-verb cmdlets" {
        # Reproduce environments that expose an application or alias whose
        # name starts with Stop- but which is not a PowerShell cmdlet.
        Set-Alias -Name Stop-Clock -Value Get-Date -Scope Local
        $stopCmds = Get-Command -Verb Stop | Where-Object CommandType -EQ Cmdlet
        $stopCmds.Count | Should -BeGreaterThan 0
        $stopCmds | ForEach-Object { $_.Verb | Should -Be 'Stop' }
    }

    It "Ex-4 (Extreme): system health summary has 5+ data points" {
        $health = [PSCustomObject]@{
            ProcessCount  = (Get-Process).Count
            ThreadCount   = (
                Get-Process |
                    ForEach-Object { $_.Threads.Count } |
                    Measure-Object -Sum
            ).Sum
            Uptime        = (Get-Uptime).TotalHours
            UsedMemoryMB  = [math]::Round((Get-Process | Measure-Object WorkingSet64 -Sum).Sum / 1MB)
            TempFileCount = (
                Get-ChildItem ([System.IO.Path]::GetTempPath()) -ErrorAction SilentlyContinue
            ).Count
        }
        @($health.PSObject.Properties).Count | Should -BeGreaterOrEqual 5
    }
}
