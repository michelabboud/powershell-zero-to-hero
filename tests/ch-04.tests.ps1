#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 04 - Variables & Types" {
    It "Ex-1 (Simple): 5 different types verified" {
        $str  = "hello"
        $int  = 42
        $bool = $true
        $arr  = @(1, 2, 3)
        $hash = @{ a = 1 }

        $str.GetType().Name            | Should -Be 'String'
        $int.GetType().Name            | Should -Be 'Int32'
        $bool.GetType().Name           | Should -Be 'Boolean'
        $arr.GetType().BaseType.Name   | Should -Be 'Array'
        $hash.GetType().Name           | Should -Be 'Hashtable'
    }

    It "Ex-2 (Normal): array of server hashtables" {
        $servers = @(
            @{ Name = 'web01'; IP = '10.0.0.1'; Role = 'Web'      },
            @{ Name = 'db01';  IP = '10.0.0.2'; Role = 'Database' },
            @{ Name = 'app01'; IP = '10.0.0.3'; Role = 'App'      }
        )

        $servers.Count            | Should -Be 3
        $servers[0].Keys          | Should -Contain 'Name'
        $servers[0].Keys          | Should -Contain 'IP'
        $servers[0].Keys          | Should -Contain 'Role'
        $servers[1].Name          | Should -Be 'db01'
        $servers[2].Role          | Should -Be 'App'
    }

    It "Ex-3 (Advanced): string interpolation and format operator" {
        $name = "PowerShell"
        $ver  = 7

        # Double-quoted interpolation
        "$name version $ver"  | Should -Be "PowerShell version 7"

        # Subexpression operator
        $arr = @(1, 2, 3)
        "Count: $($arr.Count)" | Should -Be "Count: 3"

        # Format operator positional
        '{0} v{1}' -f $name, $ver | Should -Be "PowerShell v7"

        # Format operator with padding (left-aligned, width 12)
        $padded = '{0,-12}|' -f 'hi'
        $padded | Should -Be 'hi          |'

        # Here-string produces correct line count (double-quoted)
        $block = @"
line one
line two
line three
"@
        ($block -split "`n").Count | Should -BeGreaterOrEqual 3
    }

    It "Ex-4 (Extreme): nested hashtable with validation" {
        $config = @{
            Server = @{
                Host = 'localhost'
                Port = [int]8080
                TLS  = [bool]$true
            }
            Database = @{
                ConnectionString = 'Server=.;DB=test'
                Timeout          = [int]30
                PoolSize         = [int]10
            }
            Logging = @{
                Level  = 'Info'
                Path   = '/var/log'
                MaxMB  = [int]100
            }
        }

        # Top-level structure
        $config.Keys.Count              | Should -Be 3

        # Type assertions on nested values
        $config.Server.Port             | Should -BeOfType [int]
        $config.Database.Timeout        | Should -BeOfType [int]
        $config.Logging.MaxMB           | Should -BeOfType [int]

        # Value assertions
        $config.Server.Port             | Should -Be 8080
        $config.Database.Timeout        | Should -Be 30

        # Nested key existence
        $config.Server.Keys             | Should -Contain 'Host'
        $config.Database.Keys           | Should -Contain 'ConnectionString'
        $config.Logging.Keys            | Should -Contain 'Level'

        # TLS is a boolean
        $config.Server.TLS              | Should -BeOfType [bool]
        $config.Server.TLS              | Should -Be $true
    }
}
