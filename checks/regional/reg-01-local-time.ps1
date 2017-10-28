<#
    DESCRIPTION: 
        Check that the server time is correct.  If a valid source is used, the time is also checked against that source.
        Maximum time difference allowed is 10 seconds, any longer and the check fails.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Time source is set to a remote server, and is synchronised correctly
        WARNING:
        FAIL:
            Time source is set to a remote server, and is not synchronised correctly
            Time source is not set
            Time source is not set correctly
            Error getting required information
        MANUAL:
            Not a supported operating system for this check
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function reg-01-local-time
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'reg-01-local-time'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]  $domCheck = (Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property ('Domain', 'PartOfDomain'))
        [object]  $gCIMi    = (Get-CimInstance -ClassName 'Win32_LocalTime'      -Property 'Day', 'Month', 'Year', 'Hour', 'Minute', 'Second')
        [datetime]$rdt      = (Get-Date -Year $gCIMi.Year -Month $gCIMi.Month -Day $gCIMi.Day -Hour $gCIMi.Hour -Minute $gCIMi.Minute -Second $gCIMi.Second)
        [string]  $domain   = ($domCheck.Domain -split '\.')[0]

        If ($domCheck.PartOfDomain -eq $true)
        {
            [string]$source = (Invoke-Command -ScriptBlock { &"$env:SystemRoot\System32\w32tm.exe" /query /source } -ErrorAction SilentlyContinue)
            If ($source.Contains(',') -eq $true) { $source = ($source.Split(',')[0]) }
        }
        Else { $source = 'WORKGROUP' }
        
        If ([string]::IsNullOrEmpty($source) -eq $true)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }
        ElseIf (($source -eq 'Local CMOS Clock') -or ($source -eq 'Free-Running System Clock'))
        {
            $result.result  =    $script:lang['Fail']
            $result.message =    $script:lang['f002']
            $result.data    = ($($script:lang['dt01']) -f $source.ToLower(), $rdt)
        }
        ElseIf ($source -like '*The following error*')
        {
            $result.result  =    $script:lang['Fail']
            $result.message =    $script:lang['f003']
            $result.data    = ($($script:lang['dt01']) -f $source.ToLower(), $rdt)
        }
        ElseIf ($source -eq 'WORKGROUP')
        {
            $result.result   =    $script:lang['Warning']
            $result.message +=    $script:lang['w001']
            $result.data    += ($($script:lang['dt02']) -f $rdt, $domain)
        }
        Else
        {
            $offSet = (Get-NtpTime -NTPServer $source.Trim() -InputDateTime $rdt)
            If ($offSet -lt 10)
            {
                $result.result   =    $script:lang['Pass']
                $result.message +=    $script:lang['p001']
                $result.data    += ($($script:lang['dt03']) -f $source.Trim().ToLower(), $offSet)
            }
            Else
            {
                $result.result   =    $script:lang['Fail']
                $result.message +=    $script:lang['f004']
                $result.data    += ($($script:lang['dt03']) -f $source.Trim().ToLower(), $offSet)
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

Function Get-NtpTime {
    Param ([string]$NTPServer, [datetime]$InputDateTime)
    $StartOfEpoch = New-Object DateTime(1900,1,1,0,0,0,[DateTimeKind]::Utc)   

    [Byte[]]$NtpData = ,0 * 48
    $NtpData[0]      = 0x1B

    $Socket = New-Object Net.Sockets.Socket([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Dgram, [Net.Sockets.ProtocolType]::Udp)
    $Socket.SendTimeOut    = 2000
    $Socket.ReceiveTimeOut = 2000

    Try {       $Socket.Connect($NTPServer, 123)                        } Catch { Return $($script:lang['ntp1']) }
    Try { [void]$Socket.Send($NtpData); [void]$Socket.Receive($NtpData) } Catch { Return $($script:lang['ntp2']) }

    $Socket.Shutdown('Both')
    $Socket.Close()

    $IntPart  = [System.BitConverter]::ToUInt32($NtpData[35..32], 0)
    $FracPart = [System.BitConverter]::ToUInt32($NtpData[39..36], 0)
    $CalcPart = $IntPart * 1000 + ($FracPart * 1000 / 0x100000000)

    $Offset =  ($CalcPart - ($InputDateTime.ToUniversalTime() - $StartOfEpoch).TotalMilliseconds)

    Return [Math]::Round($Offset/1000, 3)
}
