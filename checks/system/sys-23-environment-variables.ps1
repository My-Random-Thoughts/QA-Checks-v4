<#
    DESCRIPTION: 
        Allows you to checks a specific list of system environment variables and values to see if they are set correctly.
        Up to nine system environment variables and values can be checked - You must edit the settings file manually for more than the currently configured.
        Note: All keys must be machine variables only.

    REQUIRED-INPUTS:
        Variable01 - Name of the system environment variable to check for
        Variable02 - Name of the system environment variable to check for
        Variable03 - Name of the system environment variable to check for
        Value01    - String value required for the variable entry.  Enter "ReportOnly" to just report the value
        Value02    - String value required for the variable entry.  Enter "ReportOnly" to just report the value
        Value03    - String value required for the variable entry.  Enter "ReportOnly" to just report the value

    DEFAULT-VALUES:
        Variable01 = ''
        Variable02 = ''
        Variable03 = ''
        Value01    = 'ReportOnly'
        Value02    = ''
        Value03    = ''

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All environment variables checks were found and correct
        WARNING:
        FAIL:
            One or more environment variables checks were below specified value
        MANUAL:
            One or more environment variables checks were "Report Only"
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-23-environment-variables
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-23-environment-variables'

    #... CHECK STARTS HERE ...#

    Try
    {
        [hashtable]$envVars = ([System.Environment]::GetEnvironmentVariables('Machine'))
        If ($envVars.Count -eq 0) { Throw 'No system environment variables found' }

        1..9 |  ForEach-Object -Process {
            [string]$Num = ($_.ToString().PadLeft(2, '0'))
            If ($script:chkValues["Variable$Num"].Length -gt 0)
            {
                [string]$chkValue = ($envVars["$($script:chkValues["Variable$Num"])"])
                [string]$dspValue = $chkValue.Replace(' ,',',').Replace('; ',';')    # Remove any existing spaces between delimiters,
                        $dspValue = $dspValue.Replace(',',', ').Replace(';','; ')    # Add the spaces back in.  This stops duplicate spaces.

                # Build output data
                $result.data += ("$($Num): ({0}) {1}: {2},#" -f '-ReplaceMe-', $($script:chkValues["Variable$Num"]), $dspValue)

                If ($script:chkValues["Value$Num"] -eq 'ReportOnly') {
                    $result.data = ($result.data.Replace('-ReplaceMe-', $script:lang['dt01']))
                } Else {
                    If ($chkValue  -eq ($script:chkValues["Value$Num"] -as [string])) {
                        $result.data = ($result.data.Replace('-ReplaceMe-', $script:lang['Pass'])) } Else {
                        $result.data = ($result.data.Replace('-ReplaceMe-', $script:lang['Fail']))
                    }
                }
            }
        }

        If ([string]::IsNullOrEmpty($result.data) -eq $true)
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
        }
        Else
        {
            If ($result.data.Contains(": ($($script:lang['Pass']))")) { $result.result = $script:lang['Pass']  ; $result.message = $script:lang['p001'] }
            If ($result.data.Contains(": ($($script:lang['dt01']))")) { $result.result = $script:lang['Manual']; $result.message = $script:lang['m001'] }
            If ($result.data.Contains(": ($($script:lang['Fail']))")) { $result.result = $script:lang['Fail']  ; $result.message = $script:lang['f001'] }
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
