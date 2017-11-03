<#
    DESCRIPTION: 
        Check NetBackup agent is installed and that the correct port is open to the management server.
        Only applies to physical servers, or virtual servers with a list of known software installed.

    REQUIRED-INPUTS:
        ProductName         - Full name of the product to look for
        RequiredServerRoles - "LIST" - List of known software to check if installed

    DEFAULT-VALUES:
        ProductName         = 'Symantec NetBackup'
        RequiredServerRoles = @('Exchange', 'SQL')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            NetBackup agent found, Port 1556 open to {server}
        WARNING:
        FAIL:
            NetBackup agent not found
            Port 1556 not open to {server}
            NetBackup agent software not found, but this server has {role} installed which requires it
            NetBackup agent software not found, but this server is a domain controller which requires it
        MANUAL:
            Is this server backed up via VADP.?  Manually check vCenter annotations, and look for "NetBackup.VADP: 1"
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-IsDomainController
        Check-IsVMwareGuest
        Check-IsHyperVGuest
        Check-IsPortOpen
        Check-Software
#>

Function com-04-netbackup-agent-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'com-04-netbackup-agent-installed'
    
    #... CHECK STARTS HERE ...#

    [object]$verCheck = (Check-Software -DisplayName $script:chkValues['ProductName'])
    If ($verCheck -eq '-1') { Throw $script:lang['trw1'] }

    If ([string]::IsNullOrEmpty($verCheck) -eq $false)
    {
        $result.result  =    $script:lang['Pass']
        $result.message =    $script:lang['dt01']
        $result.data    = ($($script:lang['dt02']) -f $verCheck.Version)

        [string[]]$ServerNames = @(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veritas\NetBackup\CurrentVersion\Config' -Name 'Server' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'Server')
        $ServerNames | ForEach-Object -Process {
            [boolean]$portTest = (Check-IsPortOpen -DestinationServer $_ -Port 1556)
            If   ($portTest -eq $true)                   { $result.data += ($($script:lang['dt03']) -f $_.ToLower()) }
            Else { $result.result = $script:lang['Fail'];  $result.data += ($($script:lang['dt04']) -f $_.ToLower()) }
        }
    }
    Else
    {
        If ((Check-IsVMwareGuest -eq $true) -or (Check-IsHyperVGuest -eq $true))
        {
            # If backup software not installed, and is a VM, then check for additional software to see if it should be installed
            $found = $false
            $script:chkValues['RequiredServerRoles'] | ForEach-Object -Process {
                [string]$verExist = (Check-Software -DisplayName $_)
                If ($verCheck -eq '-1') { Throw $($script:lang['trw1']) }
                If ([string]::IsNullOrEmpty($verCheck) -eq $false)
                {
                    $result.result  =    $script:lang['Fail']
                    $result.message =    $script:lang['dt05']
                    $result.data    = ($($script:lang['dt06']) -f $_)
                    $found          =    $true
                }
            }

            If (Check-IsDomainController -eq $true)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['dt05']
                $result.data    = $script:lang['dt07']
                $found          = $true
            }

            If ($found -eq $false)
            {
                $result.result  = $script:lang['Manual']
                $result.message = $script:lang['m001']
                $result.data    = $script:lang['dt08']
            }
        }
        Else
        {
            # Physical server
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['dt05']
            $result.data    = $script:lang['dt09']
        }
    }
    
    Return $result
}
