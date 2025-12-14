-- TODO
-- For GW, the scenario file is automatically generated.
-- lobbyComm.desiredScenario = '/maps/gwScenario/gw_scenario.lua'

--TODO
-- Set army colors depending on the faction

do
    local oldCreateLocalPlayer = AutolobbyCommunications.CreateLocalPlayer
    AutolobbyCommunications.CreateLocalPlayer = function(self)
        local info = oldCreateLocalPlayer(self)
        -- Add faction and rank info
        info.Faction = self:GetCommandLineArgumentNumber("/faction", 1) + 1
        info.Rank = self:GetCommandLineArgumentNumber("/rank", 1)
        --WARN("AutolobbyCommunications hooked")
        return info
    end

    ---Creates a table with players' ranks
    ---@param self UIAutolobbyCommunications
    ---@param playerOptions UIAutolobbyPlayer[]
    ---@return table<string, number>
    AutolobbyCommunications.CreateRanksTable = function(self, playerOptions)
        ---@type table<string, number>
        local allRanks = {}

        for slot, options in pairs(playerOptions) do
            if options.Human and options.Rank then
                allRanks[options.PlayerName] = options.Rank
            end
        end

        --LOG(repr(allRanks))
        return allRanks
    end

    ---@alias SpawnAreaType
    ---| "none"
    ---| "auto" -- automatically generated
    ---| "tvsb" -- top vs bottom
    ---| "rvsl" -- right vs left
    ---| "tlvsbr" -- top left vs bottom right
    ---| "trvsbl" -- top right vs bottom left
    ---| "whole" -- whole map

    ---@param self UIAutolobbyCommunications
    ---@return SpawnAreaType
    AutolobbyCommunications.GetSpawnAreaType = function(self)
        local spawnAreaType = self:GetCommandLineArgumentString("/ssl", "none") --[[@as SpawnAreaType]]

        return spawnAreaType
    end

    -- TODO: Hook instead of shadow
    ---@param self UIAutolobbyCommunications
    AutolobbyCommunications.LaunchThread = function(self)
        while not IsDestroyed(self) do
            if self:CanLaunch(self.LaunchStatutes) then

                WaitSeconds(5.0)
                if (not IsDestroyed(self)) and self:CanLaunch(self.LaunchStatutes) then

                    -- send player options to the server
                    -- GW: if slots have gaps, make sure we have army indexes in the expected order
                    local slots = {}
                    for slot, _ in pairs(self.PlayerOptions) do
                        table.insert(slots, slot)
                    end
                    table.sort(slots)
                    for armyIndex, slot in ipairs(slots) do
                        local playerOptions = self.PlayerOptions[slot]
                        local ownerId = playerOptions.OwnerID
                        self:SendPlayerOptionToServer(ownerId, 'Team', playerOptions.Team)
                        self:SendPlayerOptionToServer(ownerId, 'Army', armyIndex) -- GW: replaced playerOptions.StartSpot
                        self:SendPlayerOptionToServer(ownerId, 'StartSpot', playerOptions.StartSpot)
                        self:SendPlayerOptionToServer(ownerId, 'Faction', playerOptions.Faction)
                    end

                    -- tuck them into the game options. By all means a hack, but
                    -- this way they are available in both the sim and the UI
                    self.GameOptions.Ratings = self:CreateRatingsTable(self.PlayerOptions)
                    self.GameOptions.Divisions = self:CreateDivisionsTable(self.PlayerOptions)
                    self.GameOptions.ClanTags = self:CreateClanTagsTable(self.PlayerOptions)
                    self.GameOptions.Ranks = self:CreateRanksTable(self.PlayerOptions) --GW: Populate ranks for the UI
                    self.GameOptions.SSLSpawnAreaType = self:GetSpawnAreaType()
                    self.GameOptions.SSLPreparationTime = 30

                    -- create game configuration
                    local gameConfiguration = {
                        GameMods = self.GameMods,
                        GameOptions = self.GameOptions,
                        PlayerOptions = self.PlayerOptions,
                        Observers = {},
                    }

                    -- send it to all players and tell them to launch with the configuration
                    self:BroadcastData({ Type = "Launch", GameConfig = gameConfiguration })
                    self:LaunchGame(gameConfiguration)
                end
            end

            WaitSeconds(1.0)
        end
    end
end
