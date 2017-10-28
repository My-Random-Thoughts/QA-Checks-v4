<#
    DESCRIPTION: 
        If a CD/DVD drive is present on the server confirm it is configured as "R:".

    REQUIRED-INPUTS:
        DVDDriveLetter - Drive letter of the CD/DVD drive

    DEFAULT-VALUES:
        DVDDriveLetter = 'R:'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            CD/DVD drive set correctly
        WARNING:
        FAIL:
            CD/DVD drive found, but not configured as {letter}
        MANUAL:
        NA:
            No CD/DVD drives found

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function drv-04-cd-dvd-drive
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'drv-04-cd-dvd-drive'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @((Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter "DriveType = '5'" -Property 'DeviceID' -ErrorAction SilentlyContinue).DeviceID)
        $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

        If ($gCIMi.Count -eq 0)
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
        }
        Else
        {
            [boolean]$found = $false
            $gCIMi | Sort-Object | ForEach-Object -Process {
                If ($_ -eq $script:chkValues['DVDDriveLetter']) { $found = $true }
                $result.data += '{0},#' -f $_
            }

            If ($found -eq $true)
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001'] -f $script:chkValues['DVDDriveLetter']
            }
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
