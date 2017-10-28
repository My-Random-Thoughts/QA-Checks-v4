<#
    DESCRIPTION: 
        Check all local users to ensure that no non-standard accounts exist.  Unless the server is not in a domain, there should be no additional user accounts. Example standard accounts include "ASPNET", "__VMware"

    REQUIRED-INPUTS:
        IgnoreTheseUsers - "LIST" - Known user or group accounts to ignore

    DEFAULT-VALUES:
        IgnoreTheseUsers = @('Guest', 'ASPNET', '___VMware')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No additional local accounts exist
        WARNING:
            This is a work group server, is this correct.?
        FAIL:
            One or more local accounts exist
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function acc-01-local-users
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'acc-01-local-users'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Text.StringBuilder]   $filter = "LocalAccount='True'"
        $script:chkValues['IgnoreTheseUsers'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT Name LIKE '%$_%'") }
        [System.Collections.ArrayList]$gCIMi  = @((Get-CimInstance -ClassName 'Win32_UserAccount' -Filter $filter.ToString() -Property 'Name' -ErrorAction SilentlyContinue).Name)
        [object]$domCheck = (Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property ('Domain', 'PartOfDomain'))

        [string]$domain = ($domCheck.Domain -split '\.')[0]
        $gCIMi = @($gCIMi1 | Where-Object { $_ })    # Remove any empty items

        If ($domCheck.PartOfDomain -eq $true)
        {
            If ($gCIMi.Count -gt 0)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
                $gCIMi | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
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
