#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 02 - The Console" {
    It "Ex-1 (Simple): PROFILE variable contains a valid path string" {
        $PROFILE | Should -Not -BeNullOrEmpty
        $PROFILE | Should -BeOfType [string]
    }

    It "Ex-2 (Normal): profile script sets aliases" {
        function Test-ProfileAliases {
            Set-Alias -Name ll -Value Get-ChildItem -Scope Local
            Set-Alias -Name np -Value notepad -Scope Local
            (Get-Alias ll -Scope Local).Definition | Should -Be 'Get-ChildItem'
            (Get-Alias np -Scope Local).Definition | Should -Be 'notepad'
        }
        Test-ProfileAliases
    }

    It "Ex-3 (Advanced): PSReadLine module is available" {
        $module = Get-Module PSReadLine -ListAvailable
        $module | Should -Not -BeNullOrEmpty
    }

    It "Ex-4 (Extreme): admin detection logic returns boolean" {
        function Test-IsAdmin {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
                $principal = [Security.Principal.WindowsPrincipal]$identity
                return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            }
            return (id -u) -eq '0'
        }
        Test-IsAdmin | Should -BeOfType [bool]
    }
}
