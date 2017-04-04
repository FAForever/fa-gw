local utilities = import('/lua/utilities.lua')

local oldACUUnit = ACUUnit
local oldOnCreate = ACUUnit.OnCreate
local oldOnStartBuild = ACUUnit.OnStartBuild
ACUUnit = Class(oldACUUnit) {
	OnCreate = function(self)
		oldOnCreate(self)

		self.Idling = true
        self:ForkThread(self.CheckIdling)
	end,

	CheckIdling = function(self)
        WaitSeconds(20)
        local aiBrain = self:GetAIBrain()
        local distance = utilities.XZDistanceTwoVectors(self:GetPosition(), aiBrain:GetStartVector3f())
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

    OnStartBuild = function(self, unitBeingBuilt, order)
    	oldOnStartBuild(self, unitBeingBuilt, order)

    	self.Idling = false
    end,
}