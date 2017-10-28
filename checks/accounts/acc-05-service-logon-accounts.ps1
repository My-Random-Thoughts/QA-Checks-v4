<#
    DESCRIPTION: 
        Checks all services to ensure no user accounts are assigned.
        If specific application service accounts are required then they should be domain level accounts (not local) and restricted from interactice access by policy.

    REQUIRED-INPUTS:
        IgnoreTheseUsers - "LIST" - Known user or group accounts to ignore

    DEFAULT-VALUES:
        IgnoreTheseUsers = @('NT AUTHORITY\\NetworkService', 'NT AUTHORITY\\LocalService', 'LocalSystem')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No services found running under a local accounts
        WARNING:
        FAIL:
            One or more services was found to be running under local accounts
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function acc-05-service-logon-accounts
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'acc-05-service-logon-accounts'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Text.StringBuilder]   $filter = "DisplayName=''"
        $script:chkValues['IgnoreTheseUsers'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT StartName LIKE '$_%'") }
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_Service' -Filter $filter.ToString() -Property ('DisplayName', 'StartName'))
        $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

        If ($gCIMi.Count -gt 0)
        {
            $result.result  = $script:lang['Warning']
            $result.message = $script:lang['w001']
            $gCIMi | Sort-Object | ForEach-Object -Process { $result.data += "$($_.DisplayName) ($($_.Startname)),#" }
        }
        Else
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
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
