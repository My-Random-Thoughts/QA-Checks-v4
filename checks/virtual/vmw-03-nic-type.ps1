<#
    DESCRIPTION: 
        Check all virtual servers have network cards that are configured as VMXNET3.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All active NICS configured correctly
        WARNING:
        FAIL:
            No network adapters found
            One or more active NICs were found not to be VMXNET3
        MANUAL:
        NA:
            Not a virtual machine

    APPLIES:
        Virtual Servers

    REQUIRED-FUNCTIONS:
        Check-IsVMwareGuest
#>

Function vmw-03-nic-type
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'vmw-03-nic-type'
    
    #... CHECK STARTS HERE ...#

    If ((Check-IsVMwareGuest) -eq $true)
    {
        Try
        {
            [System.Collections.ArrayList]$gCIMi = @((Get-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled='True'" -Property 'Description' -ErrorAction SilentlyContinue).Description)
            $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

            If ($gCIMi.Count -eq 0)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
            Else
            {
                $gCIMi | Sort-Object | ForEach-Object -Process {
                    If ($_ -notlike ('*VMXNET3*')) { $result.data += "$_,#" }
                }

                If ([string]::IsNullOrEmpty($result.data) -eq $false)
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f002']
                }
                Else
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p001']
                }
            }
        }
        Catch
        {
            $result.result  = $script:lang['Error']
            $result.message = $script:lang['Script-Error']
            $result.data    = $_.Exception.Message
        }
    }
    Else
    {
        $result.result  = $script:lang['Not-Applicable']
        $result.message = $script:lang['n001']
    }

    Return $result
}
