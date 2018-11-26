local function MakeLocalPlayerInfo(name)
    local result = LobbyComm.GetDefaultPlayerOptions(name)
    result.Human = true
    
    local factionData = import('/lua/factions.lua')
    
    for index, tbl in factionData.Factions do
        if HasCommandLineArg("/" .. tbl.Key) then
            result.Faction = index
            break
        end
    end
    
    result.Team = tonumber(GetCommandLineArg("/team", 1)[1])
    result.Rank = tonumber(GetCommandLineArg("/rank", 1)[1])
	result.StartSpot = tonumber(GetCommandLineArg("/StartSpot", 1)[1])
    LOG('Local player info: ' .. repr(result))
    return result
end

local function HostAddPlayer(senderId, playerInfo)
    playerInfo.OwnerID = senderId

    --the slot is not random...
    local slot = playerInfo.StartSpot

    -- while gameInfo.PlayerOptions[slot] do
    --     slot = slot + 1
    -- end

    playerInfo.PlayerName = lobbyComm:MakeValidPlayerName(playerInfo.OwnerID,playerInfo.PlayerName)

    -- figure out a reasonable default color
    for colorIndex,colorVal in gameColors.PlayerColors do
        if IsColorFree(colorIndex) then
            playerInfo.PlayerColor = colorIndex
            break
        end
    end

    gameInfo.PlayerOptions[slot] = playerInfo
end


local function CheckForLaunch()

    local important = {}
    for slot,player in gameInfo.PlayerOptions do
        GpgNetSend('PlayerOption', string.format("startspot %s %d %s", player.PlayerName, slot, slot))
        if not table.find(important, player.OwnerID) then
            table.insert(important, player.OwnerID)
        end
    end

    -- counts the number of players in the game.  Include yourself by default.
    local playercount = 1
    for k,id in important do
        if id != localPlayerID then
            local peer = lobbyComm:GetPeer(id)
            if peer.status ~= 'Established' then
                LOG("No connection to a player")
                return
            end
            if not table.find(peer.establishedPeers, localPlayerID) then
                LOG("No establishedPeers to a player")
                return
            end
            playercount = playercount + 1
            for k2,other in important do
                if id != other and not table.find(peer.establishedPeers, other) then
                    LOG("No establishedPeers between two players")
                    return
                end
            end
        end
    end

    if playercount < requiredPlayers then
        LOG("No enough players in the game")
       return
    end
    
    local allRanks = {}
    for k,v in gameInfo.PlayerOptions do
        if v.Human and v.Rank then
            allRanks[v.PlayerName] = v.Rank
        end
    end
    gameInfo.GameOptions['Ranks'] = allRanks

    LOG("Host launching game.")
    lobbyComm:BroadcastData( { Type = 'Launch', GameInfo = gameInfo } )
    LOG(repr(gameInfo))
    lobbyComm:LaunchGame(gameInfo)
end

-- create the lobby as a host
function HostGame(gameName, scenarioFileName, singlePlayer)
    CreateUI()

    requiredPlayers = 2
    local args = GetCommandLineArg("/players", 1)
    if args then
        requiredPlayers = tonumber(args[1])
        LOG("requiredPlayers was set to: "..requiredPlayers)
    end

    
    -- For GW, the scenario file is automatically generated.
    lobbyComm.desiredScenario = '/maps/gwScenario/gw_scenario.lua'


    lobbyComm:HostGame()
end