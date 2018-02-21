<#
    DESCRIPTION: 
        Check server is compliant with patch policy (must be patched to latest released patch level for this customer).
        Check date of last patch and return WARNING if not within specified number of days, and FAIL if not within number of days *2.

    REQUIRED-INPUTS:
        MaximumLastPatchAgeAllowed - Maximum number of days that patching is allowed to be out of date|Integer

    DEFAULT-VALUES:
        MaximumLastPatchAgeAllowed = '35'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Windows patches applied
        WARNING:
            Server not patched within the last {num} days
        FAIL:
            Server not patched within the last {num} days
            No last patch date - Check data for any error messages
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function tol-05-last-patch-date
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'tol-05-last-patch-date'

    #... CHECK STARTS HERE ...#

    Try
    {
        Try
        {
            $session  = [activator]::CreateInstance([type]::GetTypeFromProgID('Microsoft.Update.Session'))
            $searcher = $session.CreateUpdateSearcher()
            $history  = $searcher.GetTotalHistoryCount()
            If ($history -gt 0) { [object]$HistoryItem = $searcher.QueryHistory(0, 1) | Select-Object -Property 'Title', 'Date' } Else { [string]$HistoryItem = $null }
        }
        Catch
        {
            $history = ($Error[0].Exception.Message)
        }

        If ([string]::IsNullOrEmpty($HistoryItem) -eq $false)
        {
            [int]$days = ((Get-Date) - $($HistoryItem.Date)).Days
            If ($days -gt ($script:chkValues['MaximumLastPatchAgeAllowed'] * 2))
            {
                # 2 months (using default setting)
                $result.result  =    $script:lang['Fail']
                $result.message = ($($script:lang['dt01']) -f (($script:chkValues['MaximumLastPatchAgeAllowed'] -as [int])* 2))
            }
            ElseIf ($days -gt $script:chkValues['MaximumLastPatchAgeAllowed'])
            {
                # 1 month (using default setting)
                $result.result  =    $script:lang['Warning']
                $result.message = ($($script:lang['dt01']) -f $script:chkValues['MaximumLastPatchAgeAllowed'])
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }

            $result.data = ($($script:lang['dt02']) -f $HistoryItem.Date, $days, $HistoryItem.Title)
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
            If ($history -eq '0') { $result.data = $script:lang['dt03'] } Else { $result.data = $history }
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
