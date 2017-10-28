<#
    DESCRIPTION: 
        Check the state of the HPe System Management Homepage service and version

    REQUIRED-INPUTS:
        MinimumVersion - Minimum installed version number allowed|Decimal
        ServiceState   - "Automatic|Manual|Disabled" - Default state of the service

    DEFAULT-VALUES:
        MinimumVersion = '7.6'
        ServiceState   = 'Disabled'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Service state and version are correct
        WARNING:
        FAIL:
            Service state is not correct
            Installed version is below the minimum set
            HPe SMH not installed
        MANUAL:
        NA:
            Not a HPe physical server

    APPLIES:
        All HPe Physical Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-19-hp-smh-version
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-19-hp-smh-version'
    
    #... CHECK STARTS HERE ...#

    If (isHPServer -eq $true)
    {
        Try
        {
            [object]$gCIMi = (Get-CimInstance -ClassName 'Win32_Service' -Filter "Name='SysMgmtHp'"                          -Property 'StartMode'            -ErrorAction SilentlyContinue)
            [object]$gITMp = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Hewlett-Packard\System Management Homepage' -Name ('InstallPath', 'Version') -ErrorAction SilentlyContinue)

            If ([string]::IsNullOrEmpty($gCIMi) -eq $true)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
            Else
            {
                If ($gCIMi.StartMode -ne $script:chkValues['ServiceState'])
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f002']
                }

                If (($keyVal2.Version -as [version]) -lt ($script:chkValues['MinimumVersion'] -as [version]))
                {
                    $result.result   = $script:lang['Fail']
                    $result.message += $script:lang['f003']
                }

                If ([string]::IsNullOrEmpty($result.message) -eq $true)
                {
                    $result.result   = $script:lang['Pass']
                    $result.message += $script:lang['p001']
                }

                $result.data = ($($script:lang['dt01']) -f $gCIMi.StartMode, $gITMp.InstallPath, $gITMp.Version)
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

Function isHPServer
{
    [string]$wmiBIOS = ((Get-CimInstance -ClassName 'Win32_BIOS' -Property 'Manufacturer').Manufacturer)
    If ($wmiBIOS -like 'HP*') { Return $true } Else { Return $false }
}
