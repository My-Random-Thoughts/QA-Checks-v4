<#
    DESCRIPTION: 
        Check that Trend anti-virus is installed and virus definitions are up to date.

    REQUIRED-INPUTS:
        MaximumDATAgeAllowed - Maximum number of days that DATs are allowed to be out of date|Integer
        ProductName          - Full name of the Trend product
        ProductVersion       - Current version of the product that you are using|Decimal
        DATPathLocation      - Full path location of the DAT location|File

    DEFAULT-VALUES:
        MaximumDATAgeAllowed = '7'
        ProductName          = 'Trend Micro OfficeScan Client'
        ProductVersion       = '10.6'
        DATPathLocation      = 'C:\Program Files (x86)\Trend Micro\OfficeScan Client\'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Trend product found, DATs are OK
        WARNING:
        FAIL:
            Trend product not found, install required
            DATs are not up-to-date
            No DAT version found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function tol-09-trend-antivirus-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'tol-09-trend-antivirus-installed'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$verCheck = (Check-Software -DisplayName $script:chkValues['ProductName'])
        If ($verCheck -eq '-1') { Throw $script:lang['trw1'] }

        If ([string]::IsNullOrEmpty($verCheck) -eq $false)
        {
            # Check AV Version
            If (($verCheck.Version -as [version]) -ge ($($script:chkValues['ProductVersion']) -as [version]))
            {
                $result.result  =    $script:lang['Pass']
                $result.message =    $script:lang['p001']
                $result.data    = ($($script:lang['dt01']) -f $verCheck.Version)
            }
            Else
            {
                $result.result  =    $script:lang['Fail']
                $result.message =    $script:lang['f001']
                $result.data    = ($($script:lang['dt02']) -f $verCheck.Version, $script:chkValues['ProductVersion'])
            }

            # Check DAT Update date
            Try
            {
                [string]$datName = 'icrc$oth.*'
                If (Test-Path -Path ($script:chkValues['DATPathLocation']))
                {
                    [datetime]$dtVal = '01/01/1901'
                    $dtVal = (Get-ItemProperty -Path "$($script:chkValues['DATPathLocation'])\$datName" | Sort-Object LastWriteTime | Select-Object -Last 1).LastWriteTime

                    If ($dtVal -ne '01/01/1901')
                    {
                        $days = ((Get-Date) - $dtVal).Days
                        If ($days -le $script:chkValues['MaximumDATAgeAllowed'])
                        {
                            $result.result   =    $script:lang['Pass']
                            $result.message +=    $script:lang['p002']
                            $result.data    += ($($script:lang['dt03']) -f $days.ToString())
                        }
                        Else
                        {
                            $result.result   =    $script:lang['Fail']
                            $result.message +=    $script:lang['f002']
                            $result.data    += ($($script:lang['dt03']) -f $days.ToString())
                        }
                    }
                }
                Else
                {
                    $result.result   = $script:lang['Fail']
                    $result.message += $script:lang['f003']
                }
            }
            Catch
            {
                $result.result   = $script:lang['Fail']
                $result.message += $script:lang['f003']
            }

            # Get master server name
            [object]$gItmP = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Internet Settings' -Name ('Server', 'ServerPort'))
            If ([string]::IsNullOrEmpty($gItmP) -eq $false) {
                $result.data += ($($script:lang['dt04']) -f $gItmP.Server, $gItmP.ServerPort )
            }
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f004']
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
