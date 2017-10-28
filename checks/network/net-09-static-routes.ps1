<#
    DESCRIPTION:
        Checks to make sure the specified static routes have been added.  Add routes to check as: StaticRoute01 = ("source", "mask", "gateway").  To check for no extra persistent routes, use: StaticRoute01 = ("None", "", "").
        Up to 99 routes can be checked - You must edit the settings file manually for more than the currently configured.

    REQUIRED-INPUTS:
        AllMustExist  - "True|False" - Should all static route entries exist for a Pass.?
        DestinationMustNotExist - Destination IP that must not exist in the route table|IPv4
        StaticRoute01 - "LIST" - IP details for a single static route to check.  Order is: Source, Mask, Gateway|IPv4
        StaticRoute02 - "LIST" - IP details for a single static route to check.  Order is: Source, Mask, Gateway|IPv4
        StaticRoute03 - "LIST" - IP details for a single static route to check.  Order is: Source, Mask, Gateway|IPv4
        StaticRoute04 - "LIST" - IP details for a single static route to check.  Order is: Source, Mask, Gateway|IPv4
        StaticRoute05 - "LIST" - IP details for a single static route to check.  Order is: Source, Mask, Gateway|IPv4

    DEFAULT-VALUES:
        AllMustExist  = 'False'
        DestinationMustNotExist = ''
        StaticRoute01 = @('', '', '')
        StaticRoute02 = @('', '', '')
        StaticRoute03 = @('', '', '')
        StaticRoute04 = @('', '', '')
        StaticRoute05 = @('', '', '')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Required static routes are present
        WARNING:
        FAIL:
            No static routes present
            One or more static routes are missing or incorrect
            All entered static routes are missing
            A static route exists that must not
        MANUAL:
        NA:
            No static routes to check

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-09-static-routes
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-09-static-routes'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_IP4PersistedRouteTable' -Property ('Destination', 'Mask', 'NextHop'))
        Try { [boolean]$RoutesToCheck = (-not [string]::IsNullOrEmpty($script:chkValues['StaticRoute01'][0])) } Catch { [boolean]$RoutesToCheck = $false }

        If ([string]::IsNullOrEmpty($gCIMi) -eq $true)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }
        ElseIf ([string]::IsNullOrEmpty($script:chkValues['DestinationMustNotExist']) -eq $false)
        {
            $gCIMi | Sort-Object | ForEach-Object -Process {
                If ($_.Destination -eq $script:chkValues['DestinationMustNotExist'])
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f004']
                    $result.data    = $script:chkValues['DestinationMustNotExist']
                }
            }
        }
        ElseIf ($RoutesToCheck -eq $false)
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
        }
        Else
        {
            [int]   $entryCount    = 0
            [int]   $ignoreCount   = 0
            [string]$ignoreEntries = ''

            1..99 | ForEach-Object -Process {
                [string[]]$Entry = @($script:chkValues["StaticRoute$(($_ -as [string]).PadLeft(2, '0'))"])
                If ([string]::IsNullOrEmpty($Entry) -eq $false)
                {
                    $entryCount++
                    [boolean]$found = $false
                    $gCIMi | Sort-Object | ForEach-Object -Process {
                        If ($_.Destination -eq $Entry[0])
                        {
                            $found = $true
                            If ($_.Mask    -ne $Entry[1]) { $result.data += ($($script:lang['dt01']) -f $($Entry[0])) }
                            If ($_.NextHop -ne $Entry[2]) { $result.data += ($($script:lang['dt02']) -f $($Entry[0])) }
                        }
                    }

                    If ($found -eq $false)
                    {
                        If ($script:chkValues['AllMustExist'] -eq 'True') { $result.data += ($($script:lang['dt03']) -f $($Entry[0])) }
                        Else {                              $ignoreCount++; $ignoreEntries += ($($script:lang['dt03']) -f $($Entry[0])) }
                    }
                }
                $routeEntry = $null
            }

            If ($ignoreCount -eq $entryCount)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f002']
                $result.data    = $ignoreEntries
            }
            ElseIf ($result.data -eq '')
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                If ([string]::IsNullOrEmpty($result.message) -eq $true) {
                    $result.message = $script:lang['f003']
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
