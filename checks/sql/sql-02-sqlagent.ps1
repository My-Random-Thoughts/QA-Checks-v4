<#
    DESCRIPTION:
        Checks that the SQL Server Agent service is up and running.
        Note: The PowerShell module for SQL (SQLPS) is required for this check.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            SQL Server Agent service is running
        WARNING:
        FAIL:
            SQL Server Agent service is stopped
        MANUAL:
        NA:

    APPLIES:
        SQL Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function sql-02-sqlagent
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sql-02-sqlagent'

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

SET @V_ROWCOUNT = (SELECT COUNT(*) FROM sysprocesses WHERE LEFT(PROGRAM_NAME, 8) = 'SQLAgent')

IF @V_ROWCOUNT <> 0
    SELECT '$($script:lang['Pass'])' AS 'result',
           '$($script:lang['p001'])' AS 'message',
           '' AS 'data'
ELSE
    SELECT '$($script:lang['Fail'])' AS 'result',
           '$($script:lang['f001'])' AS 'message',
           '$($script:lang['dt01'])' AS 'data'

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
