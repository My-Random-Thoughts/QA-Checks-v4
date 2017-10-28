<#
    DESCRIPTION: 
        Check BladeLogic monitoring agent is installed, and that the correct port is listening.
        Also check that the USERS.LOCAL file is configured correctly.

    REQUIRED-INPUTS:
        ListeningPort - Port number that the agent listens on|Integer
        CustomerCode  - Customer name found in USERS.LOCAL: ACME_L3AdminW:* rw,map=Administrator
        LocalAccount  - Mapped account name found in USERS.LOCAL: ACME_L3AdminW:* rw,map=Administrator

    DEFAULT-VALUES:
        ListeningPort = '4750'
        CustomerCode  = 'ACME'
        LocalAccount  = 'Administrator'

    DEFAULT-STATE:
        Skip

    RESULTS:
        PASS:
            BladeLogic agent found
            Port {0} is listening
            USERS.LOCAL configured correctly
        WARNING:
        FAIL:
            BladeLogic agent not found, install required
            Port {0} is not listening
            USERS.LOCAL not configured
            USERS.LOCAL not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function com-08-bladelogic-agent-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'com-08-bladelogic-agent-installed'

    #... CHECK STARTS HERE ...#

    [object]$verCheck = (Check-Software -DisplayName 'BMC BladeLogic Server Automation RSCD Agent')
    If ($verCheck -eq '-1') { Throw $script:lang['trw1'] }

    If ([string]::IsNullOrEmpty($verCheck) -eq $false)
    {
        $result.result  =    $script:lang['Pass']
        $result.message =    $script:lang['p001']
        $result.data    = ($($script:lang['dt01']) -f $verCheck.Version)

        Try
        {
            # Check for listening port...
            [boolean]$found = $false
            $TCPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
            [System.Net.IPEndPoint[]]$Connections = $TCPProperties.GetActiveTcpListeners()
            $Connections | ForEach-Object -Process { If ($($_.Port) -eq $script:chkValues['ListeningPort']) { $found = $true } }

            If ($found -eq $true) {
                $result.data   += ($($script:lang['dt02']) -f $script:chkValues['ListeningPort'])
            }
            Else {
                $result.result  =    $script:lang['Fail']
                $result.data   += ($($script:lang['dt03']) -f $script:chkValues['ListeningPort'])
            }

            # Check USER.LOCAL configuration file
            If ((Test-Path -Path "$env:windir\rsc\users.local") -eq $true)
            {
                [boolean] $found     = $false
                [string[]]$usersfile = (Get-Content -Path "$env:windir\rsc\users.local")
                $usersfile | ForEach-Object -Process {
                    If (($_.StartsWith($script:chkValues['CustomerCode']) -eq $true) -and 
                          ($_.EndsWith($script:chkValues['LocalAccount']) -eq $true)) { $found = $true }
                }

                If ($found -eq $true)
                {
                    $result.data += $script:lang['dt04']
                }
                Else
                {
                    $result.result  = $script:lang['Fail']
                    $result.data   += $script:lang['f001']
                }
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.data   += $script:lang['f002']
            }
        }
        Catch
        {
            $result.result  = $script:lang['Error']
            $result.message = $script:lang['Script-Error']
            $result.data    = $_.Exception.Message
        }
    }
    Else
    {
        $result.result  = $script:lang['Fail']
        $result.message = $script:lang['f003']
    }

    Return $result
}
