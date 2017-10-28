<#
    DESCRIPTION: 
        Check network interfaces for known teaming names, manually check they are configured correctly.  Fail if no teams found or if server is a virtual.  Checked configuration is:
        Teaming Mode: "Static Independent";  Load Balancing Mode: "Address Hash";  Standby Adapter: (set).

    REQUIRED-INPUTS:
        NetworkTeamNames - "LIST" - Network teaming adapters names

    DEFAULT-VALUES:
        NetworkTeamNames = @('HP Network Teaming', 'BASP Virtual Adapter', 'Microsoft Network Adapter Multiplexor Driver')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Network team count: {number}
            Team configuration is set correctly
        WARNING:
        FAIL:
            No teamed network adapters found
            Teamed network adapters found on a virtual machine
            Team configuration is not set correctly
            Teaming Count Issue
        MANUAL:
            Teamed network adapters found, check they are configured correctly
        NA:
            Not a physical server
            Not a supported operating system for this check

    APPLIES:
        Physical Servers

    REQUIRED-FUNCTIONS:
        Check-IsVMwareGuest
        Check-IsHyperVGuest
#>

Function net-07-network-teaming
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-07-network-teaming'

    #... CHECK STARTS HERE ...#

    If ((Check-IsVMwareGuest -eq $true) -or (Check-IsHyperVGuest -eq $true)) { [boolean]$isVirtual = $true } Else { [boolean]$isVirtual = $false }

    Try
    {
        [string]$checkOS = ((Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption').Caption)
        If ($checkOS -like '*2008*')
        {
            # Windows 2008 does not support native teaming, check for known team adpaters
            [System.Text.StringBuilder]   $filter = "ProductName='Null'"
            $script:chkValues['NetworkTeamNames'] | ForEach-Object -Process { [void]$filter.Append(" OR ProductName='$_'") }
            [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter $filter -Property ('ProductName', 'NetConnectionID'))
        }
        ElseIf ($checkOS -like '*201*')    # 2012, 2016
        {
            # All 2012+ servers should be using native teaming, only check for this
            [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'MSFT_NetLbfoTeam' -Namespace 'ROOT\StandardCimv2' -Property ('Name', 'LoadBalancingAlgorithm', 'TeamingMode') | Sort-Object -Property 'Name') 
        }
        Else
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
            $Result.data    = $checkOS
            Return $result
        }

        If ($gCIMi.Count -eq 0)
        {
            # No teams found
            If ($isVirtual -eq $true)
            {
                $result.result  = $script:lang['Not-Applicable']
                $result.message = $script:lang['n002']
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
                $result.data    = $script:lang['dt01']
            }
        }
        Else
        {
            # One or more teams found
            If ($isVirtual -eq $true)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f002']
                $result.data    = $script:lang['dt02']
            }
            Else
            {
                If ($checkOS -like '*2008*')       # 2008
                {
                    $result.result  = $script:lang['Manual']
                    $result.message = $script:lang['m001']
                    $gCIMi | ForEach-Object -Process { $result.data += "$($_.NetConnectionID),#" }
                }
                ElseIf ($checkOS -like '*201*')    # 2012, 2016
                {
                    [System.Collections.ArrayList]$teams = @()
                    $gCIMi | Sort-Object | ForEach-Object -Process {
                        [string]  $team    = ($_)
                        [PSObject]$newTeam = New-Object -TypeName PSObject -Property @{'name'=$($team.Name); 'lba'=$($team.LoadBalancingAlgorithm); 'tm'=$($team.TeamingMode); 'adp'=@(); 'sdby'='' }

                        [System.Collections.ArrayList]$gCIMi2 = @(Get-CimInstance -ClassName 'MSFT_NetLbfoTeamMember' -Namespace 'ROOT\StandardCimv2' -Property ('Name', 'Team', 'AdministrativeMode', 'FailureReason', 'OperationalMode'))
                        [System.Collections.ArrayList]$gCIMi3 = @(Get-CimInstance -ClassName 'MSFT_NetLbfoTeamNic'    -Namespace 'ROOT\StandardCimv2' -Property ('Team', 'VlanID'))

                        $gCIMi2 | Sort-Object -Property 'Team' | ForEach-Object -Process {
                            If ($_.Team -eq $team.Name)
                            {
                                $newTeam.adp += ($_.Name)
                                If (($_.AdministrativeMode -eq '1') -and
                                    ($_.FailureReason      -eq '1') -and
                                    ($_.OperationalMode    -eq '1')) { $newTeam.sdby = $_.Name }
                            }
                        }
                        [void]$teams.Add($newTeam)
                    }

                    If ($teams.Count -ne $gCIMi.Count)
                    {
                        [boolean]$pass  =    $true
                        $result.message = ($($script:lang['dt03']) -f $teams.Count)

                        $teams | Sort-Object | ForEach-Object -Process {
                            [string]$vlan = $gCIMi3[$gCIMi3.Team.IndexOf($_.name)].VlanID
                            If ($vlan -eq '') { $vlan = '' } Else { $vlan = "(VLAN $vlan)" }
                            $result.data += "$($_.name) $($vlan): NICs: $($_.adp.Count), "

                            # Check Teaming Mode
                            Switch ($_.tm)
                            {
                                '0' { $result.data += $script:lang['dt04']; $pass = $false }
                                '1' { $result.data += $script:lang['dt05']                 }
                                '2' { $result.data += $script:lang['dt06']; $pass = $false }
                            }

                            # Check Load Balancing Algorithm
                            Switch ($_.lba)
                            {
                                '0' { $result.data += $script:lang['dt07']                 }
                                '4' { $result.data += $script:lang['dt08']; $pass = $false }
                                '5' { $result.data += $script:lang['dt09']; $pass = $false }
                            }

                            # Only 2 adapters per team
                            If ($_.adp.Count -ne 2) { $pass = $false }

                            # Check for standby adapter
                            If ($_.sdby -eq '') {    $result.data += $script:lang['dt10']; $pass = $false }
                            Else                { ($($result.data += $script:lang['dt11']) -f $_.sdby)    }
                        }

                        If ($pass -eq $true)
                        {
                            $result.result   = $script:lang['Pass']
                            $result.message += $script:lang['p001']
                        }
                        Else
                        {
                            $result.result   = $script:lang['Fail']
                            $result.message += $script:lang['f003']
                        }
                    }
                    Else
                    {
                        $result.result   = $script:lang['Fail']
                        $result.message += $script:lang['f004']
                    }
                }
            }
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
