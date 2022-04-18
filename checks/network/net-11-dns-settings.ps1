<#
    DESCRIPTION: 
        Checks that all DNS servers are configured, and if required, in the right order.

    REQUIRED-INPUTS:
        DNSServers    - "LIST" - DNS IP addresses that you want to check|IPv4
        OrderSpecific - "True|False" - Should the DNS order match exactly for a Pass.?  If the number of entries does not match the input list, this is set to "FALSE"
        AllMustExist  - "True|False" - Should all DNS entries exist for a Pass.?

    DEFAULT-VALUES:
        DNSServers    = @('')
        OrderSpecific = 'True'
        AllMustExist  = 'True'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All DNS servers configured (and in the right order)
        WARNING: 
        FAIL:
            DNS Server count mismatch
            Mismatched DNS servers
            DNS Server list is not in the required order
            No DNS servers are configured
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-11-dns-settings
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-11-dns-settings'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @((Get-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled='True'" -Property 'DNSServerSearchOrder').DNSServerSearchOrder)
        $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

        If ($gCIMi.Count -gt 0)
        {
            If (($script:chkValues['AllMustExist']) -eq 'True')
            {
                If ($gCIMi.Count -ne ($script:chkValues['DNSServers'].Count))
                {
                    $result.result  =    $script:lang['Fail']
                    $result.message =    $script:lang['f001']
                    $result.data    = ($($script:lang['dt01']) -f $($gCIMi -join ', '), $($script:chkValues['DNSServers'] -join ', '))
                    Return $result
                }
            }

            If ($gCIMi.Count -ne ($script:chkValues['DNSServers'].Count)) { $script:chkValues['OrderSpecific'] = 'False' }

            If (($script:chkValues['OrderSpecific']) -eq 'True')
            {
                For ($i = 0; $i -le ($gCIMi.Count); $i++) {
                    If ($gCIMi[$i] -ne $script:chkValues['DNSServers'][$i]) { $result.message = 'DNS Server list is not in the required order' }
                }

                If (($result.message) -ne '')
                {
                    $result.result =    $script:lang['Fail']
                    $result.data   = ($($script:lang['dt01']) -f $($gCIMi -join ', '), $($script:chkValues['DNSServers'] -join ', '))
                }
                Else
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p001']
                    $result.data    = ($gCIMi -join ', ')
                }
            }
            Else
            {
                [int]$Found = 0
                $gCIMi | ForEach-Object -Process {
                    If ($script:chkValues['DNSServers'] -contains $_) { $Found++ }
                }

                If ($Found -eq 0)
                {
                    $result.result  =    $script:lang['Fail']
                    $result.message =    $script:lang['f002']
                    $result.data    = ($($script:lang['dt01']) -f $($gCIMi -join ', '), $($script:chkValues['DNSServers'] -join ', '))
                }
                Else
                {
                    $result.result  =  $script:lang['Pass']
                    $result.message =  $script:lang['p002']
                    $result.data    = ($script:chkValues['DNSServers'] -join ', ')
                }
            }
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f003']
            $result.data    = $script:lang['dt02']
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
