<#
    DESCRIPTION: 
        Check that File And Print Services has been disabled on all adapters, except for those specified.

    REQUIRED-INPUTS:
        IgnoreTheseAdapters - "LIST" - Names or partial names of network adapters to ignore

    DEFAULT-VALUES:
        IgnoreTheseAdapters = @('Production', 'PROD', 'PRD')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            File And Print Services are disabled correctly
        WARNING:
        FAIL:
            File And Print Services are enabled
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-12-fileprint-services
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-12-fileprint-services'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Text.StringBuilder]   $filter = "NetConnectionStatus='2'"
        $script:chkValues['IgnoreTheseAdapters'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT NetConnectionID LIKE '%$_%'") }
        [System.Collections.ArrayList]$gCimI  = @((Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter $filter.ToString() -Property ('NetConnectionID', 'GUID')))
        [System.Collections.ArrayList]$gITMp  = @(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Linkage' -Name 'Bind')
        $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

        [System.Collections.ArrayList]$fpEbld = @()
        $gCimI | ForEach-Object -Process {
            If ($gITMp.Bind.Contains("\Device\Tcpip_$($_.GUID)") -eq $true) { [void]$fpEbld.Add($_.NetConnectionID) }
        }

        If ($fpEbld.Count -gt 0)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
            $fpEbld | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
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
