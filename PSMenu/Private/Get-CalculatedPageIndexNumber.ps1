function Get-CalculatedPageIndexNumber(
    [Parameter(Mandatory)][pscustomobject]$Viewport,
    [Parameter(Mandatory)][int]$Position,
    [Parameter(Mandatory)][int]$ItemCount,
    [int]$HeaderSpace = 0
) {
    # update height to match console
    $Viewport.height = [Math]::min((Get-ConsoleHeight) - $HeaderSpace, $ItemCount)
    # Scroll up as necessary
    if($Viewport.top -gt $Position) {
        $Viewport.top = $Position
    }
    # Scroll down as necessary
    if($Viewport.top + $Viewport.height -le $Position) {
        $Viewport.top = $Position - $Viewport.height + 1
    }
}