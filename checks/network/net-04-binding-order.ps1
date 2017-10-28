<#
    DESCRIPTION: 
        Check binding order is set correctly for "Production" as the primary network adapter then as applicable for other interfaces.
        If no "Production" adapter is found, then "Management" should be first.

    REQUIRED-INPUTS:
        ManagementAdapterNames - "LIST" - Names or partial names of Management network adapters
        ProductionAdapterNames - "LIST" - Names or partial names of Production network adapters

    DEFAULT-VALUES:
        ManagementAdapterNames = @('Management', 'MGMT', 'MGT')
        ProductionAdapterNames = @('Production', 'PROD', 'PRD')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Binding order correctly set
        WARNING:
        FAIL:
            No network adapters found
            Production or management adapters not listed
            Binding order incorrect, {name} should be first
            Registry setting not found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function net-04-binding-order
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'net-04-binding-order'

    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$BindOrder = @()
        [System.Collections.ArrayList]$BindList  = @((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\TcpIp\Linkage' -Name 'Bind' -ErrorAction SilentlyContinue).'Bind')
        If ($BindList.Count -gt 0)
        {
            $BindList | ForEach-Object -Process {
                [string]$DeviceID = "{$($_.Split('{')[1])"
                [object]$gCIMi    = (Get-CimInstance -ClassName 'Win32_NetworkAdapter' -Filter "GUID='$DeviceID'" -Property 'NetConnectionID' -ErrorAction SilentlyContinue)

                If ([string]::IsNullOrEmpty($gCIMi) -eq $false)
                {
                    [void]$BindOrder.Add($($gCIMi.NetConnectionID))
                    $result.data     += "$($gCIMi.NetConnectionID),#"
                }
            }
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
            $result.data    = ''
            Return $result
        }

        [boolean]$prodExists = $false
        [boolean]$mgmtExists = $false

        If ($BindOrder.Count -eq 0)
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f002']
            $result.data    = ''
        }
        Else
        {
            # Check if 'Production' actually exists
            $script:chkValues['ProductionAdapterNames'] | ForEach-Object -Process {
                # Check if first binding is 'Production'
                If ($BindOrder[0] -like "$_*" )
                {
                    $prodExists     = $true
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p001']
                }
                ElseIf ($BindOrder -like "$_*")
                {
                    $prodExists     =    $true
                    $result.result  =    $script:lang['Fail']
                    $result.message = ($($script:lang['f003']) -f $script:chkValues['ProductionAdapterNames'][0])
                }
            }

            If ($prodExists -eq $false)
            {
                # No 'Production', check for 'Management'
                $script:chkValues['ManagementAdapterNames'] | ForEach-Object -Process {
                    # Check if first binding is 'Management'
                    If ($BindOrder[0] -like "$_*")
                    {
                        $mgmtExists     = $true
                        $result.result  = $script:lang['Pass']
                        $result.message = $script:lang['p001']
                    }
                    ElseIf ($BindOrder -like "$_*")
                    {
                        $mgmtExists     =    $true
                        $result.result  =    $script:lang['Fail']
                        $result.message = ($($script:lang['f003']) -f $script:chkValues['ManagementAdapterNames'][0])
                    }
                }
            }
        }

        If (($prodExists -eq $false) -and ($mgmtExists -eq $false))
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f002']
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
