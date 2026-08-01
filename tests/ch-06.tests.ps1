#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 06 - Control Flow" {
    It "Ex-1 (Simple): if/elseif/else categorizes numbers" {
        function Get-NumberCategory {
            param([int]$Number)
            if ($Number -lt 0) { 'Negative' }
            elseif ($Number -eq 0) { 'Zero' }
            else { 'Positive' }
        }
        Get-NumberCategory -Number -5 | Should -Be 'Negative'
        Get-NumberCategory -Number 0 | Should -Be 'Zero'
        Get-NumberCategory -Number 42 | Should -Be 'Positive'
    }

    It "Ex-2 (Normal): switch classifies log severity" {
        function Get-Severity {
            param([string]$Line)
            switch -Regex ($Line) {
                'FATAL|CRITICAL' { 'Critical'; break }
                'ERROR'          { 'Error'; break }
                'WARN'           { 'Warning'; break }
                'INFO'           { 'Info'; break }
                default          { 'Unknown' }
            }
        }
        Get-Severity '2024-01-15 ERROR disk full' | Should -Be 'Error'
        Get-Severity '2024-01-15 WARN low memory' | Should -Be 'Warning'
        Get-Severity '2024-01-15 FATAL crash' | Should -Be 'Critical'
    }

    It "Ex-3 (Advanced): foreach with continue skips items" {
        $servers = @('web01', '', 'db01', $null, 'app01')
        $processed = foreach ($s in $servers) {
            if ([string]::IsNullOrEmpty($s)) { continue }
            $s
        }
        $processed.Count | Should -Be 3
        $processed | Should -Not -Contain ''
        $processed | Should -Not -Contain $null
    }

    It "Ex-4 (Extreme): retry with backoff respects max attempts" {
        $script:attempts = 0
        function Invoke-WithRetry {
            param([scriptblock]$Action, [int]$MaxRetries = 3)
            for ($i = 0; $i -lt $MaxRetries; $i++) {
                try {
                    return & $Action
                } catch {
                    if ($i -eq ($MaxRetries - 1)) { throw }
                    Start-Sleep -Milliseconds ([math]::Pow(2, $i) * 100)
                }
            }
        }
        # Simulate a flaky operation that succeeds on 3rd try
        $script:attempts = 0
        $result = Invoke-WithRetry -Action {
            $script:attempts++
            if ($script:attempts -lt 3) { throw "Flaky!" }
            "Success"
        } -MaxRetries 5
        $result | Should -Be "Success"
        $script:attempts | Should -Be 3
    }
}
