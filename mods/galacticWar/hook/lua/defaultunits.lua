local utilities = import('/lua/utilities.lua')

local oldACUUnit = ACUUnit
local oldOnCreate = ACUUnit.OnCreate
local oldOnStartBuild = ACUUnit.OnStartBuild
local oldOnKilled = ACUUnit.OnKilled
---@type ACUUnit
ACUUnit = Class(oldACUUnit) {
    ---@param self ACUUnit
	OnCreate = function(self)
		oldOnCreate(self)

		self.Idling = true
        --self:ForkThread(self.CheckIdling)
	end,

    ---@param self ACUUnit
	CheckIdling = function(self)
        WaitSeconds(20)
        local aiBrain = self:GetAIBrain()
        local startX, startZ = aiBrain:GetArmyStartPos()
        local pos = self:GetPosition()
        local distance = utilities.GetDistanceBetweenTwoPoints2(startX, startZ, pos[1], pos[3])
        if distance == 0 and self.Idling then
            self:PlayTeleportOutEffects()
            self:CleanupTeleportChargeEffects()
            WaitSeconds( 0.1 )
            self:StopUnitAmbientSound('TeleportLoop')
            self:PlayUnitSound('TeleportEnd')
            aiBrain:OnRecall()
            self:Destroy()
        end
    end,

    ---@param self ACUUnit
    OnStartBuild = function(self, unitBeingBuilt, order)
    	oldOnStartBuild(self, unitBeingBuilt, order)

    	self.Idling = false
    end,

    ---@param self ACUUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        oldOnKilled(self, instigator, type, overkillRatio)

        if not Sync.CommanderKilled then
            Sync.CommanderKilled = {}
        end
        local data = {
            armyIndex = self.Army
        }
        if instigator and instigator.Army then
            data.instigatorIndex = instigator.Army
        end

        table.insert(Sync.CommanderKilled, data)
    end,
}