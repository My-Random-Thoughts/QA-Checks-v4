<#
    DESCRIPTION: 
        Ensure SMB signing is turned on. 

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            SMB Signing configured correctly
        WARNING:
        FAIL:
            SMB Signing not configured correctly
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-12-smb-signing-on
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-12-smb-signing-on'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$gITMp1  = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'      -Name 'RequireSecuritySignature' -ErrorAction SilentlyContinue)
        [object]$gITMp2  = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' -Name 'RequireSecuritySignature' -ErrorAction SilentlyContinue)
        [string]$missing = ''

        If (([string]::IsNullOrEmpty($gITMp1) -eq $true) -or ($gITMp1.RequireSecuritySignature -ne '1')) { $missing  = 'LanmanServer, '    }
        If (([string]::IsNullOrEmpty($gITMp2) -eq $true) -or ($gITMp2.RequireSecuritySignature -ne '1')) { $missing += 'LanmanWorkstation' }

        If ($missing -eq '')
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  =    $script:lang['Fail']
            $result.message =    $script:lang['f001']
            $result.data    = ($($script:lang['dt01']) -f $missing)
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
