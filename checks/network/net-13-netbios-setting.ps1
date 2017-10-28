<#
    DESCRIPTION: 
        Check the WINS NetBIOS Settings for each enabled network adapter

    REQUIRED-INPUTS:
        RequriedSetting - "0|1|2" - Each adapter should be set to this value

    DEFAULT-VALUES:
        RequriedSetting = 2

    DEFAULT-STATE:
        Enabled

    INPUT-DESCRIPTION:
        RequriedSetting:
            0: Default (Use NetBIOS setting from DHCP server)
            1: Enabled NetBIOS over TCP/IP
            2: Disabled NetBIOS over TCP/IP

    RESULTS:
        PASS:
            All adapters are configured correctly
        WARNING:
            No network adapters configured
        FAIL:
            One or more adapters are not configured correctly
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-13-netbios-setting
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-13-netbios-setting'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled='True'")
        If ($gCIMi.Count -gt 0)
        {
            $gCIMi | ForEach-Object -Process {
                If ($_.TCPIPNetBIOSOptions -ne $script:chkValues['RequriedSetting'])
                {
                    [string]$gCIMi2 = (Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter "Index='$($_.Index)'" -Property 'NetConnectionID').NetConnectionID
                    Switch ($_.TCPIPNetBIOSOptions)
                    {
                        0 { $value = $script:lang['dt01'] }
                        1 { $value = $script:lang['dt02'] }
                        2 { $value = $script:lang['dt03'] }
                    }
                    $result.data += ($($script:lang['dt04']) -f $gCIMi2, $value)
                }
            }

            If ($result.data -ne '')
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
                $result.data    = ($result.data | Sort-Object)
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
