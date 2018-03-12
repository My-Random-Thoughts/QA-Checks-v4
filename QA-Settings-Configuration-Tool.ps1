<#
    ###############################################################################################

      SERVER QA SCRIPTS
      CONFIGURATION TOOL              Developed and written by Mike Blackett @ My Random Thoughts
                                                                   support@myrandomthoughts.co.uk

      v4                                       https://github.com/my-random-thoughts/qa-checks-v4

    ###############################################################################################

    ###############################################################################################
    #                                                                                             #
    #  Aids in the configuration of customer or environment specific settings for the QA Scripts  #
    #                                                                                             #
    #              CONTACT ME IF YOU REQUIRE HELP - READ ALL THE DOCUMENTATION FIRST              #
    #                                                                                             #
    ###############################################################################################
#>

Param ([string]$Language)
Remove-Variable -Name    * -Exclude 'Language' -ErrorAction SilentlyContinue
#Requires       -Version 4
Set-StrictMode  -Version 2
Clear-Host

# IMG_MAINFORM Icon List
#    0: Gear      : (green)      - default-settings
#    1: Gear      : (blue)       - enabled item / custom settings
#    2: Gear      : (grey)       - disabled item
#    3: Flag      : '?'          - for languages with no flag
#    4: Flag      : 'en-GB'      - default english language
#    5: Clock     : timeout      - extra settings window
#    6: Gears     : concurrent   - extra settings window
#    7: Cross     : (red)        - clear search field
#    8: Cloud     : 'MRT' logo   - github link on about screen
#    9: All       : tab 2 button - select all visible checks
#   10: Invert    : tab 2 button - invert visible selected checks
#   11: None      : tab 2 button - unselect all visible checks
#   12: Reset     : tab 2 button - reset all checks back to setting defaults
#   15: Help/Info : tab 2 image  - search help

# NO LONGER NEEDED
#   13: Duplicate : input form   - duplicate entry
#   14: Invalid   : input form   - validation error

[void][Reflection.Assembly]::LoadWithPartialName('System.Data')
[void][Reflection.Assembly]::LoadWithPartialName('System.Drawing')
[void][Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[System.Drawing.Font]$sysFont       = [System.Drawing.SystemFonts]::MessageBoxFont
[System.Drawing.Font]$sysFontBold   = (New-Object -TypeName 'System.Drawing.Font' ($sysFont.Name, ($sysFont.SizeInPoints + 1), [System.Drawing.FontStyle]::Bold  ))
[System.Drawing.Font]$sysFontItalic = (New-Object -TypeName 'System.Drawing.Font' ($sysFont.Name,  $sysFont.SizeInPoints     , [System.Drawing.FontStyle]::Italic))
[System.Windows.Forms.Application]::EnableVisualStyles()

[hashtable]$script:languageINI      = @{}
[hashtable]$script:ToolLangINI      = @{}
[object]   $script:SelectedLanguage = $null
[string]   $script:SelectedToolLang = ''
[string]   $script:regExMatch       = '((?:.|\s)+?)(?:(?:[A-Z\- ]+:\n)|(?:#>))'    # Used for all RegEx search matching used in the check comments
[string]   $script:toolName         = 'QA Settings Configuration Tool'             # QASCT Name
[string]   $script:toolVersion      = 'v4.18.0308'                                 # QASCT Version (v4.yy.mmdd)

###################################################################################################
##                                                                                               ##
##   Various Required Scripts                                                                    ##
##                                                                                               ##
###################################################################################################
#region Various Required Scripts
Function New-IconComboItem { Return (New-Object -TypeName 'PSObject' -Property @{'Icon' = ''; 'Name' = ''; 'Text' = ''; }) }
[System.Collections.ArrayList]$script:IconCombo_Items  = @{}    # - Holds current items
[System.Collections.ArrayList]$script:IC_T1_ToolLang   = @{}    # \
[System.Collections.ArrayList]$script:IC_T1_Language   = @{}    #   Holds all the custom
[System.Collections.ArrayList]$script:IC_T1_Settings   = @{}    #   items for all the
[System.Collections.ArrayList]$script:IC_AS_Timeout    = @{}    #   Combo Boxes
[System.Collections.ArrayList]$script:IC_AS_Concurrent = @{}    # /

# Enable Cue Banner text to be applied to textbox controls
$Definition = @'
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SendNotifyMessage(IntPtr hWnd, int msg, int wParam, string lParam);
'@
$DefFunc = Add-Type -MemberDefinition $Definition -Name 'User32' -Namespace 'Win32' -PassThru
Function SendMessage([intptr]$ControlHandle, [string]$DisplayString) { Return $DefFunc::SendNotifyMessage($ControlHandle, '&H1501', 0, $DisplayString) }

Function Get-Folder ([string]$Description, [string]$InitialDirectory, [boolean]$ShowNewFolderButton)
{
    [string]$return = ''
    If ([threading.thread]::CurrentThread.GetApartmentState() -eq 'STA')
    {
        $FolderBrowser = (New-Object -TypeName 'System.Windows.Forms.FolderBrowserDialog')
        $FolderBrowser.RootFolder          = 'MyComputer'
        $FolderBrowser.Description         = $Description
        $FolderBrowser.ShowNewFolderButton = $ShowNewFolderButton
        If ([string]::IsNullOrEmpty($InitialDirectory) -eq $False) { $FolderBrowser.SelectedPath = $InitialDirectory }
        If ($FolderBrowser.ShowDialog($MainForm) -eq [System.Windows.Forms.DialogResult]::OK) { $return = $($FolderBrowser.SelectedPath) }
        Try { $FolderBrowser.Dispose() } Catch {}
    }
    Else
    {
        # Workaround for MTA not showing the dialog box.
        # Initial Directory is not possible when using the COM Object
        $Description  += "`n$($script:ToolLangINI['page1']['FolderOpen2'])"
        $comObject     = (New-Object -ComObject 'Shell.Application')
        $FolderBrowser = $comObject.BrowseForFolder(0, $Description, 512, '')    # 512 = No 'New Folder' button, '' = Initial folder (Desktop)
        If ([string]::IsNullOrEmpty($FolderBrowser) -eq $False) { $return = $($FolderBrowser.Self.Path) } Else { $return = '' }
        [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($comObject)    # Dispose COM object
    }
    Return $return
}

Function Open-File ([string]$InitialDirectory, [string]$Title)
{
    [string]$return = ''
    $OpenFile = (New-Object -TypeName 'System.Windows.Forms.OpenFileDialog')
    $OpenFile.InitialDirectory = $InitialDirectory
    $OpenFile.Multiselect      = $False
    $OpenFile.Title            = $Title
    $OpenFile.Filter           = 'Compiled QA Scripts|*.ps1'
    If ([threading.thread]::CurrentThread.GetApartmentState() -ne 'STA') { $OpenFile.ShowHelp = $True }    # Workaround for MTA issues not showing dialog box
    If ($OpenFile.ShowDialog($MainFORM) -eq [System.Windows.Forms.DialogResult]::OK) { $return = ($OpenFile.FileName) }
    Try { $OpenFile.Dispose() } Catch {}
    Return $return
}

Function Save-File ([string]$InitialDirectory, [string]$Title, [string]$InitialFileName)
{
    [string]$return = ''
    $SaveFile = (New-Object -TypeName 'System.Windows.Forms.SaveFileDialog')
    $SaveFile.InitialDirectory = $InitialDirectory
    $SaveFile.Title            = $Title
    $SaveFile.FileName         = $InitialFileName
    $SaveFile.Filter           = 'QA Configuration Settings|*.ini'
    If ([threading.thread]::CurrentThread.GetApartmentState() -ne 'STA') { $SaveFile.ShowHelp = $True }    # Workaround for MTA issues not showing dialog box
    If ($SaveFile.ShowDialog($MainForm) -eq [System.Windows.Forms.DialogResult]::OK) { $return = ($SaveFile.FileName) }
    Try { $SaveFile.Dispose() } Catch {}
    Return $return
}

Function Load-ComboBoxIcon ([System.Windows.Forms.ComboBox]$ComboBox, [string[]]$Items, [string]$SelectedItem, [switch]$Clear, [string]$Type)
{
    If ($Clear) { $ComboBox.Items.Clear() }
    If ($Items[0] -eq $($script:ToolLangINI['page1']['LangMissing']))
    {
        $newItem = (New-IconComboItem)
        $newItem.Icon = $img_MainForm.Images[3]; $newItem.Name = $Items[0]; $newItem.Text = $Items[0]
        [void]$script:IC_T1_Language.Add($newItem); $newItem = $null
        [void]$ComboBox.Items.AddRange($script:IC_T1_Language); $ComboBox.SelectedIndex = 0
        Return
    }

    # Clear each of the collections
    Switch ($Type)
    {
        'Timeout'    { [void]$script:IC_AS_Timeout.Clear()    }
        'ToolLang'   { [void]$script:IC_T1_ToolLang.Clear()   }
        'Language'   { [void]$script:IC_T1_Language.Clear()   }
        'Settings'   { [void]$script:IC_T1_Settings.Clear()   }
        'Concurrent' { [void]$script:IC_AS_Concurrent.Clear() }
    }

    [int]$SelectedIndex = -1
    $Items | ForEach-Object -Process {
        $newItem = (New-IconComboItem)
        $newItem.Name = "$_"
        $newItem.Text = "$_"

        If (($Type -eq 'Language') -or ($Type -eq 'ToolLang'))
        {
            Try
            {
                # This method does not lock the image files as [System.Drawing.Image]::FromFile() does
                $bytes        = [System.IO.File]::ReadAllBytes("$script:scriptLocation\i18n\$($_).png")
                $MemSt        = (New-Object -TypeName 'System.IO.MemoryStream'(,$bytes))
                $newItem.Icon = [System.Drawing.Image]::FromStream($MemSt)
                $MemSt.Flush(); $MemSt.Dispose()
            }
            Catch
            {
                If (($newItem.Name -eq 'default-settings') -or ($newItem.Name -eq 'en-GB')) { $newItem.Icon = $img_MainForm.Images[4] }    # Built-in British flag
                Else                                                                        { $newItem.Icon = $img_MainForm.Images[3] }    # Unknown flag
            }

            # Load INI Value for this language and get the icon index
            [string]$filePart = ''; If ($Type -eq 'ToolLang') { $filePart = '-tool' }
            Try { [string]$TextName = (Load-IniFile -Inputfile "$script:scriptLocation\i18n\$($_)$filePart.ini").Language.Name } Catch { Return }
            $newItem.Text = $TextName    # Overwrite above default
            If ($Type -eq 'Language') { [void]$script:IC_T1_Language.Add($newItem) } Else { [void]$script:IC_T1_ToolLang.Add($newItem) }
        }
        
        ElseIf ($Type -eq 'Settings')
        {
            If ($_ -eq 'default-settings') { $newItem.Icon = $img_MainForm.Images[0] } Else { $newItem.Icon = $img_MainForm.Images[1] }
            [void]$script:IC_T1_Settings.Add($newItem)
        }

        ElseIf ($Type -eq 'TimeOut')
        {
            $newItem.Icon = $img_MainForm.Images[5]
            [void]$script:IC_AS_Timeout.Add($newItem)
            If ($_ -eq $SelectedItem) { $SelectedIndex = $script:IC_AS_Timeout.Count - 1 }
        }
        
        ElseIf ($Type -eq 'Concurrent')
        {
            $newItem.Icon = $img_MainForm.Images[6]
            [void]$script:IC_AS_Concurrent.Add($newItem)
            If ($_ -eq $SelectedItem) { $SelectedIndex = $script:IC_AS_Concurrent.Count - 1 }
        }

        Else
        {
            Write-Warning "Load-ComboBoxIcon: Wrong TYPE entered: $Type"
        }

        $newItem = $null
    }

    Switch ($Type)
    {
        'Timeout'    {                                                                                    [void]$ComboBox.Items.AddRange($script:IC_AS_Timeout   ) }
        'ToolLang'   { $script:IC_T1_ToolLang = @($script:IC_T1_ToolLang | Sort-Object -Property 'Text'); [void]$ComboBox.Items.AddRange($script:IC_T1_ToolLang  ) }
        'Language'   { $script:IC_T1_Language = @($script:IC_T1_Language | Sort-Object -Property 'Text'); [void]$ComboBox.Items.AddRange($script:IC_T1_Language  ) }
        'Settings'   { $script:IC_T1_Settings = @($script:IC_T1_Settings | Sort-Object -Property 'Text'); [void]$ComboBox.Items.AddRange($script:IC_T1_Settings  ) }
        'Concurrent' {                                                                                    [void]$ComboBox.Items.AddRange($script:IC_AS_Concurrent) }
    }

    If ($SelectedIndex -eq -1) {
        For ($x=0; $x -lt $ComboBox.Items.Count; $x++) { If ($ComboBox.Items[$x].Name -eq $SelectedItem) { $ComboBox.SelectedIndex = $x; Break } }
    } Else { $ComboBox.SelectedIndex = $SelectedIndex }
}

Function ComboIcons_OnDrawItem ([System.Windows.Forms.ComboBox]$Control)
{
    [System.Windows.Forms.DrawItemEventArgs]$e = $_
    $e.DrawBackground()
    $e.DrawFocusRectangle()

    If ($Control.Enabled -eq $False) { $Control.BackColor = [System.Drawing.SystemColors]::Control }
    Else                             { $Control.BackColor = [System.Drawing.SystemColors]::Window  }

    [System.Drawing.Rectangle]$bounds = $e.Bounds
    If (($e.Index -gt -1) -and ($e.Index -lt $Control.Items.Count))
    {
        $currItem = $Control.Items[$e.Index]
        [System.Drawing.Image]     $icon       = $null
        [System.Drawing.SolidBrush]$solidBrush = [System.Drawing.SolidBrush]$e.ForeColor
        Try { $icon = $currItem.Icon } Catch { $icon = $img_MainForm.Images[3] }    # Unknown flag on failure

        # Specific for this tool - Resize the image just in case it's not 16x16 - can't trust anyone.!
        If (($icon.Width -ne 16) -or ($icon.Height -ne 16)) { $icon = (New-Object -TypeName 'System.Drawing.Bitmap'($icon, 16, 16)) }

        # Format and display the image/text
        $middle   = ((($bounds.Top) + ((($bounds.Height) - ($icon.Height)) / 2)) -as [int])
        $iconRect = (New-Object -TypeName 'System.Drawing.RectangleF'((($bounds.Left) +                     5), $middle,     $icon.Width,                           $icon.Width))
        $textRect = (New-Object -TypeName 'System.Drawing.RectangleF'((($bounds.Left) + ($iconRect.Width) + 9), $middle, (($bounds.Width) - ($iconRect.Width) - 9), $icon.Width))
        $format   = (New-Object -TypeName 'System.Drawing.StringFormat')
        $format.Alignment     = [System.Drawing.StringAlignment]::Near                 # Left aligned
        $format.LineAlignment = [System.Drawing.StringAlignment]::Center               # Verically centered
        $format.Trimming      = [System.Drawing.StringTrimming ]::EllipsisCharacter    # Trim trailing characters

        $e.Graphics.DrawImage($icon, $iconRect)
        $e.Graphics.DrawString($currItem.Text, $e.Font, $solidBrush, $textRect, $format)
        $e.Graphics.Dispose()
        $icon = $null
    }
}

Function Add-ListViewItem ([System.Windows.Forms.ListView]$ListView, [string]$Name, [int]$ImageIndex = -1, [string[]]$SubItems, [string]$Group, [switch]$Clear, [boolean]$Enabled )
{
    [System.Windows.Forms.ListViewGroup]$lvGroup = $null
    If ($ListView -ne $null)
    {
        If ($Clear) { [void]$ListView.Items.Clear() }
        ForEach ($groupItem in $ListView.Groups) { If ($groupItem.Name -eq $Group) { $lvGroup = $groupItem; Break } }
        If ($lvGroup -eq $null) { $lvGroup = $ListView.Groups.Add($Group, "ERR: $Group") }
    }

    # Create item
    $lvItem            = (New-Object -TypeName 'System.Windows.Forms.ListViewItem')
    $lvItem.Name       = $Name
    If ($Name.StartsWith('*') -eq $false) { $lvItem.Text = $Name } Else { $lvItem.Text = '' }
    $lvItem.ImageIndex = $ImageIndex
    $lvItem.Group      = $lvGroup
    $lvItem.Tag        = $Group
    $lvitem.Checked    = $false
    $lvItem.SubItems.AddRange($SubItems)

    # Used for each tab section items, not the check selection window
    If (($Enabled -eq $false) -and ($lvItem.Text -ne ' ')) { $lvItem.ForeColor = 'ControlDark'; $lvItem.ImageIndex = 2 }

    # Add or return item
    If ($ListView -ne $null) { $ListView.Items.Add($lvItem) } Else { Return $lvItem }
}

Function Load-IniFile ([string]$Inputfile, [hashtable]$ExistingHashTable = $null)
{
    [string]   $comment = ";"
    [string]   $header  = "^\s*(?!$($comment))\s*\[\s*(.*[^\s*])\s*]\s*$"
    [string]   $item    = "^\s*(?!$($comment))\s*([^=]*)\s*=\s*(.*)\s*$"
    [hashtable]$ini     = @{}
    If ($ExistingHashTable -ne $null) { $ini = $ExistingHashTable.Clone() }

    If ((Test-Path -LiteralPath $inputfile) -eq $False) { Write-Warning "Load-IniFile: Path not found: $inputfile"; Return $null }

    [string]$name    = $null
    [string]$section = $null
    Switch -Regex -File $inputfile {
        "$($header)" {
            [string]$section = (($matches[1] -replace ' ','_').Trim().Trim("'"))
            If ($section.StartsWith('com') -eq $true) { $section = "tol$($section.Substring(3))" }
            If ([string]::IsNullOrEmpty($ini[$section]) -eq $true) { $ini[$section] = @{} }
        }
        "$($item)"   {
            [string]$name, $value = $matches[1..2]
            If (([string]::IsNullOrEmpty($name) -eq $False) -and ([string]::IsNullOrEmpty($section) -eq $False))
            {
                $value = (($value -split '    #')[0]).Trim()    # Remove any comments
                If ($inputfile.Contains('\settings\') -eq $False) { $value = $value.Trim("'") }
                $ini[$section][$name.Trim()] = ($value.Replace('`n', "`n"))
            }
        }
    }
    Return $ini
}

Function Get-DefaultINISettings ()
{
    [hashtable]$defaultINI = @{}
    [object[]] $folders    = (Get-ChildItem -Path "$script:scriptLocation\checks" | Where-Object -FilterScript { $_.PsIsContainer -eq $True } | Select-Object -ExpandProperty 'Name' | Sort-Object -Property 'Name' )

    ForEach ($folder In ($folders | Sort-Object -Property 'Name'))
    {
        [object[]]$scripts = (Get-ChildItem -Path "$script:scriptLocation\checks\$folder" -Filter '???-??-*.ps1' | Select-Object -ExpandProperty 'Name' | Sort-Object -Property 'Name' )
        If ([string]::IsNullOrEmpty($scripts) -eq $False)
        {
            ForEach ($script In ($scripts | Sort-Object -Property 'Name'))
            {
                [string]$getContent = ((Get-Content -Path "$script:scriptLocation\checks\$folder\$script" -TotalCount 50) -join "`n")
                [string]$checkCode  = ($script.Substring(0, 6).Replace('-',''))    # Get check code: "acc-01-local-user.ps1"  -->  "acc01"

                # Get default state (ENABLED / SKIPPED)
                $regExE = [regex]::Match($getContent, "DEFAULT-STATE:$script:regExMatch")
                If ($regExE.Groups[1].Value.Trim() -ne 'Enabled') { $checkCode += '-skip' }

                # Add check
                $defaultINI[$checkCode] = @{}

                # Get default values
                $regExV = [regex]::Match($getContent, "DEFAULT-VALUES:$script:regExMatch")
                [string[]]$Values = ($regExV.Groups[1].Value.Trim()).Split("`n")
                If (([string]::IsNullOrEmpty($Values) -eq $false) -and ($Values -ne 'None'))
                {
                    ForEach ($EachValue In $Values) { $defaultINI[$checkCode][(($EachValue -split ' = ')[0]).Trim()] = (($EachValue -split ' = ')[1]).Trim() }
                }
            }
        }
    }
    Return $defaultINI
}
#endregion
###################################################################################################
##                                                                                               ##
##   Secondary Forms                                                                             ##
##                                                                                               ##
###################################################################################################
#region Secondary Forms
Function Show-InputForm
{
    Param
    (
        [parameter(Mandatory=$True )][string]  $Type,
        [parameter(Mandatory=$True )][string]  $Title,
        [parameter(Mandatory=$True )][string]  $Description,
        [parameter(Mandatory=$false)][string]  $Validation = 'None',
        [parameter(Mandatory=$false)][string[]]$InputList,
        [parameter(Mandatory=$false)][string[]]$CurrentValue,
        [parameter(Mandatory=$false)][string  ]$InputDescription = '',
        [parameter(Mandatory=$false)][int     ]$MaxNumberInputBoxes
    )

    # [ValidateSet('Simple', 'Check', 'Option', 'List', 'Large')]
    # [ValidateSet('None', 'AZ', 'Numeric', 'Integer', 'Decimal', 'Symbol', 'File', 'URL', 'Email', 'IPv4', 'IPv6')]

#region Form Scripts
    $ChkButton_Click = {
        If ($ChkButton.Text -eq $($script:ToolLangINI['input']['CheckAll'])) {
            $ChkButton.Text   = $($script:ToolLangINI['input']['CheckNone'])
            [boolean]$checked = $True
        } Else {
            $ChkButton.Text   = $($script:ToolLangINI['input']['CheckAll'])
            [boolean]$checked = $False
        }
        ForEach ($Control In $floPanel.Controls) { If ($control -is [System.Windows.Forms.CheckBox]) { $control.Checked = $checked } }
    }

    # Start form validation and make sure everything entered is correct
    $btn_Accept_Click = {
        [string[]]$currentValues  = @('')
        [boolean] $ValidatedInput = $True
        ForEach ($Control In $floPanel.Controls)
        {
            If (($Control -is [System.Windows.Forms.TextBox]) -and ($Control.Visible -eq $True))
            {
                $Control.BackColor = 'Window'
                If (($Type -eq 'LIST') -and ($Control.Text.Contains(';') -eq $True))
                {
                    [string[]]$ControlText = ($Control.Text).Split(';')
                    $Control.Text = ''    # Remove current data so that it can be used as a landing control for the split data
                    ForEach ($item In $ControlText) { AddButton_Click -Value $item -Override $false -AddType 'TEXT' }
                }
            }
        }

        # Reset Control Loop for any new fields that may have been added
        [string]$validationText = $($script:ToolLangINI['input']['ValidationFail'])
        ForEach ($Control In $floPanel.Controls)
        {
            If (($Control -is [System.Windows.Forms.TextBox]) -and ($Control.Visible -eq $True))
            {
                $ValidatedInput = $(ValidateInputBox -Control $Control)
                If ($ValidatedInput -eq $True)
                {
                    If (($Type -eq 'LIST') -and (([string]::IsNullOrEmpty($Control.Text) -eq $false) -and ($currentValues -contains ($Control.text))))
                    {
                        $ValidatedInput = $false
                        $validationText = $($script:ToolLangINI['input']['DuplicateFound'])
                    }
                    Else { $currentValues += $Control.Text }
                }

                If ($ValidatedInput -eq $false)
                {
                    $Control.Focus()
                    $Control.SelectAll()
                    $ToolTip.Show($validationText, $Control, 12, $Control.Height, 2500)
                    $Control.BackColor = 'Info'
                    Break
                }
            }
        }

        $currentValues = $null
        If ($ValidatedInput -eq $True) { $frm_Input.DialogResult = [System.Windows.Forms.DialogResult]::OK }
    }

    $frm_Input_Resize = {
        # Change textbox widths for the scroll bar
        If ($Type -eq 'LIST')
        {
            ForEach ($Control In $floPanel.Controls)
            {
                If ($Control -is [System.Windows.Forms.TextBox])
                {
                    If ($floPanel.VerticalScroll.Visible -eq $false) { $Control.Width = 340                        }
                    Else { $Control.Width = 340 - [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth }
                }
            }
        }
    }

    [int]$numberOfTextBoxes = 0
    $AddButton_Click = { AddButton_Click -Value '' -Override $false -AddType 'TEXT' }
    Function AddButton_Click ([string]$Value, [boolean]$Override, [string]$AddType, [string]$ItemTip)
    {
        [int]$BoxNumber = 0
        ForEach ($Control In $floPanel.Controls) { If (($Control -is [System.Windows.Forms.TextBox]) -or ($Control -is [System.Windows.Forms.CheckBox])) { $BoxNumber++ } }
        If ($BoxNumber -eq ($MaxNumberInputBoxes - 1)) { $AddButton.Visible = $false }    # Hide 'Add' button if required
        If ($BoxNumber -eq ($MaxNumberInputBoxes)) { Return }

        If ($AddType -eq 'TEXT')
        {
            ForEach ($control In $floPanel.Controls) {
                If ($control -is [System.Windows.Forms.TextBox]) {
                    [System.Windows.Forms.TextBox]$isEmtpy = $null
                    If ([string]::IsNullOrEmpty($control.Text) -eq $True) { $isEmtpy = $control; Break }
                }
            }

            If ($Override -eq $True) { $isEmtpy = $null } 
            If ($isEmtpy -ne $null)
            {
                $isEmtpy.Select()
                $isEmtpy.Text = $Value
                Return
            }
        }

        # Increase form size, move buttons down, add new field
        $numberOfTextBoxes++
        If ($AddType -eq 'TEXT')
        {
            # Add new counter label
            $labelCounter           = (New-Object -TypeName 'System.Windows.Forms.Label')
            $labelCounter.Size      = ' 21,   23'
            $labelCounter.Font      = $sysFont
            $labelCounter.Text      = "$($BoxNumber + 1):"
            $labelCounter.TextAlign = 'MiddleRight'
            $labelCounter.Margin    = '1, 1, 6, 2'    # Using Margin as we are relying on
            $labelCounter.Padding   = '0, 0, 0, 0'    # the flow panel to position controls: Left,Top,Right,Bottom
            $floPanel.Controls.Add($labelCounter)

            # Add new text box and select it for focus
            $textBox                = (New-Object -TypeName 'System.Windows.Forms.TextBox')
            $textBox.Size           = '340, 23'
            $textBox.Font           = $sysFont
            $textBox.Name           = "textBox$BoxNumber"
            $textBox.Text           = $Value.Trim()
            $textBox.Margin         = '1, 1, 0, 2'
            $textBox.Padding        = '0, 0, 0, 0'

            If (($Validation -ne 'None') -and (($Type -eq 'Simple') -or ($Type -eq 'List'))) {
                [void](SendMessage -ControlHandle $textBox.Handle -DisplayString $($lbl_Validation.Text))
            }

            $floPanel.Controls.Add($textBox)
            $floPanel.Controls["textbox$BoxNumber"].Select()
            $frm_Input_Resize.Invoke()
        }
        ElseIf ($AddType -eq 'CHECK')
        {
            # Add new check box
            $chkBox                 = (New-Object -TypeName 'System.Windows.Forms.CheckBox')
            $chkBox.Size            = "$(370 - 2 - [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth), 23"
            $chkBox.Font            = $sysFont
            $chkBox.Name            = "chkBox$BoxNumber"
            $chkBox.Text            = $Value + $ItemTip
            $chkBox.TextAlign       = 'MiddleLeft'
            $chkBox.Margin          = '1, 1, 0, 2'
            $chkBox.Padding         = '0, 0, 0, 0'
            $floPanel.Controls.Add($chkBox)
            $floPanel.Controls["chkbox$BoxNumber"].Select()
        }
        Else { }
    }

    Function Change-Form ([string]$ChangeTo)
    {
        If (($Type -eq 'Check') -or ($Type -eq 'List') -or ($Type -eq 'Large'))
        {   # Large form
            $frm_Input.ClientSize = '394, 251'
            $btn_Accept.Location  = '307, 214'
            $btn_Cancel.Location  = '220, 214'
        }
        Else
        {   # Small form
            $frm_Input.ClientSize = '394, 147'
            $btn_Accept.Location  = '307, 110'
            $btn_Cancel.Location  = '220, 110'
        }

        $frm_Input.MinimumSize = $frm_Input.Size
        If (($Type -eq 'List') -or ($Type -eq 'Check')) { $frm_Input.MaximumSize = "$($frm_Input.Width), 9999"; $frm_Input.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Show }
        Else                                            { $frm_Input.MaximumSize =    $frm_Input.Size         ; $frm_Input.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide }
    }

    Function ValidateInputBox ([System.Windows.Forms.Control]$Control)
    {
        $Control.Text = ($Control.Text.Trim())
        [boolean]$ValidateResult = $false
        [string] $StringToCheck  = $($Control.Text)

        # Ignore for LARGE fields
        If ($Type -eq 'LARGE') { Return $True }

        # Ignore control if empty
        If ([string]::IsNullOrEmpty($StringToCheck) -eq $True) { Return $True }

        # Validate
        Switch ($Validation)
        {
            'AZ'      { $ValidateResult = ($StringToCheck -match "^[A-Za-z]+$");            Break }              # Letters only (A-Za-z)
            'Numeric' { $ValidateResult = ($StringToCheck -match '^(-)?([\d]+)?\.?[\d]+$'); Break }              # Both integer and decimal numbers
            'Integer' { $ValidateResult = ($StringToCheck -match '^(-)?[\d]+$');            Break }              # Integer numbers only
            'Decimal' { $ValidateResult = ($StringToCheck -match '^(-)?[\d]+\.[\d]+$');     Break }              # Decimal numbers only
            'Symbol'  { $ValidateResult = ($StringToCheck -match '^[^A-Za-z0-9]+$');        Break }              # Any symbol (not numbers or letters)
            'File'    {                                                                                          # Valid file or folder name
                $StringToCheck  = $StringToCheck.TrimEnd('\')
                $ValidateResult = ($StringToCheck -match "^(?:[a-zA-Z]\:|\\\\[\w\.]+\\[\w.$]+)\\(?:[\w]+\\)*\w([\w.])+$")
                Break
            }
            'URL'     {                                                                                          # URL
                [url]    $url       = ''
                [boolean]$ValidURL1 = ($StringToCheck -match '^(ht|(s)?f|)tp(s)?:\/\/(.*)\/([a-z]+\.[a-z]+)')    # http(s):// or (s)ftp(s)://
                [boolean]$ValidURL2 = ([System.Uri]::TryCreate($StringToCheck, [System.UriKind]::Absolute, [ref]$url))
                $ValidateResult     = ($ValidURL1 -and $ValidURL2)
                Break
            }
            'Email'   {                                                                                          # email@address.validation
                Try   { $ValidateResult = (($StringToCheck -as [System.Net.Mail.MailAddress]).Address -eq $StringToCheck) }
                Catch { $ValidateResult =   $false }
                Break
            }
            'IPv4'    {                                                                                          # IPv4 address (1.2.3.4)
                [boolean]$Octets  = (($StringToCheck.Split('.') | Measure-Object).Count -eq 4)
                [boolean]$ValidIP =  ($StringToCheck -as [ipaddress]) -as [boolean]
                $ValidateResult   =  ($ValidIP -and $Octets)
                Break
            }
            'IPv6'    {                                                                                          # IPv6 address (REGEX from 'https://www.powershellgallery.com/packages/IPv6Regex/1.1.1')
                [string]$IPv6 = @"
                    ^((([0-9a-f]{1,4}:){7}([0-9a-f]{1,4}|:))|(([0-9a-f]{1,4}:){6}(:[0-9a-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9])|:))|(([0-9a-f]
                    {1,4}:){5}(((:[0-9a-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9])|:))|(([0-9a-f]{1,4}:){4}(((:[0-9a-f]{1,4}){1,3})|((:[0-9a-f]
                    {1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9]))|:))|(([0-9a-f]{1,4}:){3}(((:[0-9a-f]{1,4}){1,4})|((:[0-9a-f]{1,4}){0,2}:((25[0-5]|
                    2[0-4]\d|1\d\d|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9]))|:))|(([0-9a-f]{1,4}:){2}(((:[0-9a-f]{1,4}){1,5})|((:[0-9a-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]
                    ?[0-9])\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9]))|:))|(([0-9a-f]{1,4}:){1}(((:[0-9a-f]{1,4}){1,6})|((:[0-9a-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9])\.){3}(25[0-5]|
                    2[0-4]\d|1\d\d|[1-9]?[0-9]))|:))|(:(((:[0-9a-f]{1,4}){1,7})|((:[0-9a-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?[0-9]))|:)))$
"@
                $ValidateResult = ($StringToCheck -match $IPv6)
                Break
            }
            Default   {                                                                                          # No Validation
                $ValidateResult = $True
            }
        }
        Return $ValidateResult
    }

    $frm_Input_Cleanup_FormClosed = {
        Try {
            $btn_Accept.Remove_Click($btn_Accept_Click)
            $AddButton.Remove_Click($AddButton_Click)
        } Catch {}
        $frm_Input.Remove_Resize($frm_Input_Resize)
        $frm_Input.Remove_FormClosed($frm_Input_Cleanup_FormClosed)
    }
#endregion
#region Input Form Controls
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $frm_Input                      = (New-Object -TypeName 'System.Windows.Forms.Form')
    $frm_Input.FormBorderStyle      = 'Sizable'
    $frm_Input.Text                 = " $Title"
    $frm_Input.MaximizeBox          = $False
    $frm_Input.MinimizeBox          = $False
    $frm_Input.ControlBox           = $True
    $frm_Input.ShowIcon             = $False
    $frm_Input.ShowInTaskbar        = $False
    $frm_Input.AutoScaleDimensions  = '6, 13'
    $frm_Input.AutoScaleMode        = 'None'
    $frm_Input.ClientSize           = '394, 147'    # 400 x 175
    $frm_Input.StartPosition        = 'CenterScreen' # 'CenterParent'
    $frm_Input.Add_Resize($frm_Input_Resize)

    $ToolTip                        = (New-Object -TypeName 'System.Windows.Forms.ToolTip')
                                    
    $lbl_Description                = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Description.Location       = ' 12,  12'
    $lbl_Description.Size           = '370,  48'
    $lbl_Description.Font           = $sysFont
    $lbl_Description.Text           = $($Description.Trim())
    $frm_Input.Controls.Add($lbl_Description)

    If (($Validation -ne 'None') -and (($Type -eq 'Simple') -or ($Type -eq 'List')))
    {
        $lbl_Validation             = (New-Object -TypeName 'System.Windows.Forms.Label')
        $lbl_Validation.Location    = '212,  60'
        $lbl_Validation.Size        = '170,  15'
        $lbl_Validation.Text        = "$($script:ToolLangINI['input']['Validation']) $($script:ToolLangINI['input'][$Validation])"
        $lbl_Validation.TextAlign   = 'BottomRight'
        $frm_Input.Controls.Add($lbl_Validation)
    }

    $btn_Accept                     = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_Accept.Location            = '307, 110'
    $btn_Accept.Size                = ' 75,  25'
    $btn_Accept.Font                = $sysFont
    $btn_Accept.Text                = $($script:ToolLangINI['input']['OK'])
    $btn_Accept.Anchor              = 'Bottom, Right'
    $btn_Accept.Add_Click($btn_Accept_Click)
    If ($Type -ne 'LARGE') { $frm_Input.AcceptButton = $btn_Accept }
    $frm_Input.Controls.Add($btn_Accept)

    $btn_Cancel                     = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_Cancel.Location            = '220, 110'
    $btn_Cancel.Size                = ' 75,  25'
    $btn_Cancel.Font                = $sysFont
    $btn_Cancel.Text                = $($script:ToolLangINI['input']['Cancel'])
    $btn_Cancel.Anchor              = 'Bottom, Right'
    $btn_Cancel.DialogResult        = [System.Windows.Forms.DialogResult]::Cancel
    $frm_Input.CancelButton         = $btn_Cancel
    $frm_Input.Controls.Add($btn_Cancel)
    $frm_Input.Add_FormClosed($frm_Input_Cleanup_FormClosed)

    $floPanel                       = (New-Object -TypeName 'System.Windows.Forms.FlowLayoutPanel')
    $floPanel.Location              = ' 11,  74'
    $floPanel.Size                  = '372,  26'
    $floPanel.AutoScroll            = $True
    $floPanel.Padding               = '0, 0, 0, 0'
    $floPanel.AutoScrollMargin      = '0, 0'
    $floPanel.Anchor                = 'Top, Bottom, Left, Right'
    $frm_Input.Controls.Add($floPanel)
#endregion
#region Input Form Controls Part 2
    [string]$ItemTip = ''
    Switch ($Type)
    {
        'LIST' {
            # List of text boxes
            [int]$itemCount = ($CurrentValue.Count)
            If ($itemCount -ge 5) { [int]$numberOfTextBoxes = $itemCount + 1 } Else { [int]$numberOfTextBoxes = 5 }
            $numberOfTextBoxes--    # Count from zero

            # Add 'Add' button
            $AddButton              = (New-Object -TypeName 'System.Windows.Forms.Button')
            $AddButton.Location     = " 39, $($btn_Accept.Top)"
            $AddButton.Size         = ' 75,  25'
            $AddButton.Font         = $sysFont
            $AddButton.Text         = $($script:ToolLangINI['input']['Add'])
            $AddButton.Anchor       = 'Bottom, Left'
            $AddButton.Add_Click($AddButton_Click)
            $frm_Input.Controls.Add($AddButton)

            # Add initial textboxes
            For ($i = 0; $i -le $numberOfTextBoxes; $i++) { AddButton_Click -Value ($CurrentValue[$i]) -Override $True -AddType 'TEXT' }
            $floPanel.Controls['textbox0'].Select()
            Break
        }

        'CHECK' {
            # Add 'Check All' button
            $ChkButton              = (New-Object -TypeName 'System.Windows.Forms.Button')
            $ChkButton.Location     = " 12, $($btn_Accept.Top)"
            $ChkButton.Size         = '125,  25'
            $ChkButton.Font         = $sysFont
            $ChkButton.Text         = $($script:ToolLangINI['input']['CheckAll'])
            $ChkButton.Anchor       = 'Bottom, Left'
            $ChkButton.Add_Click($ChkButton_Click)
            $frm_Input.Controls.Add($ChkButton)

            # Add initial textboxes
            [int]$i = 0
            If ($InputDescription -ne '') { For ($x=0;$x-lt$InputList.Count;$x++) { ForEach ($iDec In $InputDescription.Split('|')) { If ($iDec.StartsWith($InputList[$x] + ': ') -eq $true) { $InputList[$x] = $iDec } } } }
            ForEach ($item In $InputList)
            {
                AddButton_Click -Value ($item.Trim()) -Override $True -AddType 'CHECK'
                If ([string]::IsNullOrEmpty($CurrentValue) -eq $false) { If ($CurrentValue.Contains($item.Split(':')[0].Trim())) { $floPanel.Controls["chkBox$i"].Checked = $True } }
                $i++
            }
            $floPanel.Controls['chkBox0'].Select()
            Break
        }

        'OPTION' {
            # Drop down selection list
            If ($InputDescription -ne '') { For ($x=0;$x-lt$InputList.Count;$x++) { ForEach ($iDec In $InputDescription.Split('|')) { If ($iDec.StartsWith($InputList[$x] + ': ') -eq $true) { $InputList[$x] = $iDec } } } }

            $comboBox               = (New-Object -TypeName 'System.Windows.Forms.ComboBox')
            $comboBox.Size          = '370,  23'
            $comboBox.Font          = $sysFont
            $comboBox.DropDownStyle = 'DropDownList'
            $comboBox.Margin        = '1, 1, 1, 1'
            $comboBox.Padding       = '0, 0, 0, 0'
            $floPanel.Controls.Add($comboBox)
            [void]$comboBox.Items.AddRange(($InputList.Trim()))
            $frm_Input.Add_Shown({$comboBox.Select()})
            $comboBox.SelectedIndex = -1
            ForEach ($item In $InputList) { If ([string]::IsNullOrEmpty($CurrentValue) -eq $false) { if ($CurrentValue[0].Contains($item.Split(':')[0].Trim())) { $comboBox.SelectedItem = $item } } }
            Break
        }

        'LARGE' {
            # Multi-line text entry
            $textBox                = (New-Object -TypeName 'System.Windows.Forms.TextBox')
            $textBox.Size           = '370, 127'
            $textBox.Font           = $sysFont
            $textBox.Multiline      = $True
            $textBox.ScrollBars     = 'Vertical'
            $textBox.Margin         = '1, 1, 1, 1'
            $textBox.Padding        = '0, 0, 0, 0'
            $floPanel.Controls.Add($textBox)
            $frm_Input.Add_Shown({$textBox.Select()})
            $textBox.Text           = (($CurrentValue.Trim()) -join "`r`n")
            $textBox.Select()
            Break
        }

        'SIMPLE' {
            # Add default text box
            $textBox                = (New-Object -TypeName 'System.Windows.Forms.TextBox')
            $textBox.Size           = '370,  23'
            $textBox.Margin         = '1, 1, 1, 1'
            $textBox.Padding        = '0, 0, 0, 0'
            $textBox.Font           = $sysFont
            $floPanel.Controls.Add($textBox)
            $textBox.Text           = (($CurrentValue.Trim()) -join "`r`n")
            If (($Validation -ne 'None') -and (($Type -eq 'Simple') -or ($Type -eq 'List'))) {
                [void](SendMessage -hWnd $textBox.Handle -msg '&H1501' -wParam 1 -lParam $($lbl_Validation.Text))
            }
            $textBox.Select()
            Break
        }
        Default { Write-Warning "Input Form: Invalid Type: $Type" }
    }

    Change-Form -ChangeTo $Type
#endregion
#region Show Form And Return Value
    ForEach ($control In $frm_Input.Controls) { $control.Font = $sysFont; Try { $control.FlatStyle = 'Standard' } Catch {} }
    ForEach ($control In $floPanel.Controls)  { $control.Font = $sysFont; Try { $control.FlatStyle = 'Standard' } Catch {} }
    If (($Validation -ne 'None') -and (($Type -eq 'Simple') -or ($Type -eq 'List'))) { $lbl_Validation.Font = $sysFontItalic }
    $result = $frm_Input.ShowDialog($MainForm)

    If ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        Switch ($Type)
        {
            'LIST'   {
                [string[]]$return = @()
                ForEach ($control In $floPanel.Controls) { If ($control -is [System.Windows.Forms.TextBox]) {
                    If ([string]::IsNullOrEmpty($control.Text) -eq $false) { $return += ($($control.Text.Trim())) } }
                } Return $return
            }
            'CHECK'  {
                [string[]]$return = @()
                ForEach ($Control In $floPanel.Controls) { If ($control -is [System.Windows.Forms.CheckBox]) {
                    If ($control.Checked -eq $True) { $return += ($($control.Text.Split(':')[0].Trim())) } }
                } Return $return
            }
            'LARGE'  {
                Do { [string]$return = $($textBox.Text.Trim()).Replace("`r`n", ' ') }
                While ( $return.IndexOf("`r`n") -gt -1 ); Return ($return.Trim("`r`n"))
            }
            'SIMPLE' {
                Do { [string]$return = $($textBox.Text.Trim()).Replace("`r`n", ' ') }
                While ( $return.IndexOf("`r`n") -gt -1 ); Return ($return.Trim("`r`n"))
            }
            'OPTION' {
                Return $($comboBox.SelectedItem.Split(':')[0].Trim())
            }
            Default  {
                Return "Invalid return type: $Type"
            }
        }
    }
    ElseIf ($result -eq [System.Windows.Forms.DialogResult]::Cancel) { Return '!!-CANCELLED-!!' }
#endregion
}

Function Show-AdditionalOptions ()
{
#region FORM SCRIPTS
    $frm_Additional_Cleanup_FormClosed = {
        Try { $btn_Accept.Remove_Click($btn_Accept_Click) } Catch {}
        $frm_Additional.Remove_FormClosed($frm_Additional_Cleanup_FormClosed)
        $frm_Additional.Dispose()
    }

    $btn_Module_Click = {
        [string]  $title       = "$($script:ToolLangINI['additional']['Button']) - $($script:ToolLangINI['add-page4']['Tab'])"
        [string]  $description =  $($script:ToolLangINI['add-page4']['Description'])

        [string[]]$currentVal  = @('')
        If ($lbl_ModuleList.Text -ne $($script:ToolLangINI['add-page4']['None'])) { [string[]]$currentVal  = $($lbl_ModuleList.Text) -split ",`n" }
        [string[]]$returnValue = @(Show-InputForm -Type 'List' -Title $title -Description $description -CurrentValue $currentVal -MaxNumberInputBoxes 5)

        If ([string]::IsNullOrEmpty($returnValue) -eq $True) { $lbl_ModuleList.Text = $($script:ToolLangINI['add-page4']['None']) }
        If ($returnValue -ne '!!-CANCELLED-!!') { $lbl_ModuleList.Text = $($returnValue -join ",`n") }
    }

    $btn_Save_Click = {
        # Save the results before closing the form...
        $script:settings.Timeout        = $($cmo_TimeOut.SelectedItem.Text.Trim())
        $script:settings.Concurrent     = $($cmo_Concurrent.SelectedItem.Text.Trim())
        $script:settings.OutputLocation = $($txt_Location.Text.Trim())
        $script:settings.SessionPort    = $($txt_Port.Text.Trim())
        $script:settings.SessionUseSSL  = $($chk_UseSSL.Checked.ToString())

        If ($lbl_ModuleList.Text -eq $($script:ToolLangINI['add-page4']['None'])) { $script:settings.Modules = '' }
        Else                                                                      { $script:settings.Modules = $($lbl_ModuleList.Text) }

        $frm_Additional.DialogResult    = [System.Windows.Forms.DialogResult]::OK
    }
#endregion
#region MAIN FORM
    $frm_Additional                     = (New-Object -TypeName 'System.Windows.Forms.Form')
    $frm_Additional.FormBorderStyle     = 'FixedDialog'
    $frm_Additional.MaximizeBox         =  $False
    $frm_Additional.MinimizeBox         =  $False
    $frm_Additional.ControlBox          =  $False
    $frm_Additional.Text                = $($script:ToolLangINI['additional']['Button'])
    $frm_Additional.ShowInTaskbar       =  $False
    $frm_Additional.AutoScaleDimensions = '6, 13'
    $frm_Additional.AutoScaleMode       = 'None'
    $frm_Additional.ClientSize          = '494, 351'    # 500 x 379
    $frm_Additional.StartPosition       = 'CenterParent'
    $frm_Additional.Add_FormClosed($frm_Additional_Cleanup_FormClosed)

    $lbl_Description                    = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Description.Location           = ' 12,  12'
    $lbl_Description.Size               = '470,  33'
    $lbl_Description.Text               = $($script:ToolLangINI['additional']['Description'])
    $frm_Additional.Controls.Add($lbl_Description)

    $tab_PagesExt                       = (New-Object -TypeName 'System.Windows.Forms.TabControl')
    $tab_PagesExt.Location              = ' 12,  60'
    $tab_PagesExt.Size                  = '470, 239'
    $tab_PagesExt.Padding               = ' 12,   6'
    $tab_PagesExt.SelectedIndex         = 0
    $tab_PagesExt.Add_SelectedIndexChanged($tab_Pages_SelectedIndexChanged)
    $frm_Additional.Controls.Add($tab_PagesExt)

    $ext_Page1                         = (New-Object -TypeName 'System.Windows.Forms.TabPage')
    $ext_Page1.BackColor               = 'Control'
    $ext_Page1.Text                    = ($script:ToolLangINI['add-page1']['Tab'])
    $tab_PagesExt.Controls.Add($ext_Page1)

    $ext_Page2                         = (New-Object -TypeName 'System.Windows.Forms.TabPage')
    $ext_Page2.BackColor               = 'Control'
    $ext_Page2.Text                    = ($script:ToolLangINI['add-page2']['Tab'])
    $tab_PagesExt.Controls.Add($ext_Page2)

    $ext_Page3                         = (New-Object -TypeName 'System.Windows.Forms.TabPage')
    $ext_Page3.BackColor               = 'Control'
    $ext_Page3.Text                    = ($script:ToolLangINI['add-page3']['Tab'])
    $tab_PagesExt.Controls.Add($ext_Page3)

    $ext_Page4                         = (New-Object -TypeName 'System.Windows.Forms.TabPage')
    $ext_Page4.BackColor               = 'Control'
    $ext_Page4.Text                    = ($script:ToolLangINI['add-page4']['Tab'])
    $tab_PagesExt.Controls.Add($ext_Page4)
#endregion
#region BUTTONS
    $btn_Reset                         = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_Reset.Location                = ' 12, 314'
    $btn_Reset.Size                    = '125,  25'
    $btn_Reset.Font                    = $sysFont
    $btn_Reset.Text                    = $($script:ToolLangINI['additional']['Button_Reset'])
    $btn_Reset.Add_Click({
        # Reset all values to defaults
        $cmo_Timeout.SelectedIndex     =  2    # 60
        $cmo_Concurrent.SelectedIndex  =  2    #  5
        $txt_Location.Text             = 'C:\QA\Results\'
        $chk_UseSSL.Checked            =  $false
        $txt_Port.Text                 = '5985'
        $lbl_ModuleList.Text           = $($script:ToolLangINI['add-page4']['None'])    # (none)
    })
    $frm_Additional.Controls.Add($btn_Reset)

    $btn_Save                          = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_Save.Location                 = '407, 314'
    $btn_Save.Size                     = ' 75,  25'
    $btn_Save.Font                     = $sysFont
    $btn_Save.Text                     = $($script:ToolLangINI['additional']['Button_Save'])
    $btn_Save.Add_Click($btn_Save_Click)
    $frm_Additional.AcceptButton = $btn_Save
    $frm_Additional.Controls.Add($btn_Save)

    $btn_Cancel                        = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_Cancel.Location               = '317, 314'
    $btn_Cancel.Size                   = ' 75,  25'
    $btn_Cancel.Font                   = $sysFont
    $btn_Cancel.Text                   = $($script:ToolLangINI['additional']['Button_Cancel'])
    $btn_Cancel.Add_Click({$frm_Additional.DialogResult = [System.Windows.Forms.DialogResult]::Cancel})
    $frm_Additional.CancelButton       = $btn_Cancel
    $frm_Additional.Controls.Add($btn_Cancel)
#endregion
#region TAP PAGES
  # PAGE 1
    $lbl_Title1                        = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Title1.Location               = ' 12,  12'
    $lbl_Title1.Size                   = '438,  33'
    $lbl_Title1.Text                   = $($script:ToolLangINI['add-page1']['Title'])
    $ext_Page1.Controls.Add($lbl_Title1)

    $lbl_TimeOut1                      = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_TimeOut1.Location             = ' 12,  60'
    $lbl_TimeOut1.Size                 = '150,  27'
    $lbl_TimeOut1.Text                 = $($script:ToolLangINI['add-page1']['Timeout'])
    $lbl_TimeOut1.TextAlign            = 'MiddleRight'
    $ext_Page1.Controls.Add($lbl_Timeout1)

    $cmo_TimeOut                       = (New-Object -TypeName 'System.Windows.Forms.ComboBox')
    $cmo_TimeOut.Location              = '168,  60'
    $cmo_TimeOut.Size                  = ' 75,  27'
    $cmo_TimeOut.ItemHeight            = ' 21'
    $cmo_TimeOut.DrawMode              = 'OwnerDrawFixed'
    $cmo_TimeOut.DropDownStyle         = 'DropDownList'
    $cmo_TimeOut.Add_DrawItem(            { ComboIcons_OnDrawItem       -Control $this })
    $cmo_TimeOut.Add_SelectedIndexChanged({ cmo_t1_SelectedIndexChanged -Control $this })
    $ext_Page1.Controls.Add($cmo_TimeOut)
    Load-ComboBoxIcon -ComboBox $cmo_TimeOut -Items @('30','45','60','75','90','120') -SelectedItem $($script:settings.Timeout) -Type 'TimeOut' -Clear

    $lbl_TimeOut2                      = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_TimeOut2.Location             = '249,  60'
    $lbl_TimeOut2.Size                 = '201,  27'
    $lbl_TimeOut2.Text                 = $($script:ToolLangINI['add-page1']['SecondsPer'])
    $lbl_TimeOut2.TextAlign            = 'MiddleLeft'
    $ext_Page1.Controls.Add($lbl_TimeOut2)

    $lbl_Concurrent1                   = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Concurrent1.Location          = ' 12,  96'
    $lbl_Concurrent1.Size              = '150,  27'
    $lbl_Concurrent1.Text              = $($script:ToolLangINI['add-page1']['Concurrency'])
    $lbl_Concurrent1.TextAlign         = 'MiddleRight'
    $ext_Page1.Controls.Add($lbl_Concurrent1)

    $cmo_Concurrent                    = (New-Object -TypeName 'System.Windows.Forms.ComboBox')
    $cmo_Concurrent.Location           = '168,  96'
    $cmo_Concurrent.Size               = ' 75,  27'
    $cmo_Concurrent.ItemHeight         = ' 21'
    $cmo_Concurrent.DrawMode           = 'OwnerDrawFixed'
    $cmo_Concurrent.DropDownStyle      = 'DropDownList'
    $cmo_Concurrent.Add_DrawItem(            { ComboIcons_OnDrawItem       -Control $this })
    $cmo_Concurrent.Add_SelectedIndexChanged({ cmo_t1_SelectedIndexChanged -Control $this })
    $ext_Page1.Controls.Add($cmo_Concurrent)
    Load-ComboBoxIcon -ComboBox $cmo_Concurrent -Items @('2','3','5','7','10','15') -SelectedItem $($script:settings.Concurrent) -Type 'Concurrent' -Clear

    $lbl_Concurrent2                   = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Concurrent2.Location          = '249,  96'
    $lbl_Concurrent2.Size              = '201,  27'
    $lbl_Concurrent2.Text              = $($script:ToolLangINI['add-page1']['ChecksAtATime'])
    $lbl_Concurrent2.TextAlign         = 'MiddleLeft'
    $ext_Page1.Controls.Add($lbl_Concurrent2)

  # PAGE 2
    $lbl_Title2                        = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Title2.Location               = ' 12,  12'
    $lbl_Title2.Size                   = '438,  33'
    $lbl_Title2.Text                   = $($script:ToolLangINI['add-page2']['Title'])
    $ext_Page2.Controls.Add($lbl_Title2)

    $lbl_Location                      = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Location.Location             = ' 12,  60'
    $lbl_Location.Size                 = '150,  27'
    $lbl_Location.Text                 = $($script:ToolLangINI['add-page2']['ReportLocation'])
    $lbl_Location.TextAlign            = 'MiddleRight'
    $ext_Page2.Controls.Add($lbl_Location)

    $txt_Location                      = (New-Object -TypeName 'System.Windows.Forms.Textbox')
    $txt_Location.Location             = '174,  65'    # + 6, +5
    $txt_Location.Size                 = '270,  22'    # -12, -5
    $txt_Location.TextAlign            = 'Left'
    $txt_Location.BorderStyle          = 'None'
    If ($($script:settings.OutputLocation) -ne '') { $txt_Location.Text = $($script:settings.OutputLocation) } Else { $txt_Location.Text = 'C:\QA\Results\' }
    $ext_Page2.Controls.Add($txt_Location)

    $txt_L_Outer                       = (New-Object -TypeName 'System.Windows.Forms.Textbox')
    $txt_L_Outer.Location              = '168,  60'
    $txt_L_Outer.Size                  = '282,  27'
    $txt_L_Outer.Multiline             = $True
    $txt_L_Outer.TabStop               = $False
    $txt_L_Outer.Add_Enter({ $txt_Location.Focus.Invoke() })
    $ext_Page2.Controls.Add($txt_L_Outer)    # Border wrapper for Location box to make it look bigger

  # PAGE 3
    $lbl_Title3                        = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Title3.Location               = ' 12,  12'
    $lbl_Title3.Size                   = '438,  33'
    $lbl_Title3.Text                   = $($script:ToolLangINI['add-page3']['Title'])
    $ext_Page3.Controls.Add($lbl_Title3)

    $lbl_UseSSL                        = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_UseSSL.Location               = ' 12,  60'
    $lbl_UseSSL.Size                   = '150,  27'
    $lbl_UseSSL.Text                   = $($script:ToolLangINI['add-page3']['UseSSL'])
    $lbl_UseSSL.TextAlign              = 'MiddleRight'
    $ext_Page3.Controls.Add($lbl_UseSSL)

    $chk_UseSSL                        = (New-Object -TypeName 'System.Windows.Forms.CheckBox')
    $chk_UseSSL.Location               = '168,  60'
    $chk_UseSSL.Size                   = '282,  27'
    $chk_UseSSL.AutoSize               = $false
    $chk_UseSSL.Checked                = ([System.Convert]::ToBoolean($($script:settings.SessionUseSSL)))
    $chk_UseSSL.Text                   = $($script:ToolLangINI['add-page3']['ForWinRM'])
    $chk_UseSSL.Add_CheckedChanged({
        If ($chk_UseSSL.Checked -eq $true) { If ($txt_Port.Text -eq '5985') { $txt_Port.Text = '5986' } }
        Else                               { If ($txt_Port.Text -eq '5986') { $txt_Port.Text = '5985' } }
    })
    $ext_Page3.Controls.Add($chk_UseSSL)

    $lbl_Port1                         = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Port1.Location                = ' 12,  96'
    $lbl_Port1.Size                    = '150,  27'
    $lbl_Port1.Text                    = $($script:ToolLangINI['add-page3']['ConnectionPort'])
    $lbl_Port1.TextAlign               = 'MiddleRight'
    $ext_Page3.Controls.Add($lbl_Port1)

    $txt_Port                          = (New-Object -TypeName 'System.Windows.Forms.Textbox')
    $txt_Port.Location                 = '171, 101'    # +3, +5
    $txt_Port.Size                     = ' 69,  22'    # -6, -5
    $txt_Port.TextAlign                = 'Center'
    $txt_Port.BorderStyle              = 'None'
    $txt_Port.MaxLength                = '5'
    $txt_port.Add_KeyPress({ If ((-not [char]::IsNumber($_.KeyChar)) -and (-not [char]::IsControl($_.KeyChar))) { $_.KeyChar = 0 } })
    If ($($script:settings.SessionPort) -ne '') { $txt_Port.Text = $($script:settings.SessionPort) } Else { $txt_Port.Text = '5985' }
    $ext_Page3.Controls.Add($txt_Port)

    $txt_P_Outer                       = (New-Object -TypeName 'System.Windows.Forms.Textbox')
    $txt_P_Outer.Location              = '168,  96'
    $txt_P_Outer.Size                  = ' 75,  27'
    $txt_P_Outer.Multiline             = $True
    $txt_P_Outer.TabStop               = $False
    $txt_P_Outer.Add_Enter({ $txt_Port.Focus.Invoke() })
    $ext_Page3.Controls.Add($txt_P_Outer)    # Border wrapper for Port box to make it look bigger

    $lbl_Port2                         = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Port2.Location                = '249,  96'
    $lbl_Port2.Size                    = '201,  27'
    $lbl_Port2.Text                    = $($script:ToolLangINI['add-page3']['DefaultPorts'])
    $lbl_Port2.TextAlign               = 'MiddleLeft'
    $ext_Page3.Controls.Add($lbl_Port2)

  # PAGE 4
    $lbl_Title4                        = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Title4.Location               = ' 12,  12'
    $lbl_Title4.Size                   = '438,  33'
    $lbl_Title4.Text                   = $($script:ToolLangINI['add-page4']['Title'])
    $ext_Page4.Controls.Add($lbl_Title4)

    $lbl_Module                        = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Module.Location               = ' 12,  60'
    $lbl_Module.Size                   = '150,  27'
    $lbl_Module.Text                   = $($script:ToolLangINI['add-page4']['ModuleList'])
    $lbl_Module.TextAlign              = 'MiddleRight'
    $ext_Page4.Controls.Add($lbl_Module)

    $btn_Module                        = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_Module.Location               = '168,  60'
    $btn_Module.Size                   = ' 27,  27'
    $btn_Module.Text                   = '...'
    $btn_Module.Add_Click($btn_Module_Click)
    $ext_Page4.Controls.Add($btn_Module)

    $lbl_ModuleList                    = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_ModuleList.Location           = '180,  93'
    $lbl_ModuleList.Size               = '270, 102'
    If ($($script:settings.Modules) -ne '') { $lbl_ModuleList.Text = $($script:settings.Modules) } Else { $lbl_ModuleList.Text = $($script:ToolLangINI['add-page4']['None']) }
    $ext_Page4.Controls.Add($lbl_ModuleList)
#endregion
#region FORM STARTUP / SHUTDOWN
    ForEach ($control In $frm_Additional.Controls) { $control.Font = $sysFont }
    $tab_PagesExt.SelectedIndex = 0
    Return ($frm_Additional.ShowDialog())
#endregion
}

Function Show-AboutSplash ()
{
#region FORM SHUTDOWN
    $frm_About_Cleanup_FormClosed = {
        Try { $sysFontH.Dispose() } Catch {}
        $frm_About.Remove_FormClosed($frm_About_Cleanup_FormClosed)
        $frm_About.Dispose()
        $sysFontH.Dispose()
    }
#endregion
#region MAIN FORM
    $frm_About                     = (New-Object -TypeName 'System.Windows.Forms.Form')
    $frm_About.FormBorderStyle     = 'FixedToolWindow'
    $frm_About.MaximizeBox         =  $False
    $frm_About.MinimizeBox         =  $False
    $frm_About.ControlBox          =  $False
    $frm_About.Text                = "$($script:ToolLangINI['about']['Button']) $($script:toolName)"
    $frm_About.ShowInTaskbar       =  $False
    $frm_About.AutoScaleDimensions = '6, 13'
    $frm_About.AutoScaleMode       = 'None'
    $frm_About.ClientSize          = '419, 226'    # 425 x 250
    $frm_About.StartPosition       = 'CenterParent'
    $frm_About.Add_FormClosed($frm_About_Cleanup_FormClosed)

    $btn_Close                     = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_Close.Location            = '332, 189'
    $btn_Close.Size                = ' 75,  25'
    $btn_Close.Text                = $($script:ToolLangINI['about']['Close'])
    $frm_About.CancelButton        = $btn_Close
    $frm_About.Controls.Add($btn_Close)

    $pic_Logo                      = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_Logo.Location             = ' 12,  12'
    $pic_Logo.Size                 = ' 64,  64'
    $pic_Logo.Image                = [System.Convert]::FromBase64String('
        iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAdgSURBVHhe7ZttbExZGMcHrRZFUaxoaCgRVjReEm+ReouX
        FA0jQipZ4qWRZcXyacXGVxsqKamxtZVISBQl84GmoqrRin5oKGmklE2x0UYXJRVVz57/6bnTe+45dzoz2HubzC/5p9P7POf0Pv85995zznQ8ghim3Ux1TNQN1MSUw5TE9NWg+KtMuj/kdj1lSmb6Kn5j0nXeXVTC
        9FU0MOk67k5KZYoYXYfdTelMEaN06GbS09OV82WKGsAUMUqHbiZqQNSAqAHK+TI5Y8CbN2+opqaGHjx4QC0tLeJoaHz69Em8Cg/HDfjy5QudOXOGZsyYQT169Ai06dmzJ82dO5eKiopEpj3oIyUlheLi4mjgwIG8
        /fXr10U0OI4a8P79e8rIyFDyrcrKygr6Dt+6dUtps3LlShENjmMGtLe309KlS5VcO23YsEG0VNm2bZuS36tXL2poaBAZ9jhmQG5urpKH4btkyRJatGgR9evXT4mfPXtWtO6ktbWVEhMTlVzo4MGDIsseRwz4/Pkz
        jRw5UspZtWoVvXv3TmQQNTY20rx586SciRMnimgn58+fl3LMGj16NB9pwXDEgDt37kjx4cOH8/uBlVevXlH//v2l3EePHoloB+Z7CG6c69atk/KvXbsmMvU4YkB+fr4U37p1q4ioeL1eKffChQsi0mFQTExMIDZ/
        /nyqrq6W8teuXSuy9ThiwOHDh6X4gQMHRERl165dUu6pU6dEhOjIkSNSLC8vjx8fNWpU4Fjv3r2pqamJH9fhiAEnT56U4tnZ2SKignfQnItr3iAtLU2KvXz5kh/fuHGjdDwnJ4cf1+GIARUVFVI8OTmZ382tvH79
        mgYMGCDlYqYI7t+/Lx2HJk2axE2xPhUmT57M2+hwxAA8BUaMGCHlrF+/nj58+CAyOopfuHChlDN27Fg+6wN79+6VYl2pqqqKt7PiiAHAev1CgwcP5pOjxYsXU0JCghLHpQN0j9GutGPHDt7WimMGtLW10YIFC5Rc
        Oy1fvjzwTC8pKZFiffv2pWXLllFmZmZAU6dOlXJg7sePH3l7M44ZADDxCWUtsHr1auny2Lx5sxTfvn27iHTy4sULKQe6ePGiiHbiqAEGODEMe0xkjDbx8fH8Xff7/SKrE9wbsPqDUlNTqbS0VERksCAy8iDd1NgV
        BhiY5/9Dhw7l0+HvjasMGDZsmNQO+wHm9cH3wFUG3Lx5k44fP05Hjx7lOnfuHN8l+p64ygAniBoQNSBqgHK+TP+fAbW1tbRz504+e8P8/smTJ3y5jAlSpOD5jz5CIWIDfJ5UpjymLUz4p5AASod2oFjs+EyZMoUO
        HTrEt8Vw99+zZw9f+GAdf/v2bWlHuK6ujsrLy+nt27fiCFFzczPfGUYMjBs3jvcBnj179u33A3yeRKYGJhKqZPpRRKWOuOzYv38//yzg+fPn4gjxwnDymN+PGTOGzw6xLQ4wUrDZgfnBkCFDqL6+nq5cucJzp02b
        xucRd+/eDRiAjdc+ffrwY3ZEaECBqXhDbUzZCCsd2oGtMJygFZw8NjSx9MW8f/z48dwk9IVlM3aQsBWG0YLCsRACMA/LaBgwZ84cio2NpYKCAh6zI2wDfB6vqWirWpGidGgHdmoQv3HjBv8dBWBPz7gEAF6joMeP
        H/Pcffv20eXLl7mwKYLNDmyEAqwwsbmKfBiDPYdNmzbxmB1hGeDzJDE1mQq2qgppSod24PO/6dOn84+0Zs+eTYMGDaJjx45pDQArVqygpKQkfknMmjWLb66eOHGCj4Y1a9bw3SDsNhmXwKVLl/jf1y2oDMI0oNBS
        sFktTPx/i5QOg4F3Dev706dPU2VlJR/2eLexdQ7Mr7EfUFZWxnOLi4sD22gPHz7kny/iGPpDPtoB3ETv3bvHX+vQGNDCpP6rnM+TZSpWp59FJvvFIjejMSBQSAAfM8Tn+ddUrFWlIpNj7VD8KXdiMUAqJIDP47cU
        bBaMkUaMuUMuN2MyAEM/hUkGjzZ94YZ+EpkBpOIhN2MyQDf0U5hwc9MVDvlFpoRUPORmhAF2Q7/UUrBZeBz+IDIlupUBbA6B/w3WDf1fTMXq5BWZCq4zoKa5hoqeFlFbe5s4IqE+832eCUytpmKtKhSZWlxlQPk/
        5ZTwVwI/8cziTJ0JsgFY2XUsbqxFG8IiKFFka3GNAebiDXlLvFYTrAb8as7XKENk2uIKA6oaq5TiDVlM6DTA50ljwqpO246pQGQGxRUGbCnboisgIMQFHQZ0DP1qc45FT5kSeG4XuMIA/99+ivkzRldIQLsrdiPV
        MOB3a9wi+VIJgisMAIX1hV2aEJcfl8t+zmQKNvRzWR0h4xoDQCgmMAWb7dUyxbM6QsZVBoAQTdAJo2ImqyEsXGcAiNCEP9j5h40rDQBhmoAngrTdHSquNQCEaAKGfho794hQDHBCsbGxleyn/rndsbMb7K6PL39G
        jJu+OFnOFK4JWAdENPQN3PbV2XBMwONwgohGjBu/PB3MhHSmEqGwH3l2wAS3fX3e3oRvhsfzH5yXK93yKsM4AAAAAElFTkSuQmCC')
    $frm_About.Controls.Add($pic_Logo)

    $lbl_Header                    = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Header.Location           = ' 82,  12'
    $lbl_Header.Size               = '250,  32'
    $lbl_Header.Text               = 'Server QA Checks v4'
    $frm_About.Controls.Add($lbl_Header)

    $lbl_SubHeader                 = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_SubHeader.Location        = ' 85,  44'
    $lbl_SubHeader.Size            = '322,  32'
    $lbl_SubHeader.Text            = "Mike Blackett`nsupport@myrandomthoughts.co.uk"
    $frm_About.Controls.Add($lbl_SubHeader)

    $lbl_Version                   = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_Version.Location          = '332,  12'
    $lbl_Version.Size              = ' 75,  32'
    $lbl_Version.Text              = $script:toolVersion
    $lbl_Version.TextAlign         = 'TopRight'
    $frm_About.Controls.Add($lbl_Version)

    $pic_GitHub                    = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_GitHub.Location           = ' 12, 106'
    $pic_GitHub.Size               = ' 16,  29'
    $frm_About.Controls.Add($pic_GitHub)

    $lbl_GitText                   = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_GitText.Location          = ' 34, 103'
    $lbl_GitText.Size              = '373,  16'
    $lbl_GitText.Text              = $($script:ToolLangINI['about']['AllSourceCode'])
    $frm_About.Controls.Add($lbl_GitText)

    $lnk_GitLink                   = (New-Object -TypeName 'System.Windows.Forms.LinkLabel')
    $lnk_GitLink.Location          = ' 34, 119'
    $lnk_GitLink.Size              = '373,  16'
    $lnk_GitLink.Text              = 'https://github.com/my-random-thoughts/qa-checks-v4'
    $lnk_GitLink.Add_Click({ Start-Process -FilePath $($lnk_GitLink.Text) })
    $frm_About.Controls.Add($lnk_GitLink)

    $pic_Flags                     = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_Flags.Location            = ' 12, 153'
    $pic_Flags.Size                = ' 16,  29'
    $frm_About.Controls.Add($pic_Flags)

    $lbl_FlagText                  = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_FlagText.Location         = ' 34, 150'
    $lbl_FlagText.Size             = '373,  16'
    $lbl_FlagText.Text             = $($script:ToolLangINI['about']['FlagIcons'])
    $frm_About.Controls.Add($lbl_FlagText)

    $lnk_FlagLink                  = (New-Object -TypeName 'System.Windows.Forms.LinkLabel')
    $lnk_FlagLink.Location         = ' 34, 166'
    $lnk_FlagLink.Size             = '373,  16'
    $lnk_FlagLink.Text             = 'http://www.icondrawer.com/free.php'
    $lnk_FlagLink.Add_Click({ Start-Process -FilePath $($lnk_FlagLink.Text) })
    $frm_About.Controls.Add($lnk_FlagLink)
#endregion
#region FORM STARTUP
    [System.Drawing.Font]$sysFontH = (New-Object -TypeName 'System.Drawing.Font' ($sysFont.Name, ($sysFont.SizeInPoints + 7), [System.Drawing.FontStyle]::Bold))
    ForEach ($control In $frm_About.Controls) { $control.Font = $sysFont }
    $lbl_Header.Font  = $sysFontH
    $pic_GitHub.Image = $img_MainForm.Images[8]
    $pic_Flags.Image  = $img_MainForm.Images[4]
    [void]$frm_About.ShowDialog()
#endregion
}
#endregion
###################################################################################################
##                                                                                               ##
##   Main Form                                                                                   ##
##                                                                                               ##
###################################################################################################
Function Display-MainForm
{
#region FORM STARTUP / SHUTDOWN
    $InitialFormWindowState        = (New-Object -TypeName 'System.Windows.Forms.FormWindowState')
    $MainFORM_StateCorrection_Load = { $MainForm.WindowState = $InitialFormWindowState }

    $MainFORM_Load = {
        # Change font to a nicer one
        ForEach ($control In $MainForm.Controls)                                        { $control.Font = $sysFont }
        ForEach ($tab     In $tab_Pages.TabPages) { ForEach ($control In $tab.Controls) { $control.Font = $sysFont } }
        Update-NavButtons

        # Get GUI tool language options
        [string[]]$ToolLangList = (Get-ChildItem -Path "$script:scriptLocation\i18n" -Filter '??-??-tool.ini' -ErrorAction Stop | Select-Object -ExpandProperty 'Name' | ForEach-Object -Process { $_.Replace('-tool.ini','') })
        Load-ComboBoxIcon -ComboBox $cmo_t1_ToolLang -Items @($ToolLangList | Sort-Object) -SelectedItem $Language -Type 'ToolLang' -Clear

        # Set some specific fonts
        $lbl_t1_Welcome.Font         = $sysFontBold                # Tab 1 Section Header
        $lbl_t1_MissingFile.Font     = $sysFontItalic              # Hidden by default ("'default-settings.ini' file not found")
        $lbl_t2_CheckSelection.Font  = $sysFontBold                # Tab 2 Section Header
        $lbl_t3_ScriptSelection.Font = $sysFontBold                # Tab 3 Section Header
        $lbl_t4_Complete.Font        = $sysFontBold                # Tab 4 Section Header

        # Set picture and button icons
        $pic_t1_RestoreHelp.Image    = $img_MainForm.Images[13]    # Restore Help
        $pic_t2_SearchClear.Image    = $img_MainForm.Images[ 7]    # Cancel Search
        $btn_t2_SelectAll.Image      = $img_MainForm.Images[ 9]    # Select All
        $btn_t2_SelectInv.Image      = $img_MainForm.Images[10]    # Select Invert
        $btn_t2_SelectNone.Image     = $img_MainForm.Images[11]    # Select None
        $btn_t2_SelectReset.Image    = $img_MainForm.Images[12]    # Reset All
        $pic_t2_SearchHelp.Image     = $img_MainForm.Images[13]    # Search Help

        # Setup default views/messages
        $lbl_t3_NoChecks.Visible        = $True
        $lst_t2_SelectChecks.CheckBoxes = $False
        $lst_t2_SelectChecks.Groups.Add('PleaseNote', ($script:ToolLangINI['page2']['PleaseNote']))    # Second quotes stops error in 'lst_t2_SelectChecks_SelectedIndexChanged'
        Add-ListViewItem -ListView $lst_t2_SelectChecks -Name '*PN1' -SubItems @('', '')                                                -ImageIndex -1 -Group 'PleaseNote' -Enabled $True
        Add-ListViewItem -ListView $lst_t2_SelectChecks -Name '*PN2' -SubItems @($($script:ToolLangINI['page2']['SelectLocation']), '') -ImageIndex -1 -Group 'PleaseNote' -Enabled $True

        # Realign and center everything.!
        $MainFORM_Resize.Invoke()
    }

    $MainFORM_FormClosing = [System.Windows.Forms.FormClosingEventHandler] {
        [System.Windows.Forms.DialogResult]$quit = [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['exit']['Message']), $script:toolName, 'YesNo', 'Question')
        If ($quit -eq [System.Windows.Forms.DialogResult]::No) { $_.Cancel = $True }
    }

    $Form_Cleanup_FormClosed = {
        $tab_Pages.Remove_SelectedIndexChanged($tab_Pages_SelectedIndexChanged)
        $tim_CompleteButton.Remove_Tick($tim_CompleteButton_Tick)
        $btn_t1_Search.Remove_Click($btn_t1_Search_Click)
        $lnk_t1_Language.Remove_Click($lnk_t1_Language_Click)
        $btn_t1_Import.Remove_Click($btn_t1_Import_Click)
        $btn_t1_RestoreINI.Remove_Click($btn_t1_RestoreINI_Click)
        $pic_t1_RestoreHelp.Remove_Click($pic_t1_RestoreHelp_Click)
        $lst_t2_SelectChecks.Remove_Enter($lst_t2_SelectChecks_Enter)
        $lst_t2_SelectChecks.Remove_ItemChecked($lst_t2_SelectChecks_ItemChecked)
        $lst_t2_SelectChecks.Remove_SelectedIndexChanged($lst_t2_SelectChecks_SelectedIndexChanged)
        $lnk_t2_Description.Remove_LinkClicked($lnk_t2_Description_LinkClicked)
        $pic_t2_SearchHelp.Remove_Click($pic_t2_SearchHelp_Click)
        $txt_t2_Search.Remove_TextChanged($txt_t2_Search_TextChanged)
        $chk_t2_Search.Remove_CheckedChanged($chk_t2_Search_CheckedChanged)
        $btn_t2_SetValues.Remove_Click($btn_t2_SetValues_Click)
        $tab_t3_Pages.Remove_SelectedIndexChanged($tab_t3_Pages_SelectedIndexChanged)
        $btn_t3_PrevTab.Remove_Click($btn_t3_PrevTab_Click)
        $btn_t3_NextTab.Remove_Click($btn_t3_NextTab_Click)
        $btn_t3_Complete.Remove_Click($btn_t3_Complete_Click)
        $txt_t4_ShortCode.Remove_TextChanged($txt_t4_ShortCode_TextChanged)
        $btn_t4_Save.Remove_Click($btn_t4_Save_Click)
        $btn_t4_Generate.Remove_Click($btn_t4_Generate_Click)
        $chk_t4_GenerateMini.Remove_CheckedChanged($txt_t4_ShortCode_TextChanged) 
        $btn_t4_Additional.Remove_Click($btn_t4_Additional_Click)

        Try {
            $sysFont.Dispose()
            $sysFontBold.Dispose()
            $sysFontItalic.Dispose()
        } Catch {}

        $MainFORM.Remove_Load($MainFORM_Load)
        $MainFORM.Remove_Load($MainFORM_StateCorrection_Load)
        $MainFORM.Remove_Resize($MainFORM_Resize)
        $MainFORM.Remove_FormClosing($MainFORM_FormClosing)
    }
#endregion
#region FORM Scripts
#region SCRIPTS-GENERAL
    $tab_Pages_SelectedIndexChanged = {
        If ($tab_Pages.SelectedIndex -eq 0) {  $pic_t1_RestoreHelp.Visible = $True                   } Else {  $pic_t1_RestoreHelp.Visible = $False }    # Show/Hide 'INI Tools' button
        If ($tab_Pages.SelectedIndex -eq 1) {  $lbl_t2_ChangesMade.Visible = $script:ShowChangesMade } Else {  $lbl_t2_ChangesMade.Visible = $False }    # Show/Hide 'Selection Changes' label
        If ($tab_Pages.SelectedIndex -eq 2) {                                                        } Else {                                       }
        If ($tab_Pages.SelectedIndex -eq 3) {   $btn_t4_Additional.Visible = $True                   } Else {   $btn_t4_Additional.Visible = $False }    # Show/Hide 'Additional Options' button
        $btn_t1_RestoreINI.Visible = $pic_t1_RestoreHelp.Visible
    }

    $MainFORM_Resize = {
        # Tab 1 - Button/Label/Dropdown cluster in middle
        $btn_t1_Search.Left         = ($tab_Page1.Width        -  $btn_t1_Search.Width)       / 2
        $btn_t1_Import.Left         = ($tab_Page1.Width        -  $btn_t1_Import.Width)       / 2
        $cmo_t1_Language.Left       = ($tab_Page1.Width        -  $cmo_t1_Language.Width)     / 2
        $cmo_t1_SettingsFile.Left   = ($tab_Page1.Width        -  $cmo_t1_SettingsFile.Width) / 2
        $lbl_t1_Language.Left       = ($btn_t1_Search.Left     -  $lbl_t1_Language.Width)     - 6
        $lbl_t1_SettingsFile.Left   = ($btn_t1_Search.Left     -  $lbl_t1_SettingsFile.Width) - 6
        $lbl_t1_MissingFile.Left    = ($btn_t1_Search.Left     +  $btn_t1_Search.Width)       + 6
        $lnk_t1_Language.Left       = ($btn_t1_Search.Left     +  $btn_t1_Search.Width)       + 6
        $btn_t1_RestoreINI.Left     = ($MainFORM.Width         -  $btn_t1_RestoreINI.Width)   / 2
        $pic_t1_RestoreHelp.Left    = ($btn_t1_RestoreINI.Left +  $btn_t1_RestoreINI.Width)   + 6

        # Tab 2 - Column Width
        $lst_t2_SelectChecks.Columns[0].Width = 100
        $lst_t2_SelectChecks.Columns[1].Width = ($lst_t2_SelectChecks.Width - 100 - 4 - [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth)
        $lst_t2_SelectChecks.Columns[2].Width = 0

        # Tab 3 - Column width and Prev/Next buttons - Selected tab only, as other listviews are not selectable
        Try {
            [System.Windows.Forms.ListView]$lvwObject = $tab_t3_Pages.SelectedTab.Controls["lvw_$($tab_t3_Pages.SelectedTab.Text.Trim())"]
            $lvwObject.Columns[0].Width = 225
            $lvwObject.Columns[1].Width = ($lvwObject.Width - 225 - [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth)
            $lvwObject.Columns[2].Width = 0
            $lvwObject.Columns[3].Width = 0
            $lvwObject.Columns[4].Width = 0
        } Catch {}

        $gap = $btn_t3_NextTab.Left - ($btn_t3_PrevTab.Left    +  $btn_t3_PrevTab.Width)
        $btn_t3_PrevTab.Left        = ($tab_Page3.Width        - ($btn_t3_PrevTab.Width       + $btn_t3_NextTab.Width + $gap)) / 2
        $btn_t3_NextTab.Left        = ($btn_t3_PrevTab.Left    +  $btn_t3_PrevTab.Width       + $gap)
        $lbl_t3_SectionTabs.Left    = ($btn_t3_PrevTab.Left    -  $lbl_t3_SectionTabs.Width)  - 6

        # Tab 4 - Button/Label cluster in middle
        $btn_t4_Save.Left           = ($tab_Page4.Width        -  $btn_t4_Save.Width)         / 2
        $btn_t4_Generate.Left       = ($tab_Page4.Width        -  $btn_t4_Generate.Width)     / 2
        $txt_t4_ShortCode.Left      = ($tab_Page4.Width        -  $txt_t4_ShortCode.Width)    / 2
        $txt_t4_SC_Outer.Left       = ($tab_Page4.Width        -  $txt_t4_SC_Outer.Width)     / 2
        $txt_t4_ReportTitle.Left    = ($tab_Page4.Width        -  $txt_t4_ReportTitle.Width)  / 2
        $txt_t4_RT_Outer.Left       = ($tab_Page4.Width        -  $txt_t4_RT_Outer.Width)     / 2
        $lbl_t4_ShortName.Left      = ($btn_t4_Save.Left       -  $lbl_t4_ShortName.Width)    - 6
        $lbl_t4_ReportTitle.Left    = ($btn_t4_Save.Left       -  $lbl_t4_ReportTitle.Width)  - 6
        $lbl_t4_CodeEg.Left         = ($btn_t4_Save.Left       +  $btn_t4_Save.Width)         + 6
        $lbl_t4_QAReport.Left       = ($btn_t4_Save.Left       +  $btn_t4_Save.Width)         + 6
        $chk_t4_GenerateMini.Left   = ($btn_t4_Save.Left       +  $btn_t4_Save.Width)         + 6
        $btn_t4_Additional.Left     = ($MainFORM.Width         -  $btn_t4_Additional.Width)   / 2
    }

    # ###########################################
#endregion
#region SCRIPTS-TAB-1
    Function cmo_t1_ToolLang_SelectedIndexChanged
    {
        If (($script:SelectedToolLang -ne '') -and ($($script:SelectedToolLang) -ne $($cmo_t1_ToolLang.SelectedItem.Text)))
        {
            [System.Windows.Forms.DialogResult]$ChangeLang = [System.Windows.Forms.MessageBox]::Show($MainFORM, ($($script:ToolLangINI['page1']['ChangeLanguage']) -f $script:toolName, $script:SelectedToolLang, $cmo_t1_ToolLang.SelectedItem.Text), $($script:ToolLangINI['page1']['ToolLanguage']), 'YesNo', 'Question')
            If ($ChangeLang -eq [System.Windows.Forms.DialogResult]::No) { Return }
        }

        # Load the new language
        $script:SelectedToolLang = $($cmo_t1_ToolLang.SelectedItem.Text)
        [void]$script:ToolLangINI.Clear()
        $script:ToolLangINI = (Load-IniFile -Inputfile "$script:scriptLocation\i18n\$($cmo_t1_ToolLang.SelectedItem.Name)-tool.ini")
        [void](ChangeLanguage)
    }

    Function cmo_t1_SelectedIndexChanged ([System.Windows.Forms.ComboBox]$Control)
    {
        $script:SelectedLanguage = ($cmo_t1_Language.SelectedItem)
        $script:SelectedSettings = ($cmo_t1_SettingsFile.SelectedItem)
        If (([string]::IsNullOrEmpty($script:SelectedLanguage) -eq $False) -and ($script:SelectedLanguage.Text -ne 'Unknown')) { $btn_t1_Import.Enabled = $True }

        # If the settings file has changed, update the language to the settings specific one (if possible)
        If (($Control.Name -eq 'Settings') -and ($cmo_t1_Language.Items.Count -gt 0))
        {
            [object]$LangSel = ''
            Try {
                [hashtable]$LangSet =  (Load-IniFile -Inputfile "$script:scriptLocation\settings\$($cmo_t1_SettingsFile.SelectedItem.Name).ini")
                           $LangSel = $($script:IC_T1_Language.Where({ $_.Name -eq $($LangSet.Settings.Language) }))
            } Catch { }

            # Fall back to British if selected language does not exist anymore
            If ([string]::IsNullOrEmpty($LangSel) -eq $True) { $LangSel = $($script:IC_T1_Language.Where({ $_.Name -eq 'en-GB' })) }
            $cmo_t1_Language.SelectedItem = $LangSel
        }
    }

    $btn_t1_Search_Click = {
        # Search location and read in scripts
        $MainFORM.Cursor             = 'WaitCursor'
        $cmo_t1_ToolLang.Enabled     =  $False
        $btn_t1_Search.Enabled       =  $False
        $btn_t1_Import.Enabled       =  $False
        $cmo_t1_Language.Enabled     =  $False
        $lnk_t1_Language.Enabled     =  $False
        $cmo_t1_SettingsFile.Enabled =  $False
        $lbl_t1_MissingFile.Visible  =  $False

        $script:IC_T1_Language.Clear()
        $script:IC_T1_Settings.Clear()

        $script:scriptLocation = (Get-Folder -Description $($script:ToolLangINI['page1']['FolderOpen']) -InitialDirectory $script:scriptLocation -ShowNewFolderButton $False)
        If ([string]::IsNullOrEmpty($script:scriptLocation) -eq $True) { $btn_t1_Search.Enabled = $True; $MainFORM.Cursor = 'Default'; Return }
        If ($script:scriptLocation.EndsWith('\checks')) { $script:scriptLocation = $script:scriptLocation.TrimEnd('\checks') }

        # Check there is a CHECKS folder with actual checks
        [object]$qaChecks = (Get-ChildItem -Path "$script:scriptLocation\checks" -Recurse -Filter '???-??-*.ps1')

        If ((Test-Path -Path "$script:scriptLocation\checks") -eq $False)
        {
            [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['page1']['FolderError']), $script:toolName, 'OK', 'Error')
            $btn_t1_Search.Enabled = $True
            $MainFORM.Cursor       = 'Default'
            Return
        }

        # Check SETTINGS file is loaded OK
        Try {
            [string[]]$settingList = (Get-ChildItem -Path "$script:scriptLocation\settings" -Filter '*.ini' -ErrorAction Stop | Select-Object -ExpandProperty 'Name' | ForEach-Object -Process { $_.Replace('.ini','') } )
            Load-ComboBoxIcon -ComboBox $cmo_t1_SettingsFile -Items @($settingList | Sort-Object) -SelectedItem 'default-settings' -Type 'Settings' -Clear
            If ($settingList.Contains('default-settings') -eq $False) { Throw }
        }
        Catch
        {
            $newItem = (New-IconComboItem)
            $cmo_t1_SettingsFile.Items.Clear()
            $newItem.Icon = 0; $newItem.Name = 'default-settings'; $newItem.Text = $($script:ToolLangINI['page1']['UseDefault'])
            [void]$script:IC_T1_Settings.Insert(0, $newItem); $newItem = $null
            [void]$cmo_t1_SettingsFile.Items.AddRange($script:IC_T1_Settings)
            $cmo_t1_SettingsFile.SelectedIndex = 0
            $lbl_t1_MissingFile.Visible        = $True
        }

        # Check LANGUAGE file is loaded OK
        [boolean]$iniLoadOK = $True
        Try {
            [string[]]$langList = @(Get-ChildItem -Path "$script:scriptLocation\i18n" -Filter '??-??.ini' -ErrorAction Stop | Select-Object -ExpandProperty 'Name' | ForEach-Object -Process { $_.Replace('.ini','') })
            If ($langList.Contains('en-GB') -eq $False) { Throw }    # Oh dear.!
            Load-ComboBoxIcon -ComboBox $cmo_t1_Language -Items @($langList | Sort-Object) -SelectedItem 'en-GB' -Type 'Language' -Clear
            $lnk_t1_Language.Text = $($script:ToolLangINI['page1']['Translation'])
        } Catch {
            # No language file, stop import!
            Load-ComboBoxIcon -ComboBox $cmo_t1_Language -Items @($($script:ToolLangINI['page1']['LangMissing'])) -SelectedItem $($script:ToolLangINI['page1']['LangMissing']) -Clear -Type 'Language'
            $iniLoadOK = $False
            $lnk_t1_Language.Text = $($script:ToolLangINI['page1']['LangMissing2'])
            [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['page1']['MissingENGB']), 'Language File Missing', 'OK', 'Error')
        }
        
        $cmo_t1_ToolLang.Enabled     = $True
        $btn_t1_Search.Enabled       = $True
        $btn_t1_Import.Enabled       = $iniLoadOK
        $cmo_t1_Language.Enabled     = $iniLoadOK
        $lnk_t1_Language.Enabled     = $iniLoadOK
        $cmo_t1_SettingsFile.Enabled = $iniLoadOK
        $btn_t1_Import.Focus()
        $MainFORM.Cursor = 'Default'
    }

    $lnk_t1_Language_Click = {
        $selLanguage = (Load-IniFile -Inputfile $("$script:scriptLocation\i18n\$($cmo_t1_Language.SelectedItem.Name).ini"))
        [System.Text.StringBuilder]$MessageBox = ''
        $MessageBox.AppendLine("$($selLanguage.Language.Name)")
        $MessageBox.AppendLine("$($cmo_t1_Language.SelectedItem.Name).ini"); $MessageBox.AppendLine("")
        $MessageBox.AppendLine("$($selLanguage.Language.Author)")
        $MessageBox.AppendLine("$($selLanguage.Language.Contact)");          $MessageBox.AppendLine("")
        $MessageBox.AppendLine("$($selLanguage.Language.LastUpdated)")
        [System.Windows.Forms.MessageBox]::Show($MainFORM, $MessageBox.ToString(), $($script:ToolLangINI['page1']['Translation']), 'OK', 'Information')
        $selLanguage = $null
    }

    $btn_t1_Import_Click = {
        If (($cmo_t1_SettingsFile.Text -eq '') -or ($cmo_t1_Language.Text -eq '')) { Return }

        $MainFORM.Cursor                = 'WaitCursor'
        $cmo_t1_ToolLang.Enabled        =  $False
        $btn_t1_RestoreINI.Enabled      =  $False
        $btn_t1_Search.Enabled          =  $False
        $btn_t1_Import.Enabled          =  $False
        $cmo_t1_Language.Enabled        =  $False
        $lnk_t1_Language.Enabled        =  $False
        $cmo_t1_SettingsFile.Enabled    =  $False
        [void]$script:ListViewCollection.Clear()

        # Load Language, Settings and Help details
        [hashtable]$settingsINI =        (Load-IniFile -Inputfile "$script:scriptLocation\settings\$($script:SelectedSettings.Name).ini")
                   $script:languageINI = (Load-IniFile -Inputfile "$script:scriptLocation\i18n\en-GB.ini"                               )           # Load default values

        If ($script:SelectedLanguage.Name -ne 'en-GB') {
            $script:languageINI = (Load-IniFile -Inputfile "$script:scriptLocation\i18n\$(    $script:SelectedLanguage.Name).ini" -ExistingHashTable $script:languageINI)    # Overwrite language specific
        }

        # Load settings from INI file - if possible
        Try { $txt_t4_ShortCode.Text          = ($settingsINI['settings']['ShortCode'])         } Catch { $txt_t4_ShortCode.Text   = 'ACME' }
        Try { $txt_t4_ReportTitle.Text        = ($settingsINI['settings']['ReportCompanyName']) } Catch { $txt_t4_ReportTitle.Text = 'Acme' }
        Try { $script:settings.Timeout        = ($settingsINI['settings']['Timeout'])           } Catch { }    # \
        Try { $script:settings.Concurrent     = ($settingsINI['settings']['Concurrent'])        } Catch { }    #  \
        Try { $script:settings.OutputLocation = ($settingsINI['settings']['OutputLocation'])    } Catch { }    #   Get All The
        Try { $script:settings.SessionPort    = ($settingsINI['settings']['SessionPort'])       } Catch { }    #   Default Settings
        Try { $script:settings.SessionUseSSL  = ($settingsINI['settings']['SessionUseSSL'])     } Catch { }    #  /
        Try { $script:settings.Modules        = ($settingsINI['settings']['RequiredModules'])   } Catch { }    # /

        # Clear any existing entries and start from scratch
        $tab_t3_Pages.TabPages.Clear()
        $lst_t2_SelectChecks.Items.Clear()
        $lst_t2_SelectChecks.Groups.Clear()
        $lst_t2_SelectChecks.CheckBoxes = $True

        [object[]]$folders = (Get-ChildItem -Path "$script:scriptLocation\checks" -Recurse | Where-Object -FilterScript { $_.PsIsContainer -eq $True } | Select-Object -Property ('Name', 'FullName'))
        [System.Globalization.TextInfo]$TextInfo = (Get-Culture).TextInfo    # Used for 'ToTitleCase' below
        ForEach ($folder In ($folders | Sort-Object -Property 'Name'))
        {
            [string]  $folderName = ($folder.Name.ToLower())
            [string]  $folderPath = ($folder.FullName.ToLower().Substring("$script:scriptLocation\checks\".Length))
            [object[]]$scripts    = (Get-ChildItem -Path "$script:scriptLocation\checks\$folderPath" -Filter '???-??-*.ps1' | Select-Object -ExpandProperty 'Name' | Sort-Object -Property 'Name' )

            # Only run if the folder contains checks
            If ([string]::IsNullOrEmpty($scripts) -eq $False)
            {
                # FOR TAB-2 LIST OF CHECKS
                # Generate GUID for group IDs
                [string]$guid = ([guid]::NewGuid() -as [string]).Split('-')[0]
                $lst_t2_SelectChecks.Groups.Add("$guid", $script:languageINI['Section'][$folderName])

                ForEach ($script In ($scripts | Sort-Object -Property 'Name'))
                {
                    [string]$Name      =  $script.TrimEnd('.ps1')                   # Remove .PS1 extension
                    [string]$checkCode = ($Name.Substring(0, 6).Replace('-',''))    # Get check code: acc-01-local-user  -->  acc01

                    Try { [string]$checkName        =   (                                 $script:languageINI[$checkCode]['Name'])   } Catch { [string]$checkName        = '' }    # Get check name from INI file
                    Try { [string]$checkDesc        =   (                                 $script:languageINI[$checkCode]['Desc'])   } Catch { [string]$checkDesc        = '' }    # Get check description from INI file
                    Try { [string]$checkAppl        =   ($script:languageINI['applyto'][$($script:languageINI[$checkCode]['Appl'])]) } Catch { [string]$checkAppl        = '' }    # Get check applies to from INI file
                    Try { [string]$checkDescription = "$($script:languageINI['engine']['AppliesTo']): $checkAppl`n`n$checkDesc"      } Catch { [string]$checkDescription = '' }

                    # Checks to see if the "checkName" value has been retreved or not
                    If ([string]::IsNullOrEmpty($checkName) -eq $False) { $checkName = $checkName.Trim("'") }
                    Else                                                { $checkName = '*' + $TextInfo.ToTitleCase($(($Name.Substring(6)).Replace('-', ' '))) }

                    [string]$getContent = ''
                    # Default back to the scripts description of help if required
                    If ($checkDesc -eq '')
                    {
                        $getContent = ((Get-Content -Path ("$script:scriptLocation\checks\$folderPath\$script") -TotalCount 50) -join "`n")
                        $regExA = [regex]::Match($getContent,     "APPLIES:$script:regExMatch")
                        $regExD = [regex]::Match($getContent, "DESCRIPTION:$script:regExMatch")

                        [string]$checkDesc = "Applies To: $($regExA.Groups[1].Value.Trim())!n"
                        ($regExD.Groups[1].Value.Trim().Split("`n")) | ForEach-Object -Process { $checkDesc += $_.Trim() + '!n' }
                        $checkDescription = "$checkAppl`n`n$checkDesc".Trim()
                    }

                    # Add check details to selection list, and check if required
                    [System.Windows.Forms.ListViewItem]$newItem = (Add-ListViewItem -ListView $null -Name $checkCode -SubItems ($checkName, $checkDescription, "$folderPath\$script") -Group $guid -ImageIndex 1 -Enabled $True)

                    [int]$notFound = 2
                    If ([string]::IsNullOrEmpty($settingsINI) -eq $False)
                    {
                        If ($settingsINI.ContainsKey("$checkCode")      -eq $True) { $newItem.Checked = $True ; $notFound-- }    # Enabled checks
                        If ($settingsINI.ContainsKey("$checkCode-skip") -eq $True) { $newItem.Checked = $False; $notFound-- }    # Skipped checks
                    }

                    If ($notFound -eq 2)                                                                                         # Unknown State
                    {
                        # Load default "ENABLED/SKIPPED" value from the check itself
                        If ($getContent -eq '') { $getContent = ((Get-Content -Path ("$script:scriptLocation\checks\$folderPath\$script") -TotalCount 50) -join "`n") }
                        $regExE = [regex]::Match($getContent, "DEFAULT-STATE:$script:regExMatch")
                        If ($regExE.Groups[1].Value.Trim() -eq 'Enabled') { $newItem.Checked = $True }
                    }

                    # Add the item to the collection
                    [void]$script:ListViewCollection.Add($newItem)
                }

                # #####################################################################################
                # FOR TAB-3 OF MAIN TABPAGE CONTROL
                # Add TabPage for folder
                [string]$folderLang = $($script:languageINI['Section'][$folderName])

                $newTab = (New-Object -TypeName 'System.Windows.Forms.TabPage')
                $newTab.Font           =  $sysFont
                $newTab.Text           =  $folderLang
                $newTab.Name           = "tab_$folderLang"
                $newTab.Tag            = "tab_$folderLang"
                $newTab.Margin         = '0, 0, 0, 0'
                $newTab.Padding        = '0, 0, 0, 0'
                $tab_t3_Pages.TabPages.Add($newTab)

                # Create a new ListView object
                $newLVW = (New-Object -TypeName 'System.Windows.Forms.ListView')
                $newLVW.Font           =  $sysFont
                $newLVW.Name           = "lvw_$folderLang"
                $newLVW.HeaderStyle    = 'Nonclickable'
                $newLVW.FullRowSelect  =  $True
                $newLVW.GridLines      =  $False
                $newLVW.LabelWrap      =  $False
                $newLVW.MultiSelect    =  $False
                $newLVW.Dock           = 'Fill'
                $newLVW.BorderStyle    = 'None'
                $newLVW.View           = 'Details'
                $newLVW.SmallImageList =  $img_MainForm

                # Add columns
                [int]$width     = (($newTab.Width - 225) - [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth)
                $newLVW_CH_Name = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader'); $newLVW_CH_Name.Text = $($script:ToolLangINI['page3']['Column_Check']); $newLVW_CH_Name.Width =  225      # Check code (acc01)
                $newLVW_CH_Valu = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader'); $newLVW_CH_Valu.Text = $($script:ToolLangINI['page3']['Column_Value']); $newLVW_CH_Valu.Width = $width    # Check name
                $newLVW_CH_Type = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader'); $newLVW_CH_Type.Text = ''                                             ; $newLVW_CH_Type.Width =   0       # Input type: List/Combo/Simple, etc
                $newLVW_CH_Desc = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader'); $newLVW_CH_Desc.Text = ''                                             ; $newLVW_CH_Desc.Width =   0       # Description from check file
                $newLVW_CH_Vali = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader'); $newLVW_CH_Vali.Text = ''                                             ; $newLVW_CH_Vali.Width =   0       # Validation type
                $newLVW_CH_Vdsc = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader'); $newLVW_CH_Vdsc.Text = ''                                             ; $newLVW_CH_Vdsc.Width =   0       # Value Description
                [void]$newLVW.Columns.Add($newLVW_CH_Name)
                [void]$newLVW.Columns.Add($newLVW_CH_Valu)
                [void]$newLVW.Columns.Add($newLVW_CH_Type)
                [void]$newLVW.Columns.Add($newLVW_CH_Desc)
                [void]$newLVW.Columns.Add($newLVW_CH_Vali)
                [void]$newLVW.Columns.Add($newLVW_CH_Vdsc)

                # Add Events for each Listview
                $newLVW.Add_KeyPress( { If ($_.KeyChar -eq 13) { ListView_DoubleClick -SourceControl $this } } )
                $newLVW.Add_DoubleClick(                       { ListView_DoubleClick -SourceControl $this }   )

                # Add new Listview to new folder
                $newTab.Controls.Add($newLVW)
            }
            Else {}
        }

        $tab_Pages.SelectedIndex               =  1
        $btn_t1_RestoreINI.Enabled             =  $True
        $btn_t1_Search.Enabled                 =  $True
        $btn_t1_Import.Enabled                 =  $True
        $cmo_t1_Language.Enabled               =  $True
        $lnk_t1_Language.Enabled               =  $True
        $cmo_t1_SettingsFile.Enabled           =  $True
        $chk_t2_Search.Enabled                 =  $True
        $txt_t2_Search.Enabled                 =  $True
        $pic_t2_SearchHelp.Visible             =  $True
        $txt_t2_Search_Outer.Enabled           =  $True
        $btn_t2_SetValues.Enabled              =  $True
        $btn_t2_SelectAll.Enabled              =  $True
        $btn_t2_SelectInv.Enabled              =  $True
        $btn_t2_SelectNone.Enabled             =  $True
        $btn_t2_SelectReset.Enabled            =  $True
        $btn_t4_Additional.Enabled             =  $True
        $txt_t2_Search_TextChanged.Invoke()
        $lst_t2_SelectChecks.Items[0].Selected =  $True
        Update-SelectedCount
        Update-NavButtons
        $script:UpdateSelectedCount            =  $True
        $script:ShowChangesMade                =  $False
        $MainFORM.Cursor                       = 'Default'
    }

    $pic_t1_RestoreHelp_Click = {
        [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['restore']['Message']), $($script:ToolLangINI['Restore']['Button']), 'OK', 'Information')
    }

    $btn_t1_RestoreINI_Click = {
        [string]$originalQA = (Open-File -InitialDirectory $script:scriptLocation -Title $($script:ToolLangINI['restore']['FileOpen']))
        If ([string]::IsNullOrEmpty($originalQA)) { Return }
        $MainFORM.Cursor = 'WaitCursor'

        # Start retrevial process
        [string[]]$content   = (Get-Content -Path $originalQA)
        [string]  $enabledF  = ([regex]::Match($content, "(\[System.Collections.ArrayList\]\`$script\:qaChecks \= \()$script:regExMatch"))    # Get list of enabled functions
                  $enabledF  = $enabledF.Replace(' ', '').Trim()
        [string[]]$functions = ($content | Select-String -Pattern '(Function )([a-z]{3}[-][0-9]{2}-)' -AllMatches)    # Get list of all functions

        # Get list of skipped functions
        [array]$skippedChecks = ''
        $functions | Sort-Object | ForEach-Object -Process { If ($enabledF.Contains($_.Substring(9)) -eq $false) { $skippedChecks += ($_.Substring(9, 6).Replace('-', '')) } }

        [System.Text.StringBuilder]$outputFile = ''
        [void]$outputFile.AppendLine('[settings]')
        [void]$outputFile.AppendLine('shortcode         = RESTORED')
        [void]$outputFile.AppendLine('language          = en')

        ForEach ($line In $content)
        {
            If ($line.StartsWith('[string]   $reportCompanyName'   )) { [void]$outputFile.AppendLine("reportCompanyName = $($line.Split('=')[1])".Replace('"', '').Trim()) }
            If ($line.StartsWith('[string]   $script:qaOutput'     )) { [void]$outputFile.AppendLine("outputLocation    = $($line.Split('=')[1])".Replace('"', '').Trim()) }
            If ($line.StartsWith('[int]      $script:ccTasks'      )) { [void]$outputFile.AppendLine("concurrent        = $($line.Split('=')[1])".Replace('"', '').Trim()) }
            If ($line.StartsWith('[int]      $script:checkTimeout' )) { [void]$outputFile.AppendLine("timeout           = $($line.Split('=')[1])".Replace('"', '').Trim()) }
            If ($line.StartsWith('[int]      $script:sessionPort'  )) { [void]$outputFile.AppendLine("sessionPort       = $($line.Split('=')[1])".Replace('"', '').Trim()) }
            If ($line.StartsWith('[string]   $script:sessionUseSSL')) { [void]$outputFile.AppendLine("sessionUseSSL     = $($line.Split('=')[1])".Replace('"', '').Trim()) }
            If ($line.StartsWith('[string]   $script:Modules'      )) { [void]$outputFile.AppendLine("RequiredModules   = $($line.Split('=')[1])".Replace('"', '').Trim()) }
        }

        If ($outputFile.Length -lt 75)
        {
            $outputFile.Clear()
            $MainFORM.Cursor = 'Default'
            [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['restore']['FileError']), $($script:ToolLangINI['restore']['Button']), 'OK', 'Error')
            Return
        }

        [string]   $FuncOLD  = ''
        [string]   $FuncNEW  = ''
        [hashtable]$Sections = @{'acc'='Accounts';
                                 'com'='Tooling';
                                 'ctx'='Citrix';
                                 'drv'='Drives';
                                 'exh'='Exchange';
                                 'hvh'='HyperV-Host';
                                 'net'='Network';
                                 'reg'='Regional';
                                 'sec'='Security';
                                 'sql'='SQL';
                                 'sys'='System';
                                 'tol'='Tooling';
                                 'vmw'='Virtual'}

        # Start process
        ForEach ($line In $content)
        {
            If ($line.StartsWith('Function newResult { Return ')) { [string]$funcName = ''; [string[]]$chkValues = $null }    # Clear settings
            If ($line.StartsWith('$script:chkValues['        )) {
                # Need to have spaces around the equals sign due to check settings having equal signs in them (ie:SYS-18)
                [string[]]$newLine = ($line.Substring(21).Replace("']", '')) -Split ' = '
                $chkValues += (($newLine[0].Trim()).PadRight(35) + '= ' + ($newLine[1]).Trim())
            }

            If (($line -match 'Function ([a-z]{3}-[0-9]{2}-)') -and ($line.Contains('internal-check') -eq $false))
            {
                $funcName = ($line.Trim().Substring(9, 6).Replace('-', ''))
                $FuncNEW  = $funcName.Substring(0,3)

                If ($FuncNEW -ne $FuncOLD)
                {
                    $FuncOLD = $FuncNEW
                    [void]$outputFile.AppendLine('')
                    [void]$outputFile.AppendLine('; _________________________________________________________________________________________________')
                    [void]$outputFile.AppendLine("; $(($Sections[$FuncNEW.Trim()]).ToUpper())")
                }

                If ($skippedChecks.Contains($funcName))  { [void]$outputFile.AppendLine("[$funcName-skip]") }    # Skipped check
                Else                                     { [void]$outputFile.AppendLine("[$funcName]"     ) }    # Enabled check

                If ([string]::IsNullOrEmpty($chkValues)) { [void]$outputFile.AppendLine("; No Settings")    }    # No settings for this check
                Else { ForEach ($setting In $chkValues)  { [void]$outputFile.AppendLine($setting)         } }    # Write out all settings and values

                [void]$outputFile.AppendLine('')
            }
        }

        $outputFile.ToString() | Out-File -FilePath "$(Split-Path -Path $originalQA -Parent)\RESTORED.ini" -Encoding utf8 -Force

        $MainFORM.Cursor = 'Default'
        [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['restore']['RestoreDone']), $($script:ToolLangINI['restore']['Button']), 'OK', 'Information')
    }

    # ###########################################
#endregion
#region SCRIPTS-TAB-2
    Function Update-SelectedCount {
        [int]$checked = 0
        $script:ListViewCollection | ForEach-Object -Process { If ($_.Checked -eq $True) { $checked++ } }
        $lbl_t2_SelectedCount.Text = ($($script:ToolLangINI['page2']['Selected']) -f $checked, $script:ListViewCollection.Count)
        If ($checked -eq 0) { $btn_t2_SetValues.Enabled = $False } Else { $btn_t2_SetValues.Enabled = $True }
        Return $checked
    }

    Function btn_t2_SelectButtons([string]$SourceButton)
    {
        $MainFORM.Cursor = 'AppStarting'    # Not 'Wait'
        $script:UpdateSelectedCount = $False

        If ($SourceButton -eq 'SelectReset')
        {
            # Reset the checkbox selection back to the INI settings
            $btn_t1_Import_Click.Invoke()
        }
        Else
        {
            Switch ($SourceButton)
            {                   # Only apply to the currently shown items, this could be filtered via a search
                'SelectAll'  { ($lst_t2_SelectChecks.Items) | ForEach-Object -Process { $_.Checked =       $True       } }
                'SelectInv'  { ($lst_t2_SelectChecks.Items) | ForEach-Object -Process { $_.Checked = (-not $_.Checked) } }
                'SelectNone' { ($lst_t2_SelectChecks.Items) | ForEach-Object -Process { $_.Checked =       $False      } }
            }
            Update-SelectedCount
        }
        $script:UpdateSelectedCount = $True
        $lst_t2_SelectChecks.Focus()
        $MainFORM.Cursor = 'Default'
    }

    $lst_t2_SelectChecks_ItemChecked = {
        If ($_.Item.Checked -eq $True) { $_.Item.ForeColor = 'WindowText';  $_.Item.ImageIndex = 1 }    # Enabled
        Else                           { $_.Item.ForeColor = 'ControlDark'; $_.Item.ImageIndex = 2 }    # Disabled
        If ($script:UpdateSelectedCount -eq $True) { Update-SelectedCount } 
    }

    $lst_t2_SelectChecks_SelectedIndexChanged = {
        If ($lst_t2_SelectChecks.SelectedItems.Count -eq 1) {
            $lnk_t2_Description.Text = (($lst_t2_SelectChecks.SelectedItems[0].SubItems[2].Text) -replace ('!n',"`n`n")) + ' '
            $lnk_t2_Description.LinkArea = (New-Object -TypeName 'System.Windows.Forms.LinkArea'(0, 0))

            # Search for and enable any links within descriptions (only one per description)
            If ($lnk_t2_Description.Text -like '*http*')
            {
                [int]$start  = $lnk_t2_Description.Text.IndexOf('http', 1)
                [int]$length = $lnk_t2_Description.Text.IndexOf(' ', $start + 1) - $start
                $lnk_t2_Description.LinkArea = (New-Object -TypeName 'System.Windows.Forms.LinkArea'($start, $length))
            }
        }
    }

    $lnk_t2_Description_LinkClicked = {
        [string]$link = $lnk_t2_Description.Text.SubString($($lnk_t2_Description.LinkArea.Start), $($lnk_t2_Description.LinkArea.Length))
        If ([string]::IsNullOrEmpty($link) -eq $False) { Start-Process -FilePath $link }
    }

    # Set focus to the exit button if there are no checks listed
    $lst_t2_SelectChecks_Enter = { If ($lst_t2_SelectChecks.Checkboxes -eq $False) { $btn_Exit.Focus() } }

    $chk_t2_Search_CheckedChanged = {
        # Stops the flickering of the check list when checked
        If ($txt_t2_Search.text -ne '') { $txt_t2_Search_TextChanged.Invoke() }
    }

    # Search the list of checks - triggers with checkbox too
    $txt_t2_Search_TextChanged = {
        If ($script:ListViewCollection.Count -eq 0) { Return }

        $script:UpdateSelectedCount = $False
        [void]$lst_t2_SelectChecks.BeginUpdate()
        [void]$lst_t2_SelectChecks.Items.Clear()

        [string]$sQuery = ''
        $pic_t2_SearchHelp.Visible  = $True
        $pic_t2_SearchClear.Visible = $False
        $pic_t2_SearchHelp.BringToFront()
        $pic_t2_SearchClear.BringToFront()

        If ($txt_t2_Search.Text.Length -gt 1) { $sQuery = $txt_t2_Search.Text; $pic_t2_SearchClear.Visible = $True; $pic_t2_SearchHelp.Visible = $False }

        If ($txt_t2_Search.Text.StartsWith('!') -eq $False)
        {
            If ($chk_t2_Search.Checked -eq $False) {
                # Search CODE and NAME
                [System.Collections.ArrayList]$iResult = $script:ListViewCollection.Where({
                    $_.SubItems[0].Text.ToLower().Contains($sQuery.ToLower()) -or    # acc01
                    $_.SubItems[1].Text.ToLower().Contains($sQuery.ToLower())        # Local Users
                })
            } Else {
                # Include DESCRIPTION
                [System.Collections.ArrayList]$iResult = $script:ListViewCollection.Where({
                    $_.SubItems[0].Text.ToLower().Contains($sQuery.ToLower()) -or    # acc01
                    $_.SubItems[1].Text.ToLower().Contains($sQuery.ToLower()) -or    # Local Users
                    $_.SubItems[2].Text.ToLower().Contains($sQuery.ToLower())        # Check all local users to ensure...
                })
            }
        }
        Else
        {
            # Special Search (not case-sensitive)
            If     ($txt_t2_Search.Text -eq '!E') { [System.Collections.ArrayList]$iResult = $script:ListViewCollection.Where({ $_.Checked -eq $True  }) }    # Show all ENABLED checks
            ElseIf ($txt_t2_Search.Text -eq '!D') { [System.Collections.ArrayList]$iResult = $script:ListViewCollection.Where({ $_.Checked -eq $False }) }    # Show all DISABLED checks
            Else                                  { [System.Collections.ArrayList]$iResult = $script:ListViewCollection                                  }    # Show ALL checks
        }

        If ($iResult.Count -eq 0)
        {
            $lst_t2_SelectChecks.CheckBoxes = $False
            $lst_t2_SelectChecks.Groups.Add('PleaseNote', ($script:ToolLangINI['page2']['PleaseNote']))    # Second quotes stops error in 'lst_t2_SelectChecks_SelectedIndexChanged'
            Add-ListViewItem -ListView $lst_t2_SelectChecks -Name '*PN1' -SubItems @('', '')                                               -ImageIndex -1 -Group 'PleaseNote' -Enabled $True
            Add-ListViewItem -ListView $lst_t2_SelectChecks -Name '*PN2' -SubItems @($($script:ToolLangINI['page2']['SearchResults']), '') -ImageIndex -1 -Group 'PleaseNote' -Enabled $True
        }
        Else
        {
            $lst_t2_SelectChecks.CheckBoxes = $True
            ForEach ($item In ($iResult | Sort-Object))
            {
                [System.Windows.Forms.ListViewItem] $lvItem  = $item
                [System.Windows.Forms.ListViewGroup]$lvGroup = $null
                ForEach ($groupItem in $lst_t2_SelectChecks.Groups) { If ($groupItem.Name -eq $lvItem.Tag)  { $lvGroup = $groupItem } }
                If ($lvGroup -eq $null) { $lvGroup = ($lst_t2_SelectChecks.Groups.Add($lvItem.Tag, $lvItem.Tag)) }

                $lvItem.Group = $lvGroup
                $lst_t2_SelectChecks.Items.Add($lvItem)
            }
        }
        [void]$lst_t2_SelectChecks.EndUpdate()
        $lst_t2_SelectChecks.Items[0].Selected = $True
        $script:UpdateSelectedCount            = $True
    }

    $pic_t2_SearchHelp_Click = {
        [System.Text.StringBuilder]$msg = ''
        0..9 | ForEach { If ($($script:ToolLangINI['page2']["SearchHelp$_"]) -ne '') { [void]$msg.AppendLine($($script:ToolLangINI['page2']["SearchHelp$_"])) } }
        [System.Windows.Forms.MessageBox]::Show($MainFORM, $msg, $script:toolName, 'OK', 'Information')
    }

    # Move to next page
    $btn_t2_SetValues_Click = {
        $txt_t2_Search.Text = ''    # Reset the search field to show all items
        If ($lst_t2_SelectChecks.Items.Count        -eq 0) { Return }
        If ($lst_t2_SelectChecks.CheckedItems.Count -eq 0) { Return }

        $cmo_t1_SettingsFile.Enabled = $False
        $cmo_t1_Language.Enabled     = $False
        $lnk_t1_Language.Enabled     = $False

        If ($script:ShowChangesMade -eq $True)
        {
            [System.Windows.Forms.DialogResult]$msgbox = ([System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['page2']['ChangesMade']), $script:toolName, 'YesNo', 'Warning', 'Button2'))
            If ($msgbox -eq [System.Windows.Forms.DialogResult]::No) { Return }
        }

        # Reset the last page
        $btn_t4_Save.Enabled         = $False
        $btn_t4_Generate.Enabled     = $False
        $chk_t4_GenerateMini.Enabled = $False

        $MainFORM.Cursor             = 'WaitCursor'
        $btn_t3_Complete.Enabled     = $False
        [hashtable]$defaultINI       = (Get-DefaultINISettings)
        [hashtable]$settingsINI      = (Load-IniFile -Inputfile "$script:scriptLocation\settings\$($cmo_t1_SettingsFile.SelectedItem.Text).ini")
        Try { [string]$SkippedChecks = ($SettingsINI.Keys | Where-Object -FilterScript { $_.EndsWith('-skip') }) } Catch { }

        # Add each of the checks' settings to the correct tab page
        ForEach ($folder In $lst_t2_SelectChecks.Groups)    # SECTIONs
        {
            # Get correct ListView object
            [System.Windows.Forms.TabPage] $tabObject = $tab_t3_Pages.TabPages["tab_$($folder.Header.Trim())"]
            [System.Windows.Forms.ListView]$lvwObject =    $tabObject.Controls["lvw_$($folder.Header.Trim())"]

            # Clear any existing entries
            $lvwObject.Items.Clear()
            $lvwObject.Groups.Clear()

            ForEach ($listItem In $folder.Items)    # CHECKs
            {
                # Very specific hacks to change the message text for the several checks
                [string[]]$HackCheck = @('net09', 'sys21', 'sys23')                    # Checks that this applies to
                [string[]]$HackKeys  = @('StaticRoute', 'Key', 'Value', 'Variable')    # Keys within the above checks

                # Read in the entire file - it's needed upto three times
                [string]$getContent = ((Get-Content -Path "$script:scriptLocation\checks\$($listItem.SubItems[3].Text)" -TotalCount 50) -join "`n")

                # Create group for the checks
                [string]$guid = $($listItem.Text)
                $lvwObject.Groups.Add($guid, "$($listItem.SubItems[1].Text) ($($listItem.Text.ToUpper()))")

                # Create each item
                $iniKeys = (New-Object -TypeName 'System.Collections.Hashtable')
                $tmpKeys = (New-Object -TypeName 'System.Collections.Hashtable')

                # Load up the default settings first
                If ($defaultINI.Contains($("$($listItem.Text)-skip"))) { $iniKeys = ($defaultINI.$("$($listItem.Text)-skip")) }
                Else                                                   { $iniKeys = ($defaultINI.$(   $listItem.Text)       ) }

                Try
                {
                    # Overwrite with the custom settings
                    If ($SkippedChecks.Contains($("$($listItem.Text)-skip"))) { $tmpKeys = ($settingsINI.$("$($listItem.Text)-skip")) }
                    Else                                                      { $tmpKeys = ($settingsINI.$(   $listItem.Text)       ) }
                    ForEach ($val In $tmpKeys.Keys) { If ($val.StartsWith(';') -eq $False) { $iniKeys[$val] = $tmpKeys[$val]        } }
                }
                Catch { }

                ForEach ($item In (($iniKeys.Keys) | Sort-Object))
                {
                    $item = $item.Trim()
                    [string]$desc    = ''
                    [string]$lngDesc = '** MISSING LANGUAGE TEXT **'
                    [string]$value   = [regex]::Replace(($iniKeys.$item), "'\s{0,},\s{0,}'", "'; '")    # Replace:    ', '  -->  '; '

                    # Get the help text for each check setting from the language specific INI file
                    Try { $lngDesc = ($script:languageINI[$($listItem.Text)][$($item.Trim())].ToString().Trim()) }
                    Catch { If ($HackCheck.Contains($listItem.Text) -eq $False) { Write-Warning "Missing '$($script:SelectedLanguage.Name)' translation text: [$($listitem.Text)] $($item)" } }

                    # No details in help file yet, get from check itself (english only)
                    $regExI = [regex]::Match($getContent, "REQUIRED-INPUTS:$script:regExMatch")
                    [string[]]$Inputs = ($regExI.Groups[1].Value.Trim()).Split("`n")
                    If (([string]::IsNullOrEmpty($Inputs) -eq $false) -and ($Inputs -ne 'None')) {
                        ForEach ($EachInput In $Inputs) { If (($EachInput.Trim()).StartsWith($item)) { $desc = ($EachInput.Trim()); Break } }
                    }

                    # Very specific hacks to change the message text for the several checks
                    If (($HackCheck.Contains($($listItem.Text)) -eq $True) -and ($HackKeys.Contains($($item.Substring(0, $item.Length-2))) -eq $True))
                    {
                        $desc    = ($EachInput.Trim())
                        $lngDesc = ($script:languageINI[$($listItem.Name.ToLower())]["$($item.Substring(0, $item.Length-2))01"].ToString().Trim())
                    }

                    [string]$idsc = ''
                    # Get any input descriptions (if any exist), taken from INPUT-DESCRIPTION: section
                    $regExD = [regex]::Match($getContent, "$($item):$script:regExMatch", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    If ([string]::IsNullOrEmpty($regExD) -eq $False)
                    {
                        [string[]]$Inputs = ($regExD.Groups[1].Value.Trim()).Split("`n")
                        ForEach ($EachInput In $Inputs) { If ($EachInput -ne '') { $idsc += $EachInput.Trim() + '|' } }
                    }
                    $regExD = $null

                    Do { $desc    = $desc.Replace('  ', ' ') } While ($desc.Contains('  '))    # Remove all double spaces
                         $desc    = $desc.Replace("$($item.Trim()) - ", '')
                    [string]$type = 'Unknown'

                    Switch -Regex ($desc.Trim())
                    {
                        # DROPDOWN BOX
                        '\".*\|{1,}.*\"'    # Look for one or more PIPE splitters "..|..|.." in quotes
                        { 
                            $type = 'COMBO-' + ($desc.Split('-')[0]).Trim().Trim('"')
                            $desc =            ($desc.Split('-')[1]).Trim()
                            Break
                        }
                        
                        # CHECKBOX LIST
                        '\".*,{1,}.*\"'     # Look for one or more COMMA splitters "..,..,.." in quotes
                        {
                            $type = 'CHECK-' + ($desc.Split('-')[0]).Trim().Trim('"')
                            $desc =            ($desc.Split('-')[1]).Trim()
                            Break
                        }
                        
                        # LARGE TEXT INPUT
                        '\"LARGE\"'         # Look for the word LARGE in quotes
                        {
                            $type = 'LARGE'
                            $desc = ($desc.Split('-')[1]).Trim()
                            Break
                        }
                        
                        # MUTLI TEXT INPUT
                        '\"LIST\"'          # Look for the work LIST in quotes
                        {
                            $type = 'LIST'
                            $desc = ($desc.Split('-')[1]).Trim()
                            Break
                        }

                        # SINGLE TEXT INPUT
                        Default { $type = 'SIMPLE' }
                    }

                    If ($desc.Contains('|') -eq $True) { [string]$vali = ($desc.Split('|')[1]).Trim(); [string]$desc = ($desc.Split('|')[0]).Trim() } Else { [string]$vali = 'None' }

                    # Insert Language specific entry description
                    If ([string]::IsNullOrEmpty($lngDesc) -eq $False) { $desc = $lngDesc }
                    Add-ListViewItem -ListView $lvwObject -Name $item -SubItems ($value, $type, $desc, $vali, $idsc) -Group $guid -ImageIndex 1 -Enabled $($listItem.Checked)
                }

                # Add 'spacing' gap between groups
                If ($lvwObject.Groups[$guid].Items.Count -gt 0) { Add-ListViewItem -ListView $lvwObject -Name ' ' -SubItems ('', '', '', '') -Group $guid -ImageIndex -1 -Enabled $false }
            }
        }

        $tim_CompleteButton.Start()
        $tab_Pages.SelectedIndex     =       2
        $btn_t4_Save.Enabled         =       $True
        $lbl_t3_NoChecks.Visible     =       $False
        $script:ShowChangesMade      =       $True
        Update-NavButtons
        $MainFORM.Cursor             = 'Default'
    }

    # ###########################################
#endregion
#region SCRIPTS-TAB-3
    Function ListView_DoubleClick ([System.Windows.Forms.ListView]$SourceControl)
    {
        If ([string]::IsNullOrEmpty(($SourceControl.SelectedItems[0].Text).Trim()) -eq $True) { Return }    # No items listed
        If (($SourceControl.SelectedItems[0].ImageIndex) -eq -1)                              { Return }    # No icon
        If (($SourceControl.SelectedItems[0].ImageIndex) -eq  2)                              { Return }    # Disabled Gear icon

        # Start EDIT for selected item
        $MainFORM.Cursor = 'WaitCursor'
        Try { [System.Windows.Forms.ListViewItem]$selectedItem = $($SourceControl.SelectedItems[0]) } Catch { }
        Switch -Wildcard ($($selectedItem.SubItems[2].Text))
        {
            'COMBO*' {
                [string[]]$currentVal  =    $($selectedItem.SubItems[1].Text.Trim("'"))
                [string[]]$selections  =  (($($selectedItem.SubItems[2].Text).Split('-')[1]).Split('|'))
                [string[]]$returnValue = @(Show-InputForm -Type 'Option' -Title $($selectedItem.Group.Header) -Description "$($selectedItem.SubItems[0].Text)`n$($selectedItem.SubItems[3].Text)" -CurrentValue $currentVal -InputList $selections -InputDescription $($selectedItem.SubItems[5].Text))
                If ($returnValue -ne '!!-CANCELLED-!!') { $SourceControl.SelectedItems[0].SubItems[1].Text = "'$returnValue'" }
                Break
            }

            'CHECK*' {
                [string[]]$currentVal  =    $($selectedItem.SubItems[1].Text).Split(';')
                          $currentVal  =   ($currentVal.Trim().Replace("'",'').Replace('@(','').Replace('(','').Replace(')',''))
                [string[]]$selections  =  (($($selectedItem.SubItems[2].Text).Split('-')[1]).Split(','))
                [string[]]$returnValue = @(Show-InputForm -Type 'Check'  -Title $($selectedItem.Group.Header) -Description "$($selectedItem.SubItems[0].Text)`n$($selectedItem.SubItems[3].Text)" -CurrentValue $currentVal -InputList $selections -InputDescription $($selectedItem.SubItems[5].Text) -MaxNumberInputBoxes 30)
                If ($returnValue -ne '!!-CANCELLED-!!') { $SourceControl.SelectedItems[0].SubItems[1].Text = ("@('{0}')" -f $($returnValue -join ';').Replace(';', "'; '")) }
                Break
            }

            'LIST' {
                # Very specific hack to limit the number of input boxes for the NET-09 Static Routes check
                If ($($selectedItem.Group.Header).EndsWith('(NET09)')) { $MaxNumberInputBoxes = 3 } Else { $MaxNumberInputBoxes = 30 }

                [string[]]$currentVal  = $($selectedItem.SubItems[1].Text).Split(';')
                          $currentVal  =  ($currentVal.Trim().Replace("'",'').Replace('@(','').Replace('(','').Replace(')',''))
                [string[]]$returnValue = @(Show-InputForm -Type 'List'   -Title $($selectedItem.Group.Header) -Description "$($selectedItem.SubItems[0].Text)`n$($selectedItem.SubItems[3].Text)" -CurrentValue $currentVal -Validation $($selectedItem.SubItems[4].Text) -MaxNumberInputBoxes $MaxNumberInputBoxes)
                If ($returnValue -ne '!!-CANCELLED-!!') { $SourceControl.SelectedItems[0].SubItems[1].Text = ("@('{0}')" -f $($returnValue -join ';').Replace(';', "'; '")) }
                Break
            }

            'LARGE' {
                [string[]]$currentVal  = $($selectedItem.SubItems[1].Text.Trim("'"))
                [string]  $returnValue =  (Show-InputForm -Type 'Large'  -Title $($selectedItem.Group.Header) -Description "$($selectedItem.SubItems[0].Text)`n$($selectedItem.SubItems[3].Text)" -CurrentValue $currentVal)
                If ($returnValue -ne '!!-CANCELLED-!!') { $SourceControl.SelectedItems[0].SubItems[1].Text = "'$returnValue'" }
                Break
            }

            'SIMPLE' {
                [string[]]$currentVal  = $($selectedItem.SubItems[1].Text.Trim("'"))
                [string]  $returnValue =  (Show-InputForm -Type 'Simple' -Title $($selectedItem.Group.Header) -Description "$($selectedItem.SubItems[0].Text)`n$($selectedItem.SubItems[3].Text)" -CurrentValue $currentVal -Validation $($selectedItem.SubItems[4].Text))
                If ($returnValue -ne '!!-CANCELLED-!!') { $SourceControl.SelectedItems[0].SubItems[1].Text = "'$returnValue'" }
            }

            Default {
                Write-Warning "ListView_DoubleClick: Invalid Type: $($selectedItem.SubItems[2].Text)"
            }
        }
        $MainFORM.Cursor = 'Default'
    }

    Function Update-NavButtons
    {
        $btn_t3_NextTab.Enabled = $tab_t3_Pages.SelectedIndex -lt $tab_t3_Pages.TabCount - 1
        $btn_t3_PrevTab.Enabled = $tab_t3_Pages.SelectedIndex -gt 0
    }

    $tab_t3_Pages_SelectedIndexChanged = { $MainFORM_Resize.Invoke()    ; Update-NavButtons }
    $btn_t3_PrevTab_Click              = { $tab_t3_Pages.SelectedIndex--; Update-NavButtons }
    $btn_t3_NextTab_Click              = { $tab_t3_Pages.SelectedIndex++; Update-NavButtons }

    $btn_t3_Complete_Click = {
        $script:ListViewCollection | ForEach-Object -Process {
            # Add check specific modules as a fallback for users forgetting.!
            If (($_.Name.StartsWith('sql') -eq $True) -and ($_.Checked -eq $True)) { If ($($script:settings.Modules) -notlike "*sqlps*") { $script:settings.Modules += "SQLPS`n" } }    # SQL Server
        }
        $tab_Pages.SelectedIndex = 3
    }

    # Timer to enable the "Complete" button on Tab 3.  This helps to stop double-clicks 
    $tim_CompleteButton_Tick = {
        $script:CompleteTick++
        If ($script:CompleteTick -ge 1) { $btn_t3_Complete.Enabled = $True; $tim_CompleteButton.Stop }
    }

    # ###########################################
#endregion
#region SCRIPTS-TAB-4
    $btn_t4_Additional_Click = {
        $MainFORM.Cursor = 'WaitCursor'
        [string]$AdditionalReturn = (Show-AdditionalOptions)
        $MainFORM.Cursor = 'Default'

        If (($btn_t4_Generate.Enabled -eq $True) -and ($AdditionalReturn -eq 'OK'))
        {
            # 'Generate QA Script' is enabled therefore the settings have been saved, show warning that is needs to be saved and compliled again.
            [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['additional']['Warning']), $($script:ToolLangINI['additional']['Button']), 'OK', 'Information')
        }
    }

    $txt_t4_ShortCode_TextChanged = {
        [string]$mini = ''
        [int]   $i    = $txt_t4_ShortCode.SelectionStart; $txt_t4_ShortCode.Text = $txt_t4_ShortCode.Text.ToUpper(); $txt_t4_ShortCode.SelectionStart = $i
        If ($chk_t4_GenerateMini.Checked -eq $True) { $mini = '_MINI' }
        $lbl_t4_CodeEg.Text = "QA_$($txt_t4_ShortCode.Text.Replace(' ', '-'))_v4.$(Get-Date -Format 'yy.MMdd')$mini.ps1"
    }

    $btn_t4_Save_Click = {
        If (([string]::IsNullOrEmpty($txt_t4_ShortCode.Text) -eq $True) -or ([string]::IsNullOrEmpty($txt_t4_ReportTitle.Text) -eq $True))
        {
            [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['page4']['WarningMessage']), $script:toolName, 'OK', 'Warning')
            Return
        }

        $MainFORM.Cursor = 'WaitCursor'
        $script:saveFile = (Save-File -InitialDirectory "$script:scriptLocation\settings" -Title $($script:ToolLangINI['page4']['SaveSettings']) -InitialFileName "$($txt_t4_ReportTitle.Text.ToLower())_$($txt_t4_ShortCode.Text.ToLower())")
        $MainFORM.Cursor = 'Default'

        If ([string]::IsNullOrEmpty($script:saveFile) -eq $True) { Return }
        If ($script:saveFile.EndsWith('default-settings.ini'))
        {
            [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['page4']['SaveWarning']), ' default-settings.ini', 'OK', 'Error')
            Return
        }

        $MainFORM.Cursor = 'WaitCursor'
        [System.Text.StringBuilder]$outputFile = ''
        # Write out header information
        $outputFile.AppendLine('[settings]')
        $outputFile.AppendLine("shortcode         = $($txt_t4_ShortCode.Text)")
        $outputFile.AppendLine("reportCompanyName = $($txt_t4_ReportTitle.Text)")
        $outputFile.AppendLine('')
        $outputFile.AppendLine("Language          = $($cmo_t1_Language.SelectedItem.Name)")
        $outputFile.AppendLine("OutputLocation    = $($script:settings.OutputLocation)")
        $outputFile.AppendLine("Timeout           = $($script:settings.TimeOut)")
        $outputFile.AppendLine("Concurrent        = $($script:settings.Concurrent)")
        $outputFile.AppendLine("SessionPort       = $($script:settings.SessionPort)")
        $outputFile.AppendLine("SessionUseSSL     = $($script:settings.SessionUseSSL)")
        $outputFile.AppendLine("RequiredModules   = $($script:settings.Modules)")
        $outputFile.AppendLine('')

        # Loop through all checks saving as required, hiding others
        ForEach ($folder In $lst_t2_SelectChecks.Groups)
        {
            $outputFile.AppendLine('')
            $outputFile.AppendLine('; _________________________________________________________________________________________________')
            $outputFile.AppendLine("; $(($folder.Header).ToUpper().Trim())")

            ForEach ($check In $folder.Items)
            {
                [System.Windows.Forms.TabPage] $tabObject = $tab_t3_Pages.TabPages["tab_$($folder.Header.Trim())"]
                [System.Windows.Forms.ListView]$lvwObject = $null
                Try { $lvwObject = $tabObject.Controls["lvw_$($folder.Header.Trim())"] } Catch { $lvwObject = $null }

                If ($check.Checked -eq $False) { $outputFile.AppendLine("[$($check.Text)-skip]") }
                Else                           { $outputFile.AppendLine("[$($check.Text)]"     ) }

                ForEach ($group In $lvwObject.Groups)
                {
                    If ($group.Name -eq $check.Text)
                    {
                        ForEach ($item In $group.Items)
                        {
                            Switch -Wildcard ($item.SubItems[2].Text)
                            {
                                'COMBO*' { [string]$out =  "$($item.SubItems[1].Text)"                    }
                                'CHECK*' { [string]$out = "$(($item.SubItems[1].Text).Replace(';', ','))" }
                                'LARGE'  { [string]$out =  "$($item.SubItems[1].Text)"                    }
                                'LIST'   { [string]$out = "$(($item.SubItems[1].Text).Replace(';', ','))" }
                                'SIMPLE' { [string]$out =  "$($item.SubItems[1].Text)"                    }
                                Default  {                                                                }
                            }
                            If ([string]::IsNullOrEmpty($($item.Text).Trim(' ')) -eq $False) { $outputFile.AppendLine("$(($item.Text).Trim().PadRight(34)) = $out") }
                        }
                        If (($group.Items.Count) -eq 0) { $outputFile.AppendLine('; No Settings') }
                        $outputFile.AppendLine('')
                    }
                }
            }
        }

        $outputFile.ToString() | Out-File -FilePath $script:saveFile -Encoding utf8 -Force
        [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['page4']['SaveSuccess']) -f $(Split-Path -Path $script:saveFile -Leaf), $($script:ToolLangINI['page4']['SaveSettings']), 'OK', 'Information') 
        $btn_t4_Generate.Enabled = $True
        If ($(Update-SelectedCount) -le 7) { $chk_t4_GenerateMini.Enabled = $True } Else { $chk_t4_GenerateMini.Enabled = $False }
        $MainFORM.Cursor = 'Default'
    }

    $btn_t4_Generate_Click = {
        $MainFORM.Cursor             = 'WaitCursor'
        $btn_Exit.Enabled            =  $False
        $btn_t1_RestoreINI.Enabled   =  $False
        $btn_t4_Save.Enabled         =  $False
        $btn_t4_Additional.Enabled   =  $False
        $btn_t4_Generate.Enabled     =  $False
        $chk_t4_GenerateMini.Enabled =  $False
        $txt_t4_ShortCode.Enabled    =  $False
        $txt_t4_ReportTitle.Enabled  =  $False
        $txt_t4_ShortCode.Enabled    =  $False
        $txt_t4_ReportTitle.Enabled  =  $False
        $txt_t4_SC_Outer.Enabled     =  $False
        $txt_t4_RT_Outer.Enabled     =  $False

        # Build Standard QA Script
        [string]$mini = ''
        $lbl_t4_GenerateStatus.Text = $($script:ToolLangINI['page4']['Generating'])
        $lbl_t4_GenerateStatus.Refresh(); [System.Windows.Forms.Application]::DoEvents()
        If ($chk_t4_GenerateMini.Checked -eq $True) { $mini = '-Minimal' }
        Invoke-Expression -Command "PowerShell -NoProfile -NonInteractive -Command {& '$script:scriptLocation\Compiler.ps1' $mini -Settings '$(Split-Path -Path $script:saveFile -Leaf)' -Silent }"
        $lbl_t4_GenerateStatus.Text = ''

        # Same code as in the compiler script
        [string]$outPath = "$script:scriptLocation\$($lbl_t4_CodeEg.Text)"
        If (Test-Path -LiteralPath $outPath) { [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['page4']['GenerateDone']), $script:toolName, 'OK', 'Information') }
        Else                                 { [System.Windows.Forms.MessageBox]::Show($MainFORM, $($script:ToolLangINI['page4']['GenerateFail']), $script:toolName, 'OK', 'Warning') }

        $btn_Exit.Enabled            =  $True
        $btn_t1_RestoreINI.Enabled   =  $True
        $btn_t4_Save.Enabled         =  $True
        $btn_t4_Additional.Enabled   =  $True
        $btn_t4_Generate.Enabled     =  $True
        $txt_t4_ShortCode.Enabled    =  $True
        $txt_t4_ReportTitle.Enabled  =  $True
        $txt_t4_SC_Outer.Enabled     =  $True
        $txt_t4_RT_Outer.Enabled     =  $True
        If ($(Update-SelectedCount) -le 7) { $chk_t4_GenerateMini.Enabled = $True } Else { $chk_t4_GenerateMini.Enabled = $False }
        $MainFORM.Cursor             = 'Default'
    }
#endregion
#endregion
#region LANGUAGE CHANGE CODE
Function ChangeLanguage
{
  # General
    $btn_About.Text                       = ($script:ToolLangINI['about']['Button'])
    $btn_Exit.Text                        = ($script:ToolLangINI['exit' ]['Button'])

  # TAB-1
    $tab_Page1.Text                       = ($script:ToolLangINI['page1']['Tab'])
    $lbl_t1_Welcome.Text                  = ($script:ToolLangINI['page1']['Title'])
    $lbl_t1_Introduction.Text             = ($script:ToolLangINI['page1']['Message'])
    $btn_t1_Search.Text                   = ($script:ToolLangINI['page1']['SetLocation'])
    $lbl_t1_SettingsFile.Text             = ($script:ToolLangINI['page1']['BaseSettings'])
    $lbl_t1_MissingFile.Text              = $("'default-settings.ini' $($script:ToolLangINI['page1']['BaseMissing'])")
    $lbl_t1_Language.Text                 = ($script:ToolLangINI['page1']['Language'])
    $lnk_t1_Language.Text                 = ($script:ToolLangINI['page1']['Translation'])
    $btn_t1_Import.Text                   = ($script:ToolLangINI['page1']['ImportSettings'])
    $lbl_t1_ToolLang.Text                 = ($script:ToolLangINI['page1']['ToolLanguage'] + ' :')
    $btn_t1_RestoreINI.Text               = ($script:ToolLangINI['restore']['Button'])

  # TAB-2
    $tab_Page2.Text                       = ($script:ToolLangINI['page2']['Tab'])
    $lbl_t2_CheckSelection.Text           = ($script:ToolLangINI['page2']['Title'])
    $lst_t2_SelectChecks.Columns[0].Text  = ($script:ToolLangINI['page2']['Column_Check'])
    $lst_t2_SelectChecks.Columns[1].Text  = ($script:ToolLangINI['page2']['Column_Name'])
    $lbl_t2_Select.Text                   = ($script:ToolLangINI['page2']['Select'])
    $btn_t2_SetValues.Text                = ($script:ToolLangINI['page2']['SetValues'])
    SendMessage -ControlHandle $txt_t2_Search.Handle -DisplayString ($script:ToolLangINI['page2']['SearchName'])

    $chk_t2_Search.Text                   = ($script:ToolLangINI['page2']['SearchCheck'])
    $lbl_t2_ChangesMade.Text              = ($script:ToolLangINI['page2']['ChangeNote'])

    $MainTT.SetToolTip($btn_t2_SelectAll,   ($script:ToolLangINI['page2']['Button_All']))      # 
    $MainTT.SetToolTip($btn_t2_SelectInv,   ($script:ToolLangINI['page2']['Button_Inv']))      # ToolTip display for buttons
    $MainTT.SetToolTip($btn_t2_SelectNone,  ($script:ToolLangINI['page2']['Button_None']))     # that have icon images.
    $MainTT.SetToolTip($btn_t2_SelectReset, ($script:ToolLangINI['page2']['Button_Reset']))    # 

    Try { $lst_t2_SelectChecks.Groups['PleaseNote'].Header    = ($script:ToolLangINI['page2']['PleaseNote'])     } Catch {}
    Try { $lst_t2_SelectChecks.Items['*PN2'].SubItems[1].Text = ($script:ToolLangINI['page2']['SelectLocation']) } Catch {}
    Try { [void]$txt_t2_Search_TextChanged.Invoke()                                                              } Catch {}
    Update-SelectedCount    # Will change the "0 of 0 checks selected" label

  # TAB-3
    $tab_Page3.Text                       = ($script:ToolLangINI['page3']['Tab'])
    $lbl_t3_ScriptSelection.Text          = ($script:ToolLangINI['page3']['Title'])
    $lbl_t3_NoChecks.Text                 = ($script:ToolLangINI['page3']['SelectChecks'])
    $lbl_t3_SectionTabs.Text              = ($script:ToolLangINI['page3']['SectionTabs'])
    $btn_t3_PrevTab.Text                  = ($script:ToolLangINI['page3']['Prev'])
    $btn_t3_NextTab.Text                  = ($script:ToolLangINI['page3']['Next'])
    $btn_t3_Complete.Text                 = ($script:ToolLangINI['page3']['Complete'])

    ForEach ($tab In $tab_t3_Pages.TabPages) {
        [System.Windows.Forms.ListView]$lvTmp = $tab.Controls["lvw_$($tab.Text)"]
        $lvTmp.Columns[0].Text            = ($script:ToolLangINI['page3']['Column_Check'])
        $lvTmp.Columns[1].Text            = ($script:ToolLangINI['page3']['Column_Value'])
    }

  # TAB-4
    $tab_Page4.Text                       = ($script:ToolLangINI['page4']['Tab'])
    $lbl_t4_Complete.Text                 = ($script:ToolLangINI['page4']['Title'])
    $lbl_t4_Complete_Info.Text            = ($script:ToolLangINI['page4']['Message'])
    $lbl_t4_ShortName.Text                = ($script:ToolLangINI['page4']['ScriptName'])
    $lbl_t4_ReportTitle.Text              = ($script:ToolLangINI['page4']['ReportName'])
    $lbl_t4_QAReport.Text                 = ($script:ToolLangINI['page4']['QAReport'])
    $btn_t4_Save.Text                     = ($script:ToolLangINI['page4']['SaveSettings'])
    $btn_t4_Generate.Text                 = ($script:ToolLangINI['page4']['GenerateScript'])
    $chk_t4_GenerateMini.Text             = ($script:ToolLangINI['page4']['GenerateMini'])
    $btn_t4_Additional.Text               = ($script:ToolLangINI['additional']['Button'])
}
#endregion
#region FORM ITEMS
#region MAIN FORM
    $MainFORM                           = (New-Object -TypeName 'System.Windows.Forms.Form')
    $MainFORM.AutoScaleDimensions       = '6, 13'
    $MainFORM.AutoScaleMode             = 'None'
    $MainFORM.ClientSize                = '794, 672'    # 800 x 700
    $MainFORM.MinimumSize               = $MainFORM.Size
    $MainFORM.FormBorderStyle           = 'Sizable'
    $MainFORM.StartPosition             = 'CenterScreen'
    $MainFORM.Text                      = $script:toolName
    $MainFORM.Icon                      = [System.Convert]::FromBase64String('
        AAABAAIAICAAAAEAIACoEAAAJgAAABAQAAABACAAaAQAAM4QAAAoAAAAIAAAAEAAAAABACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAANIAAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
        AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA8AAAADcAAAAAAAAAAACZAD8AmQA9AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADXAAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
        AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAPAAAAA3AAAAAAAAAAAAmQBpAJkA/gCZAPwAmQA9AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8AAAD/QEBA/39/f/9/f3//f39//39/
        f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//y8vL////////////ltWW/wGZAf8AmQD/AJkA/wCZAN0AmQAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/wAAAP9/f3//////////
        /////////////////////////////////////////////////////////////////////////////5bVlv8BmQH/AJkA/wCZAP8AmQD/AJkA/wCZAJcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/AAAA/39/
        f/////////////////////////////////////////////////////////////////////////////////+W1Zb/AZkB/wCZAP8AmQD/AJkA/ACZAP8AmQD/AJkA/gCZAEYAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AP8AAAD/f39/////////////////////////////////////////////////////////////////////////////mNaY/wGZAf8AmQD/AJkA/xykHP8AmQAyAJkA3gCZAP8AmQD/AJkA5ACZABAAAAAAAAAAAAAA
        AAAAAAAAAAAA/wAAAP9/f3////////////////////////////////////////////////////////////////////////////9PuE//AJkA/wCZAP8VoRX/1+/X/wAAAAAAmQBBAJkA/gCZAP8AmQD/AJkAogAA
        AAAAAAAAAAAAAAAAAAAAAAD/AAAA/39/f/////////////////////////////////////////////////////////////////////////////D58P83rzf/FKEU/9Lt0v//////AAAAAAAAAAAAmQCPAJkA/wCZ
        AP8AmQD/AJkAUAAAAAAAAAAAAAAAAAAAAP8AAAD/f39///////////////////////////////////////////////////////////////////////////////////T79P/q9+r///////////8AAAAnAAAAAACZ
        AAoAmQDZAJkA/wCZAP8AmQDqAJkAFQAAAAAAAAAAAAAA/wAAAP9/f3///////////////////////////////////////////////////////////////////////////////////////////////////////wAA
        AM8AAAAbAAAAAACZADgAmQD8AJkA/wCZAP8AmQCtAAAAAAAAAAAAAAD/AAAA/39/f///////////////////////////////////////////////////////////////////////////////////////////////
        ////////AAAA3wAAALQAAAAAAAAAAACZAIYAmQD/AJkA/wCZAP8AmQBbAAAAAAAAAP8AAAD/f39/////////////////////////////////////////////////////////////////////////////////////
        //////////////////8gICD/AAAA/wAAAF8AAAAAAJkABwCZANIAmQD/AJkA/wCZAO8AmQAbAAAA/wAAAP9/f3/////////////39/f/ZGRk/2lpaf+oqKj/rKys/3h4eP/BwcH/bW1t/5+fn/+EhIT/d3d3/5ub
        m/+qqqr/hISE/////////////////yAgIP8AAAD/AAAAnwAAAAAAAAAAAJkAMACZAPoAmQD/AJkA/wCZALgAAAD/AAAA/39/f////////////7i4uP96enr//////7S0tP+Dg4P/QkJC/3Nzc/96enr/cnJy/z8/
        P//u7u7/ioqK/yMjI//AwMD/////////////////ICAg/wAAAP8AAACfAAAAAAAAAAAAAAAAAJkAfACZAP8AmQD/AJkA1gAAAP8AAAD/f39/////////////39/f/0BAQP+Wlpb/kpKS/1tbW/+jo6P/6enp/4qK
        iv/Nzc3/w8PD/4eHh/+IiIj/qamp/7W1tf////////////////8gICD/AAAA/wAAAJ8AAAAAAAAAAAAAAAAAmQAEAJkApwCZAIsAmQALAAAA/wAAAP9/f3//////////////////6enp/9DQ0P/q6ur/4ODg////
        /////////////////////////////+Dg4P/r6+v//////////////////////yAgIP8AAAD/AAAAnwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/AAAA/39/f///////////////////////////////
        ////////////////////////////////////////////////////////////////////////ICAg/wAAAP8AAACfAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8AAAD/f39/////////////////////
        ///h4eH/qamp/62trf/4+Pj///////////////////////////////////////////////////////////8gICD/AAAA/wAAAJ8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/wAAAP9/f3//////////
        /////////////4SEhP8AAAD/X19f////////////+vr6/+/v7//4+Pj////////////8/Pz/7+/v//T09P///////////yAgIP8AAAD/AAAAnwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/AAAA/39/
        f/////////////X19f9eXl7/AwMD/wAAAP8EBAT/YWFh//b29v+np6f/AAAA/zw8PP///////////3t7e/8AAAD/TU1N////////////ICAg/wAAAP8AAACfAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AP8AAAD/f39/////////////Xl5e/wAAAP8SEhL/Q0ND/w8PD/8AAAD/Y2Nj//T09P8MDAz/AAAA/wYGBv8ICAj/AgIC/wAAAP+pqan///////////8gICD/AAAA/wAAAJ8AAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAA/wAAAP9/f3///////+rq6v8CAgL/DAwM/+Pj4///////29vb/wgICP8EBAT/7+/v/11dXf8AAAD/Gxsb/ycnJ/8AAAD/EhIS//f39////////////yAgIP8AAAD/AAAAnwAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAD/AAAA/39/f///////yMjI/wAAAP88PDz/////////////////MzMz/wAAAP/Q0ND/u7u7/wAAAP9WVlb/lpaW/wAAAP9sbGz/////////////////ICAg/wAAAP8AAACfAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8AAAD/f39////////e3t7/AAAA/xgYGP/39/f///////Pz8/8SEhL/AAAA/+bm5v/9/f3/HBwc/wsLC/86Ojr/AAAA/8/Pz/////////////////8gICD/AAAA/wAA
        AJ8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/wAAAP9/f3////////////87Ozv/AAAA/zo6Ov+Dg4P/NDQ0/wAAAP9ERET///////////94eHj/AAAA/wAAAP80NDT//////////////////////yAg
        IP8AAAD/AAAAnwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/AAAA/39/f////////////97e3v8kJCT/AAAA/wAAAP8AAAD/KSkp/+Pj4////////////9XV1f8AAAD/AAAA/5mZmf//////////////
        ////////ICAg/wAAAP8AAACfAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8AAAD/f39///////////////////b29v+pqan/ioqK/6ysrP/4+Pj//////////////////////6ioqP+jo6P/9fX1////
        //////////////////8gICD/AAAA/wAAAJ8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/wAAAP9/f3//////////////////////////////////////////////////////////////////////////
        /////////////////////////////yAgIP8AAAD/AAAAnwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/AAAA/39/f///////////////////////////////////////////////////////////////
        ////////////////////////////////////////ICAg/wAAAP8AAACfAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8AAAD/QEBA/39/f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/
        f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/8QEBD/AAAA/wAAAJ8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
        AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAAeAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAA0gAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
        AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/BQUF/wAAAKAAAAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADP8AABh/AAAAPwAAAD8AAAAfAAAADwAA
        Ag8AAAMHAAABAwAAAIMAAADBAAAAQAAAAGAAAABwAAAAcAAAAH8AAAB/AAAAfwAAAH8AAAB/AAAAfwAAAH8AAAB/AAAAfwAAAH8AAAB/AAAAfwAAAH8AAAB/AAAAfwAAAH8AAAB/KAAAABAAAAAgAAAAAQAgAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALYAAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA+wAAAFcAmQAaAJkAnQCZAA8AAAAAAAAAAAAAAAAAAAD/j4+P/7+/v/+/v7//v7+//7+/v/+/v7//v7+//9LS
        0v/l9eX/Jqgm/wCZAP8AmQCgAAAAAAAAAAAAAAAAAAAA/7+/v//////////////////////////////////l9eX/Jqgm/wecB/8AmQDDAJkA/wCZAE4AAAAAAAAAAAAAAP+/v7//////////////////////////
        ////////z+zP/xOhE/+v36//AJkAEACZAOMAmQDoAJkAFAAAAAAAAAD/v7+////////////////////////////////////////3/Pf//////wAAAEQAmQBHAJkA/gCZAKsAAAAAAAAA/7+/v//9/f3/s7Oz/9XV
        1f/Ozs7/w8PD/76+vv/R0dH/4ODg//////8AAADcAAAAGACZAJgAmQD/AJkAWQAAAP+/v7//5eXl/5SUlP+JiYn/kJCQ/5GRkf+enp7/eHh4/93d3f//////AAAA7wAAAFAAmQAMAJkA3QCZAOMAAAD/v7+/////
        ///u7u7/8vLy//////////////////Ly8v///////////xAQEP8AAABQAAAAAACZACsAmQAmAAAA/7+/v///////2dnZ/21tbf/9/f3/+vr6//39/f/+/v7/+Pj4//////8QEBD/AAAAUAAAAAAAAAAAAAAAAAAA
        AP+/v7//1NTU/x0dHf8VFRX/b29v/2pqav9QUFD/YWFh/z09Pf//////EBAQ/wAAAFAAAAAAAAAAAAAAAAAAAAD/v7+//21tbf+Li4v/9vb2/xAQEP+2trb/HBwc/y8vL/+dnZ3//////xAQEP8AAABQAAAAAAAA
        AAAAAAAAAAAA/7+/v/+Ghob/UlJS/6qqqv8WFhb/+Pj4/ygoKP8cHBz/8/Pz//////8QEBD/AAAAUAAAAAAAAAAAAAAAAAAAAP+/v7//9/f3/3Fxcf9NTU3/wcHB//////+fn5//jIyM////////////EBAQ/wAA
        AFAAAAAAAAAAAAAAAAAAAAD/v7+//////////////////////////////////////////////////xAQEP8AAABQAAAAAAAAAAAAAAAAAAAA/4+Pj/+/v7//v7+//7+/v/+/v7//v7+//7+/v/+/v7//v7+//7+/
        v/8MDAz/AAAAUAAAAAAAAAAAAAAAAAAAALYAAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/GRkZ/wAAACAAAAAAAAAAAAAAAAAABwAAAAcAAAADAAAAAQAAAAEAAAAAAAAAAAAAAAQAAAAH
        AAAABwAAAAcAAAAHAAAABwAAAAcAAAAHAAAABwAA')
    $MainFORM.Add_Load($MainFORM_Load)
    $MainFORM.Add_Resize($MainFORM_Resize)
    $MainFORM.Add_FormClosing($MainFORM_FormClosing)
    $MainFORM.Add_FormClosed($Form_Cleanup_FormClosed)

    $MainTT                             = (New-Object -TypeName 'System.Windows.Forms.ToolTip')

    $tab_Pages                          = (New-Object -TypeName 'System.Windows.Forms.TabControl')
    $tab_Pages.Anchor                   = 'Top, Bottom, Left, Right'
    $tab_Pages.Location                 = ' 12,  12'
    $tab_Pages.Size                     = '770, 608'
    $tab_Pages.Padding                  = ' 12,   6'
    $tab_Pages.SelectedIndex            = 0
    $tab_Pages.Add_SelectedIndexChanged($tab_Pages_SelectedIndexChanged)
    $MainFORM.Controls.Add($tab_Pages)
    
    $tab_Page1                          = (New-Object -TypeName 'System.Windows.Forms.TabPage')
    $tab_Page1.Anchor                   = 'Top, Bottom, Left, Right'
    $tab_Page1.BackColor                = 'Control'
    $tab_Page1.Text                     = ($script:ToolLangINI['page1']['Tab'])
    $tab_Pages.Controls.Add($tab_Page1)

    $tab_Page2                          = (New-Object -TypeName 'System.Windows.Forms.TabPage')
    $tab_Page2.Anchor                   = 'Top, Bottom, Left, Right'
    $tab_Page2.BackColor                = 'Control'
    $tab_Page2.Text                     = ($script:ToolLangINI['page2']['Tab'])
    $tab_Pages.Controls.Add($tab_Page2)

    $tab_Page3                          = (New-Object -TypeName 'System.Windows.Forms.TabPage')
    $tab_Page3.Anchor                   = 'Top, Bottom, Left, Right'
    $tab_Page3.BackColor                = 'Control'
    $tab_Page3.Text                     = ($script:ToolLangINI['page3']['Tab'])
    $tab_Pages.Controls.Add($tab_Page3)

    $tab_Page4                          = (New-Object -TypeName 'System.Windows.Forms.TabPage')
    $tab_Page4.Anchor                   = 'Top, Bottom, Left, Right'
    $tab_Page4.BackColor                = 'Control'
    $tab_Page4.Text                     = ($script:ToolLangINI['page4']['Tab'])
    $tab_Pages.Controls.Add($tab_Page4)

    $btn_Exit                           = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_Exit.Location                  = '707, 635'
    $btn_Exit.Size                      = ' 75,  25'
    $btn_Exit.Text                      = ($script:ToolLangINI['exit']['Button'])
    $btn_Exit.DialogResult              = [System.Windows.Forms.DialogResult]::Cancel    # Use this instead of a 'Click' event
    $btn_Exit.Anchor                    = 'Bottom, Right'
    $MainFORM.CancelButton              = $btn_Exit
    $MainFORM.Controls.Add($btn_Exit)

    $btn_About                          = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_About.Location                 = ' 12, 635'
    $btn_About.Size                     = ' 75,  25'
    $btn_About.Text                     = ($script:ToolLangINI['about']['Button'])
    $btn_About.Anchor                   = 'Bottom, Left'
    $btn_About.Add_Click({ Show-AboutSplash })
    $MainFORM.Controls.Add($btn_About)

    $tim_CompleteButton                 = (New-Object -TypeName 'System.Windows.Forms.Timer')
    $tim_CompleteButton.Stop()
    $tim_CompleteButton.Interval        = '1000'    # 1 Second
    $tim_CompleteButton.Add_Tick($tim_CompleteButton_Tick)

    # All 16x16 Icons (See list at top of code)
    $img_MainForm                       = (New-Object -TypeName 'System.Windows.Forms.ImageList')
    $img_MainForm.TransparentColor      = 'Transparent'
    $img_MainForm_BinaryFomatter        = (New-Object -TypeName 'System.Runtime.Serialization.Formatters.Binary.BinaryFormatter')
    $img_MainForm_MemoryStream          = (New-Object -TypeName 'System.IO.MemoryStream' (,[byte[]][System.Convert]::FromBase64String('
        AAEAAAD/////AQAAAAAAAAAMAgAAAFdTeXN0ZW0uV2luZG93cy5Gb3JtcywgVmVyc2lvbj00LjAuMC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkFAQAAACZTeXN0
        ZW0uV2luZG93cy5Gb3Jtcy5JbWFnZUxpc3RTdHJlYW1lcgEAAAAERGF0YQcCAgAAAAkDAAAADwMAAABUPQAAAk1TRnQBSQFMAgEBDgEAARgBAAEIAQABEAEAARABAAT/ASEBAAj/AUIBTQE2BwABNgMAASgDAAFA
        AwABQAMAAQEBAAEgBgABQP8AWwADAgEDAxQBGgFCAkMBZgFbAVwBXQGpAWABZAFmAdsBYQFkAWcB8QFhAWQBZgHbAVsBXAFdAakCQwFEAWcDFQEbAwIBA5wAAwcBCQEyAS4BLAFDAWABTQFEAZABeAFTAUUBxAF7
        AVMBQwHNAWwBUAFGAagBQwE7ATgBXgESAhEBFxQAAwcBCQMwAUQBYwFlAWcBsQGNAZABkgH5AbcBtgG3Af8B1QHPAcwB/wHhAdoB2QH/AdQB0AHOAf8CuAG1Af8BjgGRAZIB+QFjAWUBZgGyAzEBRQMHAQmYAAFK
        AUABPAFpAYYBUQE8AewBiwFOATcB/QGEAVEBPQHoAYIBUgFAAeEBiQFQATgB9wGKAU4BNgH7AWkBUAFGAaMBIgEgAR8BLAMAAQEIAAMCAQMDMAFEAWsBbQFuAcIBrgGrAawB/wHRAawBogH/Ac0BcwFaAf8BrgFI
        ASsB/wGNATIBFQH/AZcBRQEqAf8BvQFuAVcB/wHVAawBoQH/Aa8CqwH/AWoBbQFuAcIDMQFFAwIBA5QAAT0BNwE0AVQBggFTAT8B4AFRAUQBPwF0ASoBJwEmATcBJQEjASIBMQE8ATYBNAFTAXYBUgFEAcIBiQFO
        ATcB+gFsAVABRgGoAhQBEwEaCAADFAEaAWMBZQFnAbEBrgKsAf8B0AGfAYwB/wG3AUUBHgH/AboBSQEmAf8B3wG8AbAB/wH1AekB6AH/Ac4BnwGSAf8BkwEsAQ0B/wG5AUEBIwH/AdsBnAGMAf8BrgGqAasB/wFk
        AWUBZgGyAxUBG5gAAwIBAxAAAwUBBwF0AVIBRgG7AYsBTgE3Af0BTQFCAT0BbggAAkIBQwFlAY0BkAGRAfkB0wGyAacB/wG1AUsBJgH/AakBLwEGAf8BuwFcATwB/wHpAdwB1wX/AdwBvQG1Af8BmQE4ARwB/wGx
        ASwBCAH/AccBSgEsAf8B0gGuAaUB/wGNAZEBkgH5AkMBRAFnsAABNQEwAS4BRwGGAVABOwHvAXYBUgFFAcEIAAFZAVsBXQGoAbYBtwG4Af8B0QGFAWgB/wGwATwBEAH/AagBNAENAf8BuwFaATsB/wHUAcQBwAH/
        Ae0B/QL/Ad0BvQG0Af8BlQE5AR4B/wGrATIBEQH/AbgBMQEKAf8ByQF0AVwB/wG2AbgBtwH/AVsBXAFdAamwAAEeAR0BHAEnAXsBUwFEAc4BhQFRAT0B6ggAAV8BYgFkAdsB1ALTAf8BzAFlAT0B/wHBAVUBLAH/
        Aa8BPwEWAf8BtwFYATkB/wHZAccBwgH/AfAB/gL/AeIByAHBAf8BlwFAASUB/wGqATMBDwH/AbABNwETAf8BtQFFASIB/wHWAtMB/wFgAWQBZgHbjAABPgE3ATUBVQFEATwBOAFfAUQBPAE4AV8BRAE8ATgBXwE6
        ATQBMgFPAQ0CDAEQDAABHwIdASgBfAFTAUIB0QGEAVEBPQHoCAABYAFkAWYB8QHkAt4B/wHOAVsBLwH/AcwBYwE7Af8BxAFXASwB/wHDAWgBRwH/AdUBxQHBAf8B7gH+Av8B4AHJAcIB/wGXAT8BJAH/AaYBMwEO
        Af8BrAE6ARQB/wGnAS8BBwH/AeQC3wH/AWEBZQFoAfGMAAGIAVABOgHyAYsBTQE1Af8BiwFNATUB/wGHAVABOwHxAVsBSgFEAYcDDgESDAABOgE0ATIBTwGIAVABOgHyAXMBUgFFAboIAAFfAWIBZAHbAdYC0gH/
        AdkBcgFLAf8B0QFoAT0B/wHRAWYBPgH/AdEBewFcAf8B3wHQAc0B/wH8A/8B1QHEAb4B/wGZAT0BIAH/AaUBNgEQAf8BqAE5AREB/wGwAUcBIQH/AdcB1AHSAf8BYAFkAWYB24wAAYcBTwE5AfMBiwFNATUB/wGL
        AU0BNQH/AWkBUAFGAaQDDgESDAABDQIMARABeQFTAUQByAGKAU4BNgH7AUcBPgE6AWQIAAFZAVsBXAGoAbQCtgH/AeEBnQGAAf8B2wFnAToB/wHXAW8BRQH/AdkBdwFPAf8B6QGLAWcB/wHzAZYBcwH/AdwBcQFM
        Af8BwgFRAScB/wG+AVMBKwH/AbgBRwEcAf8BywGCAWYB/wG2ArcB/wFbAVwBXQGpjAABhwFPATkB8wGIAVABOgH0AYgBTwE5AfUBhgFQATsB7gFdAUwBQwGLATEBLQEsAUIBLAEpAScBOgFJAT8BOwFmAX0BUwFC
        AdMBiQFPATkB+AFlAU8BRgGbAxABFQgAA0IBZQGLAY4BjwH5AdwBvwG1Af8B5AGHAWAB/wHiAXIBQgH/AeMBdwFMAf8B8wGgAYAB/wH3AdcBxwH/AfQBpAGDAf8B2AFkATUB/wHMAV8BMgH/Ac4BbQFFAf8B1QG1
        AaoB/wGOAZABkgH5AUICQwFmjAABhAFSAT4B5QFeAUwBRAGNAVEBRQE/AXUBgQFRAT8B3wGLAU0BNQH/AYgBTgE4AfYBhwFQATsB8QGLAU4BNwH9AYgBTwE5AfUBYQFNAUQBkwEbARoBGQEjDAADFAEaAWIBYwFl
        AbEBrAGqAakB/wHlAbgBqAH/AewBjQFlAf8B9gF8AU4C/wHRAcAG/wHTAcEB/wHgAWoBNwH/AdYBcAFJAf8B2wGsAZkB/wGtAaoBqwH/AWMBZAFmAbEDFAEajAABVAFGAUEBeQEPAg4BEwMEAQUBKgEnASYBNwFT
        AUUBQAF3AW0BUQFGAasBcQFSAUYBtAFgAU0BRAGPATcBMgEwAUsDDQEREAADAgEDAS8CMAFDAWkBagFtAcIBqwGpAasB/wHbAb8BtgH/Ae0BowGEAf8B9wGRAWQB/wH7AZgBbgH/AfYBhwFYAf8B5gGTAXAB/wHX
        AbkBrgH/Aa0CqgH/AWoBawFtAcIDMAFEAwIBA8gAAwcBCQEvAjABQwFiAWMBZQGxAYkBjgGPAfkBsgK0Af8B1AHOAcwB/wHiAdkB1wH/AdMBzgHNAf8BtAGzAbQB/wGLAY4BkAH5AWMBZAFmAbEDMAFEAwcBCdAA
        AwIBAwMUARoBQQJCAWUBWQFaAVsBqAFfAWABZAHbAV4BYwFlAfEBXwFhAWQB2wFZAVsBXAGoAUECQgFlAxQBGgMCAQP/AOUAAoYBhQH/A5oB/wGUAZUBkwH/AZQBlgGXAf8BlwKbAf8BlQGYAZcB/wKSAZEB/wKS
        AZAB/wKYAZcB/wKGAYUB/xgAAoYBhQH/A5oB/wGUAZUBkwH/AZQBlgGXAf8BlwKbAf8BlQGYAZcB/wKSAZEB/wKSAZAB/wKYAZcB/wKGAYUB/xgAAoYBhQH/A5oB/wKVAZMB/wKUAZIB/wKTAZIB/wKSAZEB/wKS
        AZAB/wKSAZAB/wKYAZcB/wKGAYUB/xAAAx4BKwM8AXsDPAF5Ax0BKAQAAwEBAgMBAQIsAAGaAZsBmQX/AfUB+AH5Bf8B7QHdAdcR/wKZAZcB/xgAAZoBmwGZBf8B9QH4AfkF/wHtAd0B1xH/ApkBlwH/GAACmwGZ
        Bf8D8QH/A/gB/wP6Af8D/g3/ApkBlwH/DAADNQFdAw4B+wNDAfkDQQH5AxAB+gM7AaoDGwHxAxYB9gM9AZ8DCAELJAAClQGUAf8B7QHsAesB/wHmAegB6gH/AcYBpwGbAf8BiwFNATUB/wHCAaIBlwH/Af0D/wHx
        AfIB8wH/Af0C/gH/AZIBkwGRAf8YAAKVAZQB/wHtAewB6wH/AeYB6AHqAf8BxgGnAZsB/wGLAU0BNQH/AcIBogGXAf8B/QP/AfEB8gHzAf8B/QL+Af8BkgGTAZEB/xgAApYBlQH/AewB6wHqAf8B1wHWAdQB/wPq
        Af8D7gH/AvQB8wH/A/UB/wPwAf8C/QH+Af8BkgGTAZEB/wQAAwQBBgMxAVEDEwHzA6kB9gj/A54B9gMCAfsDywH5A9wB+QMpAfoDPQGZAwABASAAApYBlQH/AfUB9wH2Af8B5wHjAeEB/wGIAUUBLQH/AZEBVQE+
        Af8BjAFKATQB/wH4AfMB8gH/AfQC9wH/AfoC+QH/ApMBkgH/GAAClgGVAf8B9QH3AfYB/wHnAeMB4QH/AYgBRQEtAf8BkQFVAT4B/wGMAUoBNAH/AfgB8wHyAf8B9AL3Af8B+gL5Af8CkwGSAf8YAAKYAZcB/wHp
        AegB5gH/AdgB1QHUAf8D7QH/AvEB8gH/AvUB9gH/A/cB/wPvAf8B+gL5Af8CkwGSAf8DEAEVAzAB0QMSAfwDKQH3BP0I/wT+A+MB+Qj/A8AB+QMAAf8DGwHvAz0BgAMBAQIChgGFAf8DmgH/AZQBlQGTAf8BlAGW
        AZcB/wGXApsB/wGVAZgBlwH/AZQBlQGUAf8B/QP/Ab4BowGXAf8BpQF0AWEB/wHpAeEB3AH/AZIBVwFBAf8BuQGTAYUB/wH7A/8B9QL2Af8ClAGSAf8ChgGFAf8DmgH/ApUBkwH/ApQBkgH/ApMBkgH/ApcBlgH/
        AZQBlQGUAf8B/QP/Ab4BowGXAf8BpQF0AWEB/wHpAeEB3AH/AZIBVwFBAf8BuQGTAYUB/wH7A/8B9QL2Af8ClAGSAf8ChgGFAf8DmgH/ApUBkwH/ApQBkgH/ApMBkgH/ApcBlgH/ApcBlgH/AecB5QHjAf8B0QHO
        AcoB/wLlAeQB/wHqAusB/wPwAf8D8wH/AesC6QH/AvUB9AH/ApQBkwH/AzwBnAM6AfoD+wH8IP8E/QPZAfkDxAH4AxgB/AM7AXIBmgGbAZkF/wH1AfgB+QX/Ae0B3QHXBf8BjQGOAY0B/wLoAeYB/wHVAdABzQH/
        AeIB2wHXAf8B9gH7Af4B/wG1AY0BfgH/AYkBSQExAf8D7gH/AfgC+wH/ApQBkwH/ApsBmQX/A/EB/wP4Af8D+wX/AY0BjgGNAf8C6AHmAf8B1QHQAc0B/wHiAdsB1wH/AfYB+wH+Af8BtQGNAX4B/wGJAUkBMQH/
        A+4B/wH4AvsB/wKUAZMB/wKbAZkF/wPxAf8D+AH/A/sF/wKPAY4B/wHlAeMB4gH/AcoBxAG/Af8B3gHYAdQB/wHgAd0B2gH/AeYB5QHkAf8C6gHrAf8D4QH/AfEC8AH/ApUBlAH/AyUB3gPBAfkI/wPgAfwDNwH5
        A/sB/AN/AfgDjgH5A/sB/AM2AfkD7QH7CP8DpgH4Ay4BzwKVAZQB/wHtAewB6wH/AeYB6AHqAf8BxgGnAZsB/wGLAU0BNQH/AcIBogGXAf8BiwGMAYsB/wHlAeIB4AH/AckBwgG+Af8B2QHVAdIB/wLjAeAB/wHj
        AdYB0AH/AYcBRQEuAf8BtwGSAYYF/wOUAf8ClgGVAf8B7AHrAeoB/wHXAdYB1AH/A+oB/wPvBf8BiwGMAYsB/wHlAeIB4AH/AckBwgG+Af8B2QHVAdIB/wLjAeAB/wHjAdYB0AH/AYcBRQEuAf8BtwGSAYYF/wOU
        Af8ClgGVAf8B7AHrAeoB/wHXAdYB1AH/A+oB/wPvBf8BiwGMAYsB/wHmAeMB4QH/AcoBwwG8Af8B2AHRAc0B/wHYAdMB0AH/Ad4B2gHXAf8B5AHjAeEB/wLbAdoB/wPtAf8ClgGVAf8DLwHMA5sB+Aj/A+IB+wM5
        AfgE/QOBAfkDjwH5A/sB/AM1AfkD6wH7CP8DpwH5Ay4BzwKWAZUB/wH1AfcB9gH/AecB4wHhAf8BiAFFAS0B/wGRAVUBPgH/AYwBSgE0Af8BigGLAYoB/wHkAeEB3wH/Ab0BtQGxAf8ByAHBAb0B/wHGAcABugH/
        AekB7QHsAf8BoQFxAWAB/wGVAWABSwH/Af0B+gH5Af8BlgGXAZYB/wOXAf8B6QHoAeYB/wHYAdUB1AH/A+0B/wPyBf8BigGLAYoB/wHkAeEB3wH/Ab0BtQGxAf8ByAHBAb0B/wHGAcABugH/AekB7QHsAf8BoQFx
        AWAB/wGVAWABSwH/Af0B+gH5Af8BlgGXAZYB/wOXAf8B6QHoAeYB/wHYAdUB1AH/A+0B/wPyBf8BigGLAYoB/wHkAeEB3wH/Ab0BtQGxAf8ByAHCAb0B/wHHAcABuwH/AckBwQG9Af8BzQHIAcQB/wHIAcYBwgH/
        AesB6gHoAf8BlgGXAZUB/wM2AV8DDwH9A6IB+APxAfsg/wP7AfwDvQH4AxgB/AM7AXIBlAGVAZQB/wH9A/8BvgGjAZcB/wGlAXQBYQH/AekB4QHcAf8BkgFXAUEB/wGOAY8BjQX/AeUB4gHgAf8B5wHkAeIB/wHl
        AeIB4AH/Au8B8AH/AfIB6QHmAf8B7gHgAdsF/wOaAf8CmAGXAf8B5wHlAeMB/wHRAc4BygH/AuUB5AH/AusB7AX/AY4BjwGNBf8B5QHiAeAB/wHnAeQB4gH/AeUB4gHgAf8C7wHwAf8B8gHpAeYB/wHuAeAB2wX/
        A5oB/wKYAZcB/wHnAeUB4wH/AdEBzgHKAf8C5QHkAf8C6wHsBf8BjgGPAY0F/wHlAeIB4AH/AecB5AHiAf8B5gHjAeIB/wHmAeMB4QH/AeUB4wHfAf8C5gHjBf8DmwH/BAADOAFlAxoB5gNPAfkg/wNiAfgDEAHx
        AzwBgQMBAQIBjQGOAY0B/wLoAeYB/wHVAdABzQH/AeIB2wHXAf8B9gH7Af4B/wG1AY0BfgH/Am0BbAH/AZEBkgGRAf8BkQGSAZEB/wGYAZkBmAH/AZgBmQGYAf8BlgGYAZcB/wGYAZwBmwH/AZgCmwH/AZoBmwGa
        Af8ChgGFAf8BmAGZAZgB/wHlAeQB4gH/AcoBxAG/Af8B3gHYAdQB/wHgAd0B2wH/AfMC8gH/Am0BbAH/AZEBkgGRAf8BkQGSAZEB/wGYAZkBmAH/AZgBmQGYAf8BlgGYAZcB/wGYAZwBmwH/AZgCmwH/AZoBmwGa
        Af8ChgGFAf8BmAGZAZgB/wHlAeQB4gH/AcoBxAG/Af8B3gHYAdQB/wHgAd0B2wH/AfMC8gH/Am0BbAH/AZEBkgGRAf8BkQGSAZEB/wGYAZkBmAH/AZkBmgGZAf8BmAGZAZgB/wGYAZkBmAH/AZcBmAGXAf8CmwGa
        Af8ChwGGAf8IAAM2AV8DGQT7AfwM/wOxAfgDTQH3A9QB+QOUAfcDDQH8AyoBQQgAAYsBjAGLAf8B5QHiAeAB/wHJAcIBvgH/AdkB1QHSAf8C4wHgAf8B4wHWAdAB/wGHAUUBLgH/AbcBkgGGBf8DlAH/GAABmAGZ
        AZgB/wHmAeMB4gH/AcoBwwG8Af8B2AHRAc0B/wHZAdMB0AH/AeIB3gHbAf8B8gHwAe4B/wHpAugB/wH3AfgB9wH/ApoBmQH/GAABmAGZAZgB/wHmAeMB4gH/AcoBwwG8Af8B2AHRAc0B/wHZAdMB0AH/AeIB3gHb
        Af8B8gHwAe4B/wHpAugB/wH3AfgB9wH/ApoBmQH/IAADBgEIAywB1wNDAfkD8AH5A/oB+wO5AfgDDwH9AywB0QMbAe8DLgHQAzEBUQwAAYoBiwGKAf8B5AHhAd8B/wG9AbUBsQH/AcgBwQG9Af8BxgHAAboB/wHp
        Ae0B7AH/AaEBcQFgAf8BlQFgAUsB/wH9AfoB+QH/AZYBlwGWAf8YAAGXApgB/wHlAeIB4AH/Ab0BtQGxAf8ByAHCAb0B/wHHAcABuwH/AckBwgG9Af8BzgHJAcQB/wHIAcYBwwH/AesB6gHpAf8BlgGXAZYB/xgA
        AZcCmAH/AeUB4gHgAf8BvQG1AbEB/wHIAcIBvQH/AccBwAG7Af8ByQHCAb0B/wHOAckBxAH/AcgBxgHDAf8B6wHqAekB/wGWAZcBlgH/JAADFAEbAzgBtQMLAf4DBQH/AxoB7wM7AXMcAAGOAY8BjQX/AeUB4gHg
        Af8B5wHkAeIB/wHlAeIB4AH/Au8B8AH/AfIB6QHmAf8B7gHgAdsF/wOaAf8YAAKcAZsF/wHlAeIB4AH/AeYB4wHiAf8B5gHjAeIB/wHmAeMB4QH/AeUB4wHfAf8C5gHjBf8DmwH/GAACnAGbBf8B5QHiAeAB/wHm
        AeMB4gH/AeYB4wHiAf8B5gHjAeEB/wHlAeMB3wH/AuYB4wX/A5sB/ywAAw4BEwMbASUDBAEFIAACbQFsAf8BkQGSAZEB/wGRAZIBkQH/AZgBmQGYAf8BmAGZAZgB/wGWAZgBlwH/AZgBnAGbAf8BmAKbAf8BmgGb
        AZoB/wKGAYUB/xgAAocBhgH/AZsBnAGbAf8BlwGYAZcB/wGYAZkBmAH/AZgBmQGYAf8BmAGZAZgB/wGYAZkBmAH/AZcBmAGXAf8CmwGaAf8ChwGGAf8YAAKHAYYB/wGbAZwBmwH/AZcBmAGXAf8BmAGZAZgB/wGY
        AZkBmAH/AZgBmQGYAf8BmAGZAZgB/wGXAZgBlwH/ApsBmgH/AocBhgH//wBdAAMBAQIDCQEMAxABFgMTARoDEwEaAxMBGgMTARoDEwEaAxMBGgMTARoDEwEaAxEBFwMJAQwDAQECIAABLwEtASwBPAE/AT0BOQFU
        AS4BLQErAUABVgFGATcB3wEzATEBMAFMAT4BOwE4AWMBLAEqASkBPEgAAwIBAwMHBAkBDAMJAQwDCQEMAwkBDAMJAQwDCQEMAwkBDAMJAQwDCQEMAwkBDAMJAQwDCQEMAwcBCQMCAQMEAAMDAQQDEQEXAx0BKwMm
        ATwDMgFeAzcBeAM3AYcDNwGHAzcBeAMyAV4DJgE8Ax4BLQMSARgDAwEEIAABWgFTAUoBhQGMAW4BVgHkAZIBfgFrAc8BrQGbAYQB/gGJAXgBYwHVAWwBVwFOAegBSgFGAUABhUgAAwsBDwMdASoDIwE3AyMBNwMj
        ATcDIwE3AyMBNwMjATcDIwE3AyMBNwMjATcDIwE3AyMBNwMjATcDHQEqAwsBDwwAAyIBMgNBAYEDdAG7AsMBwgHmAuwB6AH5AuwB6QH5AsQBwgHmA3UBuwNBAYEDIgEyIAACIAEfASkBWQFPAUUBhAGSAYABawHR
        Af8B+AHqAf8B9gHtAdUB/gHyAdoBygH5AewB2QHJAf4BxgGyAZUB/wGWAYMBagHXAVIBSgFEAYEDHwEqDwABAQMFBAcBCQMAAQELAAEBAwcBCQMFAQcDAAEBDAADFQEdAV4BVwHAAf8BWwFAAYsB/wFIAgAB/wFI
        AgAB/wFIAgAB/wGzAbEBxAH/AVIBSAGrAf8BTwFFAaoB/wGzAbEBxAH/AUgCAAH/AUgCAAH/AUgCAAH/AZsBcQFoAf8BngGbAckB/wMVAR0IAAMhAS8DSgGJAsQBwAHmAvMB7gH/AvEB6wH/AvEB6wH/AvEB6wH/
        AvEB6wH/AvMB7gH/AscBxQHmA0oBiQMhAS8YAAMjAS0BRAFBAUABYQGXAX4BZwHcAv8B+gH/AdUBvwGwAf4BcwFmAVgBtgFWAVABRwF/AW0BYAFUAZ4BsQGYAX4B/AHgAdABwwH/AXQBXgFMAdUBJAEjASIBMAsA
        AQEBDQIOARIBNwE4AUQBWwE7AT0BTgFmAhIBEwEYAwABAQMAAQECEgETARgBOwE9AU4BZgE3ATkBRQFcAQ0CDgESAwABAQgAAxkBIwG1Aa8BwwH/AXwBdAHxAf8BeAFIAYwB/wF0ARgBEgH/AWICDQH/AeEB3gH1
        Af8BKwEYAdQB/wEmARMB0wH/AeEB3gH1Af8BZwETARQB/wFjAg0B/wHGAZQBiAH/AckBxgH7Af8BVgFKAbgB/wMZASMEAAMMARADQwF3Ar8BtwHmAu0B5AH/AvEB6wH/AvEB6wH/AvEB6wH/AvEB6wH/AvEB6wH/
        AvEB6wH/Au0B5QH/AsQBwAHmA0MBdwMMARAUAANBAWMBcAFtAWYBwAG3AZ4BjQHpAfUB7wHZAf4BYAFTAUAB3QIOAQ0BEgQAARECEAEVAXcBaQFYAa4B3AHKAbUB/wFsAWQBWgHFAS4BLQEsAT4IAAMIAQoBOQE7
        AUgBYQFSAV4BuAHYAVMBYAHDAd8BPwFCAVYBcgMPARQCDgEPARMBPgFBAVMBbwFUAWABwgHeAVIBXgG5AdgBOQE7AUkBYQMIAQoIAAMZASMBdgE0AS8B/wHqAd0B3wH/ApAC/wF2AVQBsAH/AX4BJwEkAf8B4QHe
        AfUB/wEnARIB1AH/ASEBDAHTAf8B4QHeAfUB/wF3ASABHwH/AdoBuwGyAf8BtwG5Av8BcAFcAdQB/wFwATQBOwH/AxkBIwQAAyoBPwJ1AXIBswLgAdAB/wLvAecB/wLxAesB/wLxAesB/wLfAdwB/wLxAesB/wLx
        AesB/wLxAesB/wLvAecB/wLiAdMB/wJ4AXcBswMqAT8MAAMrATgDTAF8A2kBqAG2AaIBiAH5Ae4B1wG+Af0B2AHBAa8B/gF0AmoB3QgAAwMBBAFiAVgBTgGPAdYBxgGyAf4BpgGCAWIB+gFxAWMBUgHWCAADEAEV
        AU0BUwGBAZ8BVQFpAewB+gFWAWsB9wH/AVEBYQHQAeoBRQFIAWYBiAFEAUgBYgGEAVEBYgHOAekBVgFrAfcB/wFWAWoB7QH6AU0BVAGCAZ4CEAERARUIAAMZASMBXAIOAf8BggEuASoB/wHmAc8BxwH/AaIBoAH9
        Af8BdQFdAcgB/wHhAd4B9QH/ASYBEQHTAf8BIAEMAdIB/wHhAd4B9QH/AecB1gHUAf8BogGhAf0B/wFxAVYBwQH/AYoBOwE5Af8BYAIOAf8DGQEjBAADOAFeArcBrQHiAt0BzAH/AvEB6wH/AvEB6wH/At8B3AH/
        AzcB/wLfAdwB/wLfAdwB/wLfAdwB/wLfAdsB/wLZAcwB/wK+AbcB4gM4AV4MAAM9AVsDcgHJA8cB2AGoAaUBoQHjAYUBcAFcAegC/gH6Af4BRgEyASkB3QMUARwDAgEDAhgBFwEfAYgBdwFhAcEB2gHPAb0B/wF+
        AWwBXgG2AR8BHgEdASkIAAMEAQUBKwEsATMBPwFUAV4BogG5AVIBZgHyAf8BTwFlAfMB/wFMAV4B0gHtAUwBXQHRAe0BTwFlAfMB/wFRAWYB8gH/AVUBXwGjAbgBKwEsATMBPgMEAQUIAAMZASMBzQHKAd4B/wHi
        Ad8B9QH/AeEB3gH1Af8B4QHeAfUB/wHhAd4B9QH/AeEB3gH1Af8BJwETAdQB/wEiAQ4B0wH/AeEB3gH1Af8B4QHeAfUB/wHhAd4B9QH/AeEB3gH1Af8B4gHfAfUB/wHNAcoB3gH/AxkBIwQAAz8BbQLXAcgB+ALd
        AcwB/wLxAesB/wLxAesB/wM0Af8DdgH/AZgBRAEpAf8BowFFAScB/wGnAUUBJgH/AagBRQElAf8BqwFIASYB/wLeAdMB+AM/AW0EAAMQARQDLgFCA1kBgwOaAcoDyQHeAXYBbwFpAcsBrQGSAXIB8wT/AdUBxwGw
        Af4BSAE4ASYB5wF3AWkBWAHhAXwBZgFPAeYB0AG2Aa8B/gHqAd0BxwH/AYMBYQFQAeoBLQEsASsBPgwAAwQBBgEnASgBLgE4AVYBYgG5AdABTAFhAfAB/wFJAV8B8QH/AUkBXwHxAf8BSwFhAfAB/wFWAWIBuQHQ
        AicBLQE3AwQBBgwAAxkBIwE8ASwByQH/ATIBHwHVAf8BJAEQAdIB/wEkARAB0wH/ASQBDwHSAf8BIgEOAdIB/wEmARIB0wH/ASYBEgHTAf8BIgEOAdIB/wEjAQ8B0gH/ASQBEAHTAf8BJAEQAdIB/wEyAR8B1QH/
        ATsBKwHJAf8DGQEjBAADPwFrAtUBxgH4At0BzAH/At0BzAH/AvEB6wH/AvEB6wH/AXgBTAE9Af8B8AHHAbYB/wHwAccBtgH/AfABxwG2Af8B6wG/AawB/wG3AWYBRwH/AtsB0AH4Az8BawQAAxIBFwNKAWoDkgHP
        A7QB3AOaAc8BRwFFAUMBggFmAV8BWQGUAZwBjQF9AcwB/QH5Ae0B/QL/AfQB/wH9AekB2gH+AfMB5QHQAf8B1gHEAa4B/wGGAXQBZAGsAUgBRAE/AWkBGQIYASAPAAEBAg4BDwETAUcBTAFtAZMBSwFeAdUB8gFB
        AVkB7gH/AUEBWQHuAf8BSwFeAdUB8gFHAUwBbQGTAg4BDwETAwABAQwAAxkBIwFFATUB0gH/AVQBQwHcAf8BRQE0AdkB/wFFATMB2QH/AUUBMwHZAf8BRAEyAdkB/wFGATUB2QH/AUUBNAHZAf8BRQEzAdkB/wFG
        ATUB2QH/AUUBMwHZAf8BRQEzAdkB/wFUAUQB3QH/AUYBNwHTAf8DGQEjBAADOQFaArQBqQHhAt0BzAH/At0BzAH/At0BzAH/At0BzAH/AYQBWQFKAf8B5AG7AaMB/wHkAbsBowH/AeQBuwGjAf8B2wGjAYkB/wHL
        AZcBfAH/ArkBsQHhAzkBWgQAAxkBIANMAWQDeQGPA1sBsAO1AcADOAGBAxYBHgFpAWIBWAGgAZ0BhQFlAekBtAGiAZEC6gHPAbQB/gGUAYABaQHiAYwBdwFlAeABTgFLAUYBbhMAAQECEQESARcBPwFCAVIBbwFI
        AVoBxwHpATwBVAHqAf8BPQFVAekB/wE9AVUB6QH/ATwBVAHqAf8BSAFaAcgB6gE/AUIBUgFvAhEBEgEXAwABAQgAAxkBIwHjAeEB9AH/AeoB6AH5Af8B6AHlAfgB/wHoAeUB+AH/AegB5QH4Af8B6AHlAfgB/wFW
        AUgB3QH/AVQBRAHdAf8B6AHlAfgB/wHoAeUB+AH/AegB5QH4Af8B6AHlAfgB/wHqAegB+QH/AeMB4QH0Af8DGQEjBAADKQE6AnQBcAGsAt0BzAH/AuYB2gH/AvEB6wH/AvEB6wH/AaIBeAFqAf8B8AHHAbYB/wHw
        AccBtgH/Ae8BwgGwAf8B2AGRAXUB/wHcAc0BugH/AnYBcgGsAykBOgQAA00BawNoAX0DbgGVA28BvQO2Ab8DlAG+AzwBkAFOAUwBSgGTAXcBcwFvAdEBmQGUAY8B4wGhAYkBbQH6AWwBZwFiAcEBPwE+ATsBVwEX
        AhYBHRAAAwoBDQE/AUEBUQFsAUoBWgG5Ad4BNQFPAecB/wE7AVMB5wH/AU4BWwG2AdABTgFbAbYB0AE7AVQB5wH/ATUBTwHnAf8BSgFaAbkB3gE/AUEBUQFtAwoBDQgAAxkBIwGGAjcB/wGxAXgBdQH/AZ4BiAHI
        Af8BsgGvAfsB/wHtAeQB5wH/AeoB5wH4Af8BZQFWAeAB/wFhAVIB4AH/AeoB5wH4Af8BpAGQAdAB/wGyAbAB+wH/AfAB5QHkAf8BswGBAX0B/wGCAjcB/wMZASMEAAMLAQ4DRAFsArYBrAHjAuAB0AH/AvAB6QH/
        AvEB6wH/Aa4BhQF2Af8B8AHFAbMB/wHuAbsBqAH/AegBqAGQAf8B3gHDAa8B/wK4Aa4B4wNEAWwDCwEOBAADEgEXAz8BXQN5AYoDSgGHA1kBewOwAb0DtQHCA7cB1QO+Ad4DngHVA10BigM1AU4DEgEYFAACDwEQ
        ARQBUQFXAX4BmwE/AVUB3gH5ATkBUQHfAfoBUwFeAaABuAEoASkBLwE4AScBKAEtATcBUwFfAZ8BtwE5AVEB3wH6AT4BVgHdAfgBUQFXAX8BmgIPARABFAgAAxcBIAGgAWABYQH/AawBnQHdAf8B3wHdAfwB/wHn
        AdMBzQH/AbQBgwGBAf8B7QHsAfoB/wGDAXcB5gH/AYEBdAHmAf8B7QHsAfoB/wG3AYUBgQH/AbMBnAHJAf8BugG4Af4B/wHzAe4B8wH/Aa8BdgFwAf8DFwEgCAADHgEoA0sBeAK3AawB4wLnAdsB/wLxAesB/wHT
        AakBmgH/Ae8BxgG1Af8B7wHOAb8B/wHmAdsBzAH/ArcBrAHjA0sBeAMeASgIAAMaASEDUAFzA3QBfwNlAX8DTgGTA2MBtAN+AbcDrQHdA4EBxwNtAc4DRQFnHAADAwEEASUBJgErATQBVAFdAZQBrgFVAV8BoAG6
        ASwBLQE0AT4DBAEGAwQBBgErASwBMwE9AVQBYAGgAbkBVAFeAZYBrwElASYBKwE0AwMBBAgAAw8BFQGNAX4B3wH/AcgByQL/AdEBqwGiAf8BkQFJAUgB/wGIAkAB/wHoAeUB+AH/AVkBSQHdAf8BVQFGAd0B/wHo
        AeUB+AH/AZABRwFIAf8BlQFJAUMB/wGVAXABpQH/AZQBjQHyAf8B6gHmAfYB/wMPARUMAAMeASgDQwFpAnUBcQGqArsBsgHfAuUB3gH4AuUB3gH4ArsBsgHfAnUBcQGqA0MBaQMeASgMAAMNARADJwEzAzsBTQNx
        AX4DeAGJA3QBjQNxAY8DfAHSA1EBcwM5AVIDGwEjIAADAwEEAhcBGAEeARoBGwEdASMDBAEFCAADBAEFAhoBHAEiAhcBGAEeAwMBBAwAAwQBBgMNBBIBGAMSARgDEgEYAxIBGAMSARgDEgEYAxIBGAMSARgDEgEY
        AxIBGAMSARgDEgEYAw0BEgMEAQYQAAMKAQ0DJwQ3AVMDPgFiAz4BYgM3AVMDJwE3AwoBDRgAAyoBOANHAWgDSAFcA2YBfgNEAWEDSgFuAykBN+QAAwwBDwMQARQDEgEXA0sBbwMXAR0DFAEZAwsBDmwAATcBPAE2
        AU8DBgEIBAABWwFwAVQBvgFYAXcBUAHmBAADDwEUAUABRgE+AWcDAQECHAABQAE5ATYBTwMGAQgEAAGSAWIBVgG+AasBYQFTAeYEAAEQAg8BFAFQAUIBPwFnAwEBAhwAAx4BJwMDAQQEAANBAV8DSwFzBAADCAEK
        AyYBMwMAAQFYAAFQAVsBTQF8AXcBowFqAfkBVAFhAVABhgE/AUUBPQFcAW4BkgFiAfkBYgGCAVoB/wFFAUwBQwFuAVIBXgFOAZQBVQF4AUwB/QE/AUQBPQFkGAABZQFUAU4BfAHKAYcBbgH5AW0BWAFRAYYBSwFB
        AT4BXAHDAXkBZgH5Ab8BbgFcAf8BVwFIAUQBbgFzAVUBTgGUAbgBXwFOAf0BTgFAAT4BZBgAAy8BPgNZAXwDMwFDAyQBLgNWAXwDVAF/AykBNwM1AUoDTwF+AyUBMgwAAwIBAwMHBAkBDAMJAQwDCQEMAwkBDAMJ
        AQwDCQEMAwkBDAMJAQwDCQEMAwkBDAMJAQwDCQEMAwcBCQMCAQMMAAE+AUQBPQFaAYEBqgF0Af4BhQGuAXgB/gGIAa8BeQH/AY4BtQGCAf8BiwGvAX0B/wF6AaIBbQH/AXUBmQFnAf8BZwGMAVwB/wFBAUcBPwFl
        GAABSgFBAT0BWgHSAY0BeAH+AdQBkQF7Af4B1QGUAX0B/wHXAZwBhgH/AdUBlQGCAf8BzwGHAXAB/wHJAX4BawH/AcMBcwFfAf8BUAFDAT8BZRgAAyMBLQNdAX8DXgF/A18BfwNhAX8DXwF/A1sBfwNZAX8DVQF/
        AyUBMgwAAwsBDwMeASoDJgE3AyYBNwMmATcDJgE3AyYBNwMmATcDJgE3AyYBNwMmATcDJgE3AyYBNwMmATcDHgEqAwsBDwQAAUYBTgFEAWgBRAFLAUIBZAFtAYUBZgG8AZgBvQGKAf8BqwHMAaAB/wGlAccBmAH/
        AaQBxAGYAf8BoAHAAZIB/wGXAbgBiwH/AYYBrAF4Af8BewGjAW4B/wFnAYEBXQHIAT4BQwE8AV0BQAFGAT4BZAgAAVUBSQFFAWgBUgFHAUIBZAGaAXUBaAG8AdsBowGNAf8B4wG2AaMB/wHhAbABnAH/Ad8BrgGc
        Af8B3QGnAZUB/wHaAaIBjgH/AdMBkgF7Af8BzwGIAXEB/wGgAW8BYAHIAUoBPwE9AV0BTwFCAT4BZAgAAygBNAMnATIDRwFeA2MBfwNoAX8DZgF/A2YBfwNkAX8DYwF/A14BfwNbAX8DRwFkAyMBLgMlATIEAAMV
        AR04/wMVAR0DBAEGAXYBnQFsAeUBhgGxAXcB/wGlAcgBlQH/AbEB0QGkAf8BqgHJAZ4B/wGVAboBiAH9AX8BpAF0AeoBfQGiAXEB5wGFAasBdgH+AYEBpwFxAf8BiwGtAX4B/wGCAaYBcwH/AW8BmAFgAf8BXwGE
        AVUB9QMEAQYDBAEGAbwBhQFuAeUB1QGUAXsB/wHhAa4BmQH/AeUBuAGmAf8B4QGxAaAB/wHZAaEBjAH9AcIBjAF4AeoBwAGKAXYB5wHSAY4BegH+AdEBjQF2Af8B1AGXAYIB/wHQAYwBdwH/AckBeQFkAf8BuQFr
        AVgB9QMEAQYDAgEDA1QBcgNfAX8DZgF/A2kBfwNnAX8DYQF+A1gBdQNWAXMDXgF/A10BfwNgAX8DXQF/A1cBfwNQAXoDAgEDAxkBIzj/AxkBIwQAATcBPAE2AU0BngHCAY8B/QGxAdIBpgH/AaIBxAGXAf8BiAGt
        AXoB/AExATQBMAFDCAABOgE/ATkBUgF5AaMBbQH3AYcBrQF6Af8BjwGxAYMB/wFwAZIBZQH8ATEBNAEwAUYIAAE/ATkBNwFNAd0BqAGTAf0B5gG8AakB/wHfAa8BmwH/AdEBkQF+AfwBNwEyATABQwgAAUMBPAE5
        AVIByQGJAW4B9wHTAZMBfQH/AdYBmwGHAf8BxQF7AWcB/AE4ATIBMQFGCAADHgEmA2MBfgNpAX8DZgF/A14BfgMaASEIAAMgASkDWQF7A18BfwNhAX8DWAF+AxsBIwQAAxkBIxT/A+QB/wNzAf8DeQH/A/YV/wMZ
        ASMEAAE5AT0BNwFNAZgBwAGLAf8BrwHPAaQB/wGFAawBegH+AUEBRwE/AWIQAAFLAVQBSAFwAX4BpgFvAf8BkQGxAYMB/wFxAZABaAH+AS4BMQEuAUEIAAFAAToBNwFNAd0BpQGOAf8B5QG6AaYB/wHSAZMBfQH+
        AU8BQwFAAWIQAAFcAU4BSQFwAdEBjAF0Af8B1wGbAYcB/wHFAXwBagH+ATUBLwEuAUEIAAMeASYDYwF/A2kBfwNfAX8DJQExEAADKwE4A1wBfwNhAX8DWAF/AxkBIAQAAxkBIxT/A/YB/wPHAf8Dyhn/AxkBIwGB
        AaYBdwHpAZcBwAGLAf8BrQHOAZwB/wGsAc0BoAH/AW4BkQFhAe4UAAETARQBEwEZAXoBowFtAfsBkQGzAYUB/wF3AaUBaQH/AW8BmAFhAf8BXwGAAVYB6QHDAY8BegHpAd0BpgGOAf8B5QGzAaAB/wHkAbYBowH/
        AbwBeAFlAe4UAAIUARMBGQHMAYkBcAH7AdcBnAGIAf8BzwGHAW4B/wHJAXoBZQH/AbABagFYAekDWAF0A2MBfwNnAX8DaAF/A1MBdxQAAwkBDANbAX0DYQF/A1sBfwNYAX8DTQF0AxkBIxT/A9oB/wOFAf8DlBn/
        AxkBIwFtAYABZgGrAYwBqwGDAeMBmQHCAY0B/wGqAcwBnAH/AWkBjgFeAfMUAAEeASABHgEoAXwBqwFvAf0BkQGzAYYB/wF4AaQBawH/AWsBjwFeAeUBWgFrAVQBqwGQAXQBaQGrAcIBlwGFAeMB3gGpAZEB/wHj
        AbQBoAH/Ab0BdAFgAfMUAAEhAR8BHgEoAdEBjgFzAf0B1wGeAYoB/wHPAYcBbwH/AbYBdgFjAeUBhQFfAVYBqwNCAVUDWAFxA2QBfwNnAX8DUwF5FAADEAEUA10BfgNhAX8DWwF/A1ABcgM8AVUDGQEjFP8D+gH/
        A5AB/wNwAf8DqQH/A/QR/wMZASMEAAERARIBEQEWAYsBsgF8Af4BuwHcAbAB/wGBAaYBdAH/AUUBTAFCAXAQAAFUAWABUQGAAYgBrwF5Af8BkgG1AYcB/wF5AaUBbAH9AwEBAggAARICEQEWAdYBlgGAAf4B6wHG
        AbMB/wHRAY4BdwH/AVgBRwFDAXAQAAFqAVgBUgGAAdUBlAF9Af8B2AGfAYsB/wHNAYgBbwH9AwEBAggAAwkBCwNgAX8DbAF/A10BfwMpATgQAAMyAUADXwF/A2IBfwNbAX4DAAEBBAADGQEjGP8D+wH/A7kB/wNu
        Af8DfRH/AxkBIwMEAQYBZQF1AV8BngGXAcEBigH+AbcB1wGtAf8BpgHIAZwB/wFzAZwBaAH9AVMBYAFOAZkDFgEdAxMBGQFkAXgBXQGtAYcBrgF2AfsBngG8AZMB/wGZAboBjwH/AX0BpQFtAf4BWAFlAVQBngQA
        AwQBBgGDAWoBYAGeAdwBpQGNAf4B6QHCAbAB/wHhAbEBnwH/AckBhQFtAf0BdgFXAVABmQEXAhYBHQEUAhMBGQGMAWoBXwGtAdEBkgF6AfsB2wGnAZUB/wHbAaUBkgH/Ac8BhgFwAf4BfAFcAVUBngQAAwIBAwM9
        AU8DYwF/A2sBfwNnAX8DWgF+AzYBTAMLAQ4DCQEMA0ABVgNdAX0DZAF/A2MBfwNbAX8DOQFPBAADGQEjEP8DywH/A7kB/wPIAf8DsQH/A3cB/wNXEf8DGQEjAwsBDgGFAasBeAHuAZQBvQGIAf8BpwHKAZkB/wG+
        AdoBsQH/AacBxwGcAf8BiAGvAXwB/wF3AaEBaAH9AXgBoQFpAfwBjAGzAX0B/wGUAbQBhgH/AZkBugGMAf8BhwGxAXkB/wF7AaUBbAH/AWoBkQFdAfsEAAMLAQ4ByAGSAXwB7gHbAaMBjAH/AeMBsQGeAf8B6wHG
        AbUB/wHhAbABngH/AdUBlwGBAf8BywGFAW0B/QHMAYQBbgH8AdcBmAGCAf8B1wGcAYoB/wHbAaIBjwH/AdUBlQF9Af8BzwGGAW8B/wHDAXMBXwH7BAADBQEHA1sBdwNjAX8DZwF/A2wBfwNmAX8DXwF/A1oBfgNa
        AX4DYAF/A2EBfwNjAX8DXwF/A1sBfwNVAX0EAAMZASMQ/wPoAf8DpQH/A4wB/wOFAf8DlQH/A9UR/wMZASMEAAEpASsBKQE3AS0BMAEsAjwBQQE7AVIBmgG+AYsB+gG4AdgBrgH/AbYB1QGrAf8BtgHVAaoB/wGu
        Ac8BowH/AaEBxgGVAf8BmAG8AY0B/wGJAbMBfAH+AU4BVwFLAXQBLQEwASwBPgEqASwBKQE6CAABLQEqASkBNwExAS4BLQE8AUQBPgE7AVIB2QGkAY8B+gHpAcIBsQH/AegBwAGuAf8B6AG+Aa0B/wHlAbgBpgH/
        AeEBrwGZAf8B2wGmAZEB/wHWAZcBgAH+AWABUQFLAXQBMwEuAS0BPgEvASsBKQE6CAADFQEbAxgBHgMhASkDYwF9A2sBfwNqAX8DagF/A2kBfwNmAX8DZAF/A2ABfwMtAToDGAEfAxYBHQQAAxgBIDj/AxgBIAwA
        AT0BQgE8AVQBjQG4AX4B/wGYAcABjAH9AZ4BwwGQAfwBrAHOAZwB/wGmAcwBlwH/AYUBrwF4Af4BhQGtAXgB/gGBAaYBcwH/ATkBPQE3AVAYAAFFAT8BPAFUAdkBnAGCAf8B2wGmAY8B/QHbAakBkwH8AeUBtAGg
        Af8B4wGwAZsB/wHUAZMBfAH+AdMBkQF7Af4B0AGNAXcB/wFBAToBOAFQGAADIQEqA2EBfwNjAX4DZAF+A2cBfwNmAX8DXwF/A14BfwNdAX8DHwEoDAADEAEVOP8DEAEVDAABMAEzAS8BQQF3AZcBcAHQATcBOwE1
        AUsDEQEWAYcBqgF4AfABigGzAXoB/wEjASQBIgEuAUwBVQFJAXABeAGYAW4B5QEnASkBJwE1GAABNQExAS8BQQGuAYQBcQHQAT4BOAE2AUsBEgIRARYByQGRAXwB8AHXAZgBfgH/ASYCIwEuAVwBTwFKAXABugGD
        AW8B5QErASgBJwE1GAADGQEgA08BaAMdASUDCQELA1oBeANgAX8DEgEXAywBOANUAXIDFAEaDAADBAEGAw4EEgEYAxIBGAMSARgDEgEYAxIBGAMSARgDEgEYAxIBGAMSARgDEgEYAxIBGAMSARgDDgESAwQBBhwA
        AXABigFoAb8BfAGhAXIB5jgAAZ4BeQFrAr8BiQF1AeY4AANIAV8DVgFzXAABQgFNAT4HAAE+AwABKAMAAUADAAFAAwABAQEAAQEGAAECFgAD/wEABP8EAAL/AcABBwQAAfABDwGAAQMEAAHwAQMBAAEBBAAB8AED
        AQABAQQAAfsBwwEAAQEEAAH/AeMBAAEBBAAB/wHjAQABAQQAAcAB4wEAAQEEAAHAAeMBAAEBBAABwQHDAQABAQQAAcABAwEAAQEEAAHAAQcBAAEBBAABwAEPAQABAQQAAv8BgAEDBAAC/wHAAQcEAAr/AfwBAAH8
        AQAB/AEAAfABnwH8AQAB/AEAAfwBAAHgAQcB/AEAAfwBAAH8AQABgAEDAfwBAAH8AQAB/CkAAYAHAAHAAQMBAAE/AQABPwEAAT8BwAEHAQABPwEAAT8BAAE/AeABfwEAAT8BAAE/AQABPwH4Af8BAAE/AQABPwEA
        AT8K/wGAAQEB/gEDAv8CAAGAAQEB/gEDAv8CAAHgAQcB+AEAAeEBhwIAAcABAwHwAQABwAEDAgABgAEBAfABIAHAAQMCAAGAAQEBwAFgAcABAwIAAYABAQHAAQABwAEDAgABgAEBAgAB4AEHAgABgAEBAgAB4AEH
        AgABgAEBAQABAwHAAQMCAAGAAQEBAAEDAcABAwIAAYABAQEAAQcBwAEDAgABwAEDAQABHwHAAQMCAAHgAQcBAAEfAeEBhwIAAfABDwHAAX8G/wHAAX8C/wHyAUcB8gFHAfIBRwL/AeABBwHgAQcB4AEHAgAB4AEH
        AeABBwHgAQcCAAGAAQEBgAEBAYABAQoABoECAAGDAcEBgwHBAYMBwQIAAQcBwAEHAcABBwHAAgABBwHAAQcBwAEHAcACAAGDAcEBgwHBAYMBwQMAAQEBAAEBAQABAQMAAQEBAAEBAQABAQIAAYABAQGAAQEBgAEB
        AgAB4AEHAeABBwHgAQcCAAHgAQcB4AEHAeABBwIAAf4BfwH+AX8B/gF/Av8L')))
    $img_MainForm.ImageStream           = $img_MainForm_BinaryFomatter.Deserialize($img_MainForm_MemoryStream)
    $img_MainForm_BinaryFomatter        = $null
    $img_MainForm_MemoryStream          = $null
#endregion
#region TAB 1 - Introduction / Select Location / Import
    $lbl_t1_Welcome                     = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t1_Welcome.Anchor              = 'Top, Left, Right'
    $lbl_t1_Welcome.Location            = '  9,   9'
    $lbl_t1_Welcome.Size                = '488,  20'
    $lbl_t1_Welcome.Text                = ($script:ToolLangINI['page1']['Title'])
    $lbl_t1_Welcome.TextAlign           = 'BottomLeft'
    $tab_Page1.Controls.Add($lbl_t1_Welcome)

    $lbl_t1_Introduction                = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t1_Introduction.Anchor         = 'Top, Left, Right'
    $lbl_t1_Introduction.Location       = '  9,  42'
    $lbl_t1_Introduction.Size           = '744, 250'
    $lbl_t1_Introduction.TextAlign      = 'TopLeft'
    $lbl_t1_Introduction.Text           = ($script:ToolLangINI['page1']['Message'])
    $tab_Page1.Controls.Add($lbl_t1_Introduction)

    $btn_t1_Search                      = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t1_Search.Anchor               = 'Bottom, Left'
    $btn_t1_Search.Location             = '281, 313'
    $btn_t1_Search.Size                 = '200, 35'
    $btn_t1_Search.Text                 = ($script:ToolLangINI['page1']['SetLocation'])
    $btn_t1_Search.Add_Click($btn_t1_Search_Click)
    $tab_Page1.Controls.Add($btn_t1_Search)

    $lbl_t1_SettingsFile                = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t1_SettingsFile.Anchor         = 'Bottom, Left'
    $lbl_t1_SettingsFile.Location       = '  9, 375'
    $lbl_t1_SettingsFile.Size           = '266, 27'
    $lbl_t1_SettingsFile.Text           = ($script:ToolLangINI['page1']['BaseSettings'])
    $lbl_t1_SettingsFile.TextAlign      = 'MiddleRight'
    $tab_Page1.Controls.Add($lbl_t1_SettingsFile)

    $cmo_t1_SettingsFile                = (New-Object -TypeName 'System.Windows.Forms.ComboBox')
    $cmo_t1_SettingsFile.Anchor         = 'Bottom, Left'
    $cmo_t1_SettingsFile.Location       = '281, 375'
    $cmo_t1_SettingsFile.Size           = '200,  27'
    $cmo_t1_SettingsFile.ItemHeight     = ' 21'
    $cmo_t1_SettingsFile.Enabled        = $False
    $cmo_t1_SettingsFile.Name           = 'Settings'
    $cmo_t1_SettingsFile.DropDownStyle  = 'DropDownList'
    $cmo_t1_SettingsFile.DrawMode       = 'OwnerDrawFixed'
    $cmo_t1_SettingsFile.DropDownHeight = (($cmo_t1_SettingsFile.ItemHeight * 10) + 2)
    $cmo_t1_SettingsFile.Add_DrawItem(            { ComboIcons_OnDrawItem       -Control $this })
    $cmo_t1_SettingsFile.Add_SelectedIndexChanged({ cmo_t1_SelectedIndexChanged -Control $this })
    $tab_Page1.Controls.Add($cmo_t1_SettingsFile)

    $lbl_t1_MissingFile                 = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t1_MissingFile.Anchor          = 'Bottom, Left'
    $lbl_t1_MissingFile.Location        = '487, 375'
    $lbl_t1_MissingFile.Size            = '266, 27'
    $lbl_t1_MissingFile.Text            = "'default-settings.ini' $($script:ToolLangINI['page1']['BaseMissing'])"
    $lbl_t1_MissingFile.TextAlign       = 'MiddleLeft'
    $lbl_t1_MissingFile.Visible         = $False
    $tab_Page1.Controls.Add($lbl_t1_MissingFile)

    $lbl_t1_Language                    = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t1_Language.Anchor             = 'Bottom, Left'
    $lbl_t1_Language.Location           = '  9, 417'
    $lbl_t1_Language.Size               = '266,  27'
    $lbl_t1_Language.Text               = ($script:ToolLangINI['page1']['Language'])
    $lbl_t1_Language.TextAlign          = 'MiddleRight'
    $tab_Page1.Controls.Add($lbl_t1_Language)

    $cmo_t1_Language                    = (New-Object -TypeName 'System.Windows.Forms.ComboBox')
    $cmo_t1_Language.Anchor             = 'Bottom, Left'
    $cmo_t1_Language.Location           = '281, 417'
    $cmo_t1_Language.Size               = '200, 27'
    $cmo_t1_Language.ItemHeight         = ' 21'
    $cmo_t1_Language.Enabled            = $False
    $cmo_t1_Language.Name               = 'Language'
    $cmo_t1_Language.DropDownStyle      = 'DropDownList'
    $cmo_t1_Language.DrawMode           = 'OwnerDrawFixed'
    $cmo_t1_Language.DropDownHeight     = (($cmo_t1_Language.ItemHeight * 10) + 2)
    $cmo_t1_Language.Add_DrawItem(            { ComboIcons_OnDrawItem       -Control $this })
    $cmo_t1_Language.Add_SelectedIndexChanged({ cmo_t1_SelectedIndexChanged -Control $this })
    $tab_Page1.Controls.Add($cmo_t1_Language)

    $lnk_t1_Language                    = (New-Object -TypeName 'System.Windows.Forms.LinkLabel')
    $lnk_t1_Language.Anchor             = 'Bottom, Left'
    $lnk_t1_Language.Location           = '487, 417'
    $lnk_t1_Language.Size               = '266,  27'
    $lnk_t1_Language.Text               = ($script:ToolLangINI['page1']['Translation'])
    $lnk_t1_Language.TextAlign          = 'MiddleLeft'
    $lnk_t1_Language.Enabled            = $False
    $lnk_t1_Language.Add_Click($lnk_t1_Language_Click)
    $tab_Page1.Controls.Add($lnk_t1_Language)

    $btn_t1_Import                      = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t1_Import.Anchor               = 'Bottom, Left'
    $btn_t1_Import.Location             = '281, 471'
    $btn_t1_Import.Size                 = '200,  35'
    $btn_t1_Import.Text                 = ($script:ToolLangINI['page1']['ImportSettings'])
    $btn_t1_Import.Enabled              = $False
    $btn_t1_Import.Add_Click($btn_t1_Import_Click)
    $tab_Page1.Controls.Add($btn_t1_Import)

    $btn_t1_RestoreINI                  = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t1_RestoreINI.Anchor           = 'Bottom, Left'
    $btn_t1_RestoreINI.Location         = '316, 635'
    $btn_t1_RestoreINI.Size             = '162,  25'
    $btn_t1_RestoreINI.Text             = ($script:ToolLangINI['restore']['Button'])
    $btn_t1_RestoreINI.Add_Click($btn_t1_RestoreINI_Click)
    $MainFORM.Controls.Add($btn_t1_RestoreINI)    # On main form (not tab 1)

    $pic_t1_RestoreHelp                 = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_t1_RestoreHelp.Anchor          = 'Bottom, Left'
    $pic_t1_RestoreHelp.Location        = '484, 640'
    $pic_t1_RestoreHelp.Size            = ' 16,  16'
    $pic_t1_RestoreHelp.Cursor          = 'Hand'
    $pic_t1_RestoreHelp.BackColor       = 'Control'
    $pic_t1_RestoreHelp.Add_Click($pic_t1_RestoreHelp_Click)
    $MainFORM.Controls.Add($pic_t1_RestoreHelp)

    $cmo_t1_ToolLang                    = (New-Object -TypeName 'System.Windows.Forms.ComboBox')
    $cmo_t1_ToolLang.Anchor             = 'Top, Right'
    $cmo_t1_ToolLang.Location           = '711,   3'
    $cmo_t1_ToolLang.Size               = ' 48,  27'
    $cmo_t1_ToolLang.ItemHeight         = ' 21'
    $cmo_t1_ToolLang.DropDownWidth      = '200'
    $cmo_t1_ToolLang.Name               = 'ToolLang'
    $cmo_t1_ToolLang.DropDownStyle      = 'DropDownList'
    $cmo_t1_ToolLang.DrawMode           = 'OwnerDrawFixed'
    $cmo_t1_ToolLang.DropDownHeight     = (($cmo_t1_ToolLang.ItemHeight * 10) + 2)
    $cmo_t1_ToolLang.Add_DrawItem(            { ComboIcons_OnDrawItem -Control $this                                                                                             })
    $cmo_t1_ToolLang.Add_DropDown(            { $cmo_t1_ToolLang.Location = "$($cmo_t1_ToolLang.Left - 152), 3"; $cmo_t1_ToolLang.Size = '200, 27'                               })
    $cmo_t1_ToolLang.Add_DropDownClosed(      { $cmo_t1_ToolLang.Location = "$($cmo_t1_ToolLang.Left + 152), 3"; $cmo_t1_ToolLang.Size = ' 48, 27'; [void]$btn_t1_Search.Focus() })
    $cmo_t1_ToolLang.Add_SelectedIndexChanged({ cmo_t1_ToolLang_SelectedIndexChanged;                                                               [void]$btn_t1_Search.Focus() })
    $tab_Page1.Controls.Add($cmo_t1_ToolLang)

    $lbl_t1_ToolLang                    = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t1_ToolLang.Anchor             = 'Top, Right'
    $lbl_t1_ToolLang.Location           = '559,   3'
    $lbl_t1_ToolLang.Size               = '146,  27'
    $lbl_t1_ToolLang.Text               = ($script:ToolLangINI['page1']['ToolLanguage'])
    $lbl_t1_ToolLang.TextAlign          = 'MiddleRight'
    $lbl_t1_ToolLang.SendToBack()
    $tab_Page1.Controls.Add($lbl_t1_ToolLang)
#endregion
#region TAB 2 - Select QA Checkes To Include
    $lbl_t2_CheckSelection              = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t2_CheckSelection.Anchor       = 'Top, Left, Right'
    $lbl_t2_CheckSelection.Location     = '  9,   9'
    $lbl_t2_CheckSelection.Size         = '744,  20'
    $lbl_t2_CheckSelection.Text         = ($script:ToolLangINI['page2']['Title'])
    $lbl_t2_CheckSelection.TextAlign    = 'BottomLeft'
    $tab_Page2.Controls.Add($lbl_t2_CheckSelection)

    $lst_t2_SelectChecks                = (New-Object -TypeName 'System.Windows.Forms.ListView')
    $lst_t2_SelectChecks_CH_Code        = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader')
    $lst_t2_SelectChecks_CH_Name        = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader')
    $lst_t2_SelectChecks_CH_Desc        = (New-Object -TypeName 'System.Windows.Forms.ColumnHeader')
    $lst_t2_SelectChecks.Anchor         = 'Top, Bottom, Left, Right'
    $lst_t2_SelectChecks.CheckBoxes     = $True
    $lst_t2_SelectChecks.HeaderStyle    = 'Nonclickable'
    $lst_t2_SelectChecks.FullRowSelect  = $True
    $lst_t2_SelectChecks.GridLines      = $False
    $lst_t2_SelectChecks.LabelWrap      = $False
    $lst_t2_SelectChecks.MultiSelect    = $False
    $lst_t2_SelectChecks.Location       = '  9,  35'
    $lst_t2_SelectChecks.Size           = '466, 492'
    $lst_t2_SelectChecks.View           = 'Details'
    $lst_t2_SelectChecks.SmallImageList = $img_MainForm
    $lst_t2_SelectChecks.Sorting        = 'Ascending'
    $lst_t2_SelectChecks_CH_Code.Text   = $($script:ToolLangINI['page2']['Column_Check'])    # acc01
    $lst_t2_SelectChecks_CH_Name.Text   = $($script:ToolLangINI['page2']['Column_Value'])    # Local User Accounts
    $lst_t2_SelectChecks_CH_Desc.Text   = ''                                                 # Description
    $lst_t2_SelectChecks_CH_Code.Width  = 100
    $lst_t2_SelectChecks_CH_Name.Width  = 100 - ([System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth + 4)
    $lst_t2_SelectChecks_CH_Desc.Width  =   0
    [void]$lst_t2_SelectChecks.Columns.Add($lst_t2_SelectChecks_CH_Code)
    [void]$lst_t2_SelectChecks.Columns.Add($lst_t2_SelectChecks_CH_Name)
    [void]$lst_t2_SelectChecks.Columns.Add($lst_t2_SelectChecks_CH_Desc)
    $lst_t2_SelectChecks.Add_Enter($lst_t2_SelectChecks_Enter)
    $lst_t2_SelectChecks.Add_ItemChecked($lst_t2_SelectChecks_ItemChecked)
    $lst_t2_SelectChecks.Add_SelectedIndexChanged($lst_t2_SelectChecks_SelectedIndexChanged)
    $tab_Page2.Controls.Add($lst_t2_SelectChecks)

    $lnk_t2_Description                 = (New-Object -TypeName 'System.Windows.Forms.LinkLabel')
    $lnk_t2_Description.Anchor          = 'Top, Bottom, Right'
    $lnk_t2_Description.BackColor       = 'Window'
    $lnk_t2_Description.Location        = '475,  36'
    $lnk_t2_Description.Size            = '277, 430'
    $lnk_t2_Description.Padding         = '3, 3, 3, 3'    # Internal padding
    $lnk_t2_Description.Text            = ''              # Description of the selected check - set via code
    $lnk_t2_Description.TextAlign       = 'TopLeft'
    $lnk_t2_Description.LinkArea        = (New-Object -TypeName 'System.Windows.Forms.LinkArea'(0, 0))
    $lnk_t2_Description.Add_LinkClicked($lnk_t2_Description_LinkClicked)
    $tab_Page2.Controls.Add($lnk_t2_Description)

    $pic_t2_SearchHelp                  = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_t2_SearchHelp.Anchor           = 'Bottom, Right'
    $pic_t2_SearchHelp.Location         = '725, 482' #'730, 458'
    $pic_t2_SearchHelp.Size             = ' 16,  16'
    $pic_t2_SearchHelp.Cursor           = 'Hand'
    $pic_t2_SearchHelp.BackColor        = 'Window'
    $pic_t2_SearchHelp.Visible          = $false
    $pic_t2_SearchHelp.Add_Click($pic_t2_SearchHelp_Click)
    $tab_Page2.Controls.Add($pic_t2_SearchHelp)

    $pic_t2_SearchClear                 = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_t2_SearchClear.Anchor          = 'Bottom, Right'
    $pic_t2_SearchClear.Location        = '725, 482'
    $pic_t2_SearchClear.Size            = ' 16,  16'
    $pic_t2_SearchClear.Cursor          = 'Hand'
    $pic_t2_SearchClear.BackColor       = 'Window'
    $pic_t2_SearchClear.Visible         = $False
    $pic_t2_SearchClear.Add_Click({ $txt_t2_Search.Text = '' })
    $tab_Page2.Controls.Add($pic_t2_SearchClear)

    $txt_t2_Search                      = (New-Object -TypeName 'System.Windows.Forms.TextBox')
    $txt_t2_Search.Anchor               = 'Bottom, Right'
    $txt_t2_Search.Location             = '486, 482'
    $txt_t2_Search.Size                 = '254,  22'
    $txt_t2_Search.BorderStyle          = 'None'
    $txt_t2_Search.Enabled              = $False
    $txt_t2_Search.Add_TextChanged($txt_t2_Search_TextChanged)
    $tab_page2.Controls.Add($txt_t2_Search)

    $txt_t2_Search_Outer                = (New-Object -TypeName 'System.Windows.Forms.TextBox')
    $txt_t2_Search_Outer.Anchor         = 'Bottom, Right'
    $txt_t2_Search_Outer.Location       = '480, 477'
    $txt_t2_Search_Outer.Size           = '266,  27'
    $txt_t2_Search_Outer.Multiline      = $True
    $txt_t2_Search_Outer.Enabled        = $False
    $txt_t2_Search_Outer.Add_Enter({ $txt_t2_Search.Focus.Invoke() })
    $tab_page2.Controls.Add($txt_t2_Search_Outer)

    $chk_t2_Search                      = (New-Object -TypeName 'System.Windows.Forms.CheckBox')
    $chk_t2_Search.Anchor               = 'Bottom, Right'
    $chk_t2_Search.Location             = '483, 507'
    $chk_t2_Search.Size                 = '263,  17'
    $chk_t2_Search.Text                 = ($script:ToolLangINI['page2']['SearchCheck'])
    $chk_t2_Search.BackColor            = 'Window'
    $chk_t2_Search.Enabled              = $False
    $chk_t2_Search.Add_CheckedChanged($chk_t2_Search_CheckedChanged)
    $tab_page2.Controls.Add($chk_t2_Search)

    $lbl_t2_SelectedCount               = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t2_SelectedCount.Anchor        = 'Bottom, Left'
    $lbl_t2_SelectedCount.Location      = '  9, 538'
    $lbl_t2_SelectedCount.Size          = '193,  28'
    $lbl_t2_SelectedCount.Text          = ($script:ToolLangINI['page2']['Selected'])
    $lbl_t2_SelectedCount.TextAlign     = 'MiddleLeft'
    $tab_Page2.Controls.Add($lbl_t2_SelectedCount)

    $lbl_t2_Select                      = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t2_Select.Anchor               = 'Bottom, Right'
    $lbl_t2_Select.Location             = '203, 538'
    $lbl_t2_Select.Size                 = '130,  28'
    $lbl_t2_Select.Text                 = ($script:ToolLangINI['page2']['Select'])
    $lbl_t2_Select.TextAlign            = 'MiddleRight'
    $tab_Page2.Controls.Add($lbl_t2_Select)

    $btn_t2_SelectAll                   = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t2_SelectAll.Anchor            = 'Bottom, Right'
    $btn_t2_SelectAll.Location          = '340, 538'
    $btn_t2_SelectAll.Size              = ' 38,  28'
    $btn_t2_SelectAll.Text              = ''
    $btn_t2_SelectAll.Enabled           = $False
    $btn_t2_SelectAll.Add_Click({ btn_t2_SelectButtons -SourceButton 'SelectAll' })
    $tab_Page2.Controls.Add($btn_t2_SelectAll)

    $btn_t2_SelectInv                   = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t2_SelectInv.Anchor            = 'Bottom, Right'
    $btn_t2_SelectInv.Location          = '382, 538'
    $btn_t2_SelectInv.Size              = ' 38,  28'
    $btn_t2_SelectInv.Text              = ''
    $btn_t2_SelectInv.Enabled           = $False
    $btn_t2_SelectInv.Add_Click({ btn_t2_SelectButtons -SourceButton 'SelectInv' })
    $tab_Page2.Controls.Add($btn_t2_SelectInv)

    $btn_t2_SelectNone                  = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t2_SelectNone.Anchor           = 'Bottom, Right'
    $btn_t2_SelectNone.Location         = '424, 538'
    $btn_t2_SelectNone.Size             = ' 38,  28'
    $btn_t2_SelectNone.Text             = ''
    $btn_t2_SelectNone.Enabled          = $False
    $btn_t2_SelectNone.Add_Click({ btn_t2_SelectButtons -SourceButton 'SelectNone' })
    $tab_Page2.Controls.Add($btn_t2_SelectNone)

    $pic_t2_SelectSepB                   = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_t2_SelectSepB.Anchor            = 'Bottom, Right'
    $pic_t2_SelectSepB.Location          = '474, 541'
    $pic_t2_SelectSepB.Size              = '  1,  22'
    $pic_t2_SelectSepB.BackColor         = [System.Drawing.SystemColors]::ButtonShadow
    $pic_t2_SelectSepB.BorderStyle       = 'None'
    $tab_Page2.Controls.Add($pic_t2_SelectSepB)

    $pic_t2_SelectSepW                   = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_t2_SelectSepW.Anchor            = 'Bottom, Right'
    $pic_t2_SelectSepW.Location          = '475, 541'
    $pic_t2_SelectSepW.Size              = '  2,  22'
    $pic_t2_SelectSepW.BackColor         = [System.Drawing.SystemColors]::ButtonHighlight
    $pic_t2_SelectSepW.BorderStyle       = 'None'
    $tab_Page2.Controls.Add($pic_t2_SelectSepW)

    $btn_t2_SelectReset                 = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t2_SelectReset.Anchor          = 'Bottom, Right'
    $btn_t2_SelectReset.Location        = '487, 538'
    $btn_t2_SelectReset.Size            = ' 38,  28'
    $btn_t2_SelectReset.Text            = ''
    $btn_t2_SelectReset.Enabled         = $False
    $btn_t2_SelectReset.Add_Click({ btn_t2_SelectButtons -SourceButton 'SelectReset' })
    $tab_Page2.Controls.Add($btn_t2_SelectReset)

    $btn_t2_SetValues                   = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t2_SetValues.Anchor            = 'Bottom, Right'
    $btn_t2_SetValues.Location          = '628, 538'
    $btn_t2_SetValues.Size              = '125,  28'
    $btn_t2_SetValues.Text              = ($script:ToolLangINI['page2']['SetValues'])
    $btn_t2_SetValues.Enabled           = $False
    $btn_t2_SetValues.Add_Click($btn_t2_SetValues_Click)
    $tab_Page2.Controls.Add($btn_t2_SetValues)
    $btn_t2_SetValues.BringToFront()

    $pic_t2_Background                  = (New-Object -TypeName 'System.Windows.Forms.PictureBox')
    $pic_t2_Background.Anchor           = 'Top, Bottom, Right'
    $pic_t2_Background.Location         = '474,  35'
    $pic_t2_Background.Size             = '279, 492'
    $pic_t2_Background.BackColor        = 'Window'
    $pic_t2_Background.BorderStyle      = 'FixedSingle'
    $pic_t2_Background.SendToBack()
    $tab_Page2.Controls.Add($pic_t2_Background)

    $lbl_t2_ChangesMade                 = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t2_ChangesMade.Anchor          = 'Bottom, Left, Right'
    $lbl_t2_ChangesMade.Location        = '102, 635'
    $lbl_t2_ChangesMade.Size            = '590,  25'
    $lbl_t2_ChangesMade.Text            = ($script:ToolLangINI['page2']['ChangeNote'])
    $lbl_t2_ChangesMade.TextAlign       = 'MiddleCenter'
    $lbl_t2_ChangesMade.Visible         = $False
    $MainFORM.Controls.Add($lbl_t2_ChangesMade)

#endregion
#region TAB 3 - Enter Values For Checks
    $lbl_t3_ScriptSelection             = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t3_ScriptSelection.Anchor      = 'Top, Left, Right'
    $lbl_t3_ScriptSelection.Location    = '  9,   9'
    $lbl_t3_ScriptSelection.Size        = '744,  20'
    $lbl_t3_ScriptSelection.Text        = ($script:ToolLangINI['page3']['Title'])
    $lbl_t3_ScriptSelection.TextAlign   = 'BottomLeft'
    $tab_Page3.Controls.Add($lbl_t3_ScriptSelection)

    $lbl_t3_NoChecks                    = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t3_NoChecks.Anchor             = 'Top, Bottom, Left, Right'
    $lbl_t3_NoChecks.Location           = '19, 218'
    $lbl_t3_NoChecks.Size               = '724, 50'
    $lbl_t3_NoChecks.Text               = ($script:ToolLangINI['page3']['SelectChecks'])
    $lbl_t3_NoChecks.TextAlign          = 'MiddleCenter'
    $lbl_t3_NoChecks.BackColor          = 'Window'
    $lbl_t3_NoChecks.Visible            = $True
    $lbl_t3_NoChecks.BringToFront()
    $tab_Page3.Controls.Add($lbl_t3_NoChecks)

    $tab_t3_Pages                       = (New-Object -TypeName 'System.Windows.Forms.TabControl')    # TabPages are generated automatically
    $tab_t3_Pages.Anchor                = 'Top, Bottom, Left, Right'
    $tab_t3_Pages.Location              = '  9,  35'
    $tab_t3_Pages.Size                  = '744, 492'
    $tab_t3_Pages.Padding               = ' 10,   6'
    $tab_t3_Pages.SelectedIndex         = 0
    $tab_t3_Pages.Add_SelectedIndexChanged($tab_t3_Pages_SelectedIndexChanged)
    $tab_Page3.Controls.Add($tab_t3_Pages)

    $lbl_t3_SectionTabs                 = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t3_SectionTabs.Anchor          = 'Bottom, Left'
    $lbl_t3_SectionTabs.Location        = '104, 538'
    $lbl_t3_SectionTabs.Size            = '190,  28'
    $lbl_t3_SectionTabs.Text            = ($script:ToolLangINI['page3']['SectionTabs'])
    $lbl_t3_SectionTabs.TextAlign       = 'MiddleRight'
    $tab_Page3.Controls.Add($lbl_t3_SectionTabs)

    $btn_t3_PrevTab                     = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t3_PrevTab.Anchor              = 'Bottom, Left'
    $btn_t3_PrevTab.Location            = '300, 538'
    $btn_t3_PrevTab.Size                = ' 75,  28'
    $btn_t3_PrevTab.Text                = ($script:ToolLangINI['page3']['Prev'])
    $btn_t3_PrevTab.Add_Click($btn_t3_PrevTab_Click)
    $tab_Page3.Controls.Add($btn_t3_PrevTab)

    $btn_t3_NextTab                     = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t3_NextTab.Anchor              = 'Bottom, Left'
    $btn_t3_NextTab.Location            = '387, 538'
    $btn_t3_NextTab.Size                = ' 75,  28'
    $btn_t3_NextTab.Text                = ($script:ToolLangINI['page3']['Next'])
    $btn_t3_NextTab.Add_Click($btn_t3_NextTab_Click)
    $tab_Page3.Controls.Add($btn_t3_NextTab)

    $btn_t3_Complete                    = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t3_Complete.Anchor             = 'Bottom, Right'
    $btn_t3_Complete.Location           = '628, 538'
    $btn_t3_Complete.Size               = '125,  28'
    $btn_t3_Complete.Text               = ($script:ToolLangINI['page3']['Complete'])
    $btn_t3_Complete.Enabled            = $False
    $btn_t3_Complete.Add_Click($btn_t3_Complete_Click)
    $tab_Page3.Controls.Add($btn_t3_Complete)
#endregion
#region TAB 4 - Generate Settings And QA Script
    $lbl_t4_Complete                    = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t4_Complete.Anchor             = 'Top, Left, Right'
    $lbl_t4_Complete.Location           = '  9,   9'
    $lbl_t4_Complete.Size               = '744,  20'
    $lbl_t4_Complete.Text               = ($script:ToolLangINI['page4']['Title'])
    $lbl_t4_Complete.TextAlign          = 'BottomLeft'
    $tab_Page4.Controls.Add($lbl_t4_Complete)

    $lbl_t4_Complete_Info               = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t4_Complete_Info.Anchor        = 'Top, Left, Right'
    $lbl_t4_Complete_Info.Location      = '  9,  42'
    $lbl_t4_Complete_Info.Size          = '744, 250'
    $lbl_t4_Complete_Info.TextAlign     = 'TopLeft'
    $lbl_t4_Complete_Info.Text          = ($script:ToolLangINI['page4']['Message'])
    $tab_Page4.Controls.Add($lbl_t4_Complete_Info)

    $lbl_t4_ShortName                   = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t4_ShortName.Anchor            = 'Bottom, Left'
    $lbl_t4_ShortName.Location          = '  9, 325'
    $lbl_t4_ShortName.Size              = '266,  27'
    $lbl_t4_ShortName.TextAlign         = 'MiddleRight'
    $lbl_t4_ShortName.Text              = ($script:ToolLangINI['page4']['ScriptName'])
    $tab_Page4.Controls.Add($lbl_t4_ShortName)

    $lbl_t4_CodeEg                      = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t4_CodeEg.Anchor               = 'Bottom, Left'
    $lbl_t4_CodeEg.Location             = '487, 325'
    $lbl_t4_CodeEg.Size                 = '266,  27'
    $lbl_t4_CodeEg.TextAlign            = 'MiddleLeft'
    $lbl_t4_CodeEg.Text                 = ''
    $tab_Page4.Controls.Add($lbl_t4_CodeEg)

    $txt_t4_ShortCode                   = (New-Object -TypeName 'System.Windows.Forms.TextBox')
    $txt_t4_ShortCode.Anchor            = 'Bottom, Left'
    $txt_t4_ShortCode.Location          = '287, 330'    # + 6, +5
    $txt_t4_ShortCode.Size              = '188,  22'    # -12, -5
    $txt_t4_ShortCode.TextAlign         = 'Center'
    $txt_t4_ShortCode.BorderStyle       = 'None'
    $txt_t4_ShortCode.MaxLength         = '12'
    $txt_t4_ShortCode.Add_KeyPress({
        # Letter, numbers or separators only
        If ((-not [char]::IsLetterOrDigit($_.KeyChar)) -and (-not [char]::IsControl($_.KeyChar)) -and (-not [char]::IsSeparator($_.KeyChar)) -and ($_.KeyChar -ne [char]'-')) { $_.KeyChar = 0 }
    })
    $txt_t4_ShortCode.Add_TextChanged($txt_t4_ShortCode_TextChanged)
    $tab_Page4.Controls.Add($txt_t4_ShortCode)

    $txt_t4_SC_Outer                    = (New-Object -TypeName 'System.Windows.Forms.TextBox')
    $txt_t4_SC_Outer.Anchor             = 'Bottom, Left'
    $txt_t4_SC_Outer.Location           = '281, 325'
    $txt_t4_SC_Outer.Size               = '200,  27'
    $txt_t4_SC_Outer.Multiline          = $True
    $txt_t4_SC_Outer.TabStop            = $False
    $txt_t4_SC_Outer.Add_Enter({ $txt_t4_ShortCode.Focus.Invoke() })
    $tab_Page4.Controls.Add($txt_t4_SC_Outer)    # Border wrapper for ShortCode box to make it look bigger

    $lbl_t4_ReportTitle                 = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t4_ReportTitle.Anchor          = 'Bottom, Left'
    $lbl_t4_ReportTitle.Location        = '  9, 367'
    $lbl_t4_ReportTitle.Size            = '266,  27'
    $lbl_t4_ReportTitle.TextAlign       = 'MiddleRight'
    $lbl_t4_ReportTitle.Text            = ($script:ToolLangINI['page4']['ReportName'])
    $tab_Page4.Controls.Add($lbl_t4_ReportTitle)

    $lbl_t4_QAReport                    = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t4_QAReport.Anchor             = 'Bottom, Left'
    $lbl_t4_QAReport.Location           = '487, 367'
    $lbl_t4_QAReport.Size               = '266,  27'
    $lbl_t4_QAReport.TextAlign          = 'MiddleLeft'
    $lbl_t4_QAReport.Text               = ($script:ToolLangINI['page4']['QAReport'])
    $tab_Page4.Controls.Add($lbl_t4_QAReport)

    $txt_t4_ReportTitle                 = (New-Object -TypeName 'System.Windows.Forms.TextBox')
    $txt_t4_ReportTitle.Anchor          = 'Bottom, Left'
    $txt_t4_ReportTitle.Location        = '287, 372'    # + 6, +5
    $txt_t4_ReportTitle.Size            = '188,  22'    # -12, -5
    $txt_t4_ReportTitle.TextAlign       = 'Center'
    $txt_t4_ReportTitle.BorderStyle     = 'None'
    $txt_t4_ReportTitle.MaxLength       = '16'
    $tab_Page4.Controls.Add($txt_t4_ReportTitle)

    $txt_t4_RT_Outer                    = (New-Object -TypeName 'System.Windows.Forms.TextBox')
    $txt_t4_RT_Outer.Anchor             = 'Bottom, Left'
    $txt_t4_RT_Outer.Location           = '281, 367'
    $txt_t4_RT_Outer.Size               = '200,  27'
    $txt_t4_RT_Outer.Multiline          = $True
    $txt_t4_RT_Outer.TabStop            = $False
    $txt_t4_RT_Outer.Add_Enter({ $txt_t4_ReportTitle.Focus.Invoke() })
    $tab_Page4.Controls.Add($txt_t4_RT_Outer)    # Border wrapper for ReportTitle box to make it look bigger

    $btn_t4_Save                        = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t4_Save.Anchor                 = 'Bottom, Left'
    $btn_t4_Save.Location               = '281, 421'
    $btn_t4_Save.Size                   = '200,  35'
    $btn_t4_Save.Text                   = ($script:ToolLangINI['page4']['SaveSettings'])
    $btn_t4_Save.Enabled                = $False
    $btn_t4_Save.Add_Click($btn_t4_Save_Click)
    $tab_Page4.Controls.Add($btn_t4_Save)

    $btn_t4_Generate                    = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t4_Generate.Anchor             = 'Bottom, Left'
    $btn_t4_Generate.Location           = '281, 471'
    $btn_t4_Generate.Size               = '200,  35'
    $btn_t4_Generate.Text               = ($script:ToolLangINI['page4']['GenerateScript'])
    $btn_t4_Generate.Enabled            = $False
    $btn_t4_Generate.Add_Click($btn_t4_Generate_Click)
    $tab_Page4.Controls.Add($btn_t4_Generate)

    $chk_t4_GenerateMini                = (New-Object -TypeName 'System.Windows.Forms.CheckBox')
    $chk_t4_GenerateMini.Anchor         = 'Bottom, Left'
    $chk_t4_GenerateMini.Location       = '487, 471'
    $chk_t4_GenerateMini.Size           = '266,  36'    # One more than button height
    $chk_t4_GenerateMini.Text           = ($script:ToolLangINI['page4']['GenerateMini'])
    $chk_t4_GenerateMini.Checked        = $False
    $chk_t4_GenerateMini.Enabled        = $False
    $chk_t4_GenerateMini.Add_CheckedChanged($txt_t4_ShortCode_TextChanged) 
    $tab_Page4.Controls.Add($chk_t4_GenerateMini)

    $lbl_t4_GenerateStatus              = (New-Object -TypeName 'System.Windows.Forms.Label')
    $lbl_t4_GenerateStatus.Anchor       = 'Bottom, Left'
    $lbl_t4_GenerateStatus.Location     = '  9, 512'
    $lbl_t4_GenerateStatus.Size         = '744,  20'
    $lbl_t4_GenerateStatus.TextAlign    = 'MiddleCenter'
    $lbl_t4_GenerateStatus.Text         = ''
    $tab_Page4.Controls.Add($lbl_t4_GenerateStatus)

    $btn_t4_Additional                  = (New-Object -TypeName 'System.Windows.Forms.Button')
    $btn_t4_Additional.Anchor           = 'Bottom, Left'
    $btn_t4_Additional.Location         = '316, 635'
    $btn_t4_Additional.Size             = '162,  25'
    $btn_t4_Additional.Text             = ($script:ToolLangINI['additional']['Button'])
    $btn_t4_Additional.Enabled          = $False
    $btn_t4_Additional.Visible          = $False
    $btn_t4_Additional.Add_Click($btn_t4_Additional_Click)
    $MainFORM.Controls.Add($btn_t4_Additional)    # On main form (not tab 4)
#endregion
#endregion
    $InitialFormWindowState = $MainFORM.WindowState
    $MainFORM.Add_Load($MainFORM_StateCorrection_Load)
    Return $MainFORM.ShowDialog()
}
#region Variables
[System.Collections.ArrayList]$script:ListViewCollection = @{}
[boolean] $script:ShowChangesMade     = $False    # Show/Hide message at bottom of tab 2
[boolean] $script:UpdateSelectedCount = $False    # Speeds up processing of All/Inv/None buttons
[string]  $script:saveFile            = ''
[int]     $script:CompleteTick        = 0
[psobject]$script:settings            = (New-Object -TypeName 'PSObject' -Property @{
                                            Timeout        =  60;
                                            Concurrent     =  5;
                                            OutputLocation = 'C:\QA\Results\';
                                            SessionPort    =  5983;
                                            SessionUseSSL  = 'False';
                                            Modules        = '';    # (none)
                                        })
#endregion
###################################################################################################
Write-Host ''
Write-Host "  Starting $script:toolName"

[void]  $script:ToolLangINI.Clear()
[string]$script:scriptLocation = (Split-Path (Get-Variable MyInvocation -ValueOnly).MyCommand.Path)

If ([string]::IsNullOrEmpty($Language) -eq $true)                                         { $Language = 'en-GB' }
If ((Test-Path -LiteralPath "$script:scriptLocation\i18n\$Language-tool.ini") -eq $False) { $Language = 'en-GB' }
If ((Test-Path -LiteralPath "$script:scriptLocation\i18n\$Language-tool.ini") -eq $true)  {
    $script:ToolLangINI = (Load-IniFile -Inputfile "$script:scriptLocation\i18n\$Language-tool.ini")
    [void](Display-MainForm)
}
Else
{
    Write-Host ''
    Write-Host '    Failed to load default language tool file.'
    Write-Host '    Please make sure this file exists:'
    Write-Host "    $script:scriptLocation\i18n\en-GB-tool.ini"
    Write-Host ''
}

Write-Host '  Complete'
Write-Host ''
