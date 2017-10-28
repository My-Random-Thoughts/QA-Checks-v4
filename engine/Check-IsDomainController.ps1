Function Check-IsDomainController
{
    [int]$gCIMi = ((Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'DomainRole' -ErrorAction SilentlyContinue).DomainRole)
    If (($gCIMi -eq 4) -or ($gCIMi -eq 5)) { Return $true }
    Return $false
}
