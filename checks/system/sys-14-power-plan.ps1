<#
    DESCRIPTION: 
        Check power plan is set to High Performance.
        
    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Power plan is set correctly
        WARNING:
        FAIL:
            Power plan is not set correctly
            Unknown power plan setting
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-14-power-plan
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-14-power-plan'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$gCIMi = (Get-CimInstance -ClassName 'Win32_PowerPlan' -Namespace 'ROOT\Cimv2\Power' -Filter "IsActive='True'" -Property 'ElementName' -ErrorAction SilentlyContinue)
        If ([string]::IsNullOrEmpty($gCIMi) -eq $false)
        {
            If (($gCIMi.ElementName) -eq $script:lang['ck01'])
            {
                $result.result  =    $script:lang['Pass']
                $result.message =    $script:lang['p001']
                $result.data    = ($($script:lang['dt01']) -f $gCIMi.ElementName)
            }
            Else
            {
                $result.result  =      $script:lang['Fail']
                $result.message =      $script:lang['f001']
                $result.data    = (("$($script:lang['dt01']),#$($script:lang['dt02'])") -f $gCIMi.ElementName, $script:lang['ck01'])
            }
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f002']
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
