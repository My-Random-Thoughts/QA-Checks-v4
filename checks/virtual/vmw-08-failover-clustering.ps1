<#
    DESCRIPTION: 
        Check that Failover Clustering is not be installed on virtual servers.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            Failover clustering is not installed
        WARNING:
        FAIL:
            Failover clustering is installed
        MANUAL:
        NA:
            Not a virtual server

    APPLIES:
        Virtual Servers

    REQUIRED-FUNCTIONS:
        Check-IsHyperVGuest
        Check-IsVMwareGuest
#>

Function vmw-08-failover-clustering
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'vmw-08-failover-clustering'
 
    #... CHECK STARTS HERE ...#

    If (((Check-IsHyperVGuest) -eq $true) -or ((Check-IsVMwareGuest) -eq $true))
    {
        Try
        {
            [string]$checkOS = ((Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption').Caption)
            If ($checkOS -like '*server*')
            {
                Import-Module -Name 'ServerManager'          # Universal Name (not language specific DisplayName)
                [object]$gWinFe = (Get-WindowsFeature -Name 'Failover-Clustering')
            }
            Else
            {
                $result.result  = $script:lang['Not-Applicable']
                $result.message = $script:lang['n002']
                $result.data    = $checkOS
                Return $result
            }

            If (($gWinFe.Installed -eq 'True') -or ($gWinFe.InstallState -eq 'Installed'))
            {
                [string]$ClusterName = $script:lang['dt01']
                Try {   $ClusterName = ((Get-Cluster -ErrorAction SilentlyContinue).Name) } Catch {}

                $result.result  =    $script:lang['Fail']
                $result.message =    $script:lang['f001']
                $result.data    = ($($script:lang['dt02']) -f $ClusterName)
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
    }
    Else
    {
        $result.result  = $script:lang['Not-Applicable']
        $result.message = $script:lang['n001']
    }

    Return $result
}
