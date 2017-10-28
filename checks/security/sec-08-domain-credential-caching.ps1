<#
    DESCRIPTION:
        Check system is not caching domain credentials.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Domain credential caching is disabled
        WARNING:
        FAIL:
            Domain credential caching is enabled
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-08-domain-credential-caching
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-08-domain-credential-caching'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        Try {
            [string]$gITMp = ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'CachedLogonsCount' -ErrorAction Stop).CachedLogonsCount)
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
