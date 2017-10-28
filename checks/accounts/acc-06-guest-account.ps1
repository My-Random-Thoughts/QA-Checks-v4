<#
    DESCRIPTION: 
        Checks to make sure that the guest user account has been disabled.  The guest account is located via the well known SID.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Guest account is disabled
        WARNING:
        FAIL:
            Guest account has not been disabled
        MANUAL:
        NA:
            Guest account does not exist

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function acc-06-guest-account
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'acc-06-guest-account'

    #... CHECK STARTS HERE ...#

    Try
    {
        # Local guest account SID always ends in '-501'
        [psobject]$guest = (Get-CimInstance -ClassName 'Win32_UserAccount' -Filter "LocalAccount='True' AND SID LIKE '%-501'" -Property ('Name', 'Disabled'))

        If ([string]::IsNullOrEmpty($guest) -eq $true)
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
        }
        Else
        {
            If ($guest.Disabled -eq $true)
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
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
