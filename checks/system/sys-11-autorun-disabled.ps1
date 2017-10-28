<#
    DESCRIPTION:
        Ensure autorun is disabled.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Autorun is disabled
        WARNING:
        FAIL:
            Autorun is enabled
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-11-autorun-disabled
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-11-autorun-disabled'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$gITMp = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoDriveTypeAutoRun' -ErrorAction SilentlyContinue)
        If ([string]::IsNullOrEmpty($gITMp) -eq $false)
        {
            If ($gITMp.NoDriveTypeAutoRun -eq '255')
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
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

    Return $result
}
