<#
    DESCRIPTION:
        Ensure the system is set to not sure LMHashes of passwords and that LMHash authentication is secure.

    REQUIRED-INPUTS:
        MinimumHashLevel - "0|1|2|3|4|5" - The minimum level that should be allowed

    DEFAULT-VALUES:
        MinimumHashLevel = '3'

    DEFAULT-STATE:
        Enabled

    INPUT-DESCRIPTION:
        MinimumHashLevel:
            0: Send LM and NTLM response; never use NTLMv2 security
            1: Use NTLMv2 security if negotiated
            2: Send NTLM authentication only
            3: Send NTLMv2 authentication only
            4: Refuse LM authentication
            5: Refuse LM and NTLM authentication; accept only NTLMv2

    RESULTS:
        PASS:
            LMHash security is disabled
            LM Compatibility Level is equal to or above configured level
        WARNING:
            LM Compatibility Level is below configured level
        FAIL:
            LMHash settings are not configured
            LMHash security is enabled
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-20-check-lmhash-security
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-20-check-lmhash-security'

    #... CHECK STARTS HERE ...#

    Try
    {
        Try {
            [string]$gITMp1 = ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'NoLMHash'             -ErrorAction Stop).NoLMHash            )
            [string]$gITMp2 = ((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LMCompatibilityLevel' -ErrorAction Stop).LMCompatibilityLevel)
        } Catch {
            [string]$gITMp1 = $null
            [string]$gITMp2 = $null
        }

        If ([string]::IsNullOrEmpty($gITMp1) -eq $true)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }
        ElseIf ($gITMp1 -eq '1')
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f002']
        }

        If ([string]::IsNullOrEmpty($gITMp2) -eq $true)
        {
            If ($result.result -eq    $script:lang['Pass']) { $result.result = $script:lang['Warning'] }
            $result.data         = ($($script:lang['dt01']) -f 'Unknown' )
        }
        ElseIf (($gITMp2 -as [int]) -ge 3)
        {
            $result.message +=    $script:lang['p002']
            $result.data     = ($($script:lang['dt01']) -f $gITMp2)
        }
        Else
        {
            If ($result.result -eq    $script:lang['Pass']) { $result.result = $script:lang['Warning'] }
            $result.message     +=    $script:lang['w001']
            $result.data         = ($($script:lang['dt01']) -f $gITMp2)
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
