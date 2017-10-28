<#
    DESCRIPTION: 
        Check shared folders to ensure no additional shares are present.  Shared folders should be documented with a designated team specified as the owner.

    REQUIRED-INPUTS:
        IgnoreTheseShares - "LIST" - List of share names that can be ignored

    DEFAULT-VALUES:
        IgnoreTheseShares = @('NETLOGON', 'SYSVOL', 'CertEnroll')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No additional shares found
        WARNING:
            Shared folders found, check against documentation
        FAIL:
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function drv-05-shared-folders
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'drv-05-shared-folders'

    #... CHECK STARTS HERE ...#

    Try
    {   #                                                     Admin Shares           IPC$ Share
        [System.Text.StringBuilder]   $filter = "NOT (Type = '2147483648' OR TYPE = '2147483651') AND NOT Name = 'Null'"
        $script:chkValues['IgnoreTheseShares'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT Name = '$_'") }
        [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_Share' -Filter $filter.ToString() -Property ('Name', 'Path') -ErrorAction SilentlyContinue)
        $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

        If ($gCIMi.Count -gt 0)
        {
            $result.result  = $script:lang['Warning']
            $result.message = $script:lang['w001']
            $gCIMi | Sort-Object -Property 'Name' | ForEach-Object -Process { $result.data += ($($script:lang['dt01']) -f $_.Name, $_.Path) }
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
