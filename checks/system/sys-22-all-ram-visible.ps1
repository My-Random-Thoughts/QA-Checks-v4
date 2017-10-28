<#
    DESCRIPTION: 
        Check that all the memory assigned to a server is visible to the OS.
        
    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All assigned memory is visible
        WARNING:
        FAIL:
            Not all assigned memory is visible
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-22-all-ram-visible
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-22-all-ram-visible'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [double]$System   =   ((Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'TotalPhysicalMemory').TotalPhysicalMemory)
        [double]$Physical = ((((Get-CimInstance -ClassName 'CIM_PhysicalMemory'   -Property 'Capacity').Capacity) | Measure-Object -Sum).Sum)

        # Get 1% range for system memory (Normal difference should be less than 0.1%)
        [double]$lowerRange = $System - (($System / 100) * 1)
        [double]$upperRange = $System + (($System / 100) * 1)

        If (($Physical -gt $lowerRange) -and ($ramTotal -lt $upperRange))
        {
            $result.result  =    $script:lang['Pass']
            $result.message =    $script:lang['p001']
            $result.data    = ($($script:lang['dt01']) -f ($Physical / 1GB).ToString('0.00'))
        }
        Else
        {
            $result.result  =    $script:lang['Fail']
            $result.message =    $script:lang['f001']
            $result.data    = ($($script:lang['dt02']) -f ($Physical / 1GB).ToString('0.00'), ($System / 1GB).ToString('0.00'))
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
