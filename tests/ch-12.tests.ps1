#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 12 - Modules & Packages" {
    It "Ex-1 (Simple): loaded modules list is not empty" {
        $modules = Get-Module
        $modules.Count | Should -BeGreaterThan 0
        $modules | ForEach-Object { $_.Name | Should -Not -BeNullOrEmpty }
    }

    It "Ex-2 (Normal): script module exports functions" {
        $modulePath = Join-Path ([System.IO.Path]::GetTempPath()) "TestModule-$(Get-Random)"
        New-Item $modulePath -ItemType Directory -Force | Out-Null
        try {
            $psm1 = @'
function Get-Greeting { param([string]$Name) "Hello, $Name!" }
function Get-Farewell { param([string]$Name) "Goodbye, $Name!" }
function Get-TimeOfDay { if ((Get-Date).Hour -lt 12) { 'Morning' } elseif ((Get-Date).Hour -lt 17) { 'Afternoon' } else { 'Evening' } }
Export-ModuleMember -Function Get-Greeting, Get-Farewell, Get-TimeOfDay
'@
            $psm1 | Set-Content (Join-Path $modulePath 'TestModule.psm1')
            Import-Module (Join-Path $modulePath 'TestModule.psm1') -Force
            Get-Greeting -Name 'World' | Should -Be 'Hello, World!'
            Get-Farewell -Name 'World' | Should -Be 'Goodbye, World!'
        } finally {
            Remove-Module TestModule -ErrorAction SilentlyContinue
            Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Ex-3 (Advanced): module manifest has correct metadata" {
        $modulePath = Join-Path ([System.IO.Path]::GetTempPath()) "ManifestMod-$(Get-Random)"
        New-Item $modulePath -ItemType Directory -Force | Out-Null
        try {
            'function Get-Demo { "demo" }' | Set-Content (Join-Path $modulePath 'ManifestMod.psm1')
            New-ModuleManifest -Path (Join-Path $modulePath 'ManifestMod.psd1') `
                -RootModule 'ManifestMod.psm1' `
                -ModuleVersion '1.0.0' `
                -Author 'TestAuthor' `
                -FunctionsToExport @('Get-Demo')
            $manifest = Test-ModuleManifest (Join-Path $modulePath 'ManifestMod.psd1')
            $manifest.Version | Should -Be '1.0.0'
            $manifest.Author | Should -Be 'TestAuthor'
        } finally {
            Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Ex-4 (Extreme): module with private and public functions" {
        $modulePath = Join-Path ([System.IO.Path]::GetTempPath()) "AdvMod-$(Get-Random)"
        New-Item $modulePath -ItemType Directory -Force | Out-Null
        try {
            $psm1 = @'
function _ValidateInput { param([string]$Value) -not [string]::IsNullOrWhiteSpace($Value) }
function Get-ProcessedData {
    param([Parameter(Mandatory)][string]$Data)
    if (-not (_ValidateInput $Data)) { throw "Invalid input" }
    $Data.ToUpper().Trim()
}
Export-ModuleMember -Function Get-ProcessedData
'@
            $psm1 | Set-Content (Join-Path $modulePath 'AdvMod.psm1')
            Import-Module (Join-Path $modulePath 'AdvMod.psm1') -Force
            Get-ProcessedData -Data '  hello  ' | Should -Be 'HELLO'
            { Get-Command _ValidateInput -ErrorAction Stop } | Should -Throw
        } finally {
            Remove-Module AdvMod -ErrorAction SilentlyContinue
            Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
