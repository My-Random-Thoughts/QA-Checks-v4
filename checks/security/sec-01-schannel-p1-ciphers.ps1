<#
    DESCRIPTION: 
        Ensure security ciphers are set correctly.  Settings taken from https://www.nartac.com/Products/IISCrypto/Default.aspx using "Best Practices/FIPS 140-2" settings.

    REQUIRED-INPUTS:
        DisabledCiphers - "LIST" - Ciphers that should be disabled
        EnabledCiphers  - "LIST" - Ciphers that should be enabled

    DEFAULT-VALUES:
        DisabledCiphers = ('DES 56/56', 'NULL', 'RC2 128/128', 'RC2 40/128', 'RC2 56/128', 'RC2 56/56', 'RC4 128/128', 'RC4 40/128', 'RC4 56/128', 'RC4 64/128')
        EnabledCiphers  = ('AES 128/128', 'AES 256/256', 'Triple DES 168/168')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All ciphers set correctly
        WARNING:
        FAIL:
            One or more ciphers set incorrectly
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-01-schannel-p1-ciphers
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-01-schannel-p1-ciphers'

    #... CHECK STARTS HERE ...#

    Try
    {
        # Check DISABLED
        $script:chkValues['DisabledCiphers'] | Sort-Object | ForEach-Object -Process {
            Try {
                [string]$gITMp = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\$_" -Name 'Enabled' -ErrorAction Stop).Enabled
            } Catch { [string]$gITMp = 'M' }

            If     ($gITMp -eq '0') {  }    # Set correctly
            ElseIf ($gITMp -eq 'M') { $result.data += ($($script:lang['dt01']) -f $_.ToUpper()) }    # {0}: Missing entry, should be disabled
            Else                    { $result.data += ($($script:lang['dt02']) -f $_.ToUpper()) }    # {0}: Should be diabled
        }

        # Check ENABLED
        $script:chkValues['EnabledCiphers'] | Sort-Object | ForEach-Object -Process {
            Try {
                [string]$gITMp = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\$_" -Name 'Enabled' -ErrorAction Stop).Enabled
            } Catch { [string]$gITMp = 'M' }

            If     ($gITMp -eq '4294967295') {  }    # Set correctly, or not set
            ElseIf ($gITMp -eq 'M')          {  }    # Ignore, we don't mind if this is missing
            Else                             { $result.data += ($($script:lang['dt03']) -f $_.ToUpper()) }    # {0}: Should be enabled
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
