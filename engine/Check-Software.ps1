$script:chkValues['Win32_Product'] = 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
Function Check-Software ([string]$DisplayName)
{
    Try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
        $regKey = $reg.OpenSubKey($script:chkValues['Win32_Product'])
        If ($regKey) { [System.Collections.ArrayList]$keyVal = $regKey.GetSubKeyNames() } }
    Catch { Return '-1' }

    If (($regKey) -and ($keyVal.Count -gt 0)) { ForEach ($app In $keyVal) {
            $appKey = $regKey.OpenSubKey($app).GetValue('DisplayName')
            If ($appKey -like ("*$DisplayName*")) {
                [psobject]$verCheck = (New-Object -TypeName 'PSObject' -Property @{'DisplayName' = $($regKey.OpenSubKey($app).GetValue('DisplayName'));
                'Version' = $($regKey.OpenSubKey($app).GetValue('DisplayVersion'))}); Return $verCheck } }
        If ($script:chkValues['Win32_Product'] -like '*Wow6432Node*') {
            $script:chkValues['Win32_Product'] = $script:chkValues['Win32_Product'].Replace('Wow6432Node\', '')
            $verCheck = (Check-Software -DisplayName $DisplayName) } Else { $verCheck = $null } }
    Else { $verCheck = $null }
    Try { $regKey.Close() } Catch { }
    $reg.Close()
    Return $verCheck
}
