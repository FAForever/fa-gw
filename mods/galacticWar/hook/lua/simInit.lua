local oldSetupSession = SetupSession
function SetupSession()
    oldSetupSession()
    -- alter ai teams for galactic War
    import('/lua/gwReinforcements.lua').assignSupports()
end

local oldBeginSession = BeginSession
function BeginSession()
    oldBeginSession()

    -- Get the right color!
    local ScenarioFramework = import('/lua/ScenarioFramework.lua')
    for _, army in ScenarioInfo.ArmySetup do
        if army.Faction == 1 then
            ScenarioFramework.SetUEFPlayerColor(army.ArmyIndex)
        elseif army.Faction == 2 then
            ScenarioFramework.SetAeonPlayerColor(army.ArmyIndex)
        elseif army.Faction == 3 then
            ScenarioFramework.SetCybranPlayerColor(army.ArmyIndex)
        elseif army.Faction == 4 then
            ScenarioFramework.SetSeraphimColor(army.ArmyIndex)
        end
    end    

    SetArmyShowScore("SUPPORT_1", false)
    SetArmyShowScore("SUPPORT_2", false)
    
	ForkThread(import('/lua/gwReinforcements.lua').gwReinforcementsMainThread)
end
