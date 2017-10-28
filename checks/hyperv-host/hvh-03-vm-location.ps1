<#
    DESCRIPTION: 
        Check all virtual machines are running from a non-system drive.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No virtual machines are using the system drive
        WARNING:
        FAIL:
            One or more virtual machines are using the system drive
        MANUAL:
        NA:
            Not a Hyper-V server
            No virtual machines exist on this host

    APPLIES:
        Hyper-V Host Servers

    REQUIRED-FUNCTIONS:
        Check-NameSpace
#>

Function hvh-03-vm-location
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'hvh-03-vm-location'
 
    #... CHECK STARTS HERE ...#

    If ((Check-NameSpace -NameSpace 'ROOT\Virtualization\v2') -eq $true)
    {
        Try
        {
            [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Msvm_ComputerSystem' -Filter 'Caption="Virtual Machine"' -Namespace 'ROOT\Virtualization\v2' -ErrorAction SilentlyContinue)
            $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items
            If ($gCIMi.Count -ne 0)
            {
                [string]$result.data = ''
                ForEach ($EachVM In $gCIMi)
                {
                    # Get VM Data
                    [object]  $VSSD =  (Get-CimInstance -ClassName 'Msvm_VirtualSystemSettingData'     -Filter "ConfigurationID =              '$($EachVM.Name)'"  -Namespace 'ROOT\Virtualization\v2' -ErrorAction SilentlyContinue)
                    [object[]]$SASD = @(Get-CimInstance -ClassName 'Msvm_StorageAllocationSettingData' -Filter      "InstanceID LIKE 'Microsoft:$($EachVM.Name)%'" -Namespace 'ROOT\Virtualization\v2' -ErrorAction SilentlyContinue)

                    # Check config location.  Either in "C:\ClusterStorage" or any drive other than "C:"
                    If ((-not $($VSSD.ConfigurationDataRoot).StartsWith("$env:SystemDrive\ClusterStorage\")) -and ($($VSSD.ConfigurationDataRoot) -eq $env:SystemDrive))
                    {
                        $result.data += ($($script:lang['dt01']) -f $VM.ElementName)
                    }

                    # Check hard disk location(s)
                    ForEach ($SA In ($SASD | Sort-Object))
                    {
                        [int]   $driveNum  = $(($SA.Parent).Split('\')[11])
                        [string]$drivePath = $SA.HostResource[$driveNum]
                        If ((-not ($drivePath.StartsWith("$env:SystemDrive\ClusterStorage\"))) -and (-not ($drivePath.ToLower()).EndsWith('.iso')))
                        {
                            $result.data += ($($script:lang['dt02']) -f $VM.ElementName, $SA.HostResource[$driveNum])
                        }
                    }
                }

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
