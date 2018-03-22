Function Check-IsPortOpen ([string]$DestinationServer, [int]$Port)
{
    Try {
        $tcp  = New-Object -TypeName 'System.Net.Sockets.TcpClient'
        $con  = $tcp.BeginConnect($DestinationServer, $port, $null, $null)
        $wait = $con.AsyncWaitHandle.WaitOne(3000, $false)
        If (-not $wait) { $tcp.Close(); Return $false }
        Else {
            $failed = $false; $error.Clear()
            Try { $tcp.EndConnect($con) } Catch {}
            If (!$?) { $failed = $true }; $tcp.Close()
            If ($failed -eq $true) { Return $false } Else { Return $true }
    } } Catch { Return $false }
}
