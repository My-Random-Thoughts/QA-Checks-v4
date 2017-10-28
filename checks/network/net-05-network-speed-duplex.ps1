<#
    DESCRIPTION: 
        Check the network adapter speed and duplex settings.  Should be set to "Full Duplex" and "Auto".

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All network adapters configured correctly
        WARNING:
            One or more network adapters configured incorrectly
        FAIL:
            No network adapters found or enabled
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-05-network-speed-duplex
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-05-network-speed-duplex'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled='TRUE'")
        If ($gCIMi.Count -gt 0)
        {
            $gCIMi | Sort-Object | ForEach-Object -Process {
                [string]$suffix = $($_.Index).ToString().PadLeft(4, '0')
                Try {
                    # PhysicalMediaType does not exist on all Adapters
                    [int]$type = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\$suffix\" -Name '*PhysicalMediaType' -ErrorAction Stop).'*PhysicalMediaType'
                } Catch { [int]$type = -1 }

                If ($type -eq '14')    # Ethernet
                {
                    # Get Name and SPEED
                    [object]$gCIMi2 = (Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter "Index='$($_.Index)'" -Property ('NetConnectionID', 'Speed'))
                    [int]   $Speed  = ([math]::Round($gCIMi2.Speed / 1000000))    # Don't use "1GB" for division

                    # Get DUPLEX setting if possible (Virtual team adapters don't have this setting)
                    Try {
                        [object]$gItmP  = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\$suffix"                              -Name '*SpeedDuplex')
                        [string]$Duplex = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\$suffix\Ndi\Params\*SpeedDuplex\enum" -Name $gItmP.'*SpeedDuplex').$($gItmP.'*SpeedDuplex')
                    } Catch { [string]$Duplex = $null }
                    If ([string]::IsNullOrEmpty($Duplex) -eq $true) { $Duplex = $script:lang['dt01'] }

                    If (($Speed -lt 1000) -or ($Duplex -notlike $script:lang['ck01']))
                    {
                        $result.result   = $script:lang['Warning']
                        $result.message  = $script:lang['w001']
                        $result.data    += "$($gCIMi2.NetConnectionID): $Speed Mbps ($Duplex),#"
                    }
                }
            }

            If ([string]::IsNullOrEmpty($result.data) -eq $true)
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
        }
        Else
        {
           $result.result  = $script:lang['Fail']
           $result.message = $script:lang['f001']
           $result.data    = ''
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
