<#
    DESCRIPTION: 
        Check Hyper-V is installed on Windows Server Core.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Hyper-V is using Windows Server Core
        WARNING:
        FAIL:
            Hyper-V is not using Windows Server Core
        MANUAL:
        NA:
            Not a Hyper-V server

    APPLIES:
        Hyper-V Host Servers

    REQUIRED-FUNCTIONS:
        Check-NameSpace
#>

Function hvh-01-server-core
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'hvh-01-server-core'
 
    #... CHECK STARTS HERE ...#

    If ((Check-NameSpace -NameSpace 'ROOT\Virtualization\v2') -eq $true)
    {
        Try
        {
            If ((Test-Path -Path "$env:windir\explorer.exe") -eq $true)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
            Else
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
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

    Return $result
}
