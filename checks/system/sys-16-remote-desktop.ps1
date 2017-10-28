<#
    DESCRIPTION: 
        Check that remote desktop is enabled and that Network Level Authentication (NLA) is set.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Secure remote desktop and NLA enabled
        WARNING:
            Network Level Authentication is not set
        FAIL:
            Secure remote desktop disabled
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-16-remote-desktop
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-16-remote-desktop'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$gCIMi1 = (Get-CimInstance -ClassName 'Win32_TerminalServiceSetting' -Namespace 'ROOT\Cimv2\TerminalServices' -Property 'AllowTSConnections'         -ErrorAction SilentlyContinue)
        [object]$gCIMi2 = (Get-CimInstance -ClassName 'Win32_TSGeneralSetting'       -Namespace 'ROOT\Cimv2\TerminalServices' -Property 'UserAuthenticationRequired' -ErrorAction SilentlyContinue)

        If (($gCIMi1.AllowTSConnections -eq 1) -and ($gCIMi2.UserAuthenticationRequired -eq 1))
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            If ($gCIMi1.AllowTSConnections -eq 0)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
            Else
            {
                $result.result  = $script:lang['Warning']
                $result.message = $script:lang['p001']
                $result.data    = $script:lang['dt01']
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
