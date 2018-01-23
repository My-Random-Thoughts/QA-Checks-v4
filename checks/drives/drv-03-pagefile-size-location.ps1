<#
    DESCRIPTION: 
        Check the page file is located on the system drive and is a fixed size.  The default setting is 4096MB (4GB).
        If the page file is larger a document detailing the tuning process used must exist and should follow Microsoft best tuning practices - http://support.microsoft.com/kb/2021748

    REQUIRED-INPUTS:
        FixedPageFileSize - Fixed size in MB of the page file|Integer
        PageFileLocation  - Drive location of the page file

    DEFAULT-VALUES:
        FixedPageFileSize = '4096'
        PageFileLocation  = 'C:\'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Pagefile is set correctly
        WARNING: 
        FAIL:
            Pagefile is system managed
            Pagefile is not set correctly
        MANUAL:
            Unable to get page file information, please check manually
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function drv-03-pagefile-size-location
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'drv-03-pagefile-size-location'

    #... CHECK STARTS HERE ...#

    Try
    {
        # Because more than one PageFile can exist.!
        [System.Collections.ArrayList]$gCIMi1 = @(Get-CimInstance -ClassName 'Win32_PageFileSetting' -Property ('Name', 'InitialSize', 'MaximumSize') -ErrorAction SilentlyContinue)
        [string]                      $gCIMi2 = ((Get-CimInstance -ClassName 'Win32_ComputerSystem'  -Property  'AutomaticManagedPageFile' -ErrorAction SilentlyContinue).AutomaticManagedPageFile)

        If ($gCIMi2 -eq $true)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }
        Else
        {
            If (($gCIMi1 -eq $null) -and ($gCIMi2 -eq $false))
            {
                $result.result  = $script:lang['Manual']
                $result.message = $script:lang['m001']
            }
            ElseIf ($gCIMi1 -ne $null)
            {
                If (($gCIMi1[0].MaximumSize -eq $script:chkValues['FixedPageFileSize']) -and ($gCIMi1[0].InitialSize -eq $script:chkValues['FixedPageFileSize']) -and ($gCIMi1[0].Name.ToLower().StartsWith($script:chkValues['PageFileLocation'].ToLower())))
                {
                    $result.result  =    $script:lang['Pass']
                    $result.message =    $script:lang['p001']
                    $result.data    = ($($script:lang['dt01']) -f $script:chkValues['PageFileLocation'], $script:chkValues['FixedPageFileSize'])
                }
                Else
                {
                    $result.result  =    $script:lang['Fail']
                    $result.message =    $script:lang['f002']
                    $result.data    = ($($script:lang['dt02']) -f $gCIMi1[0].Name, $gCIMi1[0].InitialSize, $gCIMi1[0].MaximumSize)
                }
            }
            Else
            {
                $result.result  =    $script:lang['Fail']
                $result.message = ($($script:lang['f003']) -f $script:chkValues['PageFileLocation'])
            }
        }

        If ($result.data -eq '')
        {
            $result.data = ($($script:lang['dt03']) -f $script:chkValues['FixedPageFileSize'], $script:chkValues['PageFileLocation'])
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
