#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 13 - Objects & .NET" {
    It "Ex-1 (Simple): PSCustomObject has expected properties" {
        $server = [PSCustomObject]@{
            Name   = 'web01'
            IP     = '10.0.0.1'
            Role   = 'WebServer'
            Status = 'Running'
        }
        $server.Name | Should -Be 'web01'
        $server.PSObject.Properties.Count | Should -Be 4
        $server.PSObject.Properties.Name | Should -Contain 'Status'
    }

    It "Ex-2 (Normal): .NET static methods work correctly" {
        [math]::Round(3.14159, 2) | Should -Be 3.14
        [math]::Pow(2, 10) | Should -Be 1024
        $date = [datetime]::ParseExact('2024-01-15', 'yyyy-MM-dd', $null)
        $date.Year | Should -Be 2024
        $date.DayOfWeek | Should -Be 'Monday'
    }

    It "Ex-3 (Advanced): PowerShell class with methods" {
        class ServerInfo {
            [string]$Name
            [string]$IP
            [int]$Port
            ServerInfo([string]$name, [string]$ip, [int]$port) {
                $this.Name = $name; $this.IP = $ip; $this.Port = $port
            }
            [string] GetEndpoint() { return "$($this.IP):$($this.Port)" }
            [bool] IsDefaultPort() { return $this.Port -eq 80 -or $this.Port -eq 443 }
        }
        $srv = [ServerInfo]::new('web01', '10.0.0.1', 443)
        $srv.GetEndpoint() | Should -Be '10.0.0.1:443'
        $srv.IsDefaultPort() | Should -BeTrue
    }

    It "Ex-4 (Extreme): class hierarchy with inheritance" {
        class Animal {
            [string]$Name
            [int]$Age
            Animal([string]$name, [int]$age) { $this.Name = $name; $this.Age = $age }
            [string] Speak() { return "..." }
        }
        class Dog : Animal {
            [string]$Breed
            Dog([string]$name, [int]$age, [string]$breed) : base($name, $age) { $this.Breed = $breed }
            [string] Speak() { return "Woof!" }
        }
        class Cat : Animal {
            [bool]$Indoor
            Cat([string]$name, [int]$age, [bool]$indoor) : base($name, $age) { $this.Indoor = $indoor }
            [string] Speak() { return "Meow!" }
        }
        $dog = [Dog]::new('Rex', 5, 'Labrador')
        $cat = [Cat]::new('Whiskers', 3, $true)
        $dog.Speak() | Should -Be 'Woof!'
        $cat.Speak() | Should -Be 'Meow!'
        $dog -is [Animal] | Should -BeTrue
        $cat.Indoor | Should -BeTrue
    }
}
