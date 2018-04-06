<#
    DESCRIPTION: 
        Allows you to search for a specific file and fails on the result.
        Note, depending on the number of files on the server, this check may have a high chance of timing out.

    REQUIRED-INPUTS:
        FileName    - Name of the file to search for (do not inclue any paths).  Wildcards are not supported.
        FailOnFound - "True|False" - If the file is found, should the check return a fail result

    DEFAULT-VALUES:
        FileName    = 'should-not-exist.txt'
        FailOnFound = 'True'

    DEFAULT-STATE:
        Disabled

    RESULTS:
        PASS:
            One or more matching files were found
            No matching files were found
        WARNING:
        FAIL:
            One or more matching files were found
            No matching files were found
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-24-search-for-a-file
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-24-search-for-a-file'

    #... CHECK STARTS HERE ...#

    Try
    {
        [int]     $index  = ($script:chkValues['FileName']).LastIndexOf('.')
        [string]  $name   = ($script:chkValues['FileName']).Substring(0, $index)
        [string]  $ext    = ($script:chkValues['FileName']).Substring($index + 1)
        [string]  $filter = "filename='$name' AND extension='$ext'"
        [string[]]$gCIMi  = @((Get-CimInstance -ClassName 'CIM_DataFile' -Filter $Filter -ErrorAction SilentlyContinue).Name)

        If ([string]::IsNullOrEmpty($gCIMi) -eq $false)
        {
            # One or more files found
            $result.message = $script:lang['dt01']
            $gCIMi | Sort-Object | ForEach-Object -Process { $result.data += '{0},#' -f $_ }
        }
        Else
        {
            # No files found
            $result.message = $script:lang['dt02']
        }

        $result.message += ",#'$($script:chkValues['FileName'])'"

        If ([string]::IsNullOrEmpty($result.data) -eq ($script:chkValues['FailOnFound'] -as [boolean])) { $result.result  = $script:lang['Pass'] }
        Else                                                                                            { $result.result  = $script:lang['Fail'] }
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
    }

    Return $result
}
