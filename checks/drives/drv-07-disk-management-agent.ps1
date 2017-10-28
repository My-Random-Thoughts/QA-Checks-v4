<#
    DESCRIPTION:
        Check local disk array management agent is installed on the server.
        This only checks that known software is installed.  A manual check must be done to ensure it is configured correctly.

    REQUIRED-INPUTS:
        ProductNames - "LIST" - List of software to check if installed

    DEFAULT-VALUES:
        ProductNames = @('HP Array Configuration Utility', 'Dell OpenManage Server Administrator', 'Broadcom Drivers And Management Applications')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
        WARNING:
        FAIL:
            Disk management software not found, install required
        MANUAL:
            {product} found
        NA:
            Not a physical machine

    APPLIES:
        Physical Servers

    REQUIRED-FUNCTIONS:
        Check-Software
        Check-IsVMwareGuest
        Check-IsHyperVGuest
#>

Function drv-07-disk-management-agent
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'drv-07-disk-management-agent'
    
    #... CHECK STARTS HERE ...#

    [string]$checkOS = (Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'Caption')
    If ($checkOS -like '*server*')
    {
        If (((Check-IsVMwareGuest) -eq $false) -and ((Check-IsHyperVGuest) -eq $false))
        {
            Try
            {
                [object]$details = $null
                $script:chkValues['ProductNames'] | ForEach-Object -Process {
                    If ([string]::IsNullOrEmpty($_) -eq $false)
                    {
                        $script:chkValues['Win32_Product'] = 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'    # Reset search path
                        [object]$verCheck = (Check-Software -DisplayName $_)
                        If ($verCheck -eq '-1') { Throw $($script:lang['trw1']) }
                        If ([string]::IsNullOrEmpty($verCheck) -eq $false) { $details = $verCheck }
                    }
                }

                If ([string]::IsNullOrEmpty($details) -eq $false)
                {
                    $result.result  =    $script:lang['Manual']
                    $result.message = ($($script:lang['m001']) -f $details.DisplayName)
                    $result.data    = ($($script:lang['dt01']) -f $details.Version)
                }
                Else
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f001']
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
    }
    Else
    {
        $result.result  = $script:lang['Not-Applicable']
        $result.message = $script:lang['n002']
        $result.data    = $checkOS
    }

    Return $result
}
