<#
    DESCRIPTION:
        Check a custom event log and ensure no errors are present in the last x days.  If found, will return the latest y entries.
        To get the correct name of the log, view its properties and see the "Full Name" entry.

    REQUIRED-INPUTS:
        EventLogName          - "LIST" - Exact names of the event logs to search. Examples include: Directory Service, DNS Server, Windows PowerShell.
        GetLatestEntriesAge   - Return all entries for this number of days|Integer
        GetLatestEntriesCount - Return this number of entries|Integer
        IncludeWarnings       - "True|False" - Include any warning messages.  By default they are omitted

    DEFAULT-VALUES:
        EventLogName          = @('')
        GetLatestEntriesAge   =   '14'
        GetLatestEntriesCount =   '15'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No errors found in the selected event logs
        WARNING:
            Errors were found in the following event logs
        FAIL:
            Errors were found in the following event logs
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-08-custom-event-log
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-08-custom-event-log'

    #... CHECK STARTS HERE ...#

    If ($script:chkValues['EventLogName'].Count -eq 0)
    {
        $result.result   = $script:lang['Not-Applicable']
        $result.message += 'No event log specified'
    }
    Else
    {
        [object]$eventLogs = @{}
        $script:chkValues['EventLogName'] | ForEach-Object -Process {
            [string]$logName = $_
            Try
            {
                # Get log entries
                If ($script:chkValues['IncludeWarnings'] -eq 'True') { [string]$incWarn = 'or Level=3' } Else { [string]$incWarn = '' }
                [double]$timeOffSet = ($script:chkValues['GetLatestEntriesAge'] -as [int]) * 60 * 60 * 24 * 1000    # Convert 'days' into 'miliseconds'
                [xml]   $xml        = @"
                    <QueryList>
                        <Query Id="0" Path="$logName">
                            <Select Path="$logName">*[System[(Level=1 or Level=2 $incWarn) and TimeCreated[timediff(@SystemTime) &lt;= $timeOffSet]]]
                            </Select>
                        </Query>
                    </QueryList>
"@
                [System.Collections.ArrayList]$gWINe = @(Get-WinEvent -MaxEvents $script:chkValues['GetLatestEntriesCount'] -FilterXml $xml -ErrorAction SilentlyContinue | Select-Object -Property ('Level', 'LevelDisplayName', 'TimeCreated', 'Id', 'ProviderName', 'Message'))
            }
            Catch
            {
                # Event log name is incorrect
                If ($result.result -ne  $script:lang['Fail']) { $result.result = $script:lang['Warning'] }
                $result.message     += "$logName,#"
                $result.data        +=  $script:lang['w001']
            }

            # Check event logs
            If ($gWINe.Count -gt 0)
            {
                $blob = (New-Object -TypeName PSObject -Property @{filename=''; subpath=''; type =''; data='';} )
                $blob.filename = "$($logName.Replace('/', '~'))_Event-Log.csv"
                $blob.subpath  = 'Event-Logs'
                $blob.type     = 'CSV'
                $blob.data     = ($gWINe | Sort-Object -Property 'TimeCreated')
                $result.blob = $blob

                $result.result   = $script:lang['Fail']
                $result.message += $script:lang['f001']
                $result.data    += ".\$(($result.server).ToUpper())_$($blob.filename)" + ',#'
            }
        }
    }

    # Pass or fail check
    If ([string]::IsNullOrEmpty($result.message) -eq $true)
    {
        $result.result  = $script:lang['Pass']
        $result.message = $script:lang['p001']
    }

    Return $result
}
