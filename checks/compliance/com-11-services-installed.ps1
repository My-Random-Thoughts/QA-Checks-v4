<#
    DESCRIPTION: 
        Check that a specific list of services exist on the target server.  The language specific friendly display name should be used.

    REQUIRED-INPUTS:
        SerivcesToCheck - "LIST" - List of services to check.  Enter the display name of the service.
        AllMustExist    - "True|False" - Should all services exist for a Pass.?

    DEFAULT-VALUES:
        SerivcesToCheck = @('')
        AllMustExist    = 'True'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All services were found
            One or more services were found
        WARNING:
        FAIL:
            One or more services were not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function com-11-services-installed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'com-11-services-installed'

    #... CHECK STARTS HERE ...#

    If ([string]::IsNullOrEmpty($script:chkValues['SerivcesToCheck']) -eq $true)
    {
        $result.result  = $script:lang['Not-Applicable']
        $result.message = $script:lang['n001']
    }
    Else
    {
        Try
        {
            [System.Collections.ArrayList]$found   = @{}
            [System.Collections.ArrayList]$missing = @{}

            [int]$Count = 0
            $script:chkValues['SerivcesToCheck'] | ForEach-Object -Process {
                If ([string]::IsNullOrEmpty($_) -eq $false) {
                    $Count++
                    [string]$service = ((Get-Service -DisplayName $_ -ErrorAction SilentlyContinue).DisplayName)
                    If ([string]::IsNullOrEmpty($service) -eq $true) { [void]$missing.Add($_) } Else { [void]$found.Add($_) }
                }
            }

            If ($Count -eq 1) { $script:chkValues['AllMustExist'] = 'True' }
            If ($script:chkValues['AllMustExist'] -eq 'True')
            {
                If ($missing.Count -gt 0)
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f001']
                    $missing | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
                }
                Else
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p001']
                    $found | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
                }
            }
            Else
            {
                $result.data = ''
                If ($found.Count -gt 0)
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p001']
                    $found | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
                }
                Else
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f002']
                }
            }
        }
        Catch
        {
            $result.result  = $script:lang['Error']
            $result.message = $script:lang['Script-Error']
            $result.data    = $_.Exception.Message
        }
    }

    Return $result
}
