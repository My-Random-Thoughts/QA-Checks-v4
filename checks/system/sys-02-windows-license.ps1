<#
    DESCRIPTION: 
        Check windows is licensed.

    REQUIRED-INPUTS:
        None

    DEFAULT-VALUES:
        None

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Windows is licenced, Port 1688 open to KMS Server {server}
        WARNING:
        FAIL:
            Windows is licenced, Port 1688 not open to KMS Server {server}
            Windows licence check failed
            Windows not licensed
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        Check-IsPortOpen
#>

Function sys-02-windows-license
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-02-windows-license'
    
    #... CHECK STARTS HERE ...#

    Try
    {
        # Keys from: https://technet.microsoft.com/library/jj612867%28v=ws.11%29.aspx
        [System.Collections.ArrayList]$KMSKeys = @('8XDDG','KHKQY','4M63B',                                            # Server 2016
                                                   'MDVJX','Q3VJ9','M4FWM',                                            # Server 2012 R2
                                                   '27GG4','GVGGY','84YXQ','DYFKP','92BT4','CYQJJ','QGJ2G','8W83P',    # Server 2012
                                                   '6RTM4','9QCTX','R7VHC','CPX3Y','7M648',                            # Server 2008 R2
                                                   'BFGM2','6FFFJ','X4Q6V','G3FPG','6X7HP','TCBY3','G3QQC')            # Server 2008

        If ((Get-CimClass -ClassName 'SoftwareLicensingProduct' -ErrorAction Stop).CimClassName -eq 'SoftwareLicensingProduct') {
            [object[]]$gCIMi1 = @(Get-CimInstance -ClassName 'SoftwareLicensingProduct' -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND NOT LicenseStatus='0'" -Property ('LicenseStatus', 'PartialProductKey') -ErrorAction SilentlyContinue)
        }

        If ((Get-CimClass -ClassName 'SoftwareLicensingService' -ErrorAction Stop).CimClassName -eq 'SoftwareLicensingService') {
            [object]$gCIMi2 = (Get-CimInstance -ClassName 'SoftwareLicensingService' -Property ('KeyManagementServiceMachine', 'DiscoveredKeyManagementServiceMachineName') -ErrorAction SilentlyContinue)
        }

        [string]$kms    = ''
        [string]$status = ''
        If ($gCIMi1.Count -gt 0)
        {
            Switch ($gCIMi1[0].LicenseStatus)
            {
                      1 { $status = $script:lang['dt01']; Break }
                      2 { $status = $script:lang['dt02']; Break }
                      3 { $status = $script:lang['dt03']; Break }
                      4 { $status = $script:lang['dt04']; Break }
                      5 { $status = $script:lang['dt05']; Break }
                      6 { $status = $script:lang['dt06']; Break }
                Default { $status = $script:lang['dt07']        }
            }
        }
        Else { $status = $script:lang['dt07'] }

        If ($gCIMi2.DiscoveredKeyManagementServiceMachineName -ne '') { $kms = $gCIMi2.DiscoveredKeyManagementServiceMachineName }
        If ($gCIMi2.KeyManagementServiceMachine               -ne '') { $kms = $gCIMi2.KeyManagementServiceMachine               }

        If ($kms -ne '')
        {
            [boolean]$portTest = Check-IsPortOpen -DestinationServer $kms -Port 1688
            If ($portTest -eq $true)
            {
                $result.result =    $script:lang['Pass']
                $result.data   = ($($script:lang['p001']) -f $kms.ToLower())
            }
            Else
            {
                $result.result =    $script:lang['Fail']
                $result.data   = ($($script:lang['p001']) -f $kms.ToLower())
            }
        }
        Else
        {
            $result.result = $script:lang['Warning']
            $result.data   = $script:lang['dt08']

            If ($KMSKeys.Contains($($gCIMi1[0].PartialProductKey)) -eq $true) {
                $result.data += ($script:lang['dt11'] + ' https://technet.microsoft.com/library/jj612867%28v=ws.11%29.aspx')
            }   #                                        ^ Note the space
        }

        If ($status -eq $script:lang['dt01'])
        {
            $result.message = $script:lang['dt09']
        }
        ElseIf ($status -eq '')
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f002']
        }
        Else
        {
            $result.result  =    $script:lang['Fail']
            $result.message =    $script:lang['f003']
            $result.data    = ($($script:lang['dt10']) -f $status, $result.data)
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
