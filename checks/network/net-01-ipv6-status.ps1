<#
    DESCRIPTION:
        Check the global IPv6 setting and of status of each NIC.

    REQUIRED-INPUTS:
        IPv6State - "Enabled|Disabled" - State of the IPv6 protocol for each network adapter

    DEFAULT-VALUES:
        IPv6State = 'Disabled'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            D:IPv6 setting disabled globally
            E:IPv6 setting enabled globally, all NICs enabled
        WARNING:
            D:IPv6 setting enabled globally, all NICs disabled
        FAIL:
            D:IPv6 setting enabled globally, one or more NICs enabled
            E:IPv6 setting enabled globally, one or more NICs disabled
            E:IPv6 setting disabled globally
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-01-ipv6-status
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-01-ipv6-status'

    #... CHECK STARTS HERE ...#

    If ($script:chkValues['IPv6State'] -eq 'Disabled') { [string]$lookingFor = '4294967295'; [string]$stateGood = $script:lang['sta2']; [string]$stateBad = $script:lang['sta1'] }
    Else                                               { [string]$lookingFor =          '0'; [string]$stateGood = $script:lang['sta1']; [string]$stateBad = $script:lang['sta2'] }

    Try
    {
        # To hold list of IPv6 adapters
        [System.Collections.ArrayList]$ipv6d = @()    # Disabled
        [System.Collections.ArrayList]$ipv6e = @()    # Enabled

        [object]$gItmP =  (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters' -Name 'DisabledComponents' -ErrorAction SilentlyContinue)
        [object]$gCimI = @(Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter "NetEnabled='True' AND NOT NetConnectionID=''" -Property ('NetConnectionID', 'GUID') -ErrorAction SilentlyContinue)
        [System.Collections.ArrayList]$BindList = @((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Linkage' -Name 'Bind' -ErrorAction SilentlyContinue).'Bind')

        If ([string]::IsNullOrEmpty($BindList) -eq $false)
        {
            $gCimI | Sort-Object | ForEach-Object -Process {
                If ($BindList.Contains("\Device\$($_.GUID)") -eq $true) { [void]$ipv6e.Add($_.NetConnectionID) } Else { [void]$ipv6d.Add($_.NetConnectionID) }
            }
        }

        # If setting is ENABLED, check all adapters
        $result.data = ''
        If ($script:chkValues['IPv6State'] -eq 'Disabled')
        {
            If ($($gItmP.DisabledComponents) -ne $lookingFor)
            {
                If ($ipv6e.Count -gt 0)
                {
                    $result.result   =    $script:lang['Fail']
                    $result.message += ($($script:lang['dt03']) -f $stateBad, $stateGood)
                    $ipv6e | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
                }
                Else
                {
                    $result.result   =    $script:lang['Warning']
                    $result.message += ($($script:lang['dt02']) -f $stateBad, $stateGood)
                    $ipv6e | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
                }
            }
            Else
            {
                $result.result   =    $script:lang['Pass']
                $result.message += ($($script:lang['dt01']) -f $stateGood)
            }
        }
        Else    # Setting is DISABLED
        {
            If ($($gItmP.DisabledComponents) -ne $lookingFor)
            {
                $result.result   =    $script:lang['Fail']
                $result.message += ($($script:lang['dt01']) -f $stateBad)
            }
            Else
            {
                If ($ipv6d.Count -gt 0)
                {
                    $result.result   =    $script:lang['Fail']
                    $result.message += ($($script:lang['dt03']) -f $stateGood, $stateBad)
                    $ipv6d | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
                }
                Else
                {
                    $result.result   =    $script:lang['Pass']
                    $result.message += ($($script:lang['dt02']) -f $stateGood, $stateBad)
                    $ipv6d | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
                }
            }
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
