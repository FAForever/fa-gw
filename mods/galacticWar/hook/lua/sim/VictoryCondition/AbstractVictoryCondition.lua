do
    --- @type AbstractVictoryCondition
    local oldAbstractVictoryCondition = AbstractVictoryCondition
    AbstractVictoryCondition = Class(oldAbstractVictoryCondition) {
        ---@param self AbstractVictoryCondition
        ---@param aiBrain AIBrain
        DefeatForArmy = function(self, aiBrain)
            self:FlagBrainAsProcessed(aiBrain)
            self:ToObserver(aiBrain)
            aiBrain:OnDefeat()

            local brainIndex = aiBrain.Army
            -- GW: Hack in recall result, maybe there's a better solution to be made in the future?
            if aiBrain.Recalled then
                SyncGameResult({ brainIndex, "recall -10" })
            else
                SyncGameResult({ brainIndex, "defeat -10" })
            end
        end,

        ---@param self AbstractVictoryCondition
        MonitoringThread = function(self)
            while ScenarioInfo.IsSpawnPhase do
                WaitTicks(5)
            end

            return oldAbstractVictoryCondition.MonitoringThread(self)
        end,
    }
end
