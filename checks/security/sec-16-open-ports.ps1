<#
    DESCRIPTION: 
        Returns a list of ports that are open, excluding anything lower than 1024 and within the dynamic port range.  Will also exclude other well known ports.
        See "default-settings.ini" file for descriptions of default ignore ports.

    REQUIRED-INPUTS:
        IgnoreThesePorts - "LIST" - Port numbers to ignore|Integer

    DEFAULT-VALUES:
        IgnoreThesePorts = @('1311', '1556', '2381', '3389', '4750', '5985', '5986', '47001')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No extra ports are open
        WARNING:
        FAIL:
            One or more extra ports are open
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-16-open-ports
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-16-open-ports'

    #... CHECK STARTS HERE ...#

    Try
    {
        [int]     $rangeS   = 49152    # Start # \
        [int]     $rangeC   = 16384    # Count #  Default dynamic port range
        [int]     $rangeE   = 65536    # End   # /
        [string[]]$dynPorts = $null
        [System.Collections.ArrayList]$PortList = @()

        # Get dynamic port range, we'll be ignoring anything in this range later
        Try { [string[]]$dynPorts = Invoke-Command -ScriptBlock { &"netsh.exe" int ipv4 show dynamicportrange tcp } -ErrorAction SilentlyContinue } Catch { }
        If ($dynPorts.Count -eq 6)
        {
            Try {
                $rangeS = ($dynPorts[3].Split(':')[1])
                $rangeC = ($dynPorts[4].Split(':')[1])
                $rangeE = (($rangeS -as [int]) + ($rangeC -as [int]))
            } Catch {}
        }

        $TCPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
        [System.Collections.ArrayList]$PortList = @($TCPProperties.GetActiveTcpListeners() | Select-Object -ExpandProperty 'Port' |
            Where-Object { ($_ -gt 1024) -and (-not (($_ -ge $rangeS) -and ($_ -le $rangeE))) } | Sort-Object -Unique)

        [System.Collections.ArrayList]$PortListC = $PortList.Clone()
        $script:chkValues['IgnoreThesePorts'] | ForEach-Object -Process {
            If ($PortList.Contains($_) -eq $true) { $PortListC.Remove($_) }
        }

        If ($PortListC.Count -gt 0)
        {
            $result.result  =    $script:lang['Fail']
            $result.message =    $script:lang['f001']
            $result.data    = ($($script:lang['dt01']) -f $($PortList -join ', '))
        }
        Else
        {
            $result.result   = $script:lang['Pass']
            $result.message += $script:lang['p001']
        }

        $result.data += ($($script:lang['dt02']) -f "0-1024, $($script:chkValues['IgnoreThesePorts'] -join ', '), $rangeS-$rangeE")
        $result.data  = (($result.data).TrimStart(',#'))
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
    }

    Return $result
}
