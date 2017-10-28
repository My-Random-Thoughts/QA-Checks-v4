<#
    DESCRIPTION: 
        Ensure the Region and Language > Location is set correctly.  Default setting is "United Kingdom".

    REQUIRED-INPUTS:
        DefaultLocation - Regional string name

    DEFAULT-VALUES:
        DefaultLocation = 'United Kingdom'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Regional location set correctly
        WARNING:
        FAIL:
            Regional location incorrectly set to {string}
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function reg-03-location
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'reg-03-location'
    
    #... CHECK STARTS HERE ...#

    Try
    {
                $null  = (New-PSDrive      -Name 'HKU' -PSProvider 'Registry' -Root 'HKEY_USERS')
        [string]$gItmP = (Get-ItemProperty -Path 'HKU:\.DEFAULT\Control Panel\International' -Name 'sCountry' -ErrorAction Stop).'sCountry'
                $null  = (Remove-PSDrive   -Name 'HKU')

        If ([string]::IsNullOrEmpty($gItmP) -eq $false)
        {
            If ($gItmP -eq $script:chkValues['DefaultLocation'])
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
            Else
            {
                $result.result  =   $script:lang['Fail']
                $result.message = $($script:lang['p001']) -f $gItmP
            }
            $result.data = $gItmP
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
