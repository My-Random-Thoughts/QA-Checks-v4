<#
    DESCRIPTION: 
        Check that the latest VMware tools or Microsoft integration services are installed.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            VMware tools are up to date
        WARNING:
        FAIL:
            Integration services not installed
            VMware tools can be upgraded
        MANUAL:
            Integration services found
            Unable to check the VMware Tools upgrade status
        NA:
            Not a virtual machine

    APPLIES:
        Virtual Servers

    REQUIRED-FUNCTIONS:
        Check-IsHyperVGuest
        Check-IsVMwareGuest
#>

Function vmw-01-tools-version
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'vmw-01-tools-version'

    #... CHECK STARTS HERE ...#

    Try
    {
        If ((Check-IsHyperVGuest) -eq $true)
        {
            [object]$gItmP = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Auto' -Name 'IntegrationServicesVersion' -ErrorAction Stop)
            If ([string]::IsNullOrEmpty($gItmP) -eq $false)
            {
                $result.result  = $script:lang['Manual']
                $result.message = $script:lang['m001']
                $result.data    = ('Version: {0}' -f $($gItmP.IntegrationServicesVersion))
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
        }
        ElseIf ((Check-IsVMwareGuest) -eq $true)
        {
            [string]$versi = (Invoke-Command -ScriptBlock { &"$env:ProgramFiles\VMware\VMware Tools\VMwareToolBoxCmd.exe" -v             } -ErrorAction SilentlyContinue)
            [string]$stats = (Invoke-Command -ScriptBlock { &"$env:ProgramFiles\VMware\VMware Tools\VMwareToolBoxCmd.exe" upgrade status } -ErrorAction SilentlyContinue)

            If ($stats -like $script:lang['ck01'])
            {
                $result.result  =    $script:lang['Pass']
                $result.message =    $script:lang['p001']
                $result.data    = ($($script:lang['dt01']) -f $versi)
            }
            ElseIf ($stats -like $script:lang['ck02'])
            {
                $result.result  =    $script:lang['Fail']
                $result.message =    $script:lang['f002']
                $result.data    = ($($script:lang['dt01']) -f $versi)
            }
            Else
            {
                $result.result  = $script:lang['Manual']
                $result.message = $script:lang['m002']
                $result.data    = $script:lang['dt02']
            }
        }
        Else
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
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
