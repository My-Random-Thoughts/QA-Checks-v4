<#
    DESCRIPTION: 
        Check that all serivce paths containing spaces are enclosed in quotes.  This is covered under CVE-2013-1609: https://www.cvedetails.com/cve/CVE-2013-1609/ 
        !nUsing code taken from http://www.ryanandjeffshow.com/blog/2013/04/11/powershell-fixing-unquoted-service-paths-complete/

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All servies are set correctly
        WARNING:
            One or more services have unquoted paths
        FAIL:
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-19-unquoted-service-paths
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-19-unquoted-service-paths'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_Service' -Property ('DisplayName', 'PathName') -ErrorAction SilentlyContinue)

        If ($gCIMi.Count -gt 0)
        {
            $gCIMi | Sort-Object -Property 'DisplayName' | ForEach-Object -Process {
                [string] $path    = $_.PathName
                [boolean]$badPath = $true

                If (($path.StartsWith('"') -eq $false) -and ($path.StartsWith('\??') -eq $false) -and ($path.Contains(' ')))
                {
                    If (($path.Contains(' -') -eq $true) -or ($path.Contains(' /') -eq $true))
                    {
                        [string[]]$splitPath = $path         -split ' -', 0, 'SimpleMatch'
                                  $splitPath = $splitPath[0] -split ' /', 0, 'SimpleMatch'
                        [string]  $newPath   = $splitPath[0].Trim(' ')

                        If ($newPath.Contains(' ') -eq $true)
                        {
                            $badPath = $true
                        }
                        Else
                        {
                            $badPath = $false
                        }
                    }
                    Else
                    {
                        $badPath = $true
                    }
                }
                Else
                {
                    $badPath = $false
                }

                If ($badPath -eq $true)
                {
                    $result.result   = $script:lang['Fail']
                    $result.message  = $script:lang['f001']
                    $result.data    += "$($_.DisplayName),#"
                }
            }
        }

        If ($result.message -eq '')
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
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
