<#
    DESCRIPTION: 
        Check the local administrators group to ensure no non-standard accounts exist.
        If there is a specific application requirement for local administration access then these need to be well documented.

    REQUIRED-INPUTS:
        IgnoreTheseUsers - "LIST" - Known user or group accounts to ignore

    DEFAULT-VALUES:
        IgnoreTheseUsers = @('Domain Admins', 'Enterprise Admins')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No local administrators found
        WARNING:
            This is a work group server, is this correct.?
        FAIL:
            One or more local administrator accounts exist
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function acc-03-local-admins
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'acc-03-local-admins'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$domCheck = (Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property ('Domain', 'PartOfDomain'))
        [string]$domain   = ($domCheck.Domain -split '\.')[0]

        If ($domCheck.PartOfDomain -eq $true)
        {
            [string] $gCIMi1                       =  ((Get-CimInstance -ClassName 'Win32_Group'     -Filter "LocalAccount='True' AND SID='S-1-5-32-544'" -Property 'Name').Name)
            [System.Collections.ArrayList]$gCIMi2  = @((Get-CimInstance -ClassName 'Win32_GroupUser' `
                                                                        -Filter    "GroupComponent=`"Win32_Group.Domain='$env:ComputerName',Name='$gCIMi1'`"" `
                                                                        -Property  'PartComponent' -ErrorAction SilentlyContinue).PartComponent)
            $gCIMi2 = @($gCIMi2 | Where-Object { $_ })    # Remove any empty items

            [System.Collections.ArrayList]$members = @($gCIMi2.Name)
            $gCIMi2 | ForEach-Object -Process {
                [string]$item = $_.Name
                $script:chkValues['IgnoreTheseUsers'] | ForEach-Object -Process { If ($item -like "$_*") { $members.Remove($item) } }
            }

            If ($members.count -gt 0)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
                $members | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
        }
        Else
        {
            $result.result  = $script:lang['Warning']
            $result.message = $script:lang['w001']
            $result.data    = ($($script:lang['dt01']) -f $domain)
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
