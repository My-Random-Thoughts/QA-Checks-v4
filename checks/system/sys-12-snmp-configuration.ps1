<#
    DESCRIPTION: 
        Check if SNMP role is install on the server.  If so, ensure the SNMP community strings follow the secure password policy.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            SNMP Service installed, but disabled
        WARNING:
            SNMP Service installed, no communities configured
        FAIL:
        MANUAL:
            SNMP Service installed, communities listed
        NA:
            SNMP Service not installed

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-12-snmp-configuration
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-12-snmp-configuration'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$gCIMi = (Get-CimInstance -ClassName 'Win32_Service' -Filter "Name='SNMP'" -Property ('DisplayName', 'StartMode') -ErrorAction SilentlyContinue)
        If ([string]::IsNullOrEmpty($gCIMi) -eq $true)
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
        }
        Else
        {
            If ($gCIMi.StartMode -eq 'Disabled')
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
            Else
            {
                [System.Collections.ArrayList]$gVALn = @()
                Try
                {
                    [Microsoft.Win32.RegistryKey]$gITM = @(Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities' -ErrorAction Stop)
                    $gVALn = $gITM.GetValueNames()
                    If ($gVALn.Count -eq 0)
                    {
                        $result.result  = $script:lang['Warning']
                        $result.message = $script:lang['w001']
                    }
                    Else
                    {
                        $result.result  = $script:lang['Manual']
                        $result.message = $script:lang['m001']

                        $gVALn | ForEach-Object -Process {
                            [string]$gValue = $gITM.GetValue($_)
                            If ($gValue -eq '4') { $result.data += ($($script:lang['dt01']) -f $_) }
                            If ($gValue -eq '8') { $result.data += ($($script:lang['dt02']) -f $_) }
                        }
                    }
                }
                Catch
                {
                    $result.result  = $script:lang['Warning']
                    $result.message = $script:lang['w001']
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
