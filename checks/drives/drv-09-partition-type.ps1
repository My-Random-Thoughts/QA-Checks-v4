<#
    DESCRIPTION: 
        Ensure all drives types are set to BASIC and with a partition style of MBR.

    REQUIRED-INPUTS:
        IgnoreOffline - "True|False" - Ignore any drives that are marked as offline

    DEFAULT-VALUES:
        IgnoreOffline = 'True'

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            All drive types are BASIC, with partition styles of MBR
        WARNING:
        FAIL:
            One or more partition styles are not MBR
            One or more drives types are not BASIC
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function drv-09-partition-type
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'drv-09-partition-type'
 
    #... CHECK STARTS HERE ...#

    Try
    {
        [System.Collections.ArrayList]$gCIMi = @(Get-CimInstance -ClassName 'Win32_DiskPartition' -Filter "NOT Type = 'Installable File System'" -Property ('Name', 'Type') -ErrorAction SilentlyContinue)
        If ($gCIMi.Count -gt 0)
        {
            [int]$gptA = 0; [int]$gptB = 0; [int]$gptC = 0; [int]$gptD = 0
            [System.Collections.ArrayList]$data = @()

            $gCIMi | Sort-Object -Property 'Name' | ForEach-Object -Process {
                [string]$type = $($_.Type)
                [string]$name = $($_.Name)

                Switch ($true)
                {
                    {($type).StartsWith('GPT: Basic'  )} { $gptA++ }
                    {($type).StartsWith('GPT: Logical')} { $gptC++ }
                    {($type).StartsWith('Logical'     )} { $gptB++ }
                    {($type).StartsWith('GPT: Unknown')} { $gptD++ }
                    Default                              { [void]$data.Add($($name).Split(',')[0]) }
                }
            }


            $result.result  = $script:lang['Fail']
            $result.data    = (($data | Sort-Object -Unique) -join ', ')

            If (($gptA -gt 0) -or ($gptC -gt 0)) { $result.message += $script:lang['f001'] }
            If (($gptB -gt 0) -or ($gptC -gt 0)) { $result.message += $script:lang['f002'] }
            If  ($gptD -gt 0)                    { $result.message += $script:lang['f003'] }

            If ($script:chkValues['IgnoreOffline'] -eq 'True') { $result.message += $script:lang['f004'] }
        }
        Else
        {
            $result.result  = $script:lang['Pass']
            $result.message = $script:lang['p001']
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
