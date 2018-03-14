<#
    DESCRIPTION: 
        Checks to see if the default web page is present in IIS, it should be removed.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            "iisstart.htm" is not listed as a default document
        WARNING:
        FAIL:
            "iisstart.htm" is listed as a default document
        MANUAL:
            "IIS Management Scripts and Tools" are not installed
        NA:
            IIS is not installed

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-NameSpace
#>

Function sec-11-iis-default-page
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-11-iis-default-page'

    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$checkOS = ((Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption').Caption)
        If ($checkOS -like '*server*')
        {
            [object]$gWinFe1 = (Get-WindowsFeature -Name 'Web-Server')             # IIS Web Server
            [object]$gWinFe2 = (Get-WindowsFeature -Name 'Web-Scripting-Tools')    # IIS Management Scripts And Tools

            If ($gWinFe1.InstallState -eq 'Installed')
            {
                If ($gWinFe2.InstallState -eq 'Installed')
                {
                    [System.Collections.ArrayList]$gCIMi = @((Get-CimInstance -ClassName 'DefaultDocumentSection' -Namespace 'ROOT\WebAdministration' -Property 'Files' -ErrorAction SilentlyContinue).Files.Files.Value)
                    If ($gCIMi.Contains('iisstart.htm') -eq $true)
                    {
                        # Fail
                        $result.result  = $script:lang['Fail']
                        $result.message = $script:lang['f001']
                        $Result.data    = ($gCIMi -join ', ')
                    }
                    Else
                    {
                        # Pass
                        $result.result  = $script:lang['Pass']
                        $result.message = $script:lang['p001']
                    }
                }
                Else
                {
                    $result.result  = $script:lang['Manual']    # IIS installed,
                    $result.message = $script:lang['m001']      # but not the WMI
                    $result.data    = $script:lang['dt01']      # management tools
                }
            }
            Else
            {
                $result.result  = $script:lang['Not-Applicable']
                $result.message = $script:lang['n001']
            }
        }
        Else
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n002']
            $result.data    = $checkOS
            Return $result
        }
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = 'SCRIPT ERROR'
        $result.data    = $_.Exception.Message
    }

    Return $result
}
