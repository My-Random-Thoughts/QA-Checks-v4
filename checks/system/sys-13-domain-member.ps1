<#
    DESCRIPTION: 
        Checks that the server is a member of the domain.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Server is a domain member
        WARNING:
            This is a work group server, is this correct.?
        FAIL:    
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-13-domain-member
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-13-domain-member'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$domCheck  = (Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property ('Domain', 'PartOfDomain'))
        [string]$domain = ($domCheck.Domain -split '\.')[0]

        If ($domCheck.PartOfDomain -eq $true)
        {
            $result.result  =  $script:lang['Pass']
            $result.message =  $script:lang['p001']
            $result.data    = ($gCIMi.Domain)
        }
        Else
        {
            $result.result  =    $script:lang['Warning']
            $result.message =    $script:lang['w001']
            $result.data    = ($($script:lang['dt01']) -f $domain)
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
