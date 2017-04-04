local oldCreateUI = CreateUI
function CreateUI(isReplay)
    oldCreateUI(isReplay)
    import('/lua/ui/ability_panel/abilities.lua').SetupOrdersControl(gameParent)
end

local oldOnPause = OnPause
function OnPause(pausedBy, timeoutsRemaining)
    oldOnPause(pausedBy, timeoutsRemaining)
    import('/lua/ui/ability_panel/abilities.lua').KillTimers()
end

local oldOnResume = OnResume
function OnResume()
    oldOnResume()
    import('/lua/ui/ability_panel/abilities.lua').RestartTimers()
end

-- Removing live replay syncing
function UiBeat()
    local observing = (GetFocusArmy() == -1)
    if (observing ~= lastObserving) then
        lastObserving = observing
        import('/lua/ui/game/economy.lua').ToggleEconPanel(not observing)
    end
end
