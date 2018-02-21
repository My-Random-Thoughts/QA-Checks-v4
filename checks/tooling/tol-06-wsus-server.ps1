<#
    DESCRIPTION: 
        Check that a WSUS server has been specified and that the correct port is open to the management server.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            WSUS server configured, port {port} open to {server}
        WARNING:
        FAIL:
            WSUS server configured, port {port} not open to {server}
            WSUS server has not been configured
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-IsPortOpen
#>

Function com-06-wsus-server
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'com-06-wsus-server'

    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$gItmP = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'WUServer' -ErrorAction SilentlyContinue).'WUServer'
        If ([string]::IsNullOrEmpty($gItmP) -eq $false)
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
            $result.data    = "$gItmP,#"

            $gItmP = $gItmP.Replace('http://', '').Replace('https://', '')
            If ($gItmP.Contains(':') -eq $true) { [string]$name = ($gItmP.Split(':')[0]); [string]$port = $gItmP.Split(':')[1] }
            Else {                                [string]$name =  $gItmP;                [string]$port = 80                   }

            [boolean]$portTest = (Check-IsPortOpen -DestinationServer $name -Port $port)
            If   ($portTest -eq $true) {                   $result.data += ($($script:lang['dt01']) -f $port, $name.ToLower()) }
            Else { $result.result = $script:lang['Fail'];  $result.data += ($($script:lang['dt02']) -f $port, $name.ToLower()) }
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
