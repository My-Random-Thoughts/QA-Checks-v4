Function Check-IsTerminalServer
{
    [int]$gCIMi = ((Get-CimInstance -ClassName 'Win32_TerminalServiceSetting' -Namespace 'ROOT\Cimv2\TerminalServices' -Property 'TerminalServerMode' -ErrorAction SilentlyContinue).TerminalServerMode)
    If ($gCIMi -eq 1) { Return $true }    # 0:RemoteAdmin, 1:AppServer
    Return $false
}
