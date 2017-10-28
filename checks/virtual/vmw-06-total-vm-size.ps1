<#
    DESCRIPTION: 
        Checks to see if the total VM size is less than 1TB.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            VM is smaller than 1TB
        WARNING:
            VM is larger than 1TB.  Make sure there is an engineering exception in place for this
        FAIL:
        MANUAL:
        NA:
            Not a virtual machine

    APPLIES:
        Virtual Servers

    REQUIRED-FUNCTIONS:
        Check-IsHyperVGuest
        Check-IsVMwareGuest
#>

Function vmw-06-total-vm-size
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'vmw-06-total-vm-size'

    #... CHECK STARTS HERE ...#

    If (((Check-IsVMwareGuest) -eq $true) -or ((Check-IsHyperVGuest) -eq $true))
    {
        Try
        {
            [int]$size = 0
            [System.Collections.ArrayList]$gCIMi = @((Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter "DriveType='3'" -Property 'Size').Size)
            $gCIMi | Sort-Object | ForEach-Object -Process { $size += ($_ / 1GB) }

            If ($size -gt 1023)
            {
                $result.result  = $script:lang['Warning']
                $result.message = $script:lang['w001']
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }

            $result.data = ($($script:lang['dt01']) -f $($size.ToString()))
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
