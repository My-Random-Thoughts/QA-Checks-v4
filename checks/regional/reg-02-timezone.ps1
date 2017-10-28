<#
    DESCRIPTION: 
        Check that the server time zone is correct.  Default setting is "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"
        For Windows 2003, check is "(UTC) Dublin, Edinburgh, Lisbon, London"

    REQUIRED-INPUTS:
        TimeZoneNames - "LIST" - Time zone strings to check against.  Different OS versions use different strings.

    DEFAULT-VALUES:
        TimeZoneNames = @('(UTC) Dublin, Edinburgh, Lisbon, London', '(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London', '(UTC+00:00) Dublin, Edinburgh, Lisbon, London')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Server time zone set correctly
        WARNING:
        FAIL:
            Server time zone is incorrect and should be set to {string}
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function reg-02-timezone
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'reg-02-timezone'

    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$gCIMi = ((Get-CimInstance -ClassName 'Win32_TimeZone' -Property 'Caption' -ErrorAction SilentlyContinue).Caption)
        If ($script:chkValues['TimeZoneNames'] -contains $gCIMi )
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  =   $script:lang['Fail']
            $result.message = $($script:lang['f001']) -f $script:chkValues['TimeZoneNames']
        }
        $result.data = $gCIMi
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
    }

    Return $result
}
