local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local _SetLayout = SetLayout
function SetLayout()
    local controls = import('/lua/ui/game/multifunction.lua').controls
    local abilitiesControl = import('/lua/ui/ability_panel/abilities.lua').controls.bg

    _SetLayout()
    LayoutHelpers.Below(controls.bg, abilitiesControl, 5)
    LayoutHelpers.AtVerticalCenterIn(controls.collapseArrow, controls.bg)
end
