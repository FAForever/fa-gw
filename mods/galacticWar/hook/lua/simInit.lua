local oldSetupSession = SetupSession
function SetupSession()
    oldSetupSession()
    -- alter ai teams for galactic War
    import('/lua/gwReinforcements.lua').AssignSupports()
end

---@param module any
---@param armyId integer
---@param faction integer
local function setPrimaryColor(module, armyId, faction)
    if faction == 1 then
        module.SetUEFPlayerColor(armyId)
    elseif faction == 2 then
        module.SetAeonPlayerColor(armyId)
    elseif faction == 3 then
        module.SetCybranPlayerColor(armyId)
    elseif faction == 4 then
        module.SetSeraphimColor(armyId)
    end
end

---@param module any
---@param armyId integer
---@param faction integer
local function setSecondaryColor(module, armyId, faction)
    if faction == 1 then
        module.SetUEFAllyColor(armyId)
    elseif faction == 2 then
        module.SetAeonAllyColor(armyId)
    elseif faction == 3 then
        module.SetCybranAllyColor(armyId)
    elseif faction == 4 then
        SetArmyColor(armyId, 255, 200, 0) --189, 116, 16 or 89, 133, 39
    end
end

---Sets army colors based on army focus. So every player sees the colors from their perspective.
---
---Focus army gets the primary faction color, all allies get the same secondary faction color.
---All enemies get the same primary faction color
---
---The colors are figured out based on army setup team and faction. We are assuming that everyone
---in the team has the same faction, and each team is different faction. Which it always is in GW
---
---Observers see primary colors
local function setArmyColorsByFocus()
    local ScenarioFramework = import('/lua/ScenarioFramework.lua')
    ---@type ArmySetup
    local armySetup = ScenarioInfo.ArmySetup
    ---@type table<integer, {["Faction"]: integer, ["ArmyIds"]: integer[]}>
    local teams = {}
    local myTeam = -1
    local myArmyId = GetFocusArmy()

    for _, army in pairs(armySetup) do
        if not army.Human then
            continue
        end

        local teamId = army.Team
        if not teams[teamId] then
            teams[teamId] = {
                Faction = army.Faction,
                ArmyIds = {}
            }
        end

        table.insert(teams[teamId].ArmyIds, army.ArmyIndex)

        if army.ArmyIndex == myArmyId then
            myTeam = teamId
        end
    end

    for teamId, data in pairs(teams) do
        for _, armyId in pairs(data.ArmyIds) do
            if armyId == myArmyId or teamId ~= myTeam then
                setPrimaryColor(ScenarioFramework, armyId, data.Faction)
            else
                setSecondaryColor(ScenarioFramework, armyId, data.Faction)
            end
        end
    end
end

local oldBeginSession = BeginSession
function BeginSession()
    oldBeginSession()

    setArmyColorsByFocus()

    SetArmyShowScore("SUPPORT_1", false)
    SetArmyShowScore("SUPPORT_2", false)

	ForkThread(import('/lua/gwReinforcements.lua').GwReinforcementsMainThread)
end
