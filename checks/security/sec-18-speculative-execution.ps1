<#
    DESCRIPTION: 
        Checks the Microsoft recommendations to help protect against speculative execution side-channel vulnerabilities
        Information taken from: https://support.microsoft.com/help/4072698

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All registry settings and patches are correct

        FAIL:
            One or more registry settings or patches are not correct

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-18-speculative-execution
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-18-speculative-execution'

    #... CHECK STARTS HERE ...#

    Try
    {
        # First check if the patch is installed
        [string]$checkOS = ((Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption').Caption)
        [string]$patch = ''

        If     ($checkOS -like '*2008 R2*') { $patch = 'KB4056897' }
        ElseIf ($checkOS -like '*2012 R2*') { $patch = 'KB4056898' }
        ElseIf ($checkOS -like '*2016*'   ) { $patch = 'KB4056890' }
        Else
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
            $Result.data    = $checkOS
            Return $result
        }

        [string]$patchInstalled = ''
        $session  = [activator]::CreateInstance([type]::GetTypeFromProgID('Microsoft.Update.Session'))
        $searcher = $session.CreateUpdateSearcher()
        $history  = $searcher.GetTotalHistoryCount()
        If ($history -gt 0) { $patchInstalled = ($searcher.QueryHistory(0, 99999999) | Where-Object { $_.Title -like "%$patch%" }) }
        If ([string]::IsNullOrEmpty($patchInstalled) -eq $true) { $result.data = 'Patch ' + $patch + ' (missing),#' }


        # Second check the known registry keys
        Try {
            [string]$gITMp1 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name 'FeatureSettingsOverride'            -ErrorAction Stop).FeatureSettingsOverride
            If ($gITMp1 -ne '0') { $result.data += "FeatureSettingsOverride ($($script:lang['dt02'])),#" }
        } Catch { $result.data += "FeatureSettingsOverride ($($script:lang['dt01'])),#" }

        Try {
            [string]$gITMp2 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name 'FeatureSettingsOverrideMask'        -ErrorAction Stop).FeatureSettingsOverrideMask
            If ($gITMp2 -ne '3') { $result.data += "FeatureSettingsOverrideMask ($($script:lang['dt02'])),#" }
        } Catch { $result.data += "FeatureSettingsOverrideMask ($($script:lang['dt01'])),#" }

        Try {
            [string]$gITMp3 = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization"        -Name 'MinVmVersionForCpuBasedMitigations' -ErrorAction Stop).MinVmVersionForCpuBasedMitigations
            If ($gITMp3 -ne '1.0') { $result.data += "MinVmVersionForCpuBasedMitigations ($($script:lang['dt02'])),#" }
        } Catch { $result.data += "MinVmVersionForCpuBasedMitigations ($($script:lang['dt01'])),#" }

        Try {
            [string]$gITMp4 = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\QualityCompat"            -Name 'cadca5fe-87d3-4b96-b7fb-a231484277cc' -ErrorAction Stop).'cadca5fe-87d3-4b96-b7fb-a231484277cc'
            If ($gITMp4 -ne '0') { $result.data += "QualityCompat ($($script:lang['dt02'])),#" }
        } Catch { $result.data += "QualityCompat ($($script:lang['dt01'])),#" }


        # Check the results
        If ([string]::IsNullOrEmpty($result.data) -eq $true)
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
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
