<#
    DESCRIPTION: 
        Check Windows disk controller is set correctly.  Default setting is "LSI logic SAS".

    REQUIRED-INPUTS:
        DiskControllerDeviceType   - VMware ESX default disk controller name
        IgnoreTheseControllerTypes - "LIST" - List of controller types to ignore

    DEFAULT-VALUES:
        DiskControllerDeviceType   = 'LSI_SAS'
        IgnoreTheseControllerTypes = @('spaceport', 'vhdmp')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Disk controller set correctly
        WARNING:
        FAIL:
            No SCSI controllers found
            Disk controller not set correctly
        MANUAL:
        NA:
            Not a virtual machine

    APPLIES:
        Virtual Servers

    REQUIRED-FUNCTIONS:
        Check-IsVMwareGuest
#>

Function vmw-04-lsi-sas-controller
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'vmw-04-lsi-sas-controller'

    #... CHECK STARTS HERE ...#

    If ((Check-IsVMwareGuest) -eq $true)
    {
        Try
        {
            [System.Text.StringBuilder]   $filter = "NOT DriverName='Null'"
            $script:chkValues['IgnoreTheseControllerTypes'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT DriverName LIKE '%$_%'") }
            [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_SCSIController' -Filter $filter.ToString() -Property ('Name', 'DriverName') -ErrorAction SilentlyContinue)
            $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

            If ($gCIMi.Count -gt 0)
            {
                $gCIMi | Sort-Object | ForEach-Object -Process {
                    If ($($_.DriverName) -ne $script:chkValues['DiskControllerDeviceType']) { $result.data += "$($_.Name) ($($_.DriverName)),#" }
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
                }
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f002']
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
