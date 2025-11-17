local Ranks = import("/lua/ui/gw/ranks.lua")

--GW update displayed name to "Rank AvatarName"
function updatePlayerName(line)
    local playerName = line.name:GetText()
    local playerRank = sessionInfo.Options.Ranks[playerName]
    for _, armyData in GetArmiesTable().armiesTable do
        if armyData.nickname == playerName then
            WARN(armyData.faction, playerRank)
            local rankName = Ranks.GetRankName(armyData.faction, playerRank)
            local text = string.format("%d-%s %s", playerRank or 0, rankName, playerName)
            line.name:SetText(text)
            break
        end
    end
end
