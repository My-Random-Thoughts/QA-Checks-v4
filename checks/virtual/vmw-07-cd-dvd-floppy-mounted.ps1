<#
    DESCRIPTION: 
        Checks for any mounted CD/DVD or floppy drives.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No CD/ROM or floppy drives are mounted
        WARNING:
        FAIL:
            One or more CD/ROM or floppy drives are mounted
        MANUAL:
        NA:
            Not a virtual machine

    APPLIES:
        Virtual Servers

    REQUIRED-FUNCTIONS:
        Check-IsVMwareGuest
#>

Function vmw-07-cd-dvd-floppy-mounted
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'vmw-07-cd-dvd-floppy-mounted'
 
    #... CHECK STARTS HERE ...#

    If ((Check-IsVMwareGuest) -eq $true)
    {
        Try
        {
            # Filter on DriveType = 2 and 5 (Removable and CD/DVD)
            [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter "DriveType='2' OR DriveType='5'" -Property ('Name', 'VolumeName') -ErrorAction SilentlyContinue)
            $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

            $gCIMi | Sort-Object | ForEach-Object -Process {
                If ($_.size -ne $null) { $result.data += "$($_.Name) ($($_.VolumeName)),#" }
            }

            If ([string]::IsNullOrEmpty($result.data) -eq $false)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
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
