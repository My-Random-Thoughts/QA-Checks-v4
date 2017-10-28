<#
    DESCRIPTION: 
        Checks to see if the default local "Administrator" and "Guest" accounts have been renamed.

    REQUIRED-INPUTS:
        InvalidAdminNames - "LIST" - Names that should not be used

    DEFAULT-VALUES:
        InvalidAdminNames = @('Administrator', 'Admin', 'Guest', 'Guest1')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Local accounts have been renamed
        WARNING:
        FAIL:
            A local account was found that needs to be renamed
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function acc-02-local-account-names
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'acc-02-local-account-names'

    #... CHECK STARTS HERE ...#

    Try
    {
        # Admin and Guest account names
        [string]$admin = ((Get-CimInstance -ClassName 'Win32_UserAccount' -Filter "LocalAccount='True' AND SID LIKE '%-500'" -Property 'Name').Name)
        [string]$guest = ((Get-CimInstance -ClassName 'Win32_UserAccount' -Filter "LocalAccount='True' AND SID LIKE '%-501'" -Property 'Name').Name)

        # All local accounts
        [System.Collections.ArrayList]$gCIMi = @((Get-CimInstance -ClassName 'Win32_UserAccount' -Filter "LocalAccount='True'" -Property 'Name').Name)
        $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

        [int]$accsFound = 0
        ForEach ($acc In $gCIMi)
        {
            $script:chkValues['InvalidAdminNames'] | Sort-Object | ForEach-Object -Process {
                If ($acc -like $_) { $accsFound++; $result.data += "$acc,#" }
            }
        }

        If ($accsFound -gt 0)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }
        Else
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }

        $result.data = ($($script:lang['dt01']) -f $admin, $guest)
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
    }
    
    Return $result
}
