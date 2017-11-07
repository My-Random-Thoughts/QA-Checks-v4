<#
    DESCRIPTION:
        Checks that all databases are online.
        Note: The PowerShell module for SQL (SQLPS) is required for this check.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            All databases are online
        WARNING:
        FAIL:
            One or more databases are offline
        MANUAL:
        NA:

    APPLIES:
        SQL Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function sql-07-db-status
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sql-07-db-status'

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
DECLARE @V_DB_STATUS              VARCHAR(200)
DECLARE @V_DB_STATUS_DETAIL       VARCHAR(1000)

DECLARE DB_STATUS CURSOR FOR
    SELECT DB_NAME(database_id)
    FROM sys.databases
    WHERE state_desc <> 'ONLINE'

OPEN DB_STATUS
    FETCH NEXT FROM DB_STATUS INTO @V_DB_STATUS
    SET @V_ROWCOUNT = 0
    SET @V_DB_STATUS_DETAIL = @V_DB_STATUS
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @V_ROWCOUNT = @V_ROWCOUNT + 1
        FETCH NEXT FROM DB_STATUS INTO @V_DB_STATUS
        IF @@FETCH_STATUS = 0 SET @V_DB_STATUS_DETAIL = @V_DB_STATUS_DETAIL + ',#' + @V_DB_STATUS
    END
CLOSE DB_STATUS
DEALLOCATE DB_STATUS

IF @V_ROWCOUNT = 0
    SELECT '$($script:lang['Pass'])' AS 'result',
           '$($script:lang['p001'])' AS 'message',
           '' AS 'data'
ELSE
    SELECT '$($script:lang['Fail'])' AS 'result',
           '$($script:lang['f001'])' AS 'message',
           @V_DB_STATUS_DETAIL AS 'data'

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
