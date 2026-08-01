#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

$config = New-PesterConfiguration
$config.Run.Path = $PSScriptRoot
$config.Run.Exit = $true
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'test-results/results.xml'
$config.TestResult.OutputFormat = 'NUnitXml'

$resultDirectory = Split-Path -Parent $config.TestResult.OutputPath.Value
New-Item -Path $resultDirectory -ItemType Directory -Force | Out-Null

Invoke-Pester -Configuration $config
