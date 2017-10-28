<#
    DESCRIPTION: 
        Check if Windows firewall is enabled or disabled for each of the three profiles.  Set to "0" for disabled, and "1" for enabled

    REQUIRED-INPUTS:
        DomainProfile   - "0|1" - Domain firewall state
        PublicProfile   - "0|1" - Public firewall state
        StandardProfile - "0|1" - Standard firewall state

    DEFAULT-VALUES:
        DomainProfile   = '0'
        PublicProfile   = '0'
        StandardProfile = '0'

    DEFAULT-STATE:
        Enabled

    INPUT-DESCRIPTION:
        DomainProfile:
            0: Disabled
            1: Enabled
        PublicProfile:
            0: Disabled
            1: Enabled
        StandardProfile:
            0: Disabled
            1: Enabled

    RESULTS:
        PASS:
            Windows firewall is set correctly
        WARNING: 
        FAIL:
            Windows firewall is not set correctly
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-15-firewall-state
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-15-firewall-state'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy'
        [object]$gITMpD = (Get-ItemProperty -Path "$regPath\DomainProfile"   -Name 'EnableFirewall' -ErrorAction SilentlyContinue)
        [object]$gITMpS = (Get-ItemProperty -Path "$regPath\StandardProfile" -Name 'EnableFirewall' -ErrorAction SilentlyContinue)
        [object]$gITMpP = (Get-ItemProperty -Path "$regPath\PublicProfile"   -Name 'EnableFirewall' -ErrorAction SilentlyContinue)

        $result.data = ''
        If (($gITMpD.EnableFirewall) -ne $script:chkValues['DomainProfile']  ) {
            $result.data += ($($script:lang['dt03']) -f ($gITMpD.EnableFirewall), $script:chkValues['DomainProfile']  )
        }

        If (($gITMpS.EnableFirewall) -ne $script:chkValues['StandardProfile']) {
            $result.data += ($($script:lang['dt04']) -f ($gITMpS.EnableFirewall), $script:chkValues['StandardProfile'])
        }

        If (($gITMpP.EnableFirewall) -ne $script:chkValues['PublicProfile']  ) {
            $result.data += ($($script:lang['dt05']) -f ($gITMpP.EnableFirewall), $script:chkValues['PublicProfile']  )
        }

        If ($result.data -eq '')
        {
            $result.result  =    $script:lang['Pass']
            $result.message =    $script:lang['p001']
            $result.data    = ($($script:lang['dt06']) -f ($gITMpD.EnableFirewall), ($gITMpS.EnableFirewall), ($gITMpP.EnableFirewall))
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }

        $result.data = (($result.data).Replace('0', $script:lang['dt02']).Replace('1', $script:lang['dt01']))
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
    }

    Return $result
}
