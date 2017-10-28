<#
    DESCRIPTION: 
        Allows you to checks a specific list of registry keys and values to see if your in-house gold image was used.
        Up to nine registry keys and values can be checked - You must edit the settings file manually for more than the currently configured.
        Note: All keys must be in HKEY_LOCAL_MACHINE hive only.

    REQUIRED-INPUTS:
        Key01   - "LARGE" - Full path and name of a registry value to check.  "HKLM:\" is added automatically
        Key02   - "LARGE" - Full path and name of a registry value to check.  "HKLM:\" is added automatically
        Key03   - "LARGE" - Full path and name of a registry value to check.  "HKLM:\" is added automatically
        Value01 - String value required for the registry entry.  Enter "ReportOnly" to just report the value
        Value02 - String value required for the registry entry.  Enter "ReportOnly" to just report the value
        Value03 - String value required for the registry entry.  Enter "ReportOnly" to just report the value

    DEFAULT-VALUES:
        Key01   = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\InstallDate'
        Key02   = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRoot'
        Key03   = ''
        Value01 = 'ReportOnly'
        Value02 = 'c:\windows'
        Value03 = ''

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All gold build checks were found and correct
        WARNING:
        FAIL:
            One or more gold build checks were below specified value
        MANUAL:
            One or more gold build checks were "Report Only"
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-21-gold-image
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-21-gold-image'

    #... CHECK STARTS HERE ...#

    Try
    {
        1..9 |  ForEach-Object -Process {
            [string]$Num = ($_.ToString().PadLeft(2, '0'))
            If ($script:chkValues["Key$Num"].Length -gt 0)
            {
                [string]$regPath = (Split-Path -Path $script:chkValues["Key$Num"] -Parent)
                [string]$regKey  = (Split-Path -Path $script:chkValues["Key$Num"] -Leaf  )

                [object]$gITMp = (Get-ItemProperty -Path "HKLM:\$regPath" -Name $regKey -ErrorAction SilentlyContinue)
                If ([string]::IsNullOrEmpty($gITMp) -eq $false)
                {
                    [string]$regValue = $($gITMp.$regKey)

                    # Check to see if it's a date we can convert (will be in localalised format)
                    If ($regKey.ToLower().Contains('date')) { If ($regValue   -eq ([System.Convert]::ToInt64($regValue))) {
                            $regValue = ((Get-Date -Date '01/01/1970').AddSeconds(([System.Convert]::ToInt64($regValue))))
                        }
                    }

                    # Build output data
                    $result.data += ("$($Num): ({0}) {1}: {2},#" -f '-ReplaceMe-', $regKey, $regValue)

                    If ($script:chkValues["Value$Num"] -eq 'ReportOnly') {
                        $result.data = ($result.data.Replace('-ReplaceMe-', $script:lang['dt01']))
                    } Else {
                        If (($regValue -as [string]) -eq ($script:chkValues["Value$Num"] -as [string])) {
                            $result.data = ($result.data.Replace('-ReplaceMe-', $script:lang['Pass'])) } Else {
                            $result.data = ($result.data.Replace('-ReplaceMe-', $script:lang['Fail']))
                        }
                    }
                }
            }
        }

        If ([string]::IsNullOrEmpty($result.data) -eq $true)
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
        }
        Else
        {
            If ($result.data.Contains(": ($($script:lang['Pass']))")) { $result.result = $script:lang['Pass']  ; $result.message = $script:lang['p001'] }
            If ($result.data.Contains(": ($($script:lang['dt01']))")) { $result.result = $script:lang['Manual']; $result.message = $script:lang['m001'] }
            If ($result.data.Contains(": ($($script:lang['Fail']))")) { $result.result = $script:lang['Fail']  ; $result.message = $script:lang['f001'] }
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
