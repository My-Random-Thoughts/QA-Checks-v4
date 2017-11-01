<#
    DESCRIPTION: 
        Ensure protocols are set correctly.  Settings taken from https://www.nartac.com/Products/IISCrypto/Default.aspx using "Best Practices/FIPS 140-2" settings.

    REQUIRED-INPUTS:
        DisabledProtocols - "LIST" - Protocols that should be disabled

    DEFAULT-VALUES:
        DisabledProtocols = ('Multi-Protocol Unified Hello', 'PCT 1.0', 'SSL 2.0', 'SSL 3.0', 'TLS 1.0', 'TLS 1.1')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All protocols set correctly
        WARNING:
        FAIL:
            One or more protocols set incorrectly
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-04-schannel-p4-protocols
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-04-schannel-p4-protocols'

    #... CHECK STARTS HERE ...#

    Try
    {
        $script:chkValues['DisabledProtocols'] | Sort-Object | ForEach-Object -Process {
            If ((Test-Path -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$_") -eq $false) {
                $result.data += ($($script:lang['dt03']) -f $_.ToUpper())    # {0}: Key missing
            }
            Else {
                Try {
                    [string]$gITMp1 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$_\Server" -Name 'Enabled'           -ErrorAction Stop).Enabled
                } Catch { [string]$gITMp1 = 'M' }
                Try {
                    [string]$gITMp2 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$_\Client" -Name 'DisabledByDefault' -ErrorAction Stop).DisabledByDefault
                } Catch { [string]$gITMp2 = 'M' }


                If     ($gITMp1 -eq '0') {  }    # Set correctly
                ElseIf ($gITMp1 -eq 'M') { $result.data += ($($script:lang['dt01']) -f "$($_.ToUpper())\Server") }    # {0}: Missing entry, should be disabled
                Else                     { $result.data += ($($script:lang['dt02']) -f "$($_.ToUpper())\Client") }    # {0}: Should be diabled

                If     ($gITMp2 -eq '1') {  }    # Set correctly
                ElseIf ($gITMp1 -eq 'M') { $result.data += ($($script:lang['dt01']) -f "$($_.ToUpper())\Server") }    # {0}: Missing entry, should be disabled
                Else                     { $result.data += ($($script:lang['dt02']) -f "$($_.ToUpper())\Client") }    # {0}: Should be diabled
            }
        }

        If ([string]::IsNullOrEmpty($result.data) -eq $true)
        {
            $result.result  = $script:lang['Pass']
            $result.message = 'All protocols set correctly'
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = 'One or more protocols set incorrectly'
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
