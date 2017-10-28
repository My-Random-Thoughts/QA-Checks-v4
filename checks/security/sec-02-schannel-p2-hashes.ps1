<#
    DESCRIPTION: 
        Ensure hashes are set correctly.  Settings taken from https://www.nartac.com/Products/IISCrypto/Default.aspx using "Best Practices/FIPS 140-2" settings.

    REQUIRED-INPUTS:
        DisabledHashes - "LIST" - Hashes that should be disabled
        EnabledHashes  - "LIST" - Hashes that should be enabled

    DEFAULT-VALUES:
        DisabledHashes = ('MD5')
        EnabledHashes  = ('SHA', 'SHA256', 'SHA384', 'SHA512')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All hashes set correctly
        WARNING:
        FAIL:
            One or more hashes set incorrectly
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-02-schannel-p2-hashes
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-02-schannel-p2-hashes'

    #... CHECK STARTS HERE ...#

    Try
    {
        # Check DISABLED
        $script:chkValues['DisabledHashes'] | Sort-Object | ForEach-Object -Process {
            Try {
                [string]$gITMp = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\$_" -Name 'Enabled' -ErrorAction Stop).Enabled
            } Catch { [string]$gITMp = 'M' }

            If     ($gITMp -eq '0') {  }    # Set correctly
            ElseIf ($gITMp -eq 'M') { $result.data += ($($script:lang['dt01']) -f $_.ToUpper()) }    # {0}: Missing entry, should be disabled
            Else                    { $result.data += ($($script:lang['dt02']) -f $_.ToUpper()) }    # {0}: Should be diabled
        }

        # Check ENABLED
        $script:chkValues['EnabledHashes'] | Sort-Object | ForEach-Object -Process {
            Try {
                [string]$gITMp = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\$_" -Name 'Enabled' -ErrorAction Stop).Enabled
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
