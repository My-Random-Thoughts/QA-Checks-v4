<#
    DESCRIPTION: 
        Check relevant monitoring tool agent is installed and that the correct port is open to the management server.

    REQUIRED-INPUTS:
        ProductNames - "LIST" - SCOM agent product names to search for

    DEFAULT-VALUES:
        ProductNames = @('Microsoft Monitoring Agent', 'System Center Operations Manager', 'Operations Manager Agent')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            {product} found, port {port} open to {server}
        WARNING:
        FAIL:
            Monitoring software not found, install required
            {product} found, agent not configured with port and/or servername
            {product} found, port {port} not open to {server}
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-IsPortOpen
        Check-Software
#>

Function tol-02-scom-monitoring-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'tol-02-scom-monitoring-installed'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$details = $null
        $script:chkValues['ProductNames'] | ForEach-Object -Process {
            If ([string]::IsNullOrEmpty($_) -eq $false)
            {
                $script:chkValues['Win32_Product'] = 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'    # Reset search path
                [object]$verCheck = (Check-Software -DisplayName $_)
                If ($verCheck -eq '-1') { Throw $($script:lang['trw1']) }
                If ([string]::IsNullOrEmpty($verCheck) -eq $false) { $details = $verCheck }
            }
        }

        If ([string]::IsNullOrEmpty($details) -eq $false)
        {
            [string]  $regPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups'
            [string[]]$regKey  = @(Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue)
            If (([string]::IsNullOrEmpty($regKey) -eq $false) -and ($regKey.Count -gt 0)) {
                [object]$valItem = (Get-ItemProperty -Path "$regPath\$(($regKey[0]).Split('\')[-1])\Parent Health Services\0" -Name ('Networkname', 'Port') -ErrorAction SilentlyContinue)
            }

            If ([string]::IsNullOrEmpty($valItem) -eq $false) 
            {
                [boolean]$portTest = (Check-IsPortOpen -DestinationServer $($valItem.NetworkName) -Port ($($valItem.Port) -as [int]))
                If ($portTest -eq $true)
                {
                    $result.result  =    $script:lang['Pass']
                    $result.message = ($($script:lang['dt01']) -f $details.DisplayName)
                    $result.data    = ($($script:lang['p001']) -f $details.Version, $($valItem.Port), $($valItem.NetworkName).ToLower())
                }
                Else
                {
                    $result.result  =    $script:lang['Fail']
                    $result.message = ($($script:lang['dt01']) -f $details.DisplayName)
                    $result.data    = ($($script:lang['f001']) -f $details.Version, $($valItem.Port), $($valItem.NetworkName).ToLower())
                }
            }
            Else
            {
                $result.result  =    $script:lang['Fail']
                $result.message = ($($script:lang['dt01']) -f $details.DisplayName)
                $result.data    = ($($script:lang['f002']) -f $details.Version)
            }
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f003']
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
