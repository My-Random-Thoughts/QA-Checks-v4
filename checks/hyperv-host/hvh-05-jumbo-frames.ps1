<#
    DESCRIPTION: 
        Check the network adapter jumbo frame setting.  Should be set to 9000 or more.

    REQUIRED-INPUTS:
        IgnoreTheseAdapters - "LIST" - List of adapters to ignore this setting for

    DEFAULT-VALUES:
        IgnoreTheseAdapters = @('')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All network adapters configured correctly
        WARNING:
        FAIL:
            One or more network adapters are not using Jumbo Frames
            No network adapters found or enabled
        MANUAL:
        NA:
            Not a Hyper-V server

    APPLIES:
        Hyper-V Host Servers

    REQUIRED-FUNCTIONS:
        Check-NameSpace
#>

Function hvh-05-jumbo-frames
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'hvh-05-jumbo-frames'

    #... CHECK STARTS HERE ...#

    If ((Check-NameSpace -NameSpace 'ROOT\Virtualization\v2') -eq $true)
    {
        Try
        {
            [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled='True'" -ErrorAction SilentlyContinue)
            If ($gCIMi.Count -gt 0)
            {
                $gCIMi | Sort-Object | ForEach-Object -Process {
                    [string]$suffix = $($_.Index).ToString().PadLeft(4, '0')

                    Try {
                        # JumboPacket does not exist on Teaming Adapters
                        [int]$jumbo = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\$suffix\" -Name '*JumboPacket' -ErrorAction Stop).'*JumboPacket'
                    } Catch { [int]$jumbo = -1 }

                    If (($jumbo -gt 1) -and ($jumbo -lt 9000))    # Jumbo frames > 9000
                    {
                        [boolean]$ignore = $false
                        [string]$nConId = (Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter "Index='$($_.Index)'" -Property 'NetConnectionID').NetConnectionID
                        $script:chkValues['IgnoreTheseAdapters'] | ForEach-Object -Process {
                            If (([string]::IsNullOrEmpty($_) -eq $false) -and ($nConId -like "*$_*")) { $ignore = $true }
                        }

                        If ($ignore -eq $false)
                        {
                            $result.result   = $script:lang['Fail']
                            $result.message  = $script:lang['f001']
                            $result.data    += "$($nConId): $jumbo,#"
                        }
                    }
                }

                If ([string]::IsNullOrEmpty($result.data) -eq $true)    # If .data is not set yet, then not failed
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p001']
                }
            }
            Else
            {
               $result.result  = $script:lang['Fail']
               $result.message = $script:lang['f002']
               $result.data    = ''
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
