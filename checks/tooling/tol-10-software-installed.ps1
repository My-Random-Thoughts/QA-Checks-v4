<#
    DESCRIPTION: 
        Check to see if a list of software title are installed.

    REQUIRED-INPUTS:
        ProductName - "LIST" - List of product names to check for.  Name should be the string found in install programs list (Add/Remove Programs / Programs And Features).
        AllMustExist - "True|False" - Should all entries exist for a Pass.?

    DEFAULT-VALUES:
        ProductName = @('')
        AllMustExist = 'True'

    DEFAULT-STATE:
        Skip

    RESULTS:
        PASS:
            All product titles were found
            One or more product titles were found
        WARNING:
        FAIL:
            One or more product titles were not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-Software
#>

Function tol-10-software-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'tol-10-software-installed'

    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$missing = ''
        $script:chkValues['ProductName'] | ForEach-Object -Process {
            If ([string]::IsNullOrEmpty($_) -eq $false)
            {
                $script:chkValues['Win32_Product'] = 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'    # Reset search path
                [object]$verCheck = (Check-Software -DisplayName $_)
                If ($verCheck -eq '-1') { Throw $($script:lang['trw1']) }

                If ([string]::IsNullOrEmpty($verCheck) -eq $true) { $missing += "$_,#" } Else { $found += ('{0} (v{1}),#' -f $_, $verCheck.Version ) }
            }
        }

        If (($missing.Length -gt 0) -and ($script:chkValues['AllMustExist'] -eq 'True'))
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
            $result.data    = $missing
        }
        ElseIf (($missing.Length -gt 0) -and ($script:chkValues['AllMustExist'] -eq 'False'))
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
            $result.data    = $found
        }
        Else
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p002']
            $result.data    = ''
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
