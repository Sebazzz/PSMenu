<#

.SYNOPSIS
Shows an interactive menu to the user and returns the chosen item or item index.

.DESCRIPTION
Shows an interactive menu on supporting console hosts. The user can interactively
select one (or more, in case of -MultiSelect) items. The cmdlet returns the items
itself, or its indices (in case of -ReturnIndex). 

The interactive menu is controllable by hotkeys:
- Arrow up/down: Focus menu item.
- Enter: Select menu item.
- Page up/down: Go one page up or down - if the menu is larger then the screen.
- Home/end: Go to the top or bottom of the menu.
- Spacebar: If in multi-select mode (MultiSelect parameter), toggle item choice.

Not all console hosts support the interactive menu (PowerShell ISE is a well-known
host which doesn't support it). The console host needs to support the ReadKey method.
The default PowerShell console host does this. 

.PARAMETER  MenuItems
Array of objects or strings containing menu items. Must contain at least one item.
Must not contain $null. 

The items are converted to a string for display by the MenuItemFormatter parameter, which
does by default a ".ToString()" of the underlying object. It is best for this string 
to fit on a single line.

The array of menu items may also contain unselectable separators, which can be used
to visually distinct menu items. You can call Get-MenuSeparator to get a separator object,
and add that to the menu item array.

.PARAMETER  ReturnIndex
Instead of returning the object(s) that has/have been chosen, return the index/indices
of the object(s) that have been chosen.

.PARAMETER  MultiSelect
Allow the user to select multiple items instead of a single item.

.PARAMETER  ItemFocusColor
The console color used for focusing the active item. This by default green,
which looks good on both default PowerShell-blue and black consoles.

.PARAMETER  MenuItemFormatter
A function/scriptblock which accepts a menu item (from the MenuItems parameter)
and returns a string suitable for display. This function will be called many times,
for each menu item once.

This parameter is optional and by default executes a ".ToString()" on the object.
If you control the objects that you pass in MenuItems, then you want to probably
override the ToString() method. If you don't control the objects, then this parameter
is very useful.

.INPUTS

None. You cannot pipe objects to Show-Menu.

.OUTPUTS

Array of chosen menu items or (if the -ReturnIndex parameter is given) the indices.

.LINK

https://github.com/Sebazzz/PSMenu

.EXAMPLE

Show-Menu @("option 1", "option 2", "option 3")

.EXAMPLE 

Show-Menu -MenuItems $(Get-NetAdapter) -MenuItemFormatter { $Args | Select -Exp Name }

.EXAMPLE 

Show-Menu @("Option A", "Option B", $(Get-MenuSeparator), "Quit")

#>
function Show-Menu {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, Position = 0)][Array] $MenuItems,
        [Switch]$ReturnIndex, 
        [Switch]$MultiSelect, 
        [ConsoleColor] $ItemFocusColor = [ConsoleColor]::Green
        [ScriptBlock] $MenuItemFormatter = { Param($M) Format-MenuItemDefault $M },
        [int] $PageSize = 0,
        [int]$HeaderSpace = 1
    )

    Test-HostSupported
    Test-MenuItemArray -MenuItems $MenuItems

    # Current pressed virtual key code
    $VKeyCode = 0

    # Initialize valid position
    $Position = Get-WrappedPosition $MenuItems -Position 0 -PositionOffset 1

    $CursorPosition = [System.Console]::CursorTop
    
    try {
        [System.Console]::CursorVisible = $False # Prevents cursor flickering

        [pscustomobject[]]$MetaItems = foreach($MenuItem in $MenuItems) {
            $IsSeparator = Test-MenuSeparator $MenuItem
            $Formatted = if ($IsSeparator) { $MenuItem } else { & $MenuItemFormatter $MenuItem }
            if (!$Formatted) {
                Throw "'MenuItemFormatter' returned an empty string for item #$CurrentIndex"
            }
            $item = [pscustomobject]@{
                MenuItem = $MenuItem
                IsSeparator = $IsSeparator
                Formatted = $Formatted
                selected = $false
            }
            $item
        }

        $viewport = @{
            top = 0
            height = 0
        }

        # Body
        $WriteMenu = {
            Get-CalculatedPageIndexNumber -Viewport $viewport -Position $Position -ItemCount $MetaItems.Count -HeaderSpace $HeaderSpace
            ([ref]$RenderedRowCount).Value = Write-Menu -MenuItems $MetaItems `
                -MenuPosition $Position `
                -MultiSelect:$MultiSelect `
                -ItemFocusColor $ItemFocusColor `
                -Viewport $viewport
        }
        $RenderedRowCount = 0

        & $WriteMenu
        While ($True) {
            $CurrentPress = Read-VKey
            $VKeyCode = $CurrentPress.VirtualKeyCode

            if (Test-KeyEnter $VKeyCode) {
                Break
            }

            If (Test-KeySpace $VKeyCode) {
                $Item = $MetaItems[$Position]
                $Item.selected = ! $Item.selected
            }

            If (Test-KeyEscape $VKeyCode) {
                return $null
            }

            $ps = if($PageSize) {$PageSize} else {$viewport.height - 1}
            $Position = Get-PositionWithVKey -MenuItems $MenuItems -Position $Position -VKeyCode $VKeyCode -PageSize $ps

            If (!$(Test-KeyEscape $VKeyCode)) {
                [System.Console]::SetCursorPosition(0, [Console]::CursorTop - $RenderedRowCount + 1)
                & $WriteMenu
            }
        }
    }
    finally {
        [System.Console]::CursorVisible = $true
        write-host ''
    }

    if ($ReturnIndex -eq $false -and $null -ne $Position) {
        if ($MultiSelect) {
            $ret = foreach($i in $MetaItems) {
                if($i.selected) {$i.MenuItem}
            }
            return $ret
        }
        else {
            Return $MenuItems[$Position]
        }
    }
    else {
        if ($MultiSelect) {
            $ret = for($i = 0; $i -lt $MetaItems.count; $i++) {
                if($MetaItems[$i].selected) {$i}
            }
            return $ret
        }
        else {
            Return $Position
        }
    }
}
