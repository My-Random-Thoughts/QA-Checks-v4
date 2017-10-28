<#
    DESCRIPTION: 
        Checks Device Manager to ensure there are no unknown devices, conflicts or errors.
        
    REQUIRED-INPUTS:
        IgnoreTheseDeviceNames - "LIST" - Known devices that can be ignored

    DEFAULT-VALUES:
        IgnoreTheseDeviceNames = ('')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No disabled devices or device errors found
        WARNING:
            Disabled devices found
        FAIL:
            Device errors found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-07-devices-status
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-07-devices-status'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Text.StringBuilder]   $filter = "NOT ConfigManagerErrorCode='0'"
        $script:chkValues['IgnoreTheseDeviceNames'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT Name='$_'") }
        [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_PnPEntity' -Filter $filter -Property ('Name', 'ConfigManagerErrorCode') -ErrorAction SilentlyContinue)

        [boolean]$onlyDisabled = $true
        $gCIMi | Sort-Object -Property 'Name' | ForEach-Object -Process {
            If ($_.ConfigManagerErrorCode -eq 22) { $result.data += ($($script:lang['dt01']) -f $_.Name) }    # Disabled devices
            Else                                  { $result.data += ($($script:lang['dt02']) -f $_.Name) }    # Other state
        }

        If ([string]::IsNullOrEmpty($result.data) -eq $false)
        {
            If ($onlyDisabled -eq $true)
            {
                $result.message = $script:lang['w001']
                $result.result  = $script:lang['Warning']
            }
            Else
            {
                $result.message = $script:lang['f001']
                $result.result  = $script:lang['Fail']
            }
        }
        Else
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
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
