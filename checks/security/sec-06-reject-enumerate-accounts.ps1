<#
    DESCRIPTION:
        Ensure the system is set to reject attempts to enumerate accounts in the SAM by anonymous users.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Reject anonymous account enumeration is enabled
        WARNING:
        FAIL:
            Reject anonymous account enumeration is disabled
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-06-reject-enumerate-accounts
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-06-reject-enumerate-accounts'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        Try {
            [string]$gITMp = ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'RestrictAnonymousSAM' -ErrorAction Stop).RestrictAnonymousSAM)
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
