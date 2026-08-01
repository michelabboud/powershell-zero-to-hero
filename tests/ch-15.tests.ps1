#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7.1' }

Describe "Chapter 15 - Active Directory" {
    BeforeAll {
        # Mock AD cmdlets since we don't have a real AD environment
        function Get-ADUser {
            [CmdletBinding()]
            param($Filter, $SearchBase, $Properties, $Identity)
        }
        function Get-ADGroup { param($Filter, $Identity) }
        function New-ADUser {
            [CmdletBinding()]
            param($Name, $SamAccountName, $UserPrincipalName, $Path, $AccountPassword, $Enabled)
        }
        function Add-ADGroupMember {
            [CmdletBinding()]
            param($Identity, $Members)
        }
        function Set-ADUser {
            [CmdletBinding()]
            param($Identity, $Department, $Title, $Manager)
        }
        function Remove-ADUser {
            [CmdletBinding(SupportsShouldProcess)]
            param($Identity)
        }

        function New-UserOnboarding {
            [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
            param(
                [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $FirstName,
                [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $LastName,
                [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Department,
                [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Title,
                [Parameter(Mandatory)] [SecureString] $TemporaryPassword,
                [switch] $RemovePartialUserOnFailure
            )

            $sam = "$($FirstName.Substring(0,1).ToLower())$($LastName.ToLower())"
            $upn = "$sam@corp.local"
            $state = [ordered]@{
                SAM              = $sam
                UPN              = $upn
                Status           = 'Planned'
                Stage            = 'Plan'
                CompletedStages  = [System.Collections.Generic.List[string]]::new()
                GroupsAdded      = [System.Collections.Generic.List[string]]::new()
                CleanupAttempted = $false
                CleanupSucceeded = $null
                Error            = $null
                CleanupError     = $null
            }

            if (-not $PSCmdlet.ShouldProcess($sam, 'Create and configure AD user')) {
                $state.Status = 'WhatIf'
                return [PSCustomObject] $state
            }

            $userCreated = $false
            try {
                $state.Stage = 'CreateUser'
                New-ADUser -Name "$FirstName $LastName" -SamAccountName $sam `
                    -UserPrincipalName $upn -AccountPassword $TemporaryPassword `
                    -Enabled $true -ErrorAction Stop
                $userCreated = $true
                $state.CompletedStages.Add('CreateUser')

                $state.Stage = 'SetAttributes'
                Set-ADUser -Identity $sam -Department $Department -Title $Title `
                    -ErrorAction Stop
                $state.CompletedStages.Add('SetAttributes')

                foreach ($group in @('AllEmployees', $Department)) {
                    $state.Stage = "AddGroup:$group"
                    Add-ADGroupMember -Identity $group -Members $sam -ErrorAction Stop
                    $state.GroupsAdded.Add($group)
                    $state.CompletedStages.Add("AddGroup:$group")
                }

                $state.Stage = 'Complete'
                $state.Status = 'Complete'
            }
            catch {
                $state.Error = $_.Exception.Message
                if ($userCreated) {
                    $state.Status = 'PartialFailure'
                }
                else {
                    $state.Status = 'Failed'
                }

                if ($userCreated -and $RemovePartialUserOnFailure -and
                    $PSCmdlet.ShouldProcess($sam, 'Remove partially provisioned AD user')) {
                    $state.CleanupAttempted = $true
                    $state.CleanupSucceeded = $false
                    try {
                        Remove-ADUser -Identity $sam -Confirm:$false -ErrorAction Stop
                        $state.CleanupSucceeded = $true
                        $state.Status = 'FailedCleanupCompleted'
                        $state.CompletedStages.Add('CleanupUser')
                    }
                    catch {
                        $state.CleanupError = $_.Exception.Message
                    }
                }
            }

            [PSCustomObject] $state
        }
    }

    It "Ex-1 (Simple): list users in an OU" {
        Mock Get-ADUser {
            @(
                [PSCustomObject]@{ Name = 'John Smith'; SamAccountName = 'jsmith'; Enabled = $true },
                [PSCustomObject]@{ Name = 'Jane Doe'; SamAccountName = 'jdoe'; Enabled = $true }
            )
        }
        $users = Get-ADUser -Filter { Enabled -eq $true } -SearchBase 'OU=Users,DC=corp,DC=local'
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
        $disabled = @(Get-ADUser -Filter * | Where-Object { -not $_.Enabled })
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

        $temporaryPassword = [SecureString]::new()
        $result = New-UserOnboarding -FirstName 'Charlie' -LastName 'Davis' `
            -Department 'Engineering' -Title 'Developer' -TemporaryPassword $temporaryPassword
        $result.SAM | Should -Be 'cdavis'
        $result.UPN | Should -Be 'cdavis@corp.local'
        $result.Status | Should -Be 'Complete'
        $result.Stage | Should -Be 'Complete'
        $result.GroupsAdded | Should -Contain 'Engineering'
        Should -Invoke New-ADUser -Times 1 -ParameterFilter {
            $AccountPassword -is [SecureString]
        }
        Should -Invoke Add-ADGroupMember -Times 2
        Should -Invoke Set-ADUser -Times 1
    }

    It "Ex-4 (Extreme): WhatIf reports a plan without AD mutations" {
        Mock New-ADUser { }
        Mock Add-ADGroupMember { }
        Mock Set-ADUser { }
        Mock Remove-ADUser { }

        $result = New-UserOnboarding -FirstName 'Charlie' -LastName 'Davis' `
            -Department 'Engineering' -Title 'Developer' `
            -TemporaryPassword ([SecureString]::new()) -WhatIf

        $result.Status | Should -Be 'WhatIf'
        $result.Stage | Should -Be 'Plan'
        $result.CompletedStages.Count | Should -Be 0
        Should -Invoke New-ADUser -Times 0
        Should -Invoke Set-ADUser -Times 0
        Should -Invoke Add-ADGroupMember -Times 0
        Should -Invoke Remove-ADUser -Times 0
    }

    It "Ex-4 (Extreme): group failure reports retained partial success" {
        Mock New-ADUser { }
        Mock Set-ADUser { }
        Mock Add-ADGroupMember {
            if ($Identity -eq 'Engineering') {
                throw 'Department group unavailable'
            }
        }
        Mock Remove-ADUser { }

        $result = New-UserOnboarding -FirstName 'Charlie' -LastName 'Davis' `
            -Department 'Engineering' -Title 'Developer' `
            -TemporaryPassword ([SecureString]::new())

        $result.Status | Should -Be 'PartialFailure'
        $result.Stage | Should -Be 'AddGroup:Engineering'
        $result.Error | Should -Be 'Department group unavailable'
        $result.CompletedStages | Should -Contain 'CreateUser'
        $result.CompletedStages | Should -Contain 'SetAttributes'
        $result.GroupsAdded | Should -Contain 'AllEmployees'
        $result.GroupsAdded | Should -Not -Contain 'Engineering'
        $result.CleanupAttempted | Should -BeFalse
        Should -Invoke Add-ADGroupMember -Times 2
        Should -Invoke Remove-ADUser -Times 0
    }
}
