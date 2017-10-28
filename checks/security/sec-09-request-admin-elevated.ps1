<#
    DESCRIPTION: 
        Ensure the system is set to request administrative credentials before granting an application elevated privileges. 
        Default setting is either "(1):Prompt for credentials on the secure desktop" or "(3):Prompt for credentials"
        Values and meanings can be seen here - https://msdn.microsoft.com/en-us/library/cc232761.aspx

    REQUIRED-INPUTS:
        ElevatePromptForAdminCredentials - "0,1,2,3,4,5" - List of settings to check for

    DEFAULT-VALUES:
        ElevatePromptForAdminCredentials = ('1', '3')

    DEFAULT-STATE:
        Enabled

    INPUT-DESCRIPTION:
        ElevatePromptForAdminCredentials:
            0: Elevate without prompting
            1: Prompt for credentials on the secure desktop
            2: Prompt for consent on the secure desktop
            3: Prompt for credentials
            4: Prompt for consent
            5: Prompt for consent for non-Windows binaries

    RESULTS:
        PASS:
            System is configured correctly
        WARNING:
        FAIL:
            System is not configured correctly
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-09-request-admin-elevated
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-09-request-admin-elevated'

    #... CHECK STARTS HERE ...#

    Try
    {
        Try {
            [string]$gITMp = ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorAdmin' -ErrorAction Stop).ConsentPromptBehaviorAdmin)
        } Catch { [string]$gITMp = $null }

        If ($script:chkValues['ElevatePromptForAdminCredentials'] -contains $gITMp)
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }

        $result.data = $script:lang['dt01']
        Switch ($gITMp)
        {
            0       { $result.data += $script:lang['dt02'] }
            1       { $result.data += $script:lang['dt03'] }
            2       { $result.data += $script:lang['dt04'] }
            3       { $result.data += $script:lang['dt05'] }
            4       { $result.data += $script:lang['dt06'] }
            5       { $result.data += $script:lang['dt07'] }

            Default { $result.data  = $script:lang['f001'] }    # Registry setting not found
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
