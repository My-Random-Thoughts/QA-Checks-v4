<#
    DESCRIPTION: 
        Check to make sure hibernation is disabled.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Hibernation is currently disabled
        WARNING:
        FAIL:
            Hibernation is currently enabled
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-15-hibernation
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-15-hibernation'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        # This is a more reliable method than "Test-Path" or "Get-ChildItem"
        [boolean]$Exists = ([System.IO.Directory]::EnumerateFiles("$env:SystemDrive\") -Contains "$env:SystemDrive\hiberfil.sys")
        If ($Exists -eq $true)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
            $result.data    = "$env:SystemDrive\hiberfil.sys"
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

    Return $result
}
