<#
    DESCRIPTION: 
        Checks to see if there are are more than 8 drives attached to the same SCSI adapter.
        
    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            More than 7 drives exist, but on different SCSI adapters
        WARNING:
        FAIL:
            More than 7 drives exist on one SCSI adapter
        MANUAL:
        NA:
            Not a virtual machine
            There are less than 8 drives attached to server

    APPLIES:
        Virtual Servers

    REQUIRED-FUNCTIONS:
        Check-IsVMwareGuest
#>

Function vmw-05-scsi-drive-count
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'vmw-05-scsi-drive-count'

    #... CHECK STARTS HERE ...#

    If ((Check-IsVMwareGuest) -eq $true)
    {
        Try
        {
            [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_DiskDrive' -Filter "NOT Caption='Microsoft Virtual Disk'" -Property ('SCSIPort', 'SCSITargetID', 'Caption'))
            $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

            If ($gCIMi.Count -gt 7)
            {
                [boolean]$found = $false
                [System.Collections.ArrayList]$group = @($gCIMi | Group-Object -Property 'SCSIPort' -NoElement | Sort-Object -Property 'SCSIPort')
                $group | ForEach-Object -Process {
                    $result.data += ($($script:lang['dt01']) -f $_.Name, $_.Count)
                    If ($_.Count -gt 7) { $found = $true }
                }

                If ($found -eq $true)
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f001']
                }
                Else
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p001']
                }
            }
            Else
            {
                $result.result  = $script:lang['Not-Applicable']
                $result.message = $script:lang['n002']
            }

            $result.data = ($($script:lang['dt02']) -f $gCIMi.Count)
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
