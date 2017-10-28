<#
    DESCRIPTION: 
        Checks to see if there are any additional firewall rules, and warns if there are any.  This ignores all default pre-configured rules

    REQUIRED-INPUTS:
        IgnoreTheseFirewallAppRules - "LIST" - Known firewall rules to ignore

    DEFAULT-VALUES:
        IgnoreTheseFirewallAppRules = ('MSExchange', 'Microsoft', 'McAfee', 'macmnsvc', 'System Center', 'nbwin', 'Java', 'Firefox', 'Chrome')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No additional firewall rules exist
        WARNING:
            One or more additional firewall rules exist, check they are required
        FAIL:
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-14-firewall-rules
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-14-firewall-rules'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$FirewallRules = @{}
        [Microsoft.Win32.RegistryKey] $gITMp = (Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules')

        $gITMp.GetValueNames() | ForEach-Object -Process {
            [psobject]$properties = @{ Active=$null; AppPath=$null; Direction=$null; EmbedCtxt=$null; Name=$null; Profile='All'; RemotePort=$null }

            ForEach ($rule In ($($gITMp.GetValue($_)).Split('|')))
            {
                Switch ($rule.Split('=')[0])
                {
                    'Active'    { [string]$properties.Active      = ($rule -split '=')[1]        }
                    'App'       { [string]$properties.AppPath     = ($rule -split '=')[1]        }
                    'Dir'       { [string]$properties.Direction   = ($rule -split '=')[1]        }
                    'EmbedCtxt' { [string]$properties.EmbedCtxt   = ($rule -split '=')[1]        }
                    'Name'      { [string]$properties.Name        = ($rule -split '=')[1]        }
                    'Profile'   { [string]$properties.Profile     = ($rule -split '=')[1]        }
                    'RPort'     { [string]$properties.RemotePort += ($rule -split '=')[1] + ', ' }
                }
            }

            If (($properties.Name -notlike '@*') -or ($properties.EmbedCtxt -notlike '@*')) {
                [void]$FirewallRules.Add((New-Object -TypeName PSObject -Property $properties))
            }
        }

        If ($FirewallRules.Count -gt 0)
        {
            [System.Collections.ArrayList]$FirewallRulesC = $FirewallRules.Clone()
            $FirewallRules | ForEach-Object -Process {
                [psobject]$Rule = $_
                $script:chkValues['IgnoreTheseFirewallAppRules'] | ForEach-Object -Process {
                    If ($Rule.Name -like "*$_*") { $FirewallRulesC.Remove($Rule) }
                }
            }

            If ($FirewallRulesC.Count -gt 0)
            {
                $result.result  = $script:lang['Warning']
                $result.message = $script:lang['w001']
                $FirewallRulesC | Sort-Object -Property 'Name' -Unique | ForEach-Object -Process {
                    If ($_.Active -eq 'False') { $act = ' (Disabled)' } Else { $act = '' }
                    $result.data += '({0}) {1}{2},#' -f $_.Direction, $_.Name, $act }
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
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

    Return $result
}
