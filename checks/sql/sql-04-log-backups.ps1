<#
    DESCRIPTION:
        Checks that all log backups have completed successfully.
        Note: The PowerShell module for SQL (SQLPS) is required for this check.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            There are no missing log backups
        WARNING:
        FAIL:
            There are one or more missing log backups
        MANUAL:
        NA:

    APPLIES:
        SQL Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function sql-04-log-backups
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sql-04-log-backups'

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
DECLARE @V_MISSING_BCK            VARCHAR(200)
DECLARE @V_MISSING_BCK_DETAIL     VARCHAR(5000)

DECLARE MISSING_LOG_BACKUPS CURSOR FOR
    SELECT db.name + ': ' + ISNULL(CONVERT(VARCHAR, max(bs.backup_finish_date), 113), 'Never')
    FROM sys.databases db LEFT JOIN msdb.dbo.backupset bs
        ON db.name = bs.database_name and bs.type IN ('L')    -- backup type D = Database, I = Differential, L = Log
    WHERE db.name NOT IN ('tempdb')                           -- list of databases to exclude from checking
    AND db.state = 0                                          -- database state is online
    AND db.recovery_model < 3                                 -- recovery model: 1 = full, 2 = bulk_logged, 3 = simple
    GROUP BY db.name
    HAVING DATEDIFF(HH, max(bs.backup_finish_date), GETDATE()) > 6
        OR DATEDIFF(HH, max(bs.backup_finish_date), GETDATE()) IS NULL
    ORDER BY db.name

OPEN MISSING_LOG_BACKUPS
    FETCH NEXT FROM MISSING_LOG_BACKUPS INTO @V_MISSING_BCK
    SET @V_ROWCOUNT = 0
    SET @V_MISSING_BCK_DETAIL = @V_MISSING_BCK
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @V_ROWCOUNT = @V_ROWCOUNT + 1
        FETCH NEXT FROM MISSING_LOG_BACKUPS INTO @V_MISSING_BCK
        IF @@FETCH_STATUS = 0 SET @V_MISSING_BCK_DETAIL = @V_MISSING_BCK_DETAIL + ',#' + @V_MISSING_BCK
    END
CLOSE MISSING_LOG_BACKUPS
DEALLOCATE MISSING_LOG_BACKUPS

IF @V_ROWCOUNT = 0
    SELECT '$($script:lang['Pass'])' AS 'result',
           '$($script:lang['p001'])' AS 'message',
           '' AS 'data'
ELSE
    SELECT '$($script:lang['Pass'])' AS 'result',
           '$($script:lang['f001'])'  AS 'message',
           @V_MISSING_BCK_DETAIL AS 'data'

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
