# INTERNAL CHECK TO GET SERVER DETAILS (HARDWARE, OS, CPU, RAM) FOR TOP OF HTML REPORT
$int00 = {
    Function newResult { Return ( New-Object -TypeName PSObject -Property @{server =''; name=''; check=''; datetime=(Get-Date -Format 'yyyy-MM-dd HH:mm'); result='Unknown'; message=''; data=''; blob=''} ) }
    $script:lang = @{}
# LANGUAGE INSERT
    Function int-00-internal-check
    {
        $result         = newResult
        $result.server  = $env:ComputerName
        $result.result  = 'INTERNAL'
        Try {
            [int]$VER = $($PSVersionTable.PSVersion.Major)
            If ($VER -lt 4) { $result.result = 'NOT_PS_V4'; Return $result }

            [string]  $TYP =     (Get-HardwareType)
            [string]  $OS  =    ((Get-CimInstance -ClassName 'CIM_OperatingSystem' -Property 'Caption' ).Caption )
            [string[]]$CPU =   @((Get-CimInstance -ClassName 'CIM_Processor'       -Property 'Name'    ).Name    )
            [string]  $RAM = (((((Get-CimInstance -ClassName 'CIM_PhysicalMemory'  -Property 'Capacity').Capacity) | Measure-Object -Sum).Sum) / 1GB).ToString('0.0')

            $CPU[0] = [regex]::Replace($CPU[0], '(\(TM\))|(\(R\))', '')    # Remove all the trademark crap as it a bit pointless for this display
            $result.data = "$TYP|$OS|$($CPU.Count)x $($CPU[0])|$($RAM)GB"
        } Catch { $result.data = "|||Error: $($Error[0].Exception.Message)" }
        Return $result
    }

    Function Get-HardwareType
    {
        [string]$SerialNumber = ((Get-CimInstance -ClassName 'Win32_BIOS'      -Property 'SerialNumber' -ErrorAction SilentlyContinue).SerialNumber)
        [string]$Product      = ((Get-CimInstance -ClassName 'Win32_BaseBoard' -Property 'Product'      -ErrorAction SilentlyContinue).Product)
        [string]$Manufacturer = ((Get-CimInstance -ClassName 'Win32_BaseBoard' -Property 'Manufacturer' -ErrorAction SilentlyContinue).Manufacturer)
        If     ($SerialNumber -like 'VMware-*'       ) { Return  $($script:lang['dt01'])                             }
        ElseIf ($Product      -eq   'Virtual Machine') { Return  $($script:lang['dt02'])                             }
        Else                                           { Return ($($script:lang['dt03']) -f $($Manufacturer.Trim())) }
    }

    int-00-internal-check
}
###################################################################################################

Function Show-HelpScreen
{
    Clear-Host
    Write-Header -Message "QA Script Engine - $($script:lang['Help01'])"
    Write-Host "  $($script:lang['Help02'])"                                               -ForegroundColor Cyan
    Write-Colr '    QA.ps1',' [-ComputerName] ','server01','[, server02, server03, ...]'   -Colour          Yellow, Gray, Yellow, Gray, Yellow, Gray
    Write-Colr '    QA.ps1',' [-ComputerName] ','(Get-Content -Path x:\path\list.txt)'     -Colour          Yellow, Gray, Yellow, Gray, Yellow
    Write-Host ''
    Write-Host "  $($script:lang['Help03'])"                                               -ForegroundColor Cyan
    Write-Colr '    -DoNotPing      ',': ',$($script:lang['Help04'])                       -Colour          Gray, Yellow, White
    Write-Colr '    -SkipHTMLHelp   ',': ',$($script:lang['Help05'])                       -Colour          Gray, Yellow, White
    Write-Colr '    -GenerateCSV    ',': ',$($script:lang['Help06'])                       -Colour          Gray, Yellow, White
    Write-Colr '    -GenerateXML    ',': ',$($script:lang['Help07'])                       -Colour          Gray, Yellow, White
    Write-Colr '    -Credential     ',': ',$($script:lang['Help08'])                       -Colour          Gray, Yellow, White
    Write-Colr '    -Authentication ',': ',$($script:lang['Help09'])                       -Colour          Gray, Yellow, White
    Write-Host ''
    Write-Host "  $($script:lang['Help10'])"                                               -ForegroundColor Cyan
    Write-Host "    $($script:lang['Help11'])"                                             -ForegroundColor Cyan
    Write-Colr '      ', $($script:lang['Help12'])                                         -Colour          Cyan, White
    Write-Colr '        QA.ps1',' [-ComputerName] ','.'                                    -Colour          Yellow, Gray, Yellow, Gray, Yellow
    Write-Colr '        QA.ps1',' [-ComputerName] ','server01'                             -Colour          Yellow, Gray, Yellow, Gray, Yellow
    Write-Host ''
    Write-Host "    $($script:lang['Help13'])"                                              -ForegroundColor Cyan
    Write-Colr '      ', $($script:lang['Help14'])                                         -Colour          Cyan, White
    Write-Colr '        QA.ps1',' [-ComputerName] ','server01, server02, server03, ...'    -Colour          Yellow, Gray, Yellow, Gray, Yellow
    Write-Colr '      ', $($script:lang['Help15'])                                         -Colour          Cyan, White
    Write-Colr '        QA.ps1',' [-ComputerName] ','(Get-Content -Path x:\path\list.txt)' -Colour          Yellow, Gray, Yellow, Gray, Yellow
    Write-Colr '      ', $($script:lang['Help16'])                                         -Colour          Cyan, White
    Write-Colr '        QA.ps1',' [-ComputerName] ','((Get-ADComputer -Filter {OperatingSystem -like "*windows server*"}).Name)' -Colour          Yellow, Gray, Yellow, Gray, Yellow
    Write-Host ''
    Write-Host "  $($script:lang['Help17'])"                                               -ForegroundColor Cyan

    18..25 | ForEach-Object -Process {
        If ([string]::IsNullOrEmpty($script:lang["Help$_"]) -eq $false) { Write-Host "    $($script:lang["Help$_"])" -ForegroundColor White }
    }

    DivLine
    Write-Host ''
    Exit
}

Function Check-CommandLine
{
    If (Test-Path variable:help) { If ($Help -eq $true) { Show-HelpScreen; Exit } }

    Clear-Host
    Write-Header -Message $script:lang['Header']

    # Check that we are running in an elevated session
    If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        Write-Host "  $($script:lang['NotAdmin1'])" -ForegroundColor Red
        Write-Host "  $($script:lang['NotAdmin2'])" -ForegroundColor Red
        Write-Host ''
        Break
    }

    # Check the age of the script
    [datetime]$dtVersion = (('{0}/{1}/20{2}' -f $version.SubString(8,2), $version.SubString(6,2), $version.SubString(3,2)) -as [datetime])
    [int]$age = (Get-Date).Subtract($dtVersion).Days
    If ($age -gt 90) { Write-Host "    $($script:lang['OldScript'])" -ForegroundColor Yellow; Write-Host ''; DivLine }

    # Process server names, removing any duplicates and sorting
    [System.Collections.ArrayList]$serverFilter = @()
    If (Test-Path variable:ComputerName) { $ComputerName | Select-Object -Unique | Sort-Object | ForEach-Object -Process { [void]$script:servers.Add($_.Trim()) } }

    $script:servers | ForEach-Object -Process {
        If (($_.Trim() -eq '.') -or ($_.Trim() -eq 'localhost')) { [void]$serverFilter.Add($env:ComputerName.ToLower()) }    # Add localhost if requested
        Else {                   If ($_.Trim().Length -gt 2)     { [void]$serverFilter.Add($_.Trim().ToLower()) } }
    }

    $script:servers.Clear()
    $script:servers = $serverFilter.Clone()
    If ([string]::IsNullOrEmpty($script:servers) -eq $true) { Show-HelpScreen; Exit }
}

Function Start-QAProcess
{
    # Verbose information output
    [boolean]$verbose = ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose'))      # Used for scanning one check at a time
    [boolean]$noPing  = ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('DoNotPing'))    # Used for ignoring PING checks

    # Write job information
    [int]$count = $script:qaChecks.Count
    Write-Host "  $($($script:lang['Header1']) -f $($count - 1), $script:ccTasks)" -ForegroundColor White
    Write-Host "  $($($script:lang['Header2']) -f $script:checkTimeout)"           -ForegroundColor White

    # Progress bar legend
    Write-Host ("   $D $($script:lang['Pass'])")           -NoNewline -ForegroundColor Green ; Write-Host ("  $D $($script:lang['Warning'])") -NoNewline -ForegroundColor Yellow
    Write-Host ( "  $D $($script:lang['Fail'])")           -NoNewline -ForegroundColor Red   ; Write-Host ("  $D $($script:lang['Manual'])")  -NoNewline -ForegroundColor Cyan
    Write-Host ( "  $D $($script:lang['Not-Applicable'])") -NoNewline -ForegroundColor Gray  ; Write-Host ("  $D $($script:lang['Error'])")              -ForegroundColor Magenta
    DivLine

    [string]$ServerCounts  = ''
    [string]$noPingMessage = ''
    If ($script:servers.Count -gt 1) { $ServerCounts  = '  '+($($script:lang['ServerCount']) -f $($script:servers.Count)) }
    If ($noPing -eq $true)           { $noPingMessage =       $($script:lang['DoNotPing'])                                }

    If (($ServerCounts -ne '') -or ($noPingMessage -ne ''))
    {
        Write-Host ('{0}{1}' -f $ServerCounts, $noPingMessage.PadLeft($script:screenwidth - $ServerCounts.Length)) -ForegroundColor White
        DivLine
    }

    # Create required output folders
    [void](New-Item -ItemType Directory -Force -Path ($script:qaOutput))
    If ($verbose     -eq $true) { $pBlock = $D } Else { $pBlock = $B }
    If ($GenerateCSV -eq $true) { If (Test-Path -Path ($script:qaOutput + 'QA_Results.csv')) { Try { Remove-Item ($script:qaOutput + 'QA_Results.csv') -Force } Catch {} } }
    If ($GenerateXML -eq $true) { If (Test-Path -Path ($script:qaOutput + 'QA_Results.xml')) { Try { Remove-Item ($script:qaOutput + 'QA_Results.xml') -Force } Catch {} } }

    # Master job loop
    [int]$CurrentServerNumber = 0
    ForEach ($server In $script:servers)
    {
        $script:ccVerbose = 1
        $CurrentServerNumber++
        [System.Collections.ArrayList]$CurrentServer = @()
        [int]   $Padding      = ($script:servers.Count -as [string]).Length
        [string]$CurrentCount = ('({0}/{1})' -f $CurrentServerNumber.ToString().PadLeft($Padding), ($script:servers.Count))
        If ($CurrentServerNumber -gt 1) { Write-Host '' }
        Write-Colr '  ', $server.PadRight($script:screenwidth - $CurrentCount.Length - 2), $CurrentCount -Colour White, White, Yellow
        Write-Host '   ' -NoNewline

        # Make sure the computer is reachable
        If (($noPing -eq $true) -or ((Test-Connection -ComputerName $server -Quiet -Count 1) -eq $true))
        {
            # Use the Check-IsPortOpen function to make sure that the WinRM port is listening
            If (($noPing -eq $true) -or ($server -eq $env:ComputerName) -or ((Check-IsPortOpen -DestinationServer $server -Port $script:sessionPort) -eq $true))
            {
                # Display progress bar blobs
                If ($verbose -eq $true) { Write-Host $script:lang['Verbose']      -ForegroundColor Yellow   -NoNewline                  }
                Else { For ([int]$x = 0; $x -lt $count - 1; $x++) { Write-Host $C -ForegroundColor DarkGray -NoNewline }; Write-Host '' }
                Write-Host '   ' -NoNewline

                # WinRM connected, loop through the checks and start a job
                [array]    $jobs         = $script:qaChecks
                [int]      $jobIndex     = 0         # Which job is up for running
                [hashtable]$workItems    = @{ }      # Items being worked on
                [hashtable]$jobtimer     = @{ }      # Timers for jobs
                [boolean]  $workComplete = $false    # Is the script done with what it needs to do?
                [boolean]  $inSession    = $false

                # Create and enter a remote session for remote servers only
                If ($server -ne $env:ComputerName)
                {
                    $origpos = $host.UI.RawUI.CursorPosition
                    Try
                    {
                        $inSession = $true
                        Write-Host "$($script:lang['CreateRemote'])" -NoNewline

                        [hashtable]$ConnectionProperties = @{
                            ComputerName  = $server;
                            Port          = $script:sessionPort;
                            UseSSL        = ([convert]::ToBoolean($script:sessionUseSSL))
                            SessionOption = $(New-PSSessionOption -OpenTimeout 300000);
                        }

                        # Check for and use WinRM credentials and authentication
                        If ($Credential     -ne [System.Management.Automation.PSCredential]::Empty) { $ConnectionProperties.Add('Credential',     $Credential)     }
                        If ($Authentication -ne $null)                                              { $ConnectionProperties.Add('Authentication', $Authentication) }

                        # Create new session to remote server
                        $script:NewSession = (New-PSSession @ConnectionProperties -ErrorAction Stop)

                        # Clear message
                        $host.UI.RawUI.CursorPosition = $origpos; Write-Host ''.PadRight($script:screenwidth, ' '); $host.UI.RawUI.CursorPosition = $origpos
                    }
                    Catch
                    {
                        $inSession       = $false
                        $workComplete    = $true
                        # Unable to connect
                        $result          = newResult
                        $result.server   = $server
                        $result.name     = $script:lang['CF-Data']
                        $result.check    = 'err-00'
                        $result.result   = 'Error'
                        $result.message  = $script:lang['CF-Message']    # CONNECTION FAILURE
                        $result.data     = $_.Exception.Message          # Show full message - may help with debugging
                        [void]$script:AllResults.Add($result)
                        [void]$CurrentServer.Add($result)
                        $script:failurecount++

                        $host.UI.RawUI.CursorPosition = $origpos; Write-Host ''.PadRight($script:screenwidth, ' '); $host.UI.RawUI.CursorPosition = $origpos
                        If ($verbose -eq $true) { Write-Host ''; Write-Host '   ' -NoNewline }
                        Write-Host ("$D $($script:lang['CF-Console'])") -ForegroundColor Magenta -NoNewline
                        Remove-PSSession -Session $script:NewSession -ErrorAction SilentlyContinue
                        $script:NewSession = $null
                    }
                }

                # Load requested module if required
                If ([string]::IsNullOrEmpty($script:requiredModules) -eq $false)
                {
                    [string]$impError = ''
                    $origpos = $host.UI.RawUI.CursorPosition
                    Try {
                        Write-Host "Loading Specified Modules..." -NoNewline
                        [hashtable]$ModuleLoading = @{
                            ErrorAction   = 'SilentlyContinue'; ErrorVariable   = 'impError';
                            WarningAction = 'SilentlyContinue'; WarningVariable = 'null';
                            Verbose       = $false;
                        }

                        If ($inSession -eq $true) { $ModuleLoading.Add('PSSession', $script:NewSession) }

                        $script:requiredModules -split ',' | ForEach-Object -Process {
                            $impError = (Import-Module -Name $($_.Trim()) -DisableNameChecking -PassThru @ModuleLoading)
                            If ([string]::IsNullOrEmpty($impError) -eq $true) { $impError = $($_.Trim()); Throw }
                        }
                        $host.UI.RawUI.CursorPosition = $origpos; Write-Host ''.PadRight($script:screenwidth, ' '); $host.UI.RawUI.CursorPosition = $origpos
                    }
                    Catch
                    {
                        $workComplete    = $true
                        $result          = newResult
                        $result.server   = $server
                        $result.name     = $script:lang['IM-Data']
                        $result.check    = 'err-00'
                        $result.result   = 'Error'
                        $result.message  = $script:lang['IM-Message']    # IMPORT MODULE ERROR
                        $result.data     = $impError                     # Show full message - may help with debugging
                        [void]$script:AllResults.Add($result)
                        [void]$CurrentServer.Add($result)
                        $script:failurecount++
                        $host.UI.RawUI.CursorPosition = $origpos; Write-Host ''.PadRight($script:screenwidth, ' '); $host.UI.RawUI.CursorPosition = $origpos
                        If ($verbose -eq $true) { Write-Host ''; Write-Host '   ' -NoNewline }
                        Write-Host ("$D $($script:lang['IM-Console'])") -ForegroundColor Magenta -NoNewline
                    }
                }

                While ($workComplete -eq $false)
                {
                    # Process any finished jobs.
                    ForEach ($key In @() + $workItems.Keys)
                    {
                        # Time in seconds current job has been running for, for timeout check
                        [int]$elapsed = $jobtimer.Get_Item($workItems[$key].Name).Elapsed.TotalSeconds

                        # Process succesful jobs
                        If ($workItems[$key].State -eq 'Completed')
                        {
                            # $key is done.
                            [PSObject]$result = (Receive-Job -Job $workItems[$key])
                            If ([string]::IsNullOrEmpty($result) -eq $false)
                            {
                                # Add to results - making sure the INTERNAL check is the first entry
                                If ($key -eq 'int00') { [void]$script:AllResults.Insert(0, $result); [void]$CurrentServer.Insert(0, $result) }
                                Else                  { [void]$script:AllResults.Add(      $result); [void]$CurrentServer.Add(      $result) }

                                # If any blob (psObject) data exists, write it out
                                If ([string]::IsNullOrEmpty($result.blob) -eq $false)
                                {
                                    # Create output path if required
                                    [string]$subpath = $script:qaOutput.TrimEnd('\') + '\' + ($result.blob.subpath.TrimEnd('\'))
                                    If ((Test-Path -Path ($subpath)) -eq $false) { Try { [void](New-Item -Path ($subpath) -ItemType Directory -Force) } Catch {} }

                                    # Generate filename and output
                                    [string]$outfile = ($subpath + "\$(($result.server).ToUpper())_" + $result.blob.filename)

                                    If ($result.blob.type -eq 'CSV') { ($result.blob.data) | Export-Csv -Path     $outFile -NoTypeInformation }
                                    Else                             { ($result.blob.data) | Out-File   -FilePath $outfile -Encoding utf8     }
                                }

                                # Provide some pretty output to the console
                                Switch ($result.result)
                                {
                                    'INTERNAL'  { }    # Display no result
                                    'NOT_PS_V4' {
                                        $result.check   = 'err-00'
                                        $result.result  = 'Error'
                                        $result.message = $script:lang['PS-Message']    # POWERSHELL VERSION
                                        $result.data    = $script:lang['PS-Data']       # POWERSHELL VERSION
                                        Write-Host ("$D $($script:lang['PS-Message'])") -ForegroundColor Magenta -NoNewline
                                        $script:failurecount++; $workComplete = $true; Break
                                    }

                                    $script:lang['Pass']           { Write-Host $pBlock -ForegroundColor Green  -NoNewline; Break }
                                    $script:lang['Warning']        { Write-Host $pBlock -ForegroundColor Yellow -NoNewline; Break }
                                    $script:lang['Fail']           { Write-Host $pBlock -ForegroundColor Red    -NoNewline; Break }
                                    $script:lang['Manual']         { Write-Host $pBlock -ForegroundColor Cyan   -NoNewline; Break }
                                    $script:lang['Not-Applicable'] { Write-Host $pBlock -ForegroundColor Gray   -NoNewline; Break }
                                    $script:lang['Error']          {
                                        If ($result.data -like '*Access is denied*') {
                                            If ($workComplete -eq $false) {
                                                $result.message = $script:lang['AD-Message']    # ACCESS DENIED
                                                $result.data    = $script:lang['AD-Data']       # ACCESS DENIED
                                                Write-Host ("$D $($script:lang['AD-Message'])") -ForegroundColor Magenta -NoNewline
                                                $script:failurecount++; $workComplete = $true
                                            } }
                                            Else { If ($workComplete -eq $false) { Write-Host $A -ForegroundColor Magenta -NoNewline }
                                        }
                                    }

                                    Default { Write-Host $pBlock -ForegroundColor DarkGray -NoNewline; Break }
                                }
                            }
                            Else
                            {
                                # Job returned no data
                                $result          = newResult
                                $result.server   = $server
                                $result.name     = $workItems[$key].Name
                                $result.check    = $workItems[$key].Name
                                $result.result   = 'Error'
                                $result.message  = $script:lang['ND-Message']    # NO DATA
                                $result.data     = $script:lang['ND-Data']       # NO DATA
                                [void]$script:AllResults.Add($result)
                                [void]$CurrentServer.Add($result)
                                Write-Host $A -ForegroundColor Magenta -NoNewline
                            }
                            $workItems.Remove($key)
                        
                        # Job failed or server disconnected
                        }
                        ElseIf (($workItems[$key].State -eq 'Failed') -or ($workItems[$key].State -eq 'Disconnected'))
                        {
                            $result          = newResult
                            $result.server   = $server
                            $result.name     = $workItems[$key].Name
                            $result.check    = $workItems[$key].Name
                            $result.result   = 'Error'
                            $result.message  = $script:lang['FD-Message']    # FAILED / DISCONNECTED
                            $result.data     = $script:lang['FD-Data']       # FAILED / DISCONNECTED
                            [void]$script:AllResults.Add($result)
                            [void]$CurrentServer.Add($result)
                            Write-Host ("$D $($script:lang['FD-Console'])") -ForegroundColor Magenta -NoNewline
                            $workItems.Remove($key)
                            $script:failurecount++
                            $workComplete = $true
                            If ($inSession -eq $true) { Remove-PSSession -Session $script:NewSession -ErrorAction SilentlyContinue }
                            $script:NewSession = $null
                        }

                        # Check for timed out jobs and kill them
                        If ($workItems[$key])
                        {
                            If ($workItems[$key].State -eq 'Running' -and ($elapsed -ge $script:checkTimeout))
                            {
                                $result          = newResult
                                $result.server   = $server
                                $result.name     = $workItems[$key].Name
                                $result.check    = $workItems[$key].Name
                                $result.result   = 'Error'
                                $result.message  = $script:lang['TO-Message']    # TIMEOUT
                                $result.data     = $script:lang['TO-Data']       # TIMEOUT
                                [void]$script:AllResults.Add($result)
                                [void]$CurrentServer.Add($result)
                                Try { Stop-Job -Job $workItems[$key]; Remove-Job -Job $workItems[$key] } Catch { }
                                Write-Host $A -ForegroundColor Magenta -NoNewline
                                $workItems.Remove($key)
                            }
                        }
                    }

                    # If in a remote session, then only allow one task at a time
                    If ($inSession -eq $false) {
                        If ($CurrentServer.Count -eq 1) { If ($verbose -eq $false) { $script:ccVerbose = $script:ccTasks } }
                    }

                    # Start new jobs if there are open slots.
                    While (($workItems.Count -lt $script:ccVerbose) -and ($jobIndex -lt $jobs.Length))
                    {
                        [string]$job        = ($jobs[$jobIndex].Substring(0, 6).Replace('-',''))    # xyz-01-check-name --> xyz01
                        [int]   $jobOn      =  $jobIndex + 1
                        [int]   $numJobs    =  $jobs.Count
                        [string]$funcName   =  $jobs[$jobIndex]
                        [object]$initScript =  Invoke-Expression "`$$job"

                        If (($verbose -eq $true) -and ($job -ne 'int00'))
                        {
                            # Show check name in Verbose mode
                            Write-Host ''
                            [int]$padWidth = ($script:screenwidth - 9) - $($jobs[$jobIndex]).Length
                            Write-Host ("    $($jobs[$jobIndex]) $(''.PadRight($padWidth, '.')): ") -ForegroundColor Gray -NoNewline
                        }

                        If ($inSession -eq $true) { $workItems[$job] = (Invoke-Command -Session $script:NewSession -AsJob -JobName $funcName -ScriptBlock $initScript) }
                        Else                      { $workItems[$job] = (Start-Job                                            -Name $funcName -ScriptBlock $initScript) }

                        $stopWatch = [System.Diagnostics.StopWatch]::StartNew()
                        [void]$jobtimer.Add($funcName, $stopWatch)
                        $jobIndex++
                    }

                    # If all jobs have been processed we are done - next server.
                    If ($jobIndex -eq $jobs.Length -and $workItems.Count -eq 0) { $workComplete = $true }
                
                    # Wait between status checks
                    Start-Sleep -Milliseconds $script:waitTime
                }
                If ($inSession -eq $true) { Remove-PSSession -Session $script:NewSession -ErrorAction SilentlyContinue }
                $script:NewSession = $null
            }
            Else
            {
                # WinRM not responding / erroring, unable to ping server
                $result          = newResult
                $result.server   = $server
                $result.name     = $script:lang['RM-Data']
                $result.check    = 'err-00'
                $result.result   = 'Error'
                $result.message  = $script:lang['RM-Message']    # WinRM FAILURE
                $result.data     = $script:lang['RM-Data']       # WinRM FAILURE
                [void]$script:AllResults.Add($result)
                [void]$CurrentServer.Add($result)
                $script:failurecount++
                Write-Host ("$D $($script:lang['RM-Console'])") -ForegroundColor Magenta -NoNewline
            }
        }
        Else
        {
            # Unable to connect
            $result          = newResult
            $result.server   = $server
            $result.name     = $script:lang['CF-Data']
            $result.check    = 'err-00'
            $result.result   = 'Error'
            $result.message  = $script:lang['CF-Message']    # CONNECTION FAILURE
            $result.data     = $script:lang['CF-Data']       # CONNECTION FAILURE
            [void]$script:AllResults.Add($result)
            [void]$CurrentServer.Add($result)
            $script:failurecount++
            Write-Host ("$D $($script:lang['CF-Console'])") -ForegroundColor Magenta -NoNewline
        }

        Write-Host ''
        $origpos = $host.UI.RawUI.CursorPosition                                                 # Set cursor position
        Write-Host "   $($script:lang['SavingResults'])" -ForegroundColor White -NoNewline       # and display message
        Export-Results -ResultsInput $CurrentServer -CurrentServerNumber $CurrentServerNumber    #
        $host.UI.RawUI.CursorPosition = $origpos; Write-Host ''.PadRight(50, ' ')                # then clear message
        $host.UI.RawUI.CursorPosition = $origpos; 

        # Show results counts
        $resultsplit = Get-ResultsSplit -ResultsInput $CurrentServer
        [int]                     $pad = (($script:qaChecks).Count - 20)      # 22:Result counts length; -2:Left padding
        If ($verbose -eq $true) { $pad =  ($script:screenwidth     - 25) }    # 22:Result counts length; +3:Right padding
        If ($pad     -le     3) { $pad =                              3  }    # Left align if needed

        Write-Colr -Text ''.PadLeft($pad), $resultsplit.p.PadLeft(2), ', ', $resultsplit.w.PadLeft(2), ', ', $resultsplit.f.PadLeft(2), ', ', `
                                           $resultsplit.m.PadLeft(2), ', ', $resultsplit.n.PadLeft(2), ', ', $resultsplit.e.PadLeft(2) `
                   -Colour White, Green, White, Yellow, White, Red, White, Cyan, White, Gray, White, Magenta
    }
}

Function Get-ResultsSplit ([System.Collections.ArrayList]$ResultsInput)
{
    [System.Collections.ArrayList]$ToSplit = @($ResultsInput | Select-Object -Skip 1)
    [string]$pa = @($ToSplit | Where-Object  { $_.result -eq $script:lang['Pass']           }).Count.ToString()
    [string]$wa = @($ToSplit | Where-Object  { $_.result -eq $script:lang['Warning']        }).Count.ToString()
    [string]$fa = @($ToSplit | Where-Object  { $_.result -eq $script:lang['Fail']           }).Count.ToString()
    [string]$ma = @($ToSplit | Where-Object  { $_.result -eq $script:lang['Manual']         }).Count.ToString()
    [string]$no = @($ToSplit | Where-Object  { $_.result -eq $script:lang['Not-Applicable'] }).Count.ToString()
    [string]$er = @($ToSplit | Where-Object  { $_.result -eq $script:lang['Error']          }).Count.ToString()
    [psobject]$return = New-Object -TypeName PSObject -Property @{ 'p'=$pa; 'w'=$wa; 'f'=$fa; 'm'=$ma; 'n'=$no; 'e'=$er; }
    Return $return
}

Function Show-Results
{
    [string]$y =    $script:failurecount
    [string]$x = (@($script:servers).Count - $y)
    $resultsplit = (Get-ResultsSplit -ResultsInput $script:AllResults)
    Write-Host ''
    DivLine

    [string[]]$lenCheck = @($script:lang['Checked'], $script:lang['Skipped'])
    [int]     $leftPad  =  ($lenCheck | Measure-Object -Maximum -Property 'Length').Maximum

    $TC2Pad =  ($script:screenwidth - (($script:lang['TotalCount2']).Length) - 1)
    Write-Host ( '  {0}{1}'         -f ($script:lang['TotalCount1']), (($script:lang['TotalCount2']).PadLeft($TC2Pad))) -ForegroundColor White
    Write-Host ('   {0}:{1}{2}:{3}' -f ($script:lang['Checked']).PadLeft($leftPad), $x.PadLeft(4), ($script:lang['Pass']          ).PadLeft(($script:screenwidth - 7) - ($leftPad + 7)), ($resultsplit.p).PadLeft(4)) -ForegroundColor Green
    Write-Host ('   {0}:{1}{2}:{3}' -f ($script:lang['Skipped']).PadLeft($leftPad), $y.PadLeft(4), ($script:lang['Warning']       ).PadLeft(($script:screenwidth - 7) - ($leftPad + 7)), ($resultsplit.w).PadLeft(4)) -ForegroundColor Yellow
    Write-Host (         ' {0}:{1}' -f                                                             ($script:lang['Fail']          ).PadLeft(($script:screenwidth - 7)                 ), ($resultsplit.f).PadLeft(4)) -ForegroundColor Red
    Write-Host (         ' {0}:{1}' -f                                                             ($script:lang['Manual']        ).PadLeft(($script:screenwidth - 7)                 ), ($resultsplit.m).PadLeft(4)) -ForegroundColor Cyan
    Write-Host (         ' {0}:{1}' -f                                                             ($script:lang['Not-Applicable']).PadLeft(($script:screenwidth - 7)                 ), ($resultsplit.n).PadLeft(4)) -ForegroundColor Gray
    Write-Host (         ' {0}:{1}' -f                                                             ($script:lang['Error']         ).PadLeft(($script:screenwidth - 7)                 ), ($resultsplit.e).PadLeft(4)) -ForegroundColor Magenta
    DivLine
}

Function Export-Results ([System.Collections.ArrayList]$ResultsInput, [int]$CurrentServerNumber)
{
    [string]$html = @'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
    <meta charset="utf-8">
    <title>QA Report</title>
    <style>
        @charset UTF-8;
        html body { font-family: Segoe UI, Verdana, Geneva, sans-serif; font-size: 12px; height: 100%; overflow: auto; color: #000000; }
        .header1  { width: 99%; margin: 0px 10px 0px auto; }
        .header2  { width: 99%; margin: 0px 10px 0px auto; padding-top: 10px; clear: both; min-height: 80px; }

        .header1 > .headerCompany { float: left;  font-size: 333%; font-weight: bold; }
        .header1 > .headerQA      { float: left;  font-size: 333%; }
        .header1 > .headerDetails { float: right; font-size: 100%; text-align: right;  }
        .header1 > .headerDetails > .item { display:block; padding: 0 0 3px 0; }

        .header2 > .headerServer { float: left; font-weight: normal; height: 88px; }
        .header2 > .headerServer > .serverName { font-size: 266%; line-height: 35px; text-transform: uppercase; }
        .header2 > .headerServer > .row { font-size: 100%; padding-left: 3px; padding-top: 2px; }

        /*  Size of check code/num boxes :                  (6 x (100 + 12)) + 10  = 682px  */
        /*  Slightly larger boxes        :                  (6 x (110 + 12)) + 10  = 742px  */
        /*  Just a bit bigger boxes      :                  (6 x (115 + 12)) + 10  = 774px  */

        .header2 > .summary { float:right; background: #f8f8f8; height: 77px; width: 742px; padding-top: 10px; border-right: 1px solid #ccc; border-bottom: 1px solid #cccccc; }
        .header2 > .summary > .summaryBox { float: left; height: 65px; width: 110px; text-align: center; margin-left: 10px; padding: 0px; border: 1px solid #000; cursor: default; }
        .header2 > .summary > .summaryBox > .code { font-size: 133%; padding-top: 5px; display: block; font-weight: bold; }
        .header2 > .summary > .summaryBox > .num  { font-size: 233%; }

        .sectionTitle    { padding: 5px; font-size: 233%; text-align: center; letter-spacing: 3px; display: block; }
        .sectionItem     { background: #707070; color: #ffffff; width: 99%; display: block; margin: 25px auto  5px auto; padding: 0; overflow: auto; }
        .checkItem       { background: #f8f8f8;                 width: 99%; display: block; margin: 10px auto 10px auto; padding: 0; overflow: auto; border-right: 1px solid #cccccc; border-bottom: 1px solid #cccccc; }
        .checkItem:hover { background: #f2f2f2; }

        .boxContainer { float: left; width: 80px; height: 77px; }
        .boxContainer > .check { position: relative; top: 0; left: 0; height: 65px; width: 100px; text-align: center; margin: 5px 0px 5px 5px; padding: 0px; border: 1px solid #707070; background: #ff00ff; cursor: default; }
        .boxContainer > .check > .code { font-size: 133%; padding-top: 5px; font-weight: bold; display: block; }
        .boxContainer > .check > .num { font-size: 233%; }

        .contentContainer { margin-left: 100px; padding: 10px 10px 10px 15px; overflow: auto; }
        .checkContainer  { float: left; width: 45%; }
        .checkContainer  > .name    { font-size: 125%; margin: 0 0 5px 0; font-weight: bold; }
        .checkContainer  > .message { font-size: 110%; }
        .resultContainer { float: left; width: 50%; }
        .resultContainer > .data > .dataHeader { font-weight: bold; margin-bottom: 5px; }
       
        .arrow          { border-right: 7px solid #000000; border-bottom: 7px solid #000000; width: 10px; height: 10px; transform: rotate(-135deg); margin-top: 5px; }
        .btt            { color: #000000; background: #ffffff; font-size: 125%; border: 1px solid #707070; margin: 0px; padding: 12px 15px; font-weight: bold; display: block; right: 10px; position: fixed; text-align: center; text-decoration: none; bottom: 10px; z-index: 100; border-radius: 50px; }
        .tocEntry       { color: #000000; background: #f8f8f8; font-size: 125%; border: 1px solid #707070; margin: 2px; padding:  5px 10px; font-weight: bold; }
        .btt:hover      { color: #ffffff; background: #707070; border: 1px solid #000000; }
        .tocEntry:hover { color: #ffffff; background: #707070; border: 1px solid #000000; }
        a               { color: #000000; text-decoration: none; }

        .note                { text-decoration: none; }
        .note div.help       { display: none; }
        .note:hover          { cursor: help; position: relative; }
        .note:hover div.help { color: #000000; background: #ffffdd; border: #000000 3px solid; display: block; right: 10px; margin: 10px; padding: 15px; position: fixed; text-align: left; text-decoration: none; top: 10px; width: 600px; z-index: 100; }
        .note li             { display: table-row-group; list-style: none; }
        .note li span        { display: table-cell; vertical-align: top; padding: 3px 0; }
        .note li span:first-child { text-align: right; min-width: 120px; max-width: 120px; font-weight: bold; padding-right: 7px; }
        .note li span:last-child  { padding-left: 7px; border-left: 1px solid #000000; }

        .p  { background: #b3ffb3 !important; }
        .w  { background: #ffffb3 !important; }
        .f  { background: #ffb3b3 !important; }
        .m  { background: #b3b3ff !important; }
        .n  { background: #e2e2e2 !important; }
        .e  { background: #c80000 !important; color: #ffffff !important; }
        .eB { background: #c80000 !important; color: #ffffff !important; border: 1px solid #ffffff !important; }
    </style>
</head>
<body>
BODY_GOES_HERE
</body>
</html>
'@

    If ($ResultsInput[0].check -eq 'err-00') { [void]$ResultsInput.Add($ResultsInput[0]) }

    [string]$dt1    = (Get-Date -Format 'yyyy/MM/dd HH:mm')                      # Used for script header information
    [string]$dt2    = $dt1.Replace('/','.').Replace(' ','-').Replace(':','.')    # Used for saving as part of filename : 'yyyy/MM/dd HH:mm'  -->  'yyyy.MM.dd-HH.mm'
    [string]$un     = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.ToLower()
    [string]$server = $ResultsInput[0].server
    [string]$path   = $script:qaOutput + $server.ToUpper() + '_' + $dt2 + '.html'
    
    $resultsplit = Get-ResultsSplit -ResultsInput $ResultsInput
    [System.Text.StringBuilder]$body = @"
    <a href="#BackToTop" title="Jump to top of page"><div class="btt"><div class="arrow"></div></div></a>
    <div id="BackToTop" class="header1">
        <span class="headerCompany">$reportCompanyName</span>
        <span class="headerQA"     >&nbsp;$($script:lang['QA-Results'])</span>
        <div class="headerDetails">
            <span class="item">$($script:lang['ScriptVersion']) <strong>$version      </strong></span>
            <span class="item">$($script:lang['Configuration']) <strong>$settingsFile </strong></span>
            <span class="item">$($script:lang['GeneratedOn']  ) <strong>$dt1          </strong></span>
            <span class="item">$($script:lang['GeneratedBy']  ) <strong>$un           </strong></span>
        </div>
    </div>

    <div class="header2">
        <div class="headerServer">
            <div class="serverName">$($server)</div>
            <div class="row"       >$($ResultsInput[0].Data.Split('|')[0])</div>
            <div class="row"><b    >$($ResultsInput[0].Data.Split('|')[1])</b></div>
            <div class="row"       >$($ResultsInput[0].Data.Split('|')[2]),&nbsp;&nbsp;&nbsp;&nbsp;$($ResultsInput[0].Data.Split('|')[3])</div>
        </div>
        <div class="summary">
            <div class="summaryBox p"><span class="code">$($script:lang['Pass']          )</span><span class="num">$($resultsplit.p)</span></div>
            <div class="summaryBox w"><span class="code">$($script:lang['Warning']       )</span><span class="num">$($resultsplit.w)</span></div>
            <div class="summaryBox f"><span class="code">$($script:lang['Fail']          )</span><span class="num">$($resultsplit.f)</span></div>
            <div class="summaryBox m"><span class="code">$($script:lang['Manual']        )</span><span class="num">$($resultsplit.m)</span></div>
            <div class="summaryBox n"><span class="code">$($script:lang['Not-Applicable'])</span><span class="num">$($resultsplit.n)</span></div>
            <div class="summaryBox e"><span class="code">$($script:lang['Error']         )</span><span class="num">$($resultsplit.e)</span></div>
        </div>
    </div>
    <div style="clear:both;"></div>

    <div class="sectionItem"><span class="sectionTitle">Jump Links To Sections</span></div>
    <div class="checkItem"><div style="text-align: center;"><br/>
SECTION_LINKS
    <br/><br/></div></div>
    <div style="clear:both;"></div>

"@

    # Replace COM with TOL for Compliance to Tooling conversion
    $ResultsInput | ForEach-Object -Process { If ($_.check.StartsWith('com-') -eq $true) { $_.check = $_.check.Replace('com-', 'tol-') } }

    # Sort the results                               # Skip Internal Check
    $ResultsInput   = @($ResultsInput | Select-Object -Skip 1 | Sort-Object check)

    $reportTemplate = @"
    <div class="checkItem"><div class="boxContainer"><div class="check RESULT_COLOUR HELP_SECTION"><span class="code">SECTION_CODE</span><span class="num">CHECK_NUMBER</span>
    </div></div><div class="contentContainer"><span class="checkContainer"><div class="name row">CHECK_TITLE</div><div class="message row">CHECK_MESSAGE</div></span>
    <span class="resultContainer"><div class="data"><div class="dataHeader">$($script:lang['HTML_Data'])</div><div class="dataItem">CHECK_DATA</div></div></span></div></div>

"@
    [string]$sectionNew = ''
    [string]$sectionOld = ''
    [System.Text.StringBuilder]$sectionLinks = ''

    $ResultsInput | ForEach-Object -Process {
        Try { $sectionNew = ($_.check).Substring(0, 3) } Catch { $sectionNew = '' }
        If ($sectionNew -ne $sectionOld)
        {
                    $sectionOld   = $sectionNew
            [string]$selctionName = $script:lang[$script:lang[$sectionNew]]
            [string]$sectionRow   = "`n    <!-- SECTION CHANGE -->`n    <div id=`"$selctionName`" class=`"sectionItem`"><span class=`"sectionTitle`">$selctionName</span></div>`n"
            [void]  $sectionLinks.AppendLine("        <a href=`"#$selctionName`"><span class=`"tocEntry`">$selctionName</span></a>")
        }
        Else { [string]$sectionRow = '' }
        [void]$body.Append($sectionRow)

        $addCheck = $reportTemplate
        $addCheck = $addCheck.Replace('SECTION_CODE'  , ($_.check  ).SubString(0,3)        )    # ACC
        $addCheck = $addCheck.Replace('CHECK_NUMBER'  , ($_.check  ).SubString(4,2)        )    # 01
        $addCheck = $addCheck.Replace('CHECK_TITLE'   , ($_.name   )                       )    # 
        $addCheck = $addCheck.Replace('CHECK_MESSAGE' , ($_.message).Replace(',#',',<br/>'))    # 
        If ([string]::IsNullOrEmpty($_.data) -eq $false) { $addCheck = $addCheck.Replace('CHECK_DATA', $($_.data -as [string]).Replace(',#',',<br/>')) }
        Else                                             { $addCheck = $addCheck.Replace('CHECK_DATA', $script:lang['None'])                           }

        Switch ($_.result)
        {
            $script:lang['Pass']           { $addCheck = $addCheck.Replace('RESULT_COLOUR',       'p' ); Break }    # Green
            $script:lang['Warning']        { $addCheck = $addCheck.Replace('RESULT_COLOUR',       'w' ); Break }    # Yellow
            $script:lang['Fail']           { $addCheck = $addCheck.Replace('RESULT_COLOUR',       'f' ); Break }    # Red
            $script:lang['Manual']         { $addCheck = $addCheck.Replace('RESULT_COLOUR',       'm' ); Break }    # Blue
            $script:lang['Not-Applicable'] { $addCheck = $addCheck.Replace('RESULT_COLOUR',       'n' ); Break }    # Grey
            $script:lang['Error']          { $addCheck = $addCheck.Replace('RESULT_COLOUR',       'eB')
                                             $addCheck = $addCheck.Replace('checkItem', 'checkItem e' ); Break }    # Full colour change to red on an error
        }

        If (-not $SkipHTMLHelp) { $addCheck = $addCheck.Replace('HELP_SECTION">', 'note">' + $(Add-HoverHelp -Check $($_.check).SubString(0,6).Replace('-', ''))) }
        Else                    { $addCheck = $addCheck.Replace('HELP_SECTION'  , '') }

        [void]$body.Append($addCheck)
    }

    $html = $html.Replace('BODY_GOES_HERE', $body.ToString())
    $html = $html.Replace('SECTION_LINKS' , $sectionLinks.ToString())
    $html | Out-File $path -Force -Encoding utf8

    # CSV Output
    If ($GenerateCSV -eq $true)
    {
        [string]$path = $script:qaOutput + 'QA_Results.csv'
        [System.Collections.ArrayList]$outCSV = @()
        [System.Collections.ArrayList]$cnvCSV = @($ResultsInput | Select-Object server, check, name, datetime, result, data | Sort-Object check, server | ConvertTo-Csv -NoTypeInformation)
        If ($CurrentServerNumber -gt 1) { $cnvCSV   = @($cnvCSV | Select-Object -Skip 1) }    # Remove header info for all but first server
        $cnvCSV | ForEach-Object -Process { [void]$outCSV.Add($_.Replace(',#',', ')) }
        $outCSV | Out-File -FilePath $path -Encoding utf8 -Force -Append
    }

    # XML Output
    If ($GenerateXML -eq $true)
    {
        [string]$path   = $script:qaOutput + 'QA_Results.xml'
        If ($CurrentServerNumber -eq 1) { '<?xml version="1.0" encoding="utf-8" ?><QAResultsFile></QAResultsFile>' | Out-File -FilePath $path -Encoding utf8 -Force }
        [string]$inXML  = (Get-Content -Path $path)
        [xml]   $cnvXML = ($ResultsInput | Select-Object server, check, name, datetime, result, data | Sort-Object check, server | ConvertTo-XML -NoTypeInformation)
        $inXML = $inXML.Replace('</QAResultsFile>', "$($cnvXML.Objects.OuterXml)</QAResultsFile>")
        $inXML = $inXML.Replace(',#',', ')
        $inXML | Out-File -FilePath $path -Encoding utf8 -Force
    }
}

Function Add-HoverHelp
{
    Param ([string]$Check)
    [System.Text.StringBuilder]$help = ''
    #If ($Check.StartsWith('tol') -eq $true) { $Check = $Check.Replace('tol', 'com') }    # COM/TOL swap
    If ($script:qahelp[$Check])
    {
        Try
        {
            [xml]   $xml          = $script:qahelp[$Check]
            [string]$selctionName = $script:lang[$script:lang[$Check.Substring(0,3)]]
            $help = '<div class="help"><li><span>{0}<br/>{1}</span><span>{2}</span></li><br/>' -f $selctionName, $check.Substring(3, 2), $xml.xml.description

            [hashtable]$resultStrings = @{'pass'   = $script:lang['Pass'];   'warning' = $script:lang['Warning']; 'fail' = $script:lang['Fail'];
                                          'manual' = $script:lang['Manual']; 'na'      = $script:lang['Not-Applicable']; }
            $xml.xml.ChildNodes | ForEach-Object -Process {
                If ($_.ToString() -in $resultStrings.Keys) {
                    [void]$help.Append($( "<li><span>$($resultStrings[$_.ToString()])</span><span>$($xml.xml.$($_.ToString()))</span></li>" ))
                }
            }

            [void]$help.Append($("<br/><li><span>$($script:lang['AppliesTo'])</span><span>$(($xml.xml.applies).Replace(', ','<br/>'))</span></li></div>"))
            $help = $help.Replace('!n', '<br/>')
        }
        Catch { $help = $($_.Exception.Message) }    # No help if XML is invalid
    }
    Return $($help.ToString())
}

Function Check-IsPortOpen
{
    Param ([string]$DestinationServer, [int]$Port)
    Try {
        $tcp  = New-Object System.Net.Sockets.TcpClient
        $con  = $tcp.BeginConnect($DestinationServer, $port, $null, $null)
        $wait = $con.AsyncWaitHandle.WaitOne(3000, $false)

        If (-not $wait) { $tcp.Close(); Return $false }
        Else {
            $failed = $false; $error.Clear()
            Try { $tcp.EndConnect($con) } Catch {}
            If (!$?) { $failed = $true }; $tcp.Close()
            If ($failed -eq $true) { Return $false } Else { Return $true }
    } } Catch { Return $false }
}

Function Write-Colr
{
    Param ([String[]]$Text, [ConsoleColor[]]$Colour, [Switch]$NoNewline = $false)
    For ([int]$x = 0; $x -lt $Text.Length; $x++) { Write-Host $Text[$x] -Foreground $Colour[$x] -NoNewLine }
    If ($NoNewline -eq $false) { Write-Host '' }
}

[string]$A=[char]9608;[string]$B=[char]9600;[string]$C=[char]9604;[string]$D=[char]9632;[string]$E=[char]9472;[string]$F=[char]9556
[string]$G=[char]9559;[string]$H=[char]9562;[string]$I=[char]9553;[string]$J=[char]9552;[string]$K=[char]9574;[string]$L=[char]9565
Function Write-Header ([string]$Message)
{
    $underline=''.PadLeft($script:screenwidth-17, $E)
    $q=("  $F$J$J$K$J$J$J$J$J$K$J$J$G  ","","","","  $I  $H$J$J$J$J$J$L  $I  ","","","","  $I "," $C$C$C $C$C$C "," $I  ","",
        "  $I "," $A $A $A$C$A "," $I  ","","  $I "," $B$A$B $B $B "," $I  ","","  $I ","","         "," $C$C ",
        "  $I ","","  CHECK  ","$C$B$A ","  $I ","","        ","$C$B $A ","  $H$J$J$J$J$J$J$J$J ","","","$B$B$B$A$B ")
    $s=('QA Script Engine','Written by Mike Blackett @ My Random Thoughts','support@myrandomthoughts.co.uk','','',$Message,'',$version,$underline)
    [System.ConsoleColor[]]$z=('White','Gray','Gray','Red','Cyan','Green','Red','Yellow','Yellow'); Write-Host ''; For ($x=0; $x-lt$q.Length; $x+=4) {
    Write-Colr $q[$x],$q[$x+1],$q[$x+2],$q[$x+3],$s[$x/4].PadLeft($script:screenwidth-17) -Colour White,Cyan,White,Green,$z[$x/4]}; Write-Host ""
}
Function DivLine { Write-Host ' '.PadRight($script:screenwidth + 1, $E) -ForegroundColor Yellow }

###################################################################################################

# COMPILER INSERT
[int]      $script:waitTime       =  100    # Time to wait between starting new tasks (milliseconds)
[int]      $script:failurecount   =    0    #
[int]      $script:ccVerbose      =    1    # 

[System.Collections.ArrayList]$script:AllResults = @()
[System.Collections.ArrayList]$script:servers    = @()

# Resize window to be 135 wide and keep the height.  Also change the buffer height to be large
# This can produce an error message, but it is safe to ignore.
Try
{
    $gh = Get-Host
    $ws = $gh.UI.RawUI.WindowSize
    $wh = $ws.Height
    If ($ws.Width -le 135) {
        $ws.Height = 9999
        $ws.Width  =  135; $gh.UI.RawUI.Set_BufferSize($ws)
        $ws.Height =  $wh; $gh.UI.RawUI.Set_WindowSize($ws)
    }
}
Catch { }
[int]$script:screenwidth = ($ws.Width - 2)

Check-CommandLine
$tt = [System.Diagnostics.StopWatch]::StartNew()
Start-QAProcess
Show-Results
$tt.Stop()
Write-Host "  $($script:lang['TimeTaken']) $($tt.Elapsed.Minutes) min, $($tt.Elapsed.Seconds) sec" -ForegroundColor White
Write-Host "  $($script:lang['ReportsLocated']) $($script:qaOutput)"                               -ForegroundColor White
DivLine
Write-Host ''
Write-Host ''

# End Of Line
