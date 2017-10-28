<#
    DESCRIPTION: 
        Check that all Windows 2012+ virtual machines are built as generation 2

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:    
            All virtual machines are the correct generation type
        WARNING:
        FAIL:
            One or more Windows 2012+ virtual machines are not set as generation 2
        MANUAL:
        NA:
            Not a Hyper-V server
            No virtual machines exist on this host

    APPLIES:
        Hyper-V Host Servers

    REQUIRED-FUNCTIONS:
        Check-NameSpace
#>

Function hvh-06-generation-type
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'hvh-06-generation-type'
 
    #... CHECK STARTS HERE ...#

    If ((Check-NameSpace -NameSpace 'ROOT\Virtualization\v2') -eq $true)
    {
        Try
        {
            [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Msvm_ComputerSystem' -Filter 'Caption="Virtual Machine"' -Namespace 'ROOT\Virtualization\v2' -ErrorAction SilentlyContinue)
            $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items

            If ($gCIMi.Count -ne 0)
            {
                # https://msdn.microsoft.com/en-us/library/hh850062(v=vs.85).aspx
                [object]$VSMS = (Get-WmiObject -ClassName 'Msvm_VirtualSystemManagementService' -Namespace 'ROOT\Virtualization\v2' -ErrorAction SilentlyContinue)
                [object]$GSI  = $VSMS.GetSummaryInformation($null, (1, 106, 135))    # 1: ElementName, 106: GuestOperatingSystem, 135: VirtualSystemSubType (Gen 1 or Gen2)

                $GSI.SummaryInformation | Sort-Object -Property 'ElementName' | ForEach-Object -Process {
                    If ($_.GuestOperatingSystem -like '*201*')    # 2012, 2016, ...
                    {
                        # Microsoft:Hyper-V:SubType:1
                        If (($_.VirtualSystemSubType).Split(':')[-1] -eq '1') { $result.data += "$($_.ElementName),#" }
                    }
                }

                If ($result.data -ne '')
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f001']
                }
                ELse
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p001']
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
