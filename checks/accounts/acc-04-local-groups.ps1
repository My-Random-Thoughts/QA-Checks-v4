<#
    DESCRIPTION: 
        Check all local groups and ensure no additional groups exist. If there is a specific application requirement for local groups then these need to be documented with a designated team specified as the owner.
        If you use specific role groups, make sure they are excluded in the settings file.

    REQUIRED-INPUTS:
        IgnoreTheseUsers - "LIST" - Known user or group accounts to ignore

    DEFAULT-VALUES:
        IgnoreTheseUsers = @('Allowed RODC Password Replication Group', 'Cert Publishers', 'ConfigMgr Remote Control Users', 'Denied RODC Password Replication Group', 'DHCP', 'DnsAdmins', 'HelpServicesGroup', 'IIS_WPG', 'Offer Remote Assistance Helpers', 'Pre-Windows 2000 Compatible Access', 'RAS and IAS Servers', 'TelnetClients', 'WinRMRemoteWMIUsers__', 'SQLServer', 'RSABypass')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No additional local accounts
        WARNING:
        FAIL:
            One or more local groups exist
        MANUAL:
        NA:
            Server is a domain controller

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-IsDomainController
#>

Function acc-04-local-groups
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'acc-04-local-groups'

    #... CHECK STARTS HERE ...#

    If ((Check-IsDomainController) -eq $false)
    {
        Try
        {
            [System.Text.StringBuilder]   $filter = "LocalAccount='True' AND NOT SID LIKE 'S-1-5-32-%'"
            $script:chkValues['IgnoreTheseUsers'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT Name LIKE '%$_%'") }
            [System.Collections.ArrayList]$gCIMi  = @((Get-CimInstance -ClassName 'Win32_Group' -Filter $filter.ToString() -Property 'Name' -ErrorAction SilentlyContinue).Name)
            $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

            If ($gCIMi.Count -gt 0)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
                $gCIMi | Sort-Object | ForEach-Object -Process { $result.data += "$_,#" }
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
        }
        Catch
        {
            $result.result  = $script:lang['Error']
            $result.message = $script:lang['Script-Error']
            $result.data    = $_.Exception.Message
        }
    }
    Else
    {
        $result.result  = $script:lang['Not-Applicable']
        $result.message = $script:lang['n001']
    }

    Return $result
}
