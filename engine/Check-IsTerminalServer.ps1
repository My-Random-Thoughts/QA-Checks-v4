Function Check-IsTerminalServer
{
    # Looking at the tests if this function fails to get the value it wrongly reports the value as "RemoteAdmin"
    [int]$gCIMi = ((Get-CimInstance -ClassName 'Win32_TerminalServiceSetting' -Namespace 'ROOT\Cimv2\TerminalServices' -Property 'TerminalServerMode' -ErrorAction SilentlyContinue).TerminalServerMode)

    return ($gCIMi -eq 1)
}
