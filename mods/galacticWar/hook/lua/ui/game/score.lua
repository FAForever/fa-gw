local ranks = {
    [0] = {"Private", "Corporal", "Sergeant", "Captain", "Major", "Colonel", "General", "Supreme Commander"},
    [1] = {"Paladin", "Legate", "Priest", "Centurion", "Crusader", "Evaluator", "Avatar-of-War", "Champion"},
    [2] = {"Drone", "Node", "Ensign", "Agent", "Inspector", "Starshina", "Commandarm" ,"Elite Commander"},
    [3] = {"Su", "Sou", "Soth", "Ithem", "YthiIs", "Ythilsthe", "YthiThuum", "Suythel Cosethuum"},
}

--GW update displayed name to "Rank AvatarName"
function updatePlayerName(line)
    local playerName = line.name:GetText()
    local playerRank = sessionInfo.Options.Ranks[playerName]
    for _, armyData in GetArmiesTable().armiesTable do
        if armyData.nickname == playerName then
            line.name:SetText(ranks[armyData.faction][playerRank] .. " " .. playerName)
            break
        end
    end
end
