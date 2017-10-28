<#
    DESCRIPTION: 
        If server is Domain Controller or a Terminal Server ensure RSA authentication agent is installed.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            RSA agent found
        WARNING:
        FAIL:
            RSA software not found
        MANUAL:
        NA:
            Not a domain controller or terminal services server

    APPLIES:
        Domain Controllers And Terminal Servers

    REQUIRED-FUNCTIONS:
        Check-Software
        Check-IsDomainController
        Check-IsTerminalServer
#>

Function sec-13-rsa-authentication
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-13-rsa-authentication'

    #... CHECK STARTS HERE ...#

    If ((Check-IsDomainController -eq $true) -or (Check-IsTerminalServer -eq $true))
    {
        Try
        {
            [object]$verCheck = (Check-Software -DisplayName 'RSA Authentication Agent')
            If ($verCheck -eq '-1') { Throw $($script:lang['trw1']) }

            If ([string]::IsNullOrEmpty($verCheck) -eq $false)
            {
                $result.result  =    $script:lang['Pass']
                $result.message =    $script:lang['p001']
                $result.data    = ($($script:lang['dt01']) -f $verCheck.Version)
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
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
        $result.result  = $script:lang['Not-Applicable']
        $result.message = $script:lang['n001']
    }

    Return $result
}
