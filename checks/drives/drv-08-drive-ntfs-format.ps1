<#
    DESCRIPTION: 
        Ensure all drives are formatted as NTFS.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All drives are formatted as NTFS
        WARNING:
        FAIL:
            One or more drives were found not formatted as NTFS
        MANUAL:
            Unable to get drive information, please check manually
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function drv-08-drive-ntfs-format
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'drv-08-drive-ntfs-format'
 
    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter "DriveType='3'" -Property ('Name', 'FileSystem') -ErrorAction SilentlyContinue)
        $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

        $countFailed = 0
        $result.data = ''
        If ($gCIMi.Count -gt 0)
        {
            $gCIMi | Sort-Object -Property 'Name' | ForEach-Object -Process {
                If ($_.FileSystem -ne 'NTFS')
                {
                    If ($_.FileSystem -eq $null) { $_.FileSystem = 'Not Formatted' }
                    $result.data += ('{0} ({1}),#' -f $_.Name, $_.FileSystem)
                    $countFailed += 1
                }
            }
    
            If ($countFailed -ne 0)
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
            $result.result  = $script:lang['Manual']
            $result.message = $script:lang['m001']
            $result.data    = $script:lang['dt01']
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
