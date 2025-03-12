local ranks = {
    [0] = {"Private", "Corporal", "Sergeant", "Captain", "Major", "Colonel", "General", "Supreme Commander"},
    [1] = {"Paladin", "Legate", "Priest", "Centurion", "Crusader", "Evaluator", "Avatar-of-War", "Champion"},
    [2] = {"Drone", "Node", "Ensign", "Agent", "Inspector", "Starshina", "Commandarm" ,"Elite Commander"},
    [3] = {"Su", "Sou", "Soth", "Ithem", "YthiIs", "Ythilsthe", "YthiThuum", "Suythel Cosethuum"},
}

local oldSetupPlayerLines = SetupPlayerLines
function SetupPlayerLines()
    -- Overrite the player's nickname to include the rank
    for armyIndex, armyData in GetArmiesTable().armiesTable do
        local playerName = armyData.nickname
        -- TODO: This info is missing
        local playerRank = sessionInfo.Options.Ranks[playerName]
        if (playerRank) then
            playerName = ranks[armyData.faction][playerRank+1] .. " " .. playerName
        end
        armyData.nickname = playerName
        --LOG("Player's name update to: " .. playerName)
    end
    oldSetupPlayerLines()
end
