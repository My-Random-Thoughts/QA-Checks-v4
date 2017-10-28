<#
    DESCRIPTION: 
        Ensure SMBv1 is disabled.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            SMBv1 is disabled
        WARNING:
        FAIL:
            SMBv1 is enabled
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-17-smb1-disabled
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-17-smb1-disabled'

    #... CHECK STARTS HERE ...#

    Try
    {
        [object]$gITMp1 =  (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'SMB1'            -ErrorAction SilentlyContinue)    #: 0
        [object]$gITMp2 = @(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation'       -Name 'DependOnService' -ErrorAction SilentlyContinue)    #: Bowser, MRxSmb20, NSI
        [object]$gITMp3 =  (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10'                -Name 'Start'           -ErrorAction SilentlyContinue)    #: 4

        [int]$validCount = 0
        If ([string]::IsNullOrEmpty($gITMp1) -eq $false) {
            If ($gITMp1.SMB1 -eq '0') { $validCount++ } Else { $result.data += 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters\SMB1,#' }
        }

        If ([string]::IsNullOrEmpty($gITMp2) -eq $false) {
            [string]$DOS = ($gITMp2.DependOnService -join ',')
            If ($DOS -eq 'Bowser,MRxSmb20,NSI') { $validCount++ } Else { $result.data += 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\DependOnService,#' }
        }

        If ([string]::IsNullOrEmpty($gITMp3) -eq $false) {
            If ($gITMp3.Start -eq '4') { $validCount++ } Else { $result.data += 'HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10\Start' }
        }

        If ($validCount -eq 3)
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
            $result.data    = $script:lang['dt01'] + $result.data
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
