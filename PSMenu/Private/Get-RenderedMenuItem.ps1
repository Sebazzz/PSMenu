function Get-RenderedMenuItem(
    [Parameter(Mandatory)][pscustomobject] $MenuItem, 
    [Switch] $MultiSelect, 
    [Parameter(Mandatory)][bool] $IsItemFocused,
    [Parameter(Mandatory)][ConsoleColor] $FocusColor,
    [Parameter(Mandatory)][int] $WindowWidth) {

    $SelectionPrefix = '    '
    $FocusPrefix = '  '
    $ItemText = ' -------------------------- '

    if ($MenuItem.IsSeparator -ne $true) {
        if ($MultiSelect) {
            $SelectionPrefix = if ($MenuItem.selected) { '[x] ' } else { '[ ] ' }
        }

        $FocusPrefix = if ($IsItemFocused) { '> ' } else { '  ' }
        $ItemText = $MenuItem.Formatted
    }

    $DesiredWidth = $WindowWidth - 2
    $Text = "{0}{1}{2}" -f $FocusPrefix, $SelectionPrefix, $ItemText
    if($Text.Length -gt $DesiredWidth) {
        $Text=  $Text.substring(0, $DesiredWidth)
    }
    $Text = $Text.PadRight($DesiredWidth, ' ')

    if ($IsItemFocused) {
        (New-Text $Text -ForegroundColor $FocusColor).ToString()
    }
    else {
        $Text
    }
}

function Format-MenuItemDefault($MenuItem) {
    Return $MenuItem.ToString()
}
