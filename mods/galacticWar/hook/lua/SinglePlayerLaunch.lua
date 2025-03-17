SetupCommandLineSkirmish = function(scenario, isPerfTest)

    local faction
    if HasCommandLineArg("/faction") then
        faction = tonumber(GetCommandLineArg("/faction", 1)[1])
        local maxFaction = table.getn(import('/lua/factions.lua').Factions)
        if faction < 1 or faction > maxFaction then
            error("SetupCommandLineSession - selected faction index " .. faction .. " must be between 1 and " ..  maxFaction)
        end
    else
        faction = GetRandomFaction()
    end

    VerifyScenarioConfiguration(scenario)

    scenario.Options = GetCommandLineOptions(isPerfTest)

    sessionInfo = { }
    sessionInfo.playerName = Prefs.GetFromCurrentProfile('Name') or 'Player'
    sessionInfo.createReplay = true
    sessionInfo.scenarioInfo = scenario
    sessionInfo.teamInfo = {}
    sessionInfo.scenarioMods = import('/lua/mods.lua').GetCampaignMods(scenario)

    local seed = GetCommandLineArg("/seed", 1)
    if seed then
        sessionInfo.RandomSeed = tonumber(seed[1])
    elseif isPerfTest then
        sessionInfo.RandomSeed = 2071971
    end

    local armies = sessionInfo.scenarioInfo.Configurations.standard.teams[1].armies

    local numColors = table.getn(import('/lua/gameColors.lua').GameColors.PlayerColors)

    for index, name in armies do
        sessionInfo.teamInfo[index] = import('/lua/ui/lobby/lobbyComm.lua').GetDefaultPlayerOptions(sessionInfo.playerName)
        if index == 1 then
            sessionInfo.teamInfo[index].PlayerName = sessionInfo.playerName
            sessionInfo.teamInfo[index].Faction = faction
            sessionInfo.teamInfo[index].Human = true
            -- GW
            sessionInfo.teamInfo[index].Team = tonumber(GetCommandLineArg("/team", 1)[1])
            sessionInfo.teamInfo[index].Rank = tonumber(GetCommandLineArg("/rank", 1)[1])
            sessionInfo.teamInfo[index].StartSpot = tonumber(GetCommandLineArg("/StartSpot", 1)[1])
            sessionInfo.scenarioInfo.Options['Ranks'] = {[sessionInfo.playerName] = sessionInfo.teamInfo[index].Rank}
            WARN("Added info:", sessionInfo.teamInfo[index].Rank, sessionInfo.teamInfo[index].StartSpot)
            -- End GW
        else
            sessionInfo.teamInfo[index].AIPersonality = 'rush'
            sessionInfo.teamInfo[index].Faction = GetRandomFaction()
            sessionInfo.teamInfo[index].PlayerName = GetRandomName(sessionInfo.teamInfo[index].Faction, sessionInfo.teamInfo[index].AIPersonality)
            sessionInfo.teamInfo[index].Human = false
        end
        sessionInfo.teamInfo[index].ArmyName = name
        sessionInfo.teamInfo[index].PlayerColor = math.mod(index, numColors)
        sessionInfo.teamInfo[index].ArmyColor = math.mod(index, numColors)
    end

    local extras = MapUtils.GetExtraArmies(sessionInfo.scenarioInfo)
    if extras then
        for k,armyName in extras do
            local index = table.getn(sessionInfo.teamInfo) + 1
            sessionInfo.teamInfo[index] = import('/lua/ui/lobby/lobbyComm.lua').GetDefaultPlayerOptions("civilian")
            sessionInfo.teamInfo[index].PlayerName = 'civilian'
            sessionInfo.teamInfo[index].Civilian = true
            sessionInfo.teamInfo[index].ArmyName = armyName
            sessionInfo.teamInfo[index].Human = false
        end
    end

    Prefs.SetToCurrentProfile('LoadingFaction', faction)

    return sessionInfo
end