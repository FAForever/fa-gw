local ranks = {
    [0] = {"Private", "Corporal", "Sergeant", "Captain", "Major", "Colonel", "General", "Supreme Commander"},
    [1] = {"Paladin", "Legate", "Priest", "Centurion", "Crusader", "Evaluator", "Avatar-of-War", "Champion"},
    [2] = {"Drone", "Node", "Ensign", "Agent", "Inspector", "Starshina", "Commandarm" ,"Elite Commander"},
    [3] = {"Su", "Sou", "Soth", "Ithem", "YthiIs", "Ythilsthe", "YthiThuum", "Suythel Cosethuum"},
}

---Returns a rank name for given faction and rank index
---@param factionId integer Faction index, 0-based
---@param rankIndex integer Rank index, 1-based
---@return string #Defaults to `UNKNOWN` if not found.
function GetRankName(factionId, rankIndex)
    return (ranks[factionId] and ranks[factionId][rankIndex]) or "UNKNOWN"
end
