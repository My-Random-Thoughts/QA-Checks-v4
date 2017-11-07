<#
    DESCRIPTION:
        Checks that the SQL version is up-to-date and supported.
        Note: The PowerShell module for SQL (SQLPS) is required for this check.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            SQL Server version and patch level are supported
        WARNING:
            SQL Server version is supported, patch level is out of date
        FAIL:
            SQL Server version and patch level is out of support
        MANUAL:
        NA:

    APPLIES:
        SQL Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function sql-01-sql-version
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sql-01-sql-version'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$verCheck = (Check-Software -DisplayName 'Microsoft SQL Server')
        If ($verCheck -eq '-1') { Throw $script:lang['trw1'] }

        If ([string]::IsNullOrEmpty($verCheck) -eq $false)
        {
            [string]$sqlScript = @"

SET NOCOUNT ON
DECLARE @V_MIN_2008_PATCHLVL      VARCHAR(5)
DECLARE @V_MIN_2012_PATCHLVL      VARCHAR(5)
DECLARE @V_MIN_2014_PATCHLVL      VARCHAR(5)
DECLARE @V_MIN_2016_PATCHLVL      VARCHAR(5)
DECLARE @V_MIN_2017_PATCHLVL      VARCHAR(5)
DECLARE @V_SQL_VER                VARCHAR(20)
DECLARE @V_MAJOR_VER              VARCHAR(5)
DECLARE @V_BUILD_VER              VARCHAR(5)
DECLARE @V_ISSUPPORTED_VERSION    VARCHAR(1)
DECLARE @V_ISSUPPORTED_PATCHLVL   VARCHAR(1)
DECLARE @V_POS1                   INT
DECLARE @V_POS2                   INT
DECLARE @V_POS3                   INT

-- Version Check Constants, these will need to be maintained as products are updated.
-- Taken from https://support.microsoft.com/help/321185
SET @V_MIN_2017_PATCHLVL = '1000'    -- SP0   for 2017
SET @V_MIN_2016_PATCHLVL = '4001'    -- SP1   for 2016
SET @V_MIN_2014_PATCHLVL = '5000'    -- SP2   for 2014
SET @V_MIN_2012_PATCHLVL = '7001'    -- SP4   for 2012
SET @V_MIN_2008_PATCHLVL = '6000'    -- SP3/4 for 2008 R1/R2

SET @V_SQL_VER = CAST(SERVERPROPERTY('productversion') AS VARCHAR)
SET @V_POS1    = CHARINDEX('.', @V_SQL_VER)
SET @V_POS2    = CHARINDEX('.', @V_SQL_VER, @V_POS1 + 1)
SET @V_POS3    = CHARINDEX('.', @V_SQL_VER, @V_POS2 + 1)

               SET @V_MAJOR_VER = SUBSTRING(@V_SQL_VER, 1, @V_POS1 - 1)
IF @V_POS3 = 0 SET @V_BUILD_VER = SUBSTRING(@V_SQL_VER, @V_POS2 + 1, 30)
ELSE           SET @V_BUILD_VER = SUBSTRING(@V_SQL_VER, @V_POS2 + 1, @V_POS3 - @V_POS2 - 1)

IF CAST(@V_MAJOR_VER AS INT) >= 10 SET @V_ISSUPPORTED_VERSION = 'Y' ELSE SET @V_ISSUPPORTED_VERSION = 'N'

     IF @V_MAJOR_VER = '10' AND @V_BUILD_VER >= @V_MIN_2008_PATCHLVL SET @V_ISSUPPORTED_PATCHLVL = 'Y'
ELSE IF @V_MAJOR_VER = '11' AND @V_BUILD_VER >= @V_MIN_2012_PATCHLVL SET @V_ISSUPPORTED_PATCHLVL = 'Y'
ELSE IF @V_MAJOR_VER = '12' AND @V_BUILD_VER >= @V_MIN_2014_PATCHLVL SET @V_ISSUPPORTED_PATCHLVL = 'Y'
ELSE IF @V_MAJOR_VER = '13' AND @V_BUILD_VER >= @V_MIN_2016_PATCHLVL SET @V_ISSUPPORTED_PATCHLVL = 'Y'
ELSE IF @V_MAJOR_VER = '14' AND @V_BUILD_VER >= @V_MIN_2017_PATCHLVL SET @V_ISSUPPORTED_PATCHLVL = 'Y'
ELSE                                                                 SET @V_ISSUPPORTED_PATCHLVL = 'N'

IF @V_ISSUPPORTED_VERSION = 'N'
    SELECT '$($script:lang['Fail'])' AS 'result',
           '$($script:lang['f001'])' AS 'message',
           @V_SQL_VER AS 'data'
ELSE IF @V_ISSUPPORTED_VERSION = 'Y' AND @V_ISSUPPORTED_PATCHLVL = 'N'
    SELECT '$($script:lang['Warning'])' AS 'result',
           '$($script:lang['w001'])' AS 'message',
           @V_SQL_VER AS 'data'
ELSE
    SELECT '$($script:lang['Pass'])' AS 'result',
           '$($script:lang['p001'])' AS 'message',
           @V_SQL_VER AS 'data'

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
