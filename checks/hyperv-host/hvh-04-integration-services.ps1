<#
    DESCRIPTION:
        Check the version of the Integration Services installed on all virtual machines

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:    
            All VMs are up to date
        WARNING:
        FAIL:
            One or more virtual machines are not up to date, or do not have the integration services installed
        MANUAL:
        NA:
            Not a Hyper-V server
            No virtual machines exist on this host

    APPLIES:
        Hyper-V Host Servers

    REQUIRED-FUNCTIONS:
        Check-NameSpace
#>

Function hvh-04-integration-services
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'hvh-04-integration-services'
 
    #... CHECK STARTS HERE ...#

    If ((Check-NameSpace -NameSpace 'ROOT\Virtualization\v2') -eq $true)
    {
        Try
        {
            # https://msdn.microsoft.com/en-us/library/hh850062(v=vs.85).aspx
            [object]$VSMS = (Get-WmiObject -ClassName 'Msvm_VirtualSystemManagementService' -Namespace 'ROOT\Virtualization\v2' -ErrorAction SilentlyContinue)
            [object]$GSI  = $VSMS.GetSummaryInformation($null, (1, 123))    # 1: ElementName, 123: IntegrationServicesVersionState

            If ([string]::IsNullOrEmpty($GSI.SummaryInformation) -eq $false)
            {
                $GSI.SummaryInformation | Sort-Object -Property 'ElementName' | ForEach-Object -Process {
                    Switch ($_.IntegrationServicesVersionState)
                    {
                        '1'     { $result.data +=  ''                                    }    # Up To Date
                        '2'     { $result.data += ($($script:lang['dt01']) -f 'REPLACE') }    # Out Of Date
                        Default { $result.data += ($($script:lang['dt02']) -f 'REPLACE') }    # Unknown
                    }
                    $result.data = ($result.data).Replace('REPLACE', $_.ElementName)

                    If ($result.data -ne '')
                    {
                        $result.result  = $script:lang['Fail']
                        $result.message = $script:lang['f001']
                    }
                    Else
                    {
                        $result.result  = $script:lang['Pass']
                        $result.message = $script:lang['p001']
                    }
                }
            }
            Else
            {
                $result.result  = $script:lang['Not-Applicable']
                $result.message = $script:lang['n002']
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
