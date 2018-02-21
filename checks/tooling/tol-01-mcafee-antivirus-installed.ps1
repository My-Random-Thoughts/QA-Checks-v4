<#
    DESCRIPTION: 
        Check that McAfee anti-virus is installed and virus definitions are up to date.

    REQUIRED-INPUTS:
        MaximumDATAgeAllowed - Maximum number of days that DATs are allowed to be out of date|Integer
        ProductName          - Full name of the McAfee product
        ProductVersion       - Current version of the product that you are using|Decimal

    DEFAULT-VALUES:
        MaximumDATAgeAllowed = '7'
        ProductName          = 'McAfee VirusScan Enterprise'
        ProductVersion       = '8.8'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            McAfee product found, DATs are OK
            Access Protection is installed and running
        WARNING:
        FAIL:
            McAfee product found, but wrong version, 
            McAfee product not found, install required
            Access Protection is not installed or enabled
            DATs are not up-to-date
            No DAT version found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-Software
        Check-IsPortOpen
#>

Function tol-01-mcafee-antivirus-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'tol-01-mcafee-antivirus-installed'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$verCheck = (Check-Software -DisplayName $script:chkValues['ProductName'])
        If ($verCheck -eq '-1') { Throw $script:lang['trw1'] }

        If ([string]::IsNullOrEmpty($verCheck) -eq $false)
        {
            # Check AV Version
            If (($verCheck.Version -as [version]) -ge ($script:chkValues['ProductVersion'] -as [version]))
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

            # Check DAT Update date, and Access Protection is installed and enabled
            [datetime]$dtVal = '01/01/1901'
                      $dtVal = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\McAfee\AvEngine'                                              -Name  'AVDatDate'                 -ErrorAction SilentlyContinue).'AVDatDate'
            [psobject]$apVal = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\McAfee\SystemCore\VSCore\On Access Scanner\BehaviourBlocking' -Name ('APEnabled', 'APInstalled') -ErrorAction SilentlyContinue)
            [string]  $msVal = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Network Associates\ePolicy Orchestrator\Agent'                -Name  'ePOServerList'             -ErrorAction SilentlyContinue).'ePOServerList'

            # Check DAT date
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
            Else
            {
                $result.result   = $script:lang['Fail']
                $result.message += $script:lang['f003']
            }

            # Check OAS
            If ([string]::IsNullOrEmpty($apVal) -eq $false)
            {
                If ((($apVal.APEnabled) -eq 1) -and (($apVal.APInstalled) -eq 1)) { $result.message += $script:lang['p003'] }
            }
            Else
            {
                $result.result   = $script:lang['Fail']
                $result.message += $script:lang['f004']
                If     ($apVal.APEnabled   -ne 1) { $result.data += $script:lang['dt04'] }
                ElseIf ($apVal.APInstalled -ne 1) { $result.data += $script:lang['dt05'] }
                Else   {}
            }

            # Check EPO access
            If ([string]::IsNullOrEmpty($msVal) -eq $false)
            {
                $msVal.Trim(';').Split(';') | ForEach -Process {
                    [boolean]$portTest = (Check-IsPortOpen -DestinationServer $($_.Split('|')[0]) -Port ($($_.Split('|')[2]) -as [int]))
                    If ($portTest -eq $true) { $result.data += ($($script:lang['dt06']) -f $($_.Split('|')[2]), $($_.Split('|')[0])) }
                    Else                     { $result.data += ($($script:lang['dt07']) -f $($_.Split('|')[2]), $($_.Split('|')[0])); $result.result = $script:lang['Fail'] }
                }
            }
            Else
            {
                $result.result   = $script:lang['Fail']
                $result.message += $script:lang['f006']
            }
        }
        Else
        {
            $result.result  =    $script:lang['Fail']
            $result.message = ($($script:lang['f005']) -f $script:chkValues['ProductName'])
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
