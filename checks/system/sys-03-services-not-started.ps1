<#
    DESCRIPTION: 
        Check services and ensure all services set to start automatically are running (NetBackup Bare Metal Restore Boot Server, NetBackup SAN Client Fibre Transport Service and .NET4.0 are all expected to be Automatic but not running).

    REQUIRED-INPUTS:
        IgnoreTheseServices - "LIST" - Known services that can ignored when set to automatic and not started

    DEFAULT-VALUES:
        IgnoreTheseServices = @('NetBackup Bare Metal Restore Boot Server', 'NetBackup SAN Client Fibre Transport Service', 'Microsoft .NET Framework NGEN', 'Software Protection', 'Volume Shadow Copy', 'Remote Registry')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All auto-start services are running
        WARNING:
        FAIL:
            One or more auto-start services were found not running
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-03-services-not-started
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-03-services-not-started'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Text.StringBuilder]   $filter = "StartMode='Auto' AND Started='False'"
        $script:chkValues['IgnoreTheseServices'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT Name LIKE '$_%'") }
        [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_Service' -Filter $filter -Property ('Name', 'DisplayName') -ErrorAction SilentlyContinue)

        If ($gCIMi.Count -gt 0)
        {
            $gCIMi | Sort-Object -Property 'DisplayName' | ForEach-Object -Process {
                Try {
                    [Microsoft.Win32.RegistryKey]$TriggerInfo = (Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($_.Name)\TriggerInfo\0" -ErrorAction Stop)
                } Catch { }

                If (-not $TriggerInfo)
                {
                    $result.result   = $script:lang['Fail']
                    $result.message  = $script:lang['f001']
                    $result.data    += "$($_.DisplayName),#"
                }
            }
        }

        If ($result.message -eq '')
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
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
