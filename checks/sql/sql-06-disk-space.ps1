<#
    DESCRIPTION:
        Checks that there enough disk space.
        Note: The PowerShell module for SQL (SQLPS) is required for this check.

    REQUIRED-INPUTS:
        MinimumFreeSpace - Minimum amount of free space in megabytes that each drive should have|Integer

    DEFAULT-VALUES:
        MinimumFreeSpace = '2048'

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            All server disks have more than {0}mb free disk space
        WARNING:
        FAIL:
           There are server disks with less than {0}mb free disk space
        MANUAL:
        NA:

    APPLIES:
        SQL Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function sql-06-disk-space
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sql-06-disk-space'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$verCheck = (Check-Software -DisplayName 'Microsoft SQL Server')
        If ($verCheck -eq '-1') { Throw $script:lang['trw1'] }

        If ([string]::IsNullOrEmpty($verCheck) -eq $false)
        {
            [string]$sqlScript = @"

SET NOCOUNT ON
DECLARE @V_ROWCOUNT               INT
DECLARE @V_FREE_DISKSPACE         VARCHAR(200)
DECLARE @V_FREE_DISKSPACE_DETAIL  VARCHAR(1000)

DECLARE FREE_DISKSPACE CURSOR FOR
    SELECT DISTINCT 'Disk ' + dovs.volume_mount_point + ': ' + CAST(CONVERT(INT, dovs.available_bytes / 1048576.0) AS varchar) + 'MB free'
    FROM sys.master_files mf
    CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
    WHERE CONVERT(INT, dovs.available_bytes / 1048576.0) < $($script:chkValues['MinimumFreeSpace'])

OPEN FREE_DISKSPACE
    FETCH NEXT FROM FREE_DISKSPACE INTO @V_FREE_DISKSPACE
    SET @V_ROWCOUNT = 0
    SET @V_FREE_DISKSPACE_DETAIL = @V_FREE_DISKSPACE

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @V_ROWCOUNT = @V_ROWCOUNT + 1
        FETCH NEXT FROM FREE_DISKSPACE INTO @V_FREE_DISKSPACE
        IF @@FETCH_STATUS = 0 SET @V_FREE_DISKSPACE_DETAIL = @V_FREE_DISKSPACE_DETAIL + ',#' + @V_FREE_DISKSPACE
    END
CLOSE FREE_DISKSPACE
DEALLOCATE FREE_DISKSPACE

IF @V_ROWCOUNT = 0
    SELECT   '$($script:lang['Pass'])' AS 'result',
           '$($($script:lang['p001']) -f $($script:chkValues['MinimumFreeSpace']))' AS 'message',
           @V_FREE_DISKSPACE_DETAIL AS 'data'
ELSE
    SELECT   '$($script:lang['Fail'])' AS 'result',
           '$($($script:lang['f001']) -f $($script:chkValues['MinimumFreeSpace']))' AS 'message',
           @V_FREE_DISKSPACE_DETAIL AS 'data'

"@
            $sqlCmd = (Invoke-Sqlcmd -ServerInstance $env:ComputerName -Query $sqlScript)
            $result.result  = $sqlCmd.result
            $result.message = $sqlCmd.message
            $result.data    = $sqlCmd.data
        }
        Else
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
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
