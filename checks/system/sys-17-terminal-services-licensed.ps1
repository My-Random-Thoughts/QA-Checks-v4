<#
    DESCRIPTION: 
        If server is a Terminal Services Server ensure it has a licence server set.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Terminal services server is licensed
        WARNING:
        FAIL:
            Terminal services server is not licensed
        MANUAL:
        NA:
            Not a terminal services server

    APPLIES:
        Terminal Servers

    REQUIRED-FUNCTIONS:
        Check-IsTerminalServer
#>

Function sys-17-terminal-services-licensed
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-17-terminal-services-licensed'

    #... CHECK STARTS HERE ...#

    Try
    {
        If ((Check-IsTerminalServer) -eq $true)
        {
            [System.Collections.ArrayList]$gITMp = @(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\TermService\Parameters\LicenseServers' -Name 'SpecifiedLicenseServers' -ErrorAction SilentlyContinue)
            If ([string]::IsNullOrEmpty($gITMp) -eq $true)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
                $gITMp.SpecifiedLicenseServers | ForEach-Object -Process { $result.data += "$_,#" }
            }
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
        Return $result
    }

    Return $result
}
