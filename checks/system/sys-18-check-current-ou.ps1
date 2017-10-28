<#
    DESCRIPTION: 
        Check that the current server OU path is not in the default location(s).  The list of OUs should contain at least the default "Computers" OU, and must be the full distinguished name of the locations.

    REQUIRED-INPUTS:
        NoInTheseOUs - "LIST" - Full distinguished OU names (minus domain) that the servers should not be located in.

    DEFAULT-VALUES:
        NoInTheseOUs = @('cn=Computers', 'ou=Quarantine')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Server not in default location
        WARNING:
            This is a work group server, is this correct.?
        FAIL:
            Server is in default location
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-18-check-current-ou
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-18-check-current-ou'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$domCheck = (Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property ('Domain', 'PartOfDomain'))
        If ($domCheck.PartOfDomain -eq $true)
        {
            [object]$gITMp = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine' -Name 'Distinguished-Name' -ErrorAction SilentlyContinue)
            If ([string]::IsNullOrEmpty($gITMp) -eq $false)
            {
                [string]$strPath   = ($gITMp.'Distinguished-Name').ToLower()
                        $strPath   = ($strPath -split  "cn=$($env:ComputerName.ToLower()),")[1]    # Remove Computer Name
                [string]$CurrentOU = ($strPath -split ',dc=')[0]                                   # Remove Domain Name
            }

            $script:chkValues['NoInTheseOUs'] | ForEach-Object -Process {
                If ($CurrentOU -like "*$_*")
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f001']
                }
            }

            If ([string]::IsNullOrEmpty($result.message) -eq $true)
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }

            [regex]$match = ',dc='
            $result.data  = ($match.Replace($strPath, ',#dc=', 1))            
        }
        Else
        {
            $result.result  =    $script:lang['Warning']
            $result.message =    $script:lang['w001']
            $result.data    = ($($script:lang['dt02']) -f (($domCheck.Domain -split '\.')[0]))
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
