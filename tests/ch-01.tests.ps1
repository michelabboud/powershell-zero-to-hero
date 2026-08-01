#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 01 - What Is PowerShell?" {

    It "Ex-1 (Simple): PSVersionTable has required keys" {
        $keys = $PSVersionTable.Keys
        $keys | Should -Contain 'PSVersion'
        $keys | Should -Contain 'PSEdition'
        $keys | Should -Contain 'OS'
    }

    It "Ex-2 (Normal): Get-Command filters by verb and module" {
        $cmds = Get-Command -Verb Get -Module Microsoft.PowerShell.Utility
        $cmds.Count | Should -BeGreaterThan 0
        $cmds | ForEach-Object { $_.Verb | Should -Be 'Get' }
    }

    It "Ex-3 (Advanced): count of cmdlets, functions, and aliases" {
        $all = Get-Command
        $cmdlets = ($all | Where-Object CommandType -eq 'Cmdlet').Count
        $functions = ($all | Where-Object CommandType -eq 'Function').Count
        $aliases = ($all | Where-Object CommandType -eq 'Alias').Count
        $cmdlets | Should -BeGreaterThan 0
        $functions | Should -BeGreaterThan 0
        $aliases | Should -BeGreaterThan 0
    }

    It "Ex-4 (Extreme): formatted table of command counts by type" {
        $result = Get-Command | Group-Object CommandType |
            Select-Object Name, Count |
            Sort-Object Count -Descending
        $result | Should -Not -BeNullOrEmpty
        $result[0].Name | Should -BeIn @('Cmdlet', 'Function', 'Alias', 'Application')
        $result[0].Count | Should -BeGreaterThan 0
    }
}
