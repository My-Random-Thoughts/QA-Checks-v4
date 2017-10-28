<#
    DESCRIPTION:
        Ensure the system is set to restrict anonymous access to named pipes

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Restrict anonymous pipe/share access is enabled
        WARNING:
        FAIL:
            Restrict anonymous pipe/share access is disabled
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-10-anonymous-pipe-share-access
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-10-anonymous-pipe-share-access'

    #... CHECK STARTS HERE ...#

    Try
    {
        Try {
            [string]$gITMp = ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters' -Name 'RestrictNullSessAccess' -ErrorAction Stop).RestrictNullSessAccess)
        } Catch { [string]$gITMp = $null }

        If ([string]::IsNullOrEmpty($gITMp) -eq $true)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }
        ElseIf ($gITMp -eq '1')
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f002']
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
