<#
    ###############################################################################################

      SERVER QA SCRIPTS
      COMPILER                        Developed and written by Mike Blackett @ My Random Thoughts
                                                                   support@myrandomthoughts.co.uk

      v4                                       https://github.com/my-random-thoughts/qa-checks-v4

    ###############################################################################################

    ###############################################################################################
    #                                                                                             #
    #        Compiles all required PowerShell scripts for QA checks into one master script        #
    #                                                                                             #
    #              CONTACT ME IF YOU REQUIRE HELP - READ ALL THE DOCUMENTATION FIRST              #
    #                                                                                             #
    ###############################################################################################
#>

Param ([string]$Settings, [switch]$Silent = $false, [switch]$Minimal = $false)
Remove-Variable -Name * -Exclude ('Settings', 'Silent', 'Minimal') -ErrorAction SilentlyContinue
#Requires       -Version 4
Set-StrictMode  -Version 2

#region SCRIPTS
[System.Text.StringBuilder]$qaScript = ''    # The resulting compiled QA script file contents
[string]$version = ('v4.{0}' -f (Get-Date -Format 'yy.MMdd'))
[string]$date    = (Get-Date -Format 'yyyy/MM/dd HH:mm')
[string]$path    = (Split-Path (Get-Variable MyInvocation -ValueOnly).MyCommand.Path)

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
If ($Host.Name -eq 'Windows PowerShell ISE Host') { $ws = New-Object -TypeName 'System.Drawing.Size'(135, 9999) }
[int]$script:screenwidth = ($ws.Width - 2)

###################################################################################################
[string]$A=[char]9608;[string]$B=[char]9600;[string]$C=[char]9604;[string]$D=[char]9632;[string]$E=[char]9472;[string]$F=[char]9556
[string]$G=[char]9559;[string]$H=[char]9562;[string]$I=[char]9553;[string]$J=[char]9552;[string]$K=[char]9574;[string]$L=[char]9565
Function DivLine { Write-Host2 ' '.PadRight($script:screenwidth + 1, $E) -ForegroundColor Yellow }
Function Write-Host2 ([string]$Message, [consolecolor]$ForegroundColor = 'White', [switch]$NoNewline = $false)
{
    If ($Silent -eq $false) {
        Write-Host -Object $Message -ForegroundColor $ForegroundColor -NoNewline:$NoNewline
    }
}
Function Write-Colr ([String[]]$Text, [ConsoleColor[]]$Colour, [Switch]$NoNewline = $false)
{
    For ([int]$y = 0; $y -lt $Text.Length; $y++) { Write-Host2 -Message $Text[$y] -Foreground $Colour[$y] -NoNewLine }
    If ($NoNewline -eq $false) { Write-Host2 -Message '' }
}
Function Write-Header ([string]$Message)
{
    $underline=''.PadLeft($script:screenwidth-17, $E)
    $q=("  $F$J$J$K$J$J$J$J$J$K$J$J$G  ","","","","  $I  $H$J$J$J$J$J$L  $I  ","","","","  $I "," $C$C$C $C$C$C "," $I  ","",
        "  $I "," $A $A $A$C$A "," $I  ","","  $I "," $B$A$B $B $B "," $I  ","","  $I ","","         "," $C$C ",
        "  $I ","","  CHECK  ","$C$B$A ","  $I ","","        ","$C$B $A ","  $H$J$J$J$J$J$J$J$J ","","","$B$B$B$A$B ")
    $s=('QA Script Engine','Written by Mike Blackett @ My Random Thoughts','support@myrandomthoughts.co.uk','','',$Message,'',$version,$underline)
    [System.ConsoleColor[]]$z=('White','Gray','Gray','Red','Cyan','Green','Red','Yellow','Yellow'); Write-Host2 ''; For ($x=0; $x-lt$q.Length; $x+=4) {
    Write-Colr $q[$x],$q[$x+1],$q[$x+2],$q[$x+3],$s[$x/4].PadLeft($script:screenwidth-17) -Colour White,Cyan,White,Green,$z[$x/4]}; Write-Host2 ''
}
Function Load-IniFile ([string]$InputFile)
{
    If ($InputFile.ToLower().EndsWith('.ini') -eq $false) { $InputFile += '.ini' }
    If ((Test-Path -Path $InputFile) -eq $false)
    {
        Switch (Split-Path -Path (Split-Path -Path $InputFile -Parent) -Leaf)
        {
            'i18n'     { [string]$errMessage = '  ERROR: Language ' }
            'settings' { [string]$errMessage = '  ERROR: Settings ' }
            Default    { [string]$errMessage = (Split-Path -Path (Split-Path -Path $InputFile -Parent) -Leaf) }
        }
        Write-Host2 "$errMessage file '$(Split-Path -Path $InputFile -Leaf)' not found." -ForegroundColor Red
        Write-Host2 "         $InputFile"                                                -ForegroundColor Red
        Write-Host2 ''
        Break
    }

    [string]   $comment = ";"
    [string]   $header  = "^\s*(?!$($comment))\s*\[\s*(.*[^\s*])\s*]\s*$"
    [string]   $item    = "^\s*(?!$($comment))\s*([^=]*)\s*=\s*(.*)\s*$"
    [hashtable]$ini     = @{}

    If ((Test-Path -LiteralPath $inputfile) -eq $False) { Write-Host "Load-IniFile: Path not found: $inputfile"; Return $null }

    [string]$name    = $null
    [string]$section = $null
    Switch -Regex -File $inputfile {
        "$($header)" {
            [string]$section = (($matches[1] -replace ' ','_').Trim().Trim("'"))
            If ([string]::IsNullOrEmpty($ini[$section]) -eq $true) { $ini[$section.Trim()] = @{} }
        }
        "$($item)"   {
            [string]$name, $value = $matches[1..2]
            If (([string]::IsNullOrEmpty($name) -eq $False) -and ([string]::IsNullOrEmpty($section) -eq $False))
            {
                $value = (($value -split '    #')[0]).Trim()    # Remove any comments
                $ini[$section][$name.Trim()] = ($value.Replace('`n', "`n"))
            }
        }
    }
    Return $ini
}
Function DrawMenu ($CursorStart, [array]$menuItems, [int]$menuPosition, [string]$menuTitle)
{
    $host.UI.RawUI.CursorPosition = $CursorStart
    ForEach ($item In $menuItems.Count) { Write-Host ''.PadRight(80, ' ') }
    $host.UI.RawUI.CursorPosition = $CursorStart

    [color]$fc  = [System.ConsoleColor]::White
    [color]$bc  =  (Get-Host).UI.RawUI.BackgroundColor
    [int]  $l   =   $menuItems.length - 1
    [int]  $max = (($menuItems | Measure-Object -Maximum -Property Length).Maximum) + 4

    Write-host "  $menuTitle`n" -ForegroundColor White
    For ($i = 0; $i -le $l; $i++)
    {
        If ($($menuItems[$i]) -eq 'default-settings') { $fc = [System.ConsoleColor]::Cyan } Else { $fc = [System.ConsoleColor]::White }
        Write-Host '   ' -NoNewLine
        If ($i -eq $menuPosition)
            { Write-Host "  $($menuItems[$i])  ".PadRight($max) -ForegroundColor $bc -BackgroundColor $fc } Else
            { Write-Host "  $($menuItems[$i])  ".PadRight($max) -ForegroundColor $fc -BackgroundColor $bc }
    }
}
Function ShowMenu ([array]$menuItems, [string]$menuTitle)
{
    [int]$vkeycode = 0
    [int]$pos      = 0
         $origpos  = $host.UI.RawUI.CursorPosition

    DrawMenu -CursorStart $origpos -menuItems $menuItems -menuPosition $pos -menuTitle $menuTitle
    Write-Host ''
    DivLine

    While ($vkeycode -ne 13)
    {
        $press    = $host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown')
        $vkeycode = $press.VirtualKeyCode

        If ($vkeycode -eq 38) { $pos-- }    # Up
        If ($vkeycode -eq 40) { $pos++ }    # Down

        If ($pos -lt 0) { $pos = $menuItems.Length - 1 }    # Loop up and over
        If ($pos -ge $menuItems.length) { $pos = 0 }        # Loop down and around

        DrawMenu -CursorStart $origpos -menuItems $menuItems -menuPosition $pos -menuTitle $menuTitle
        Write-Host ''
        DivLine
    }
    Return $($menuItems[$pos])
}
Function Write-LangSectionKeys ([string]$Section, [int]$Indent)
{
    Try {
        # Check keys exist (error-checking for new checks)
        [boolean]$keysExist = $false
        Try { [object]$keys = ($lngStrings[$Section].Keys); $keysExist = $true } Catch {}
        If ($keysExist -eq $false)
        {
            $lngStrings[$Section] = @{}
            $lngStrings[$Section]['Name'] = "'!! Missing Language Text !!'"
            $lngStrings[$Section]['Desc'] = "'Make sure you have entries in the i18n language file for this check'"
            $lngStrings[$Section]['Appl'] = 'ALL'
        }
        
        $SectionInsert = (New-Object 'System.Text.StringBuilder')
        ForEach ($key In ($lngStrings[$Section].Keys | Sort-Object))
        {
            [string]$value = ($lngStrings[$Section][$key])
            If ($value -eq ''    ) { $value = "''" }
            If ($key   -eq 'Appl') { $value = ($lngStrings['applyto'][$value.ToString()]) }
            [string]$lang = ("`$script:lang['$key'] = $($value.Trim())")
            [void]$SectionInsert.AppendLine(''.PadRight($Indent) + $lang)
        }
    } Catch {}
    Return $($SectionInsert.ToString())
}
#endregion
###################################################################################################

If ($Silent -eq $false)
{
    Clear-Host
    Write-Header -Message 'Compiler'
}

If ($Host.Name -eq 'Windows PowerShell ISE Host')
{
    Write-Host2 '  PLEASE NOTE:'                                                                             -ForegroundColor Yellow
    Write-Host2 '   Running this script in the ISE will not allow you to choose which configuration file to' -ForegroundColor Yellow
    Write-Host2 '   use due to limitations with the menu system. The default-settings will be used instead.' -ForegroundColor Yellow
    Write-Host2 '   In order to select a particular setting, please run this script via a console window.'   -ForegroundColor Yellow
    Write-Host2 ''
    $Settings = 'default-settings'
}

If ([string]::IsNullOrEmpty($Settings) -eq $True)
{
    Try {
        [System.Collections.ArrayList]$options = ((Get-ChildItem -Path "$path\settings" -Filter '*.ini').BaseName | Sort-Object)
        $Settings = (ShowMenu -menuItems $options -menuTitle 'Select a configuration file to compile:').ToLower()
    }
    Catch {
        If (@(Get-ChildItem -Path "$path\settings" -Filter '*.ini').Count -eq 0)
        {
            Write-Host2 "  No available configuration files found.`n  Exiting.`n" -ForegroundColor Red
            Break
        }
        Else
        {
            Write-Host2 "  Using only available configuration file`n" -ForegroundColor Yellow
            [string]$Settings = ((Get-ChildItem -Path "$path\settings" -Filter '*.ini').BaseName | Sort-Object)
        }
    }
}

# Load settings file
Try
{
    [hashtable]$iniSettings = (Load-IniFile -InputFile ("$path\settings\$Settings" ))
    [hashtable]$defStrings  = (Load-IniFile -InputFile ("$path\i18n\en-GB.ini"     ))
    [hashtable]$lngStrings  = (Load-IniFile -InputFile ("$path\i18n\{0}.ini" -f ($iniSettings['settings']['language'])))
    Try { [void]($lngStrings['acc01'].Keys) } Catch { Throw }    # Check the language INI file has some entries
}
Catch
{
    Write-Host2 '  ERROR: There were problems loading the required INI files.' -ForegroundColor Red
    Write-Host2 '         Please check the settings file is correct.'          -ForegroundColor Red
    Write-Host2 ''
    Break
}

[string]$shared       = "Function newResult { Return ( New-Object -TypeName 'PSObject' -Property @{server =''; name=''; check=''; datetime=(Get-Date -Format 'yyyy-MM-dd HH:mm'); result='Unknown'; message=''; data=''; blob=''} ) }"
[string]$scriptHeader = @"
<#
    ###############################################################################################

      SERVER QA SCRIPTS
      COMPILED VERSION                Developed and written by Mike Blackett @ My Random Thoughts
                                                                   support@myrandomthoughts.co.uk

      v4                                       https://github.com/my-random-thoughts/qa-checks-v4

    ###############################################################################################

      VERSION  : $version
      SETTINGS : $Settings

    ###############################################################################################
    #                                                                                             #
    #                      DO NOT EDIT THIS FILE - ALL CHANGES WILL BE LOST                       #
    #                    THIS FILE IS AUTO-COMPILED FROM SEVERAL SOURCE FILES                     #
    #                                                                                             #
    #              CONTACT ME IF YOU REQUIRE HELP - READ ALL THE DOCUMENTATION FIRST              #
    #                                                                                             #
    ###############################################################################################
#>

[CmdletBinding(DefaultParameterSetName = 'HLP')]
Param (
    # Default parameter set
    [Parameter(ParameterSetName = 'QAC', Mandatory = `$true , Position = 1)] [string[]] `$ComputerName,
    [Parameter(ParameterSetName = 'QAC', Mandatory = `$false              )] [switch]   `$SkipHTMLHelp,
    [Parameter(ParameterSetName = 'QAC', Mandatory = `$false              )] [switch]   `$GenerateCSV,
    [Parameter(ParameterSetName = 'QAC', Mandatory = `$false              )] [switch]   `$GenerateXML,
    [Parameter(ParameterSetName = 'QAC', Mandatory = `$false              )] [switch]   `$DoNotPing,

    # Optional WinRM credentials and authentication type...
    [Parameter(ParameterSetName = 'QAC', Mandatory = `$false)] [System.Management.Automation.PSCredential][System.Management.Automation.Credential()] `$Credential = [System.Management.Automation.PSCredential]::Empty,
    [Parameter(ParameterSetName = 'QAC', Mandatory = `$false)] [System.Management.Automation.Runspaces.AuthenticationMechanism] `$Authentication,

    # Show help screen
    [Parameter(ParameterSetName = 'HLP', Mandatory = `$false              )] [switch]   `$Help
)

#Requires       -Version 4
Set-StrictMode  -Version 2
Remove-Variable -Name    * -Exclude ('ComputerName', 'SkipHTMLHelp', 'GenerateCSV', 'GenerateXML', 'DoNotPing', 'Credential', 'Authentication', 'Help') -ErrorAction SilentlyContinue
"@

# Get full list of checks...                                                                    ACC-01-
[System.Collections.ArrayList]$qaChecks = (Get-ChildItem -Path "$path\checks" -Recurse -Filter '???-??-*.ps1')
If ([string]::IsNullOrEmpty($qaChecks) -eq $true)
{
    Write-Host2 '  ERROR: No checks found'                             -ForegroundColor Red
    Write-Host2 '         Please check you are in the correct folder.' -ForegroundColor Red
    Write-Host2 ''
    Break
}

###################################################################################################

[string]$shortcode = ''
If ($Settings -ne 'default-settings') {
    [string]$shortcode = ($iniSettings['settings']['shortcode'] + '_').ToString().Replace(' ', '-')
    If ($shortcode -eq '_') { $shortcode = 'UNKNOWN_' }
}

[string]$mini = ''
If ($Minimal -eq $True) { $mini = '_MINI' }

# Remove previous version if required
[string]$outPath = "$path\QA_$shortcode$version$mini.ps1"
If (Test-Path -Path $outPath) { Try { Remove-Item $outPath -Force } Catch { } }

Write-Colr  '  Compiling ', $qaChecks.Count, ' checks using settings file ', $Settings.ToUpper() -Colour White, Yellow, White, Yellow
Write-Host2 '   ' -NoNewline; For ($x = 0; $x -lt ($qaChecks.Count + 3); $x++) { Write-Host2 $C -NoNewline -ForegroundColor DarkGray }; Write-Host2 ''
Write-Host2 '   ' -NoNewline

###################################################################################################
# CHECKS building                                                                                 #
###################################################################################################
# Start building the QA file
[void]$qaScript.AppendLine($scriptHeader)
[void]$qaScript.AppendLine("[string]   `$version       = '$version'" )
[void]$qaScript.AppendLine("[string]   `$settingsFile  = '$Settings'")
[void]$qaScript.AppendLine("[hashtable]`$script:lang   = @{}")
[void]$qaScript.AppendLine("[hashtable]`$script:qahelp = @{}")
[void]$qaScript.AppendLine('')

# Get a list of all the checks, adding them into an array
[System.Text.StringBuilder]$cList = ''
[System.Text.StringBuilder]$cLine = "'int-00-internal-check', "

[void]$cList.AppendLine('[System.Collections.ArrayList]$script:qaChecks = (')
$qaChecks | ForEach-Object -Process {
    [string]$checkName = ($_.BaseName).Substring(0, 6).Replace('-','')
    If (-not $iniSettings["$checkName-skip"])
    {
        [void]$cLine.Append("'$($_.BaseName)', ")
        If ($cLine.Length -ge 120) { [void]$cList.AppendLine(''.PadRight(4) + $cLine); $cLine = '' }
    }
}

[void]$cList.AppendLine(''.PadRight(4) + $cLine)
$clist = $clist.ToString().Trim().Trim(',') + "`n)"
[void]$qaScript.AppendLine($cList.ToString())
[void]$qaScript.AppendLine('')

# Add the shared variables code
[void]$qaScript.AppendLine($shared)
[void]$qaScript.AppendLine(''.PadLeft(190, '#'))
[void]$qaScript.AppendLine('#region CHECKS')
Write-Host2 $B -NoNewline -ForegroundColor Cyan                                                          # First CYAN blob for adding the HEADER infomation

[System.Text.StringBuilder]$qaHelp = ''
# Add each check into the script
ForEach ($qa In ($qaChecks | Sort-Object -Property 'Name'))
{
    [string]$checkName = ($qa.BaseName).Substring(0, 6).Replace('-','')
    If (($Minimal -eq $True) -and (-not $iniSettings["$checkName"]))
    {
        # Skip adding check
        Write-Host2 $B -NoNewline -ForegroundColor DarkGreen                                             # DARKGREEN blob for skipping a QA CHECK
    }
    Else
    {
        [string]$CheckHeader = ((Get-Content -Path ($qa.FullName) -TotalCount 50 -ReadCount 50) -join "`n")

        [void]$qaScript.AppendLine("`$$($qa.Name.Substring(0, 6).Replace('-','')) = {")
        [void]$qaScript.AppendLine($shared)
        [void]$qaScript.AppendLine('$script:lang      = @{}')
        [void]$qaScript.AppendLine('$script:chkValues = @{}')

        [string]$checkName = ($qa.Name).Substring(0, 6).Replace('-','')
        If ($iniSettings["$checkName-skip"]) { $checkName += '-skip' }

        # Add each checks settings
        Try
        {
            ForEach ($key In ($iniSettings[$checkName].Keys | Sort-Object))
            {
                [string]$value = ($iniSettings[$checkName][$key]).ToString()
                If ($value -eq '') { $value = "''" }
                [string]$appSetting = ('$script:chkValues[' + "'{0}'] = {1}" -f $key, ($value.Trim()))
                [void]$qaScript.AppendLine($appSetting)
            }
        }
        Catch
        {
            # Missing INI Section for this check, read from the check script itself
            $regExV = [RegEx]::Match($CheckHeader, "DEFAULT-VALUES:((?:.|\s)+?)(?:(?:[A-Z\- ]+:\n)|(?:#>))")
            [string[]]$Values = ($regExV.Groups[1].Value.Trim()).Split("`n")
            If (([string]::IsNullOrEmpty($Values) -eq $false) -and ($Values -ne 'None'))
            {
                ForEach ($EachValue In $Values)
                {
                    [string]$key   = ($EachValue -split ' = ')[0].Trim()
                    [string]$value = ($EachValue -split ' = ')[1].Trim()
                    If ($value -eq '') { $value = "''" }

                    [string]$appSetting = ('$script:chkValues[' + "'{0}'] = {1}" -f $key, ($value.Trim()))
                    [void]$qaScript.AppendLine($appSetting)
                }
            }
        }

        # Add language specific strings to each check
        $checkName = $checkName.TrimEnd('-skip')
        [void]$qaScript.Append((Write-LangSectionKeys -Section 'common'   -Indent 0))
        [void]$qaScript.Append((Write-LangSectionKeys -Section $checkName -Indent 0))

        # Add the check itself
        [void]$qaScript.AppendLine(((Get-Content -Path ($qa.FullName)) -join "`n"))

        [hashtable]$addVal = @{ p=''; w=''; f=''; m=''; n='' }
        [System.Text.StringBuilder]$xmlHelp = '<xml>'
        ForEach ($key In ($lngStrings[$checkName].Keys | Sort-Object))
        {
            [string]$value = ($lngStrings[$checkName][$key]).Trim("'")
            Switch -Wildcard ($key)
            {
                'desc' {                                                                 [void]$xmlHelp.Append("<description>$value</description>"); Break }    # Description
                'appl' { $value = ($lngStrings['applyto'][$value.ToString()]).Trim("'"); [void]$xmlHelp.Append("<applies>$value</applies>");         Break }    # Applies to

                'p0*'  { $addVal.p += ($($lngStrings[$checkName][$key]).ToString().Trim("'").Replace(',#','')) + '!n'; Break }    # Pass
                'w0*'  { $addVal.w += ($($lngStrings[$checkName][$key]).ToString().Trim("'").Replace(',#','')) + '!n'; Break }    # Warning
                'f0*'  { $addVal.f += ($($lngStrings[$checkName][$key]).ToString().Trim("'").Replace(',#','')) + '!n'; Break }    # Fail
                'm0*'  { $addVal.m += ($($lngStrings[$checkName][$key]).ToString().Trim("'").Replace(',#','')) + '!n'; Break }    # Manual
                'n0*'  { $addVal.n += ($($lngStrings[$checkName][$key]).ToString().Trim("'").Replace(',#','')) + '!n'; Break }    # N/A

                Default { }    # Ignore everything else
            }
        }

        # Add result strings to help XML
        If ([string]::IsNullOrEmpty($addVal.p) -eq $false) { [void]$xmlHelp.Append("<pass>$($addVal.p)</pass>") }
        If ([string]::IsNullOrEmpty($addVal.w) -eq $false) { [void]$xmlHelp.Append("<warning>$($addVal.w)</warning>") }
        If ([string]::IsNullOrEmpty($addVal.f) -eq $false) { [void]$xmlHelp.Append("<fail>$($addVal.f)</fail>") }
        If ([string]::IsNullOrEmpty($addVal.m) -eq $false) { [void]$xmlHelp.Append("<manual>$($addVal.m)</manual>") }
        If ([string]::IsNullOrEmpty($addVal.n) -eq $false) { [void]$xmlHelp.Append("<na>$($addVal.n)</na>") }

        [void]$xmlHelp.Append('</xml>')    # Not "AppendLine()"
        [void]$qaHelp.AppendLine("`$script:qahelp['$checkName']='$($xmlHelp.ToString())'")

        # Add each required function
        $regExR = [RegEx]::Match($CheckHeader, "REQUIRED-FUNCTIONS:((?:.|\s)+?)(?:(?:[A-Z\- ]+:\n)|(?:#>))")
        [string[]]$sectionValue = ($regExR.Groups[1].Value.Trim()).Split("`n")
        If (([string]::IsNullOrEmpty($sectionValue) -eq $false) -and ($sectionValue -notlike '*None*')) {
            ForEach ($function In $sectionValue) {
                [void]$qaScript.AppendLine(((Get-Content -Path "$path\engine\$($function.Trim()).ps1") -join "`n"))
            }
        }

        # Add the check call
        [void]$qaScript.AppendLine('')
        [void]$qaScript.AppendLine($($qa.BaseName))

        # Complete this check
        [void]$qaScript.AppendLine('}')
        Write-Host2 $B -NoNewline -ForegroundColor Green                                                 # GREEN blob for adding a QA CHECK
    }
}

[void]$qaScript.AppendLine(''.PadLeft(190, '#'))
[void]$qaScript.AppendLine('#endregion')

[void]$qaScript.AppendLine('#region HELP')
[void]$qaScript.AppendLine($qaHelp.ToString())
[void]$qaScript.AppendLine(''.PadLeft(190, '#'))
[void]$qaScript.AppendLine('#endregion')

[void]$qaScript.AppendLine('#region LANGUAGE')
[void]$qaScript.Append((Write-LangSectionKeys -Section 'engine'        -Indent 0))
[void]$qaScript.Append((Write-LangSectionKeys -Section 'common'        -Indent 0))
[void]$qaScript.Append((Write-LangSectionKeys -Section 'section'       -Indent 0))
[void]$qaScript.Append((Write-LangSectionKeys -Section 'sectionlookup' -Indent 0))
[void]$qaScript.AppendLine('#endregion')
[void]$qaScript.AppendLine(''.PadLeft(190, '#'))
Write-Host2 $B -NoNewline -ForegroundColor Cyan                                                          # Second CYAN blob for adding the HELP and LANGUAGE settings

# Get the main engine file
[string]$engine = ((Get-Content ($path + '\engine\QA-Engine.ps1')) -join "`n")

# Insert language specific strings for the internal check
$engine = $engine.Replace('# LANGUAGE INSERT', (Write-LangSectionKeys -Section 'int00' -Indent 4))

# Make sure we have a value in the settings, if not use the defaults
If ([string]::IsNullOrEmpty(($iniSettings['settings']['reportCompanyName'])) -eq $True) { ($iniSettings['settings']['reportCompanyName']) =          'Acme' }
If ([string]::IsNullOrEmpty(($iniSettings['settings']['outputLocation']))    -eq $True) { ($iniSettings['settings']['outputLocation'])    = 'C:\QA\Results' }
If ([string]::IsNullOrEmpty(($iniSettings['settings']['concurrent']))        -eq $True) { ($iniSettings['settings']['concurrent'])        =             '5' }
If ([string]::IsNullOrEmpty(($iniSettings['settings']['timeout']))           -eq $True) { ($iniSettings['settings']['timeout'])           =            '50' }
If ([string]::IsNullOrEmpty(($iniSettings['settings']['sessionPort']))       -eq $True) { ($iniSettings['settings']['sessionPort'])       =          '5985' }
If ([string]::IsNullOrEmpty(($iniSettings['settings']['sessionUseSSL']))     -eq $True) { ($iniSettings['settings']['sessionUseSSL'])     =         'False' }
If ([string]::IsNullOrEmpty(($iniSettings['settings']['RequiredModules']))   -eq $True) { ($iniSettings['settings']['RequiredModules'])   =              '' }

# Insert script variables
$engine = $engine.Replace('# COMPILER INSERT', @"
[string]`$reportCompanyName      = '$($iniSettings['settings']['reportCompanyName'])'
[string]`$script:qaOutput        = '$($iniSettings['settings']['outputLocation']   )'
[int]   `$script:ccTasks         =  $($iniSettings['settings']['concurrent']       )
[int]   `$script:checkTimeout    =  $($iniSettings['settings']['timeout']          ) 
[int]   `$script:sessionPort     =  $($iniSettings['settings']['sessionPort']      ) 
[string]`$script:sessionUseSSL   = '$($iniSettings['settings']['sessionUseSSL']    )'
[string]`$script:requiredModules = '$($iniSettings['settings']['RequiredModules']  )'
"@)

[void]$qaScript.Append($engine)
Out-File -FilePath $outPath -InputObject $qaScript.ToString() -Encoding utf8
Write-Host2 $B -NoNewline -ForegroundColor Cyan                                                          # Last CYAN blob for finishing the compile
Write-Host2 ''

###################################################################################################
# FINISH                                                                                          #
###################################################################################################

DivLine
Write-Colr '  Execute ',$(Split-Path -Leaf $outPath),' for command line help' -Colour White, Yellow, White
Remove-Variable version, date, path, outpath -ErrorAction SilentlyContinue
Write-Host2 ''
Write-Host2 ''
