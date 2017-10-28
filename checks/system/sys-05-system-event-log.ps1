<#
    DESCRIPTION: 
        Check System Event Log and ensure no errors are present in the last x days.  If found, will return the latest y entries

    REQUIRED-INPUTS:
        EventLogMaxSize       - Maximum size in MB of this event log (default is 16)
        EventLogRetentionType - "Overwrite|Archive|Manual" - When the maximum log size is reached
        GetLatestEntriesAge   - Return all entries for this number of days|Integer
        GetLatestEntriesCount - Return this number of entries|Integer
        IncludeWarnings       - "True|False" - Include any warning messages.  By default they are omitted

    DEFAULT-VALUES:
        EventLogMaxSize       = '16'
        EventLogRetentionType = 'Overwrite'
        GetLatestEntriesAge   = '14'
        GetLatestEntriesCount = '15'
        IncludeWarnings       = 'False'

    DEFAULT-STATE:
        Enabled

    INPUT-DESCRIPTION:
        EventLogRetentionType:
            Overwrite: Overwrite as needed (oldest first)
            Archive: Archive log when full
            Manual: Do not overwrite (clear manually)

    RESULTS:
        PASS:
            No errors found in system event log
        WARNING:
            Errors were found in the system event log
        FAIL:
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-05-system-event-log
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-05-system-event-log'

    #... CHECK STARTS HERE ...#

    Try
    {
        # Get log entries
        If ($script:chkValues['IncludeWarnings'] -eq 'True') { [string]$incWarn = 'or Level=3' } Else { [string]$incWarn = '' }
        [double]$timeOffSet = ($script:chkValues['GetLatestEntriesAge'] -as [int]) * 60 * 60 * 24 * 1000    # Convert 'days' into 'miliseconds'
        [xml]   $xml        = @"
            <QueryList>
                <Query Id="0" Path="System">
                    <Select Path="System">*[System[(Level=1 or Level=2 $incWarn) and TimeCreated[timediff(@SystemTime) &lt;= $timeOffSet]]]
                    </Select>
                </Query>
            </QueryList>
"@
        [System.Collections.ArrayList]$gWINe = @(Get-WinEvent -MaxEvents $script:chkValues['GetLatestEntriesCount'] -FilterXml $xml -ErrorAction SilentlyContinue | Select-Object -Property ('Level', 'LevelDisplayName', 'TimeCreated', 'Id', 'ProviderName', 'Message'))

        # Check event logs
        If ($gWINe.Count -gt 0)
        {
            $blob = (New-Object -TypeName PSObject -Property @{filename=''; subpath=''; type =''; data='';} )
            $blob.filename = "$($script:lang['dt00'])_Event-Log.csv"
            $blob.subpath  = 'Event-Logs'
            $blob.type     = 'CSV'
            $blob.data     = ($gWINe | Sort-Object -Property 'TimeCreated')
            $result.blob = $blob

            $result.message += $script:lang['dt01']
            $result.data    += ".\$(($result.server).ToUpper())_$($blob.filename)" + ',#'
        }

        # Get size and retention
        [psobject]$gITMp = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\System' -Name ('MaxSize', 'Retention', 'AutoBackupLogFiles') -ErrorAction SilentlyContinue)
        If ([string]::IsNullOrEmpty($gITMp.Retention)          -eq $true) { ($gITMp | Add-Member -Name 'Retention'          -Value '0' -MemberType NoteProperty); $gITMp.Retention          = 0 }
        If ([string]::IsNullOrEmpty($gITMp.AutoBackupLogFiles) -eq $true) { ($gITMp | Add-Member -Name 'AutoBackupLogFiles' -Value '0' -MemberType NoteProperty); $gITMp.AutoBackupLogFiles = 0 }

        $gITMp.MaxSize = ($gITMp.MaxSize / (1024 * 1024))    # Convert B to MB

        # Check max size
        If ($gITMp.MaxSize -ne $script:chkValues['EventLogMaxSize'])
        {
            $result.result   =    $script:lang['Fail']
            $result.message +=    $script:lang['f001']
            $result.data    += ($($script:lang['dt02']) -f $gITMp.MaxSize)
        }

        # Check retention type
        Switch ($script:chkValues['EventLogRetentionType'])
        {                 #       Retention                   AutoBackupLogFiles
            'Overwrite' { [string]$chkRet =  '0'; [string]$chkABL = '0'; Break }
            'Archive'   { [string]$chkRet = '-1'; [string]$chkABL = '1'; Break }
            'Manual'    { [string]$chkRet = '-1'; [string]$chkABL = '0'; Break }
            Default     { }
        }

        If (($gITMp.Retention -ne $chkRet) -or ($gITMp.AutoBackupLogFiles -ne $chkABL))
        {
            [string]$currRetention = $script:lang['dt04']
            If ($gITMp.Retention -eq 0) { $currRetention = $script:lang['dt05'] }
            Else {
                If ($gITMp.AutoBackupLogFiles -eq 0) {
                    $currRetention = $script:lang['dt06'] } Else { $currRetention = $script:lang['dt07'] }
            }

            $result.result   =    $script:lang['Fail']
            $result.message +=    $script:lang['f002']
            $result.data    += ($($script:lang['dt03']) -f $currRetention)
        }

        # Pass or fail check
        If ([string]::IsNullOrEmpty($result.message) -eq $false)
        {
            $result.result   = $script:lang['Fail']
        }
        Else
        {
            $result.result   = $script:lang['Pass']
            $result.message += $script:lang['p001']
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
