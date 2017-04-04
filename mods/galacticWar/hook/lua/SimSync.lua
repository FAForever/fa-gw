local fafResetSyncTable = ResetSyncTable

ResetSyncTable = function()
    fafResetSyncTable()

	Sync.AddReinforcementList = {}
    Sync.ReinforcementCalled = {}
    Sync.AddSpecialAbility = {}
    Sync.RemoveSpecialAbility = {}
    Sync.EnableSpecialAbility = {}
    Sync.DisableSpecialAbility = {}
    Sync.StartAbilityCoolDown = {}
    Sync.StopAbilityCoolDown = {}
    Sync.SetInitialUnit = {}
    Sync.RemoveInitialUnit = {}
    Sync.SetAbilityUnits = {}
    Sync.SetAbilityRangeCheckUnits = {}
    Sync.RemoveStaticDecal = {}	
end

function AddReinforcementList (army, list)
    if army != nil and list then
		LOG("adding reinforcement!")
        table.insert(Sync.AddReinforcementList, { List = list, Army = army })
    end
end

function RemoveSpecialAbility(army, ability)
    if army != nil and ability then
        table.insert(Sync.RemoveSpecialAbility, { AbilityName = ability, Army = army })
    end
end

function EnableSpecialAbility(army, ability)
    if army != nil and ability then
        table.insert(Sync.EnableSpecialAbility, { AbilityName = ability, Army = army })
    end
end

function DisableSpecialAbility(army, ability)
    if army != nil and ability then
        table.insert(Sync.DisableSpecialAbility, { AbilityName = ability, Army = army })
    end
end

function StartAbilityCoolDown(army, ability)
    if army != nil and ability then
        table.insert(Sync.StartAbilityCoolDown, { AbilityName = ability, Army = army })
    end
end

function StopAbilityCoolDown(army, ability)
    if army != nil and Ability then
        table.insert(Sync.StopAbilityCoolDown, { AbilityName = ability, Army = army })
    end
end

function AddSpecialAbility (army, ability)
    if army != nil and ability then
        table.insert(Sync.AddSpecialAbility, { AbilityName = ability, Army = army })
    end
end

function SetAbilityUnits(army, ability, units)
    if army != nil and ability and units then
        table.insert(Sync.SetAbilityUnits, { Army = army, AbilityName = ability, UnitIds = units })
    end
end

function SetAbilityRangeCheckUnits(army, ability, units)
    if army != nil and ability and units then
        table.insert(Sync.SetAbilityRangeCheckUnits, { Army = army, AbilityName = ability, UnitIds = units })
    end
end