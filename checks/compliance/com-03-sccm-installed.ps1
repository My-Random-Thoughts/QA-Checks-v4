<#
    DESCRIPTION: 
        Check relevant SCCM agent process is running, and that the correct port is open to the management server.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            SCCM agent found, port {port} open to {server}
        WARNING:
        FAIL:
            SCCM agent found, agent not configured with port and/or servername
            SCCM agent found, port {port} not open to {server}
            SCCM agent not found, install required
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-IsPortOpen
#>

Function com-03-sccm-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'com-03-sccm-installed'

    #... CHECK STARTS HERE ...#

    Try
    {
        [string]  $gProcs  =  (Get-Process      -Name 'CcmExec' -ErrorAction SilentlyContinue)
        [psobject]$regVal1 = @(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM'             -Name ('SMSSLP', 'HttpsPort') -ErrorAction SilentlyContinue)
        [psobject]$regVal2 = @(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\CCM' -Name ('SMSSLP', 'HttpsPort') -ErrorAction SilentlyContinue)

        If (([string]::IsNullOrEmpty($gProcs) -eq $false) -and ([string]::IsNullOrEmpty($regVal1) -eq $false) -and ([string]::IsNullOrEmpty($regVal1) -eq $false))
        {
            If     (([string]::IsNullOrEmpty($($regVal1.SMSSLP)) -eq $false) -and ([string]::IsNullOrEmpty($($regVal1.HttpsPort)) -eq $false)) { [psobject]$regVal = $regVal1 }
            ElseIf (([string]::IsNullOrEmpty($($regVal2.SMSSLP)) -eq $false) -and ([string]::IsNullOrEmpty($($regVal2.HttpsPort)) -eq $false)) { [psobject]$regVal = $regVal2 }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['dt01']
                $result.data    = $script:lang['dt04']
                Return $result
            }

            [boolean]$portTest = (Check-IsPortOpen -DestinationServer $($regVal.SMSSLP) -Port $($regVal.HttpsPort))
            If ($portTest -eq $true)
            {
                $result.result  =    $script:lang['Pass']
                $result.message =    $script:lang['dt01']
                $result.data    = ($($script:lang['dt02']) -f $($regVal.HttpsPort), $($regVal.SMSSLP).ToLower())
            }
            Else
            {
                $result.result  =    $script:lang['Fail']
                $result.message =    $script:lang['dt01']
                $result.data    = ($($script:lang['dt03']) -f $($regVal.HttpsPort), $($regVal.SMSSLP).ToLower())
            }
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

    Return $result
}
