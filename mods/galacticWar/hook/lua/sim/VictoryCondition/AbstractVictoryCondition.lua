do
    --- @type AbstractVictoryCondition
    local oldAbstractVictoryCondition = AbstractVictoryCondition
    AbstractVictoryCondition = Class(oldAbstractVictoryCondition) {
        ---@param self AbstractVictoryCondition
        ---@param aiBrain AIBrain
        DefeatForArmy = function(self, aiBrain)
            local aiBrainName = aiBrain.Name

            if self.EnabledSpewing then
                SPEW("Army is defeated: ", aiBrainName)
            end

            self:FlagBrainAsProcessed(aiBrain)
            self:ToObserver(aiBrain)
            aiBrain:OnRecall()

            local brainIndex = aiBrain.Army
            -- GW: Hack in recall result, maybe there's a better solution to be made in the future?
            if aiBrain.Recalled then
                SyncGameResult({ brainIndex, "recall -10" })
            else
                SyncGameResult({ brainIndex, "defeat -10" })
            end
        end,
    }
end