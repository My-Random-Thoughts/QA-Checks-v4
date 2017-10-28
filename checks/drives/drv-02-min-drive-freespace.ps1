<#
    DESCRIPTION: 
        Ensure all drives have a minimum amount of free space.  Measured as a percentage.

    REQUIRED-INPUTS:
        IgnoreTheseDrives       - "LIST" - List of drive letters to ignore
        MinimumDrivePercentFree - Minimum free space available on each drive as a percentage|Integer

    DEFAULT-VALUES:
        IgnoreTheseDrives       = @('A', 'B')
        MinimumDrivePercentFree = '17'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All drives have the required minimum free space of {size}%
        WARNING:
        FAIL:
            One or more drives were found with less than {size}% free space
        MANUAL:
            Unable to get drive information, please check manually
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function drv-02-min-drive-freespace
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'drv-02-min-drive-freespace'
 
    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Text.StringBuilder]   $filter = "DriveType='3'"
        $script:chkValues['IgnoreTheseDrives'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT Name = '$_'") }
        [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter $filter.ToString() -Property ('Name', 'FreeSpace', 'Size') -ErrorAction SilentlyContinue)
        $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

        $countFailed = 0
        If ($gCIMi.Count -gt 0)
        {
            $gCIMi | ForEach-Object -Process {
                [double]$free = $_.FreeSpace
                [double]$size = $_.Size
                If ($size -ne 0)
                {
                    [double]$percentFree  = [decimal]::Round(($free / $size) * 100)
                    $result.data += ($_.Name + ' (' + $percentFree + '% free),#')
                    If ($percentFree -lt $script:chkValues['MinimumDrivePercentFree']) { $countFailed += 1 }
                }
            }
    
            If ($countFailed -ne 0)
            {
                $result.result  =    $script:lang['Fail']
                $result.message = ($($script:lang['f001']) -f $script:chkValues['MinimumDrivePercentFree'])
            }
            Else
            {
                $result.result  =    $script:lang['Pass']
                $result.message = ($($script:lang['p001']) -f $script:chkValues['MinimumDrivePercentFree'])
            }
        }
        Else
        {
            $result.result  =    $script:lang['Manual']
            $result.message =    $script:lang['m001']
            $result.data    = ($($script:lang['dt01']) -f $script:chkValues['MinimumDrivePercentFree'])
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
