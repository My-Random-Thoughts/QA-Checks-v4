<#
    DESCRIPTION: 
        Check there are no DHCP enabled network interfaces on the server. All NICs should have a statically assigned IP address.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No DHCP enabled adapters found
        WARNING:
        FAIL:
            DHCP enabled adapters found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-02-dhcp-enabled-adapters
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-02-dhcp-enabled-adapters'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled='TRUE' AND DHCPEnabled='TRUE'" -ErrorAction SilentlyContinue)
        If ($gCIMi.Count -gt 0)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
            $gCIMi | Sort-Object | ForEach-Object -Process {
                [string]$nConId = (Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter "Index='$($_.Index)'" -Property 'NetConnectionID' -ErrorAction SilentlyContinue).NetConnectionID
                $result.data += "$nConId,#"
            }
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
