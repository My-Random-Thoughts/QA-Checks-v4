<#
    DESCRIPTION:
        Checks if there are any failed SQL Agent jobs.
        Note: The PowerShell module for SQL (SQLPS) is required for this check.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            There are no failed SQL Agent jobs
        WARNING:
        FAIL:
            There are one or more failed SQL Agent jobs
        MANUAL:
        NA:

    APPLIES:
        SQL Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function sql-05-failed-jobs
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sql-05-failed-jobs'

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
DECLARE @V_FAILED_JOBS            VARCHAR(200)
DECLARE @V_FAILED_JOBS_DETAIL     VARCHAR(5000)
DECLARE @V_SQL_LASTCHECK          DATETIME

IF DATENAME(dw, GETDATE()) = 'Monday'
    SELECT @V_SQL_LASTCHECK = GETDATE() - 3
ELSE
    SELECT @V_SQL_LASTCHECK = GETDATE() - 1

DECLARE FAILED_JOBS CURSOR FOR
    SELECT jb.name + ': ' + CAST(msdb.dbo.agent_datetime(jh.run_date, jh.run_time) AS VARCHAR)
    FROM msdb.dbo.sysjobs AS jb JOIN msdb.dbo.sysjobhistory AS jh 
        ON (jb.job_id = jh.job_id) 
    WHERE step_name = '(job outcome)' 
    AND run_status = '0' 
    AND run_date >= (SELECT CONVERT(CHAR(8), @V_SQL_LASTCHECK, 112))
    ORDER BY jh.run_date, jh.run_time

OPEN FAILED_JOBS
    FETCH NEXT FROM FAILED_JOBS INTO @V_FAILED_JOBS
    SET @V_ROWCOUNT = 0
    SET @V_FAILED_JOBS_DETAIL = @V_FAILED_JOBS
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @V_ROWCOUNT = @V_ROWCOUNT + 1
        FETCH NEXT FROM FAILED_JOBS INTO @V_FAILED_JOBS
        IF @@FETCH_STATUS = 0 SET @V_FAILED_JOBS_DETAIL = @V_FAILED_JOBS_DETAIL + ',#' + @V_FAILED_JOBS
    END
CLOSE FAILED_JOBS
DEALLOCATE FAILED_JOBS

IF @V_ROWCOUNT = 0
    SELECT '$($script:lang['Pass'])' AS 'result',
           '$($script:lang['p001'])' AS 'message',
           '' AS 'data'
ELSE
    SELECT '$($script:lang['Fail'])' AS 'result',
           '$($script:lang['f001'])'  AS 'message',
           @V_FAILED_JOBS_DETAIL AS 'data'

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
