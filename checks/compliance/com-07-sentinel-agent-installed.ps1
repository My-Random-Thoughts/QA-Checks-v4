<#
    DESCRIPTION: 
        Check sentinel monitoring agent is installed, and that the correct port is open to the management server.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Skip

    RESULTS:
        PASS:
            Sentinel agent found, port {port} open to {server}
        WARNING:
        FAIL:
            Sentinel agent found, port {port} not open to {server}
            Sentinel agent not found, install required
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-Software
        Check-IsPortOpen
#>

Function com-07-sentinel-agent-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'com-07-sentinel-agent-installed'

    #... CHECK STARTS HERE ...#

    [object]$verCheck = (Check-Software -DisplayName 'NetIQ Sentinel Agent')
    If ($verCheck -eq '-1') { Throw $script:lang['trw1'] }

    If ([string]::IsNullOrEmpty($verCheck) -eq $false)
    {
        $result.result  =    $script:lang['Pass']
        $result.message =    $script:lang['p001']
        $result.data    = ($($script:lang['dt01']) -f $verCheck.Version)

        Try
        {
            [string]  $regPath = 'HKLM:\SOFTWARE\Wow6432Node\NetIQ\Security Manager\Configurations'
            [string[]]$gChldI  = @((Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue).Name)

            If (([string]::IsNullOrEmpty($gChldI) -eq $false) -and ($gChldI.Count -gt 0))
            {
                0..9 | ForEach-Object -Process {
                    [string]$cons = (Get-ItemProperty -Path "$regPath\$($gChldI[0].Split('\')[-1])\Operations\Agent\Consolidators" -Name ("Consolidator $_ Host", "Consolidator $_ Port") -ErrorAction SilentlyContinue)
                    If ([string]::IsNullOrEmpty($cons) -eq $false)
                    {
                        [boolean]$portTest = (Check-IsPortOpen -DestinationServer $($cons."Consolidator $_ Host") -Port $($cons."Consolidator $_ Port"))
                        If ($portTest -eq $true) {
                            $result.result = $script:lang['Pass']
                            $result.data += ($($script:lang['dt02']) -f $($cons."Consolidator $_ Port"), $($cons."Consolidator $_ Host").ToLower())
                        }
                        Else {
                            $result.result = $script:lang['Fail']
                            $result.data += ($($script:lang['dt03']) -f $($cons."Consolidator $_ Port"), $($cons."Consolidator $_ Host").ToLower())
                        }
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
    }
    Else
    {
        $result.result  = $script:lang['Fail']
        $result.message = $script:lang['f001']
    }

    Return $result
}
