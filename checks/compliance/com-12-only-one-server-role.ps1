<#
    DESCRIPTION: 
        Check that only one server role or feature is installed

    REQUIRED-INPUTS:
        IgnoreTheseRoles - "LIST" - Additional roles that can be ignored (Use the short name, not the display name)

    DEFAULT-VALUES:
        IgnoreTheseRoles = @('')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            One extra server role or feature installed
        WARNING:
        FAIL:
            One or more extra server roles or features installed
        MANUAL:
        NA:
            No extra server roles or features installed

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function com-12-only-one-server-role
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'com-12-only-one-server-role'
 
    #... CHECK STARTS HERE ...#

    Try
    {
        If ((Check-IsDomainController) -eq $false)
        {
            [string]$checkOS = (Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'Caption')
            If ($checkOS -like '*server*')
            {
                Import-Module -Name 'ServerManager'                                                                   # Windows 2008                 Windows 2012+
                [System.Collections.ArrayList]$gWinFe  = @(Get-WindowsFeature | Where-Object { ($_.Depth -eq 1) -and (($_.Installed -eq $true) -or ($_.InstallState -eq 'Installed')) } -ErrorAction Stop | Select-Object 'Name', 'DisplayName')
                [System.Collections.ArrayList]$gWinFeC = $gWinFe.Clone()

                # These are installed by default on all 2008 R2 and above servers and can be ignored
                [System.Collections.ArrayList]$ignoreList =  ('NET-Framework-Features', 'NET-Framework', 'NET-Framework-45-Features', 'FileAndStorage-Services', 'Multipath-IO', 'RSAT', 'FS-SMB1',
                                                              'Telnet-Client', 'User-Interfaces-Infra', 'PowerShellRoot', 'PowerShell-ISE', 'Windows-Defender-Features', 'WoW64-Support')

                $ignoreList                             | ForEach-Object -Process { [string]$LookingFor = $_; $gWinFe | ForEach-Object -Process { If ($_.Name -eq $LookingFor) { [void]$gWinFeC.Remove($_) } } }
                $script:chkValues['IgnoreTheseRoles'] | ForEach-Object -Process { [string]$LookingFor = $_; $gWinFe | ForEach-Object -Process { If ($_.Name -eq $LookingFor) { [void]$gWinFeC.Remove($_) } } }
            }
            Else
            {
                $result.result  = $script:lang['Not-Applicable']
                $result.message = $script:lang['n001']
                $result.data    = $checkOS
                Return $result
            }
        }
        Else
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n002']
            $result.data    = $checkOS
            Return $result
        }

        If ($gWinFeC.Count -eq 0)
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        ElseIf ($gWinFeC.Count -eq 1)
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p002']
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }

        $gWinFeC | Sort-Object -Property 'DisplayName' | ForEach-Object -Process { $result.data += "$($_.DisplayName),#" }
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
    }

    Return $result
}
