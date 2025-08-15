
do
    --- @type AbstractVictoryCondition
    local oldAbstractVictoryCondition = AbstractVictoryCondition
    AbstractVictoryCondition = Class(oldAbstractVictoryCondition) {
        DefeatForArmy = function(self, aiBrain)
            self:ToObserver(aiBrain)
            aiBrain:OnDefeat()

            local brainIndex = aiBrain.Army
            -- GW: Hack in recall result, maybe there's a better solution to be made in the future?
            if aiBrain.Recalled then
                SyncGameResult({ brainIndex, "recall -10" })
            else
                SyncGameResult({ brainIndex, "defeat -10" })
            end
        end
    }
end
