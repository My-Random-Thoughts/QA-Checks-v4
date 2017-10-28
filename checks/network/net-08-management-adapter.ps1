<#
    DESCRIPTION: 
        Check that a management network adapter exists.  This must always be present on a server and labelled correctly.

    REQUIRED-INPUTS:
        ManagementAdapterNames - "LIST" - Names or partial names of management network adapters

    DEFAULT-VALUES:
        ManagementAdapterNames = @('Management', 'MGMT', 'MGT')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Management network adapter found
        WARNING:
        FAIL:
            No management network adapter
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-08-management-adapter
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-08-management-adapter'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Text.StringBuilder]   $filter = "NetConnectionID='Null'"
        $script:chkValues['ManagementAdapterNames'] | ForEach-Object -Process { [void]$filter.Append(" OR NetConnectionID LIKE '%$_%'") }
        [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter $filter.ToString() -Property 'NetConnectionID')

        If ($gCIMi.Count -gt 0)
        {
            $result.result  =    $script:lang['Pass']
            $result.message =    $script:lang['p001']
            $result.data    = "$($gCIMi[0].NetConnectionID)"
        }
        Else
        {
            $result.result   = $script:lang['Fail']
            $result.message  = $script:lang['f001']
            $gCIMi | Sort-Object -Property 'NetConnectionID' | ForEach-Object -Process { $result.data += "$($_.NetConnectionID),#" }
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
