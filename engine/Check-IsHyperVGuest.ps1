Function Check-IsHyperVGuest
{
    [string]$gCIMi = ((Get-CimInstance -ClassName 'Win32_BaseBoard' -Property 'Product').Product)
    If ($gCIMi -eq 'Virtual Machine') { Return $true }
    Return $false
}
