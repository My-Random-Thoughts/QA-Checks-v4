<#
    DESCRIPTION: 
        Ensure the security cipher order is set correctly.  Settings taken from https://www.nartac.com/Products/IISCrypto/Default.aspx using "Best Practices/FIPS 140-2" settings.
        Group Policy Location: Computer > Policies > Administrative Templates > Network > SSL Configuration Settings > SSL Cipher Suite Order

    REQUIRED-INPUTS:
        CipherSuiteOrder - "LARGE" - Single comma separated string list of cipher suites in the order that they should be used in

    DEFAULT-VALUES:
        CipherSuiteOrder = 'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P521,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P521,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P521,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P521,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P256,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_3DES_EDE_CBC_SHA'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Cipher suite order set correctly
        WARNING:
        FAIL:
            Cipher suite order not set correctly
            Cipher suite order set to the default value
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sec-05-schannel-p5-cipher-order
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sec-05-schannel-p5-cipher-order'

    #... CHECK STARTS HERE ...#

    Try
    {
        Try {
            [string]$gITMp = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -Name 'Functions' -ErrorAction Stop).Functions
        } Catch { [string]$gITMp = 'M' }

        If ($gITMp -eq 'M')
        {
            $result.result  = $script:lang['Fail']
            $result.message = $script:lang['f001']
        }
        Else
        {
            # Remove spaces and lowercase everything
            $gITMp = ($gITMp.Replace(' ', '').ToLower())
            $script:chkValues['CipherSuiteOrder'] = ($script:chkValues['CipherSuiteOrder'].Replace(' ', '').ToLower())

            If ($gITMp -eq $script:chkValues['CipherSuiteOrder'])
            {
                $result.result  = $script:lang['Pass']
                $result.message = $script:lang['p001']
            }
            Else
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f002']
                $Result.data    = $gITMp.Replace(',', ',#')
            }
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
