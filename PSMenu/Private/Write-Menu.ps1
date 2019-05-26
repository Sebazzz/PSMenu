function Write-Menu {
    param (
        [Parameter(Mandatory)][pscustomobject[]]$MenuItems, 
        [Parameter(Mandatory)][Int] $MenuPosition,
        [Parameter(Mandatory)][ConsoleColor] $ItemFocusColor,
        [Switch] $MultiSelect,
        [Parameter(Mandatory)][pscustomobject]$Viewport
    )
    
    $CurrentIndex = $Viewport.top
    $MenuItemCount = $Viewport.height
    $WindowWidth = [Console]::BufferWidth
    $RenderedRowCount = 0

    [string[]]$lines = . {
        for ($i = 0; $i -lt $MenuItemCount;) {
            $MenuItem = $MenuItems[$CurrentIndex]
            if ($null -eq $MenuItem) {
                Continue
            }

            $IsItemFocused = $CurrentIndex -eq $MenuPosition

            Get-RenderedMenuItem -MenuItem $MenuItem -MultiSelect:$MultiSelect -IsItemFocused:$IsItemFocused -FocusColor $ItemFocusColor -WindowWidth $WindowWidth
            $RenderedRowCount += [Math]::Max([Math]::Ceiling($DisplayText.Length / $WindowWidth), 1)

            $CurrentIndex++;
            $i++;
        }
    }
    write-host ($lines -join "`n") -nonewline

    $RenderedRowCount
}
