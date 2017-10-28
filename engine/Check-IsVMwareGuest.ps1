Function Check-IsVMwareGuest
{
    [string]$gCIMi = ((Get-CimInstance -ClassName 'Win32_BIOS' -Property 'SerialNumber' -ErrorAction SilentlyContinue).SerialNumber)
    If ($gCIMi -like '*VMware*') { Return $true }
    Return $false
}
