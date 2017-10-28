<#
    DESCRIPTION: 
        Check that VMware Host Time Sync is disabled.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            VMware tools time sync is disabled
        WARNING:
        FAIL:
            VMware tools time sync is enabled
        MANUAL:
            Unable to check the VMware time sync status
        NA:
            Not a virtual machine

    APPLIES:
        Virtual Servers

    REQUIRED-FUNCTIONS:
        Check-IsVMwareGuest
#>

Function vmw-02-time-sync
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'vmw-02-time-sync'

    #... CHECK STARTS HERE ...#

    If ((Check-IsVMwareGuest) -eq $true)
    {
        Try   { [string]$iCmd = (Invoke-Command -ScriptBlock { &"$env:ProgramFiles\VMware\VMware Tools\VMwareToolBoxCmd.exe" timesync status } -ErrorAction Stop) }
        Catch { [string]$iCmd = 'Unknown' }

        If ($iCmd -like $script:lang['ck01'])
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        ElseIf ($iCmd -like $script:lang['ck02'])
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }
        Else
        {
            $result.result  = $script:lang['Manual']
            $result.message = $script:lang['m001']
            $result.data    = $script:lang['dt01']
        }
    }
    Else
    {
        $result.result  = $script:lang['Not-Applicable']
        $result.message = $script:lang['n001']
    }

    Return $result
}
