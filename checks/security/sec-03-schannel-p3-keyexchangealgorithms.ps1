<#
    DESCRIPTION:
        Ensure key exchange algorithms are set correctly.  Settings taken from https://www.nartac.com/Products/IISCrypto/Default.aspx using "Best Practices/FIPS 140-2" settings.

    REQUIRED-INPUTS:
        KeyExchangeAlgorithms - "LIST" - Key Exchange Algorithms that should be used

    DEFAULT-VALUES:
        KeyExchangeAlgorithms = ('Diffie-Hellman', 'ECDH', 'PKCS')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All key exchange algorithms set correctly
        WARNING:
        FAIL:
            One or more key exchange algorithms set incorrectly
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-03-schannel-p3-keyexchangealgorithms
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-03-schannel-p3-keyexchangealgorithms'

    #... CHECK STARTS HERE ...#

    Try
    {
        $script:chkValues['KeyExchangeAlgorithms'] | Sort-Object | ForEach-Object -Process {
            Try {
                [string]$gITMp = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\$_" -Name 'Enabled' -ErrorAction Stop).Enabled
            } Catch { [string]$gITMp = 'M' }

            If     ($gITMp -eq '4294967295') {  }    # Set correctly
            ElseIf ($gITMp -eq 'M')          { $result.data += ($($script:lang['dt01']) -f $_.ToUpper()) }    # {0}: Missing entry, should be enabled
            Else                             { $result.data += ($($script:lang['dt02']) -f $_.ToUpper()) }    # {0}: Should be enbled
        }

        If ([string]::IsNullOrEmpty($result.data) -eq $true)
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
        }
        Else
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
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
