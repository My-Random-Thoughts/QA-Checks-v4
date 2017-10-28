<#
    DESCRIPTION:
        Ensure the system is set to reject attempts to enumerate shares in the SAM by anonymous users. 

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Reject anonymous share enumeration is enabled
        WARNING:
        FAIL:
            Reject anonymous share enumeration is disabled
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-07-reject-enumerate-shares
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-07-reject-enumerate-shares'

    #... CHECK STARTS HERE ...#

    Try
    {
        Try {
            [string]$gITMp = ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'RestrictAnonymous' -ErrorAction Stop).RestrictAnonymous)
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
