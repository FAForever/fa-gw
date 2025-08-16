local oldOnSync = OnSync
OnSync = function()
    oldOnSync()

    for k, v in Sync.AddReinforcementList do
        local army = v.Army
        if army == GetFocusArmy() then
            import('/lua/ui/ability_panel/abilities.lua').AddReinforcements(v)
        end
    end

	for k, v in Sync.AddSpecialAbility do
        local army = v.Army
        if army == GetFocusArmy() then
            import('/lua/ui/ability_panel/abilities.lua').AddSpecialAbility(v)
        end
    end

    for k, v in Sync.EnableSpecialAbility do
        local army = v.Army
        if army == GetFocusArmy() then
            import('/lua/ui/ability_panel/abilities.lua').EnableSpecialAbility(v)
        end
    end
    for k, v in Sync.DisableSpecialAbility do
        local army = v.Army
        if army == GetFocusArmy() then
            import('/lua/ui/ability_panel/abilities.lua').DisableSpecialAbility(v)
        end
    end

    for k, v in Sync.StartAbilityCoolDown do
        local army = v.Army
        if army == GetFocusArmy() then
            import('/lua/ui/ability_panel/abilities.lua').DisableButtonStartCoolDown(v.AbilityName)
        end
    end
    for k, v in Sync.StopAbilityCoolDown do
        local army = v.Army
        if army == GetFocusArmy() then
            import('/lua/ui/ability_panel/abilities.lua').EnableButtonStopCoolDown(v.AbilityName)
        end
    end    
    
    if Sync.NewTech then
        import('/lua/ui/game/construction.lua').NewTech(Sync.NewTech)
    end

    if Sync.CommanderKilled then
        for _, data in Sync.CommanderKilled do
            GpgNetSend('CommanderKilled', data.armyIndex, data.instigatorIndex or -1)
        end
    end

    if Sync.ReinforcementCalled then
        for k, group in Sync.ReinforcementCalled do
            local armyIndex, groupId = unpack(group)
            GpgNetSend('UnitGroupCalled', armyIndex, groupId)
        end
    end
end
