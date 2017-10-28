<#
    DESCRIPTION: 
        Check for a pending reboot.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Server is not waiting for a reboot
        WARNING:
        FAIL:
            Server is waiting for a reboot
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-01-pending-reboot
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-01-pending-reboot'
    
    #... CHECK STARTS HERE ...#

    Try {
        [string[]]$gITMp = @(Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -ErrorAction SilentlyContinue).GetValueNames()
        If (([string]::IsNullOrEmpty($gITMp) -eq $false) -and ($gITMp.Contains('RebootRequired') -eq $true)) { $result.data += 'Pending trusted installer operations,#' }

        [string[]]$gITMp = @(Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -ErrorAction SilentlyContinue).GetValueNames()
        If (([string]::IsNullOrEmpty($gITMp) -eq $false) -and ($gITMp.Contains('RebootRequired') -eq $true)) { $result.data += 'Pending windows updates,#' }

        [string]$gITMp1 = ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName'       -Name 'ComputerName' -ErrorAction SilentlyContinue).ComputerName)
        [string]$gITMp2 = ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name 'ComputerName' -ErrorAction SilentlyContinue).ComputerName)
        If ($gITMp1 -ne $gITMp2) { $result.data += 'Pending computer rename,#' }

        Try {
            [string[]]$gITMp = @((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction Stop).PendingFileRenameOperations)
            $gITMp | ForEach-Object -Process {
                If (($_ -ne '') -and ($_ -notlike '*VMwareDnD*')) { $result.data += 'Pending file rename operations,#' }
            }
            $result.data = (($result.data.Split(',#') | Sort-Object -Unique) -join (',#')).TrimStart(',#')
        } Catch { }

        If ([string]::IsNullOrEmpty($result.data) -eq $true)
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
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
