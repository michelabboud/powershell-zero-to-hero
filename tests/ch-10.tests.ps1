#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 10 - Error Handling" {
    It "Ex-1 (Simple): try/catch handles divide-by-zero" {
        $result = try { 1 / 0 } catch { 'caught' }
        $result | Should -Be 'caught'
    }

    It "Ex-2 (Normal): catch specific exception types" {
        function Test-SpecificCatch {
            param([string]$Path)
            try {
                Get-Content $Path -ErrorAction Stop
            } catch [System.Management.Automation.ItemNotFoundException] {
                'NotFound'
            } catch {
                'OtherError'
            }
        }
        Test-SpecificCatch -Path '/nonexistent/path/file.txt' | Should -Be 'NotFound'
    }

    It "Ex-3 (Advanced): function supports -ErrorAction and -ErrorVariable" {
        function Get-SafeContent {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [string]$Path
            )
            if (-not (Test-Path $Path)) {
                Write-Error "File not found: $Path"
                return $null
            }
            Get-Content $Path
        }
        $result = Get-SafeContent -Path '/nonexistent' -ErrorAction SilentlyContinue -ErrorVariable ev
        $result | Should -BeNullOrEmpty
        $ev.Count | Should -BeGreaterThan 0
    }

    It "Ex-4 (Extreme): structured error logging to JSON" {
        $logPath = Join-Path ([System.IO.Path]::GetTempPath()) "ps-error-log-$(Get-Random).json"
        try {
            function Write-ErrorLog {
                param([System.Management.Automation.ErrorRecord]$ErrorRecord, [string]$LogPath)
                $entry = @{
                    Timestamp = (Get-Date -Format 'o')
                    Message   = $ErrorRecord.Exception.Message
                    Category  = $ErrorRecord.CategoryInfo.Category.ToString()
                    Script    = $ErrorRecord.InvocationInfo.ScriptName
                    Line      = $ErrorRecord.InvocationInfo.ScriptLineNumber
                }
                $entry | ConvertTo-Json | Add-Content $LogPath
            }
            try { 1/0 } catch { Write-ErrorLog -ErrorRecord $_ -LogPath $logPath }
            $logged = Get-Content $logPath -Raw | ConvertFrom-Json
            $logged.Message | Should -Match 'divide by zero|Attempted to divide by zero'
            $logged.Category | Should -Not -BeNullOrEmpty
        } finally {
            Remove-Item $logPath -ErrorAction SilentlyContinue
        }
    }
}
