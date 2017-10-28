<#
    DESCRIPTION: 
        Check network interfaces have their power management switch disabled.
        
    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All adapters have power saving disabled
        WARNING:
        FAIL:
            One or more adapters have power saving enabled
            No enabled network adapters found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-10-power-management
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-10-power-management'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter "NetConnectionStatus='2'" -Property ('Index', 'NetConnectionID'))
        If ($gCIMi.Count -gt 0)
        {
            $gCIMi | Sort-Object -Property 'NetConnectionID' | ForEach-Object -Process {
                [string]$suffix = $($_.Index).ToString().PadLeft(4, '0')
                Try {
                    # PnPCapabilities does not exist on all Adapters
                    [object]$pnpCap = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\$suffix" -Name 'PnPCapabilities' -ErrorAction Stop)
                } Catch { [int]$pnpCap = -1 }

                # https://support.microsoft.com/en-gb/help/2740020/information-about-power-management-setting-on-a-network-adapter
                If (($pnpCap.PnPCapabilities -ne 24) -and ($pnpCap.PnPCapabilities -ne 280))
                {
                    $result.result   = $script:lang['Fail']
                    $result.message  = $script:lang['f001']
                    $result.data    += "$($_.NetConnectionID),#"
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
            $result.result   = $script:lang['Fail']
            $result.message  = $script:lang['f002']
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
