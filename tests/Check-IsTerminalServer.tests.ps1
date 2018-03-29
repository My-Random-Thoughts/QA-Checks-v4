<#
    .SYNOPSIS
        CheckIsTerminalServer tests

    .DESCRIPTION
        Contains tests to check the function correctly returns server if the server is a terminal server or not

    .EXAMPLE
        Example: Invoke-Pester

    .NOTES
        For additional information please contact david.wallis@callcreditgroup.com

    .LINK
        https://github.com/My-Random-Thoughts/QA-Checks-v4
#>

# Remove my comments if you use this :D

# Tested with Pester 4.0.3 (BREAKING changes in 4.1+ that internally we haven't resolved - so stuck on this version)

# SUT = Subject under test (its a unit testing thing)
# dot sourcing the module allows pester to inject mocked commands
# this is why you need functions as if you dot source a script you end up executing the code!!


$sourceFolder = Resolve-Path "$PSScriptRoot\..\engine"
# Find the actual name of the script we should be testing (as the test name should follow the same naming, just .tests.ps1)
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

. "$sourceFolder\$sut"

# Example showing mocking - you can mock the command within the describe or context block and apply it 'generically' but
# I did it this way to make it a little simpler to understand.

# You should not have any logic within tests, if you need a foreach-object then look at test cases.
# Also Red Green Refactor - write a test that fails, edit your code and make the test pass
# Red = Error, failing test
# Green = Test now passing after fixing your code
# Refactor = Rewrite the function keeping the test passing.

Describe 'QA-Checks - Engine' {
    Context 'test functionality when terminal server' {
        Mock Get-CimInstance `
            -ParameterFilter {$ClassName -And $ClassName -ieq 'Win32_TerminalServiceSetting'} `
            -MockWith { return [pscustomobject]@{ Caption = "Something"; TerminalServerMode = 1} }

        It "Function returns true when it's configured as a terminal server" {
            Check-IsTerminalServer | Should Be $true
        }
    }

    Context 'test functionality when remote admin' {
        Mock Get-CimInstance `
            -ParameterFilter {$ClassName -And $ClassName -ieq 'Win32_TerminalServiceSetting'} `
            -MockWith { return [pscustomobject]@{ Caption = "Something"; TerminalServerMode = 0} }

        It "Function returns false when it's configured for remote admin" {
            Check-IsTerminalServer | Should Be $false
        }
    }
}
