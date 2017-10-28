<#
    DESCRIPTION: 
        Ensure the Region and Language > keyboard and Languages is set correctly.  Default setting is "English (United Kingdom)".

    REQUIRED-INPUTS:
        DefaultLanguage - Numerical value of the correct keyboard to use

    DEFAULT-VALUES:
        DefaultLanguage = '00000809'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Keyboard layout is set correctly
        WARNING:
        FAIL:
            Keyboard layout is not set correctly
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function reg-04-language
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'reg-04-language'

    #... CHECK STARTS HERE ...#

    Try
    {
                $null   = (New-PSDrive      -Name 'HKU' -PSProvider 'Registry' -Root 'HKEY_USERS')
        [string]$gItmP1 = (Get-ItemProperty -Path 'HKU:\.DEFAULT\Keyboard Layout\Preload' -Name '1' -ErrorAction Stop).'1'
        [string]$gItmP2 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$($gItmP1)" -Name 'Layout Text').'Layout Text'
                $null   = (Remove-PSDrive   -Name 'HKU')

        If ([string]::IsNullOrEmpty($gItmP1) -eq $false)
        {
            If ($gItmP1 -eq $script:chkValues['DefaultLanguage'])
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
        
            $result.data = $gItmP1
            If ([string]::IsNullOrEmpty($gItmP2) -eq $false) { $result.data += ",#$gItmP2" }
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f002']
            $result.data    = ''
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
