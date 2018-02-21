Function Check-NameSpace ([string]$NameSpace)
{
    $NameSpace = $NameSpace.Trim('\')
    ForEach ($Leaf In $NameSpace.Split('\'))
    {
        [string]$Path += "$($Leaf)\"
        Try { [string]$gCIMi = (Get-CimInstance -ClassName '__NameSpace' -Namespace $Path.Trim('\') -ErrorAction SilentlyContinue) } Catch { }
        If ($gCIMi -eq '') { Return $false } Else { $gCIMi = '' }
    }
    Return $true
}
