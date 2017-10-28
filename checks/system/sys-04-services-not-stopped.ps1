<#
    DESCRIPTION: 
        Check services and ensure all listed services are set to disabled and are stopped.

    REQUIRED-INPUTS:
        CheckTheseServices - "LIST" - Known services that should be in a disabled state

    DEFAULT-VALUES:
        CheckTheseServices = @('')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All services are configured correctly
        WARNING:
        FAIL:
            One or more services are configured incorrectly
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-04-services-not-stopped
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-04-services-not-stopped'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Text.StringBuilder]   $filter = "Name='Null'"
        $script:chkValues['CheckTheseServices'] | ForEach-Object -Process { [void]$filter.Append(" OR Name='$_'") }
        [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_Service' -Filter $filter -Property ('DisplayName', 'StartMode', 'State') -ErrorAction SilentlyContinue)

        If ($gCIMi.Count -gt 0)
        {
            $gCIMi | Sort-Object -Property 'DisplayName' | ForEach-Object -Process {
                $st = ''
                $sm = ''
                If ($_.State     -ne 'Stopped' ) { $st = $_.State     }
                If ($_.StartMode -ne 'Disabled') { $sm = $_.StartMode }
                If (($st -ne '') -or ($sm -ne '')) {
                    $result.data += "$($_.DisplayName) ($sm/$st),#"
                }
            }

            If ([string]::IsNullOrEmpty($result.data) -eq $false)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
        }
        Else
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
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
