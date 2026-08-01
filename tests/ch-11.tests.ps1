#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 11 - Regex & Text" {
    It "Ex-1 (Simple): validate email with -match" {
        'user@example.com' -match '^[\w.+-]+@[\w-]+\.[\w.]+$' | Should -BeTrue
        'not-an-email' -match '^[\w.+-]+@[\w-]+\.[\w.]+$' | Should -BeFalse
    }

    It "Ex-2 (Normal): extract IPs from log lines" {
        $logs = @(
            '2024-01-15 Connection from 192.168.1.100 accepted',
            '2024-01-15 Failed login from 10.0.0.50',
            '2024-01-15 No IP here'
        )
        $ips = $logs | ForEach-Object {
            if ($_ -match '(\d{1,3}\.){3}\d{1,3}') { $Matches[0] }
        }
        $ips.Count | Should -Be 2
        $ips | Should -Contain '192.168.1.100'
        $ips | Should -Contain '10.0.0.50'
    }

    It "Ex-3 (Advanced): named capture groups on log lines" {
        $line = '2024-01-15 14:30:22 ERROR [WebServer] Connection timeout'
        $line -match '(?<date>\d{4}-\d{2}-\d{2})\s(?<time>\d{2}:\d{2}:\d{2})\s(?<level>\w+)\s\[(?<source>\w+)\]' | Should -BeTrue
        $Matches.date | Should -Be '2024-01-15'
        $Matches.level | Should -Be 'ERROR'
        $Matches.source | Should -Be 'WebServer'
    }

    It "Ex-4 (Extreme): multi-pattern log analyzer" {
        $logLines = @(
            '2024-01-15 14:30:22 FATAL Database connection lost',
            '2024-01-15 14:30:23 ERROR Disk space low',
            '2024-01-15 14:30:24 WARN Memory usage high',
            '2024-01-15 14:30:25 INFO Service started',
            '2024-01-15 14:30:26 DEBUG Trace enabled'
        )
        $classified = $logLines | ForEach-Object {
            $level = if ($_ -match '\b(FATAL|CRITICAL)\b') { 'Critical' }
                     elseif ($_ -match '\bERROR\b') { 'Error' }
                     elseif ($_ -match '\bWARN\b') { 'Warning' }
                     elseif ($_ -match '\bINFO\b') { 'Info' }
                     else { 'Debug' }
            [PSCustomObject]@{ Line = $_; Severity = $level }
        }
        ($classified | Where-Object Severity -eq 'Critical').Count | Should -Be 1
        ($classified | Where-Object Severity -eq 'Error').Count | Should -Be 1
        $classified.Count | Should -Be 5
    }
}
