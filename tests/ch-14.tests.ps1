#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 14 - Remoting & Jobs" {
    It "Ex-1 (Simple): Invoke-Command runs scriptblock locally" {
        $result = Invoke-Command -ScriptBlock { $env:COMPUTERNAME ?? (hostname) }
        $result | Should -Not -BeNullOrEmpty
    }

    It "Ex-2 (Normal): Start-Job and Receive-Job work" {
        $job = Start-Job -ScriptBlock { 1..5 | ForEach-Object { $_ * 2 } }
        $job | Wait-Job -Timeout 30 | Out-Null
        $result = Receive-Job $job
        Remove-Job $job
        $result | Should -Be @(2, 4, 6, 8, 10)
    }

    It "Ex-3 (Advanced): ForEach-Object -Parallel processes concurrently" {
        $results = 1..5 | ForEach-Object -Parallel {
            [PSCustomObject]@{ Input = $_; Squared = $_ * $_ }
        } -ThrottleLimit 3
        $results.Count | Should -Be 5
        ($results | Where-Object Input -eq 3).Squared | Should -Be 9
    }

    It "Ex-4 (Extreme): parallel fan-out with throttling and aggregation" {
        $targets = @('task-A', 'task-B', 'task-C', 'task-D', 'task-E')
        $results = $targets | ForEach-Object -Parallel {
            $target = $_
            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)
            [PSCustomObject]@{
                Target    = $target
                Status    = 'Success'
                Duration  = (Get-Random -Minimum 50 -Maximum 200)
            }
        } -ThrottleLimit 2

        $results.Count | Should -Be 5
        ($results | Where-Object Status -eq 'Success').Count | Should -Be 5
        $results | ForEach-Object { $_.Target | Should -BeIn $targets }
    }
}
