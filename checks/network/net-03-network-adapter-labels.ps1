<#
    DESCRIPTION: 
        Check network interfaces are labelled so their purpose is easily identifiable.  FAIL if any adapter names are "Local Area Connection x" or "Ethernet x".

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All adapters renamed from default
        WARNING:
        FAIL:
            An adapter was found with the default name
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-03-network-adapter-labels
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-03-network-adapter-labels'

    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$filter = "NetConnectionStatus='2' AND (NetConnectionID LIKE 'Ethernet%' OR NetConnectionID LIKE 'Local Area Connection%')"
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter $filter -Property 'NetConnectionID' -ErrorAction SilentlyContinue)

        If ($gCIMi.Count -gt 0)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
            $gCIMi | Sort-Object -Property 'NetConnectionID' | ForEach-Object -Process { $result.data += "$($_.NetConnectionID),#" }
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
