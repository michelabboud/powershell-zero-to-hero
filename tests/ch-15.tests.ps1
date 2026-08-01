#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5' }

Describe "Chapter 15 - Active Directory" {
    BeforeAll {
        # Mock AD cmdlets since we don't have a real AD environment
        function Get-ADUser { param($Filter, $SearchBase, $Properties) }
        function Get-ADGroup { param($Filter, $Identity) }
        function New-ADUser { param($Name, $SamAccountName, $UserPrincipalName, $Path, $AccountPassword, $Enabled) }
        function Add-ADGroupMember { param($Identity, $Members) }
        function Set-ADUser { param($Identity, $Department, $Title, $Manager) }
    }

    It "Ex-1 (Simple): list users in an OU" {
        Mock Get-ADUser {
            @(
                [PSCustomObject]@{ Name = 'John Smith'; SamAccountName = 'jsmith'; Enabled = $true },
                [PSCustomObject]@{ Name = 'Jane Doe'; SamAccountName = 'jdoe'; Enabled = $true }
            )
        }
        $users = Get-ADUser -Filter * -SearchBase 'OU=Users,DC=corp,DC=local'
        $users.Count | Should -Be 2
        $users[0].SamAccountName | Should -Be 'jsmith'
    }

    It "Ex-2 (Normal): find disabled accounts" {
        Mock Get-ADUser {
            @(
                [PSCustomObject]@{ Name = 'Old User'; SamAccountName = 'ouser'; Enabled = $false },
                [PSCustomObject]@{ Name = 'Active User'; SamAccountName = 'auser'; Enabled = $true }
            )
        }
        $disabled = Get-ADUser -Filter * | Where-Object { -not $_.Enabled }
        $disabled.Count | Should -Be 1
        $disabled[0].SamAccountName | Should -Be 'ouser'
    }

    It "Ex-3 (Advanced): bulk create users from CSV data" {
        $csvData = @(
            [PSCustomObject]@{ FirstName = 'Alice'; LastName = 'Brown'; Department = 'IT' },
            [PSCustomObject]@{ FirstName = 'Bob'; LastName = 'Green'; Department = 'HR' }
        )
        Mock New-ADUser { }
        $created = foreach ($user in $csvData) {
            $sam = "$($user.FirstName.Substring(0,1).ToLower())$($user.LastName.ToLower())"
            New-ADUser -Name "$($user.FirstName) $($user.LastName)" -SamAccountName $sam
            [PSCustomObject]@{ Name = "$($user.FirstName) $($user.LastName)"; SAM = $sam }
        }
        $created.Count | Should -Be 2
        $created[0].SAM | Should -Be 'abrown'
        Should -Invoke New-ADUser -Times 2
    }

    It "Ex-4 (Extreme): automated onboarding workflow" {
        Mock New-ADUser { }
        Mock Add-ADGroupMember { }
        Mock Set-ADUser { }

        function New-UserOnboarding {
            param(
                [string]$FirstName, [string]$LastName,
                [string]$Department, [string]$Title
            )
            $sam = "$($FirstName.Substring(0,1).ToLower())$($LastName.ToLower())"
            $upn = "$sam@corp.local"
            New-ADUser -Name "$FirstName $LastName" -SamAccountName $sam -UserPrincipalName $upn -Enabled $true
            Set-ADUser -Identity $sam -Department $Department -Title $Title
            Add-ADGroupMember -Identity 'AllEmployees' -Members $sam
            Add-ADGroupMember -Identity $Department -Members $sam
            [PSCustomObject]@{ SAM = $sam; UPN = $upn; Groups = @('AllEmployees', $Department) }
        }

        $result = New-UserOnboarding -FirstName 'Charlie' -LastName 'Davis' -Department 'Engineering' -Title 'Developer'
        $result.SAM | Should -Be 'cdavis'
        $result.UPN | Should -Be 'cdavis@corp.local'
        $result.Groups | Should -Contain 'Engineering'
        Should -Invoke New-ADUser -Times 1
        Should -Invoke Add-ADGroupMember -Times 2
        Should -Invoke Set-ADUser -Times 1
    }
}
