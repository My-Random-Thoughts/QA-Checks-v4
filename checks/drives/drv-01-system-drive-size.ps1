<#
    DESCRIPTION: 
        Check the system drive is a minimum size of 50gb for Windows 2008+ servers (some are reporting 49gb).
        
    REQUIRED-INPUTS:
        MinimumSystemDriveSize - Minimum size of the system drive|Integer

    DEFAULT-VALUES:
        MinimumSystemDriveSize = '49'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            System drive meets minimum required size
        WARNING:
        FAIL:
            System drive is too small, should be {size}gb
        MANUAL:
            Unable to get drive size, please check manually
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function drv-01-system-drive-size
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'drv-01-system-drive-size'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [double]$gCIMi  = ((Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter "Name = '$env:SystemDrive'" -Property 'Size' -ErrorAction SilentlyContinue).Size)
        [int]   $sizeGB = (($gCIMi / 1GB) -as [int])        

        If ($sizeGB -ge $script:chkValues['MinimumSystemDriveSize'])
        {
            $result.result  =    $script:lang['Pass']
            $result.message =    $script:lang['p001']
            $result.data    = ($($script:lang['dt01']) -f $sizeGB)
        }
        Else
        {
            $result.result  =    $script:lang['Fail']
            $result.message = ($($script:lang['f001']) -f $script:chkValues['MinimumSystemDriveSize'])
            $result.data    = ($($script:lang['dt01']) -f $sizeGB)
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
