#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 07 - Functions & Scripts" {
    It "Ex-1 (Simple): greeting function returns expected string" {
        function Get-Greeting {
            param([string]$Name)
            "Hello, $Name!"
        }
        Get-Greeting -Name 'World' | Should -Be 'Hello, World!'
        Get-Greeting -Name 'PowerShell' | Should -Be 'Hello, PowerShell!'
    }

    It "Ex-2 (Normal): advanced function validates parameters" {
        function Get-ServerInfo {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [string]$Name,
                [ValidateSet('Web', 'Database', 'App')]
                [string]$Role = 'Web'
            )
            [PSCustomObject]@{ Name = $Name; Role = $Role }
        }
        $result = Get-ServerInfo -Name 'srv01' -Role 'Database'
        $result.Name | Should -Be 'srv01'
        $result.Role | Should -Be 'Database'
        { Get-ServerInfo -Name 'srv02' -Role 'Invalid' } | Should -Throw
    }

    It "Ex-3 (Advanced): pipeline function processes multiple inputs" {
        function ConvertTo-Upper {
            [CmdletBinding()]
            param(
                [Parameter(ValueFromPipeline)]
                [string]$Text
            )
            process { $Text.ToUpper() }
        }
        $result = 'hello', 'world' | ConvertTo-Upper
        $result | Should -Be @('HELLO', 'WORLD')
    }

    It "Ex-4 (Extreme): logging function writes structured output" {
        function Write-Log {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [string]$Message,
                [ValidateSet('INFO', 'WARN', 'ERROR')]
                [string]$Level = 'INFO'
            )
            begin { $entries = @() }
            process {
                $entries += [PSCustomObject]@{
                    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    Level     = $Level
                    Message   = $Message
                }
            }
            end { $entries }
        }
        $logs = 'Test1', 'Test2' | Write-Log -Level 'WARN'
        $logs.Count | Should -Be 2
        $logs[0].Level | Should -Be 'WARN'
        $logs[0].Message | Should -Be 'Test1'
    }
}
