<#
    DESCRIPTION: 
        Check to see if any non standard scheduled tasks exist on  the server (Any application specific scheduled tasks should be documented with a designated contact point specified).
        This check automatically ignores any Microsoft labelled specific tasks.
   
    REQUIRED-INPUTS:
        IgnoreTheseScheduledTasks - "LIST" - Scheduled tasks that can be ignored

    DEFAULT-VALUES:
        IgnoreTheseScheduledTasks = ('SQM data sender', 'SystemSoundsService', 'StartComponentCleanup', 'Automatic-Workplace-Join', 'ReplaceOMCert', 'Optimize Start Menu Cache Files')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No additional scheduled tasks found
        WARNING:
            Additional scheduled tasks found - make sure these are documented
        FAIL:
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-09-scheduled-tasks
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-09-scheduled-tasks'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.__ComObject]          $schedule = New-Object -ComObject('Schedule.Service')
                                      $schedule.Connect()
        [System.Collections.ArrayList]$tasks    = Get-Tasks($schedule.GetFolder('\'))
        [System.Collections.ArrayList]$taskList = @()

        $tasks | Sort-Object -Property 'Name' | ForEach-Object -Process {
            [xml]   $xml    = $_.Xml
            [string]$author = $xml.Task.RegistrationInfo.Author

            If (($Author -notlike '*Microsoft*') -and ($Author -notlike '*SystemRoot*') -and ($author -ne ''))
            {
                $nameSpace = New-Object 'System.Xml.XmlNamespaceManager'($xml.NameTable)
                $nameSpace.AddNamespace("ns", $xml.DocumentElement.NamespaceURI)
                [string]$runAs = $xml.SelectSingleNode('//ns:Principal[@id="Author"]', $nameSpace).UserID

                If ([string]::IsNullOrEmpty($runAs) -eq $true) { $runAs = $author   }    # If no RunAs user, set as author
                If ([string]::IsNullOrEmpty($runAs) -eq $true) { $runAs = 'Unknown' }    # If still no RunAs user, set as unknown

                If (($_.Name).Contains('-S-1-5-21-')) { [string]$NewName = $($_.Name).Split('-')[0] } Else { [string]$NewName = $_.Name }
                [void]$taskList.Add("$($_.Name) ($runAs)")
            }
        }

        # Remove known list
        [System.Collections.ArrayList]$taskListC = $taskList.Clone()
        If ([string]::IsNullOrEmpty($script:chkValues['IgnoreTheseScheduledTasks']) -eq $false)
        {
            $taskList | ForEach-Object -Process {
                [string]$task = $_
                $script:chkValues['IgnoreTheseScheduledTasks'] | ForEach-Object -Process {
                    If ($task -like "$_*") { $taskListC.Remove($task) }
                }
            }
        }
        
        If ($taskListC.Count -gt 0)
        {
            $result.result  = $script:lang['Warning']
            $result.message = $script:lang['w001']
            $taskListC | ForEach-Object -Process { $result.data += "$_,#" }
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

# Checks all tasks in all subfolders, not just root...
Function Get-Tasks
{
    Param ([Object]$taskFolder)
    $tasks = $taskFolder.GetTasks(0)
    $tasks | ForEach-Object { $_ }
    Try {
        $taskFolders = $taskFolder.GetFolders(0)
        $taskFolders | ForEach-Object { Get-Tasks $_ $true } }
    Catch { }
}
