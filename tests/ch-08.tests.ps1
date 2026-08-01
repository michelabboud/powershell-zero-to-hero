#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 08 - The Pipeline Deep Dive" {
    It "Ex-1 (Simple): filter processes by memory > threshold" {
        $threshold = 10MB  # Use 10MB for test reliability
        $heavy = Get-Process | Where-Object { $_.WorkingSet64 -gt $threshold }
        $heavy | Should -Not -BeNullOrEmpty
        $heavy | ForEach-Object { $_.WorkingSet64 | Should -BeGreaterThan $threshold }
    }

    It "Ex-2 (Normal): Group-Object with Measure-Object" {
        $data = @(
            [PSCustomObject]@{ Category = 'A'; Value = 10 },
            [PSCustomObject]@{ Category = 'A'; Value = 20 },
            [PSCustomObject]@{ Category = 'B'; Value = 30 }
        )
        $grouped = $data | Group-Object Category | ForEach-Object {
            [PSCustomObject]@{
                Category = $_.Name
                Average  = ($_.Group | Measure-Object Value -Average).Average
            }
        }
        $grouped.Count | Should -Be 2
        ($grouped | Where-Object Category -eq 'A').Average | Should -Be 15
    }

    It "Ex-3 (Advanced): calculated property converts bytes to MB" {
        $procs = Get-Process | Select-Object Name, @{
            Name = 'MemoryMB'
            Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) }
        } | Select-Object -First 3
        $procs[0].PSObject.Properties.Name | Should -Contain 'MemoryMB'
        $procs[0].MemoryMB | Should -BeOfType [double]
    }

    It "Ex-4 (Extreme): full pipeline with group, measure, and export" {
        $tempCsv = Join-Path ([System.IO.Path]::GetTempPath()) "ps-test-export-$(Get-Random).csv"
        try {
            # Create test data and process through pipeline
            $data = @(
                [PSCustomObject]@{ Source = 'AppA'; Duration = 100 },
                [PSCustomObject]@{ Source = 'AppA'; Duration = 200 },
                [PSCustomObject]@{ Source = 'AppB'; Duration = 150 }
            )
            $data | Group-Object Source | ForEach-Object {
                [PSCustomObject]@{
                    Source      = $_.Name
                    Count       = $_.Count
                    AvgDuration = ($_.Group | Measure-Object Duration -Average).Average
                }
            } | Export-Csv -Path $tempCsv -NoTypeInformation

            $imported = Import-Csv $tempCsv
            $imported.Count | Should -Be 2
            $imported[0].PSObject.Properties.Name | Should -Contain 'AvgDuration'
        } finally {
            Remove-Item $tempCsv -ErrorAction SilentlyContinue
        }
    }
}
