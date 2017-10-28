<#
    DESCRIPTION:
        Check all virtual machines are using VHDX disks if the host is Windows 2012 or above

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All virtual machines are using VHDX disks
        WARNING:
        FAIL:
            One or more virtual machines are not using VHDX disks
        MANUAL:
        NA:
            Not a Hyper-V server
            No virtual machines exist on this host

    APPLIES:
        Hyper-V Host Servers

    REQUIRED-FUNCTIONS:
        Check-NameSpace
#>

Function hvh-07-vhdx-disks
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'hvh-07-vhdx-disks'
 
    #... CHECK STARTS HERE ...#

    If ((Check-NameSpace -NameSpace 'ROOT\Virtualization\v2') -eq $true)
    {
        Try
        {
            [string]$checkOS = ((Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption').Caption)
            If ($checkOS -like '*201*')    # 2012, 2016
            {
                [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Msvm_ComputerSystem' -Filter 'Caption="Virtual Machine"' -Namespace 'ROOT\Virtualization\v2' -ErrorAction SilentlyContinue)
                $gCIMi = @($gCIMi | Where-Object { $_ })    # Remove any empty items
                If ($gCIMi.Count -ne 0)
                {
                    # Try to load Hyper-V module...
                    If ((Get-Module -ListAvailable -Name 'Hyper-V' -ErrorAction SilentlyContinue) -eq $null) { Throw 'Hyper-V module not found' }
                    Import-Module -Name 'Hyper-V' -WarningAction SilentlyContinue -WarningVariable null

                    Get-VM | Sort-Object -Property 'Name' | ForEach-Object -Process {
                        [string]  $vmName  =  ($_.Name)                                                #            NOT Equal
                        [object[]]$vmDisks = @((Get-VHD -VMId $($_.VMID)) | Where-Object -FilterScript { $_.VhdFormat -ne 'VHDX' })

                        If ($vmDisks.Count -gt 0)
                        {
                            $result.result  = $script:lang['Fail']
                            $result.message = $script:lang['f001']
                            $vmDisks | ForEach-Object -Process { $result.data += "$($vmName): $($_.Path),#" }
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
            Else
            {
                $result.result  = $script:lang['Not-Applicable']
                $result.message = $script:lang['n003']
                $Result.data    = $checkOS
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
