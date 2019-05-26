function Get-PositionWithVKey([Array]$MenuItems, [int]$Position, $VKeyCode, $PageSize) {
    $MinPosition = 0
    $MaxPosition = $MenuItems.Count - 1
    
    Set-Variable -Name NewPosition -Option AllScope -Value $Position

    <#
    .SYNOPSIS

    Updates the position until we aren't on a separator
    #>
    function Reset-InvalidPosition([Parameter(Mandatory)][int] $PositionOffset) {
        $NewPosition = Get-WrappedPosition $MenuItems $NewPosition $PositionOffset
    }

    If (Test-KeyUp $VKeyCode) { 
        $NewPosition--

        Reset-InvalidPosition -PositionOffset -1
    }

    If (Test-KeyDown $VKeyCode) {
        $NewPosition++

        Reset-InvalidPosition -PositionOffset 1
    }

    If (Test-KeyPageDown $VKeyCode) {
        $NewPosition = [Math]::Min($MaxPosition, $NewPosition + $PageSize)

        Reset-InvalidPosition -PositionOffset -1
    }

    If (Test-KeyEnd $VKeyCode) {
        $NewPosition = $MenuItems.Count - 1

        Reset-InvalidPosition -PositionOffset 1
    }

    IF (Test-KeyPageUp $VKeyCode) {
        $NewPosition = [Math]::Max($MinPosition, $NewPosition - $PageSize)

        Reset-InvalidPosition -PositionOffset -1
    }

    IF (Test-KeyHome $VKeyCode) {
        $NewPosition = $MinPosition

        Reset-InvalidPosition -PositionOffset -1
    }

    Return $NewPosition
}