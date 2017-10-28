<#
    DESCRIPTION: 
        Check to see if any printers exist on the server. If printers exist, ensure the spooler directory is not stored on the system drive.

    REQUIRED-INPUTS:
        IgnoreThesePrinterNames - "LIST" - Known printer names to ignore

    DEFAULT-VALUES:
        IgnoreThesePrinterNames = ('Send To OneNote', 'PDFCreator', 'Microsoft XPS Document Writer', 'Fax', 'WebEx Document Loader', 'Microsoft Print To PDF')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No printers found
            Printers found, and spool directory is not set to default path
        WARNING:
        FAIL:
            Spool directory is set to the default path and needs to be changed, Registry setting not found
        MANUAL:
        NA:
            Print Spooler service is not running

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function sys-10-print-spooler
{
    $result        = newResult
    $result.server = $env:ComputerName
    $result.name   = $script:lang['Name']
    $result.check  = 'sys-10-print-spooler'

    #... CHECK STARTS HERE ...#

    Try
    {
        [string]$serviceState = (Get-Service -Name 'Spooler' | Select-Object -ExpandProperty 'Status')
        If ($serviceState -eq 'Running')
        {
            [System.Text.StringBuilder]   $filter = "NOT Name='Null'"
            $script:chkValues['IgnoreThesePrinterNames'] | ForEach-Object -Process { [void]$filter.Append(" AND NOT Name='$_'") }
            [System.Collections.ArrayList]$gCIMi  = @(Get-CimInstance -ClassName 'Win32_Printer' -Filter $filter -Property 'Name' -ErrorAction SilentlyContinue)
        }
        Else
        {
            [System.Collections.ArrayList]$gCIMi = @('-Service-Stopped-')
        }

        If ($gCIMi[0] -eq '-Service-Stopped-')
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = $script:lang['n001']
        }
        ElseIf ($gCIMi.Count -gt 0)
        {
            [object]$gITMp = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers' -Name 'DefaultSpoolDirectory' -ErrorAction SilentlyContinue)
            If ([string]::IsNullOrEmpty($gITMp) -eq $true)
            {
                $result.result  = $script:lang['Fail']
                $result.message = $script:lang['f001']
            }
            Else
            {
                If ($gITMp.DefaultSpoolDirectory -eq "$env:SystemDrive\Windows\system32\spool\PRINTERS")
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = $script:lang['f002']
                }
                Else
                {
                    $result.result  = $script:lang['Pass']
                    $result.message = $script:lang['p002']
                }
            }

            $result.data = ($($script:lang['dt01']) -f $gITMp.DefaultSpoolDirectory)
            $gCIMi | Sort-Object | ForEach-Object -Process { $result.data += "$($_.Name),#" }    # Output list of installed printers
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
