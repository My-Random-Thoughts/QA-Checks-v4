<#
    DESCRIPTION: 
        Checks the builtin group memberships to make sure specific users or groups are members.  If there is only one entry in "GroupMembers", then "AllMustExist" will be set to "TRUE".
        !nThis is check 1 of 3 that can be used to check different groups.

    REQUIRED-INPUTS:
        AllMustExist - "True|False" - Do all group members need to exist for a "Pass"
        GroupMembers - "LIST" - Users or groups that should listed as a member
        GroupName    - Local group name to check

    DEFAULT-VALUES:
        AllMustExist =   'False'
        GroupMembers = @('Domain Admins')
        GroupName    =   'Remote Desktop Users'

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            Group membership configured correctly
            One or more users are members of the selected group
        WARNING:
            Invalid group name, or group is empty
        FAIL:
            Group membership is not correct
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function acc-07-builtin-group-members-1
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'acc-07-builtin-group-members-1'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$object = @((Get-CimInstance -ClassName 'Win32_GroupUser' `
                                                                   -Filter    "GroupComponent=`"Win32_Group.Domain='$env:ComputerName',Name='$($script:chkValues['GroupName'])'`"" `
                                                                   -Property  'PartComponent' -ErrorAction SilentlyContinue).PartComponent)
        If (([string]::IsNullOrEmpty($object) -eq $false) -and ($object.Count -gt 0))
        {
            [System.Collections.ArrayList]$inGroup  = @()
            [System.Collections.ArrayList]$outGroup = @()
            $script:chkValues['GroupMembers'] | ForEach-Object -Process {
                If ($object.Name.Contains($_)) { [void] $inGroup.Add($_) }
                Else                           { [void]$outGroup.Add($_) }
            }

            If (($inGroup.Count -eq $script:chkValues['GroupMembers'].Count) -and ($outGroup.Count -eq 0))
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
                $result.data    = $script:chkValues['GroupName']
            }
            Else
            {
                If (($script:chkValues['GroupMembers'].Count) -eq 1) { $script:chkValues['AllMustExist'] = 'True' }
                If  ($script:chkValues['AllMustExist'] -eq 'True')
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f001']
                }
                Else
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p002']
                }
                $result.data = $(($script:lang['dt01']) -f $($script:chkValues['GroupName']), $($inGroup -join ', '), $($outGroup -join ', '))
            }
        }
        Else
        {
            $result.result  = $script:lang['Warning']
            $result.message = $script:lang['w001']
            $result.data    = $script:chkValues['GroupName']
        }
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
    }

    Return $result
}
