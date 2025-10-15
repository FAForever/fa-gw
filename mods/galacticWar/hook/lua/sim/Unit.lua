local oldUnit = Unit
Unit = Class(oldUnit) {
    InitiateActivation = function(self, initTime) 
        self.initTime = initTime

        self:SetStunned(initTime)
        self:SetImmobile(true)
        self:SetBusy(true)        
        self:SetBlockCommandQueue(true)
        self:SetUnSelectable(true)
        self:SetReclaimable(false)
        self:SetPaused(true)
        self:SetProductionActive(false)
        self:SetWorkProgress(0.0)
        self:SetConsumptionActive(false)
        self:SetActiveConsumptionInactive()
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('RadarStealth')
        self:DisableUnitIntel('RadarStealthField')
        self:DisableUnitIntel('SonarStealth')
        self:DisableUnitIntel('SonarStealthField')
        self:DisableUnitIntel('Sonar')
        self:DisableUnitIntel('Omni')
        self:DisableUnitIntel('Cloak')
        self:DisableUnitIntel('CloakField')
        self:DisableUnitIntel('Spoof')
        self:DisableUnitIntel('Jammer')
        self:DisableUnitIntel('Radar')
        local unitWeaponBPs = self:GetBlueprint().Weapon 
        if unitWeaponBPs then 
            for index, weaponBP in unitWeaponBPs do
                if weaponBP.EnergyRequired and weaponBP.EnergyDrainPerSecond then
                WARN('nrgreq and drain')
                self:ForkThread(self.CompensateForWeaponCharging, weaponBP.EnergyRequired, weaponBP.EnergyDrainPerSecond, index)
                end
            end
        end

        self.InitThread = self:ForkThread(self.InitiateActivationThread)
    end,

    CompensateForWeaponCharging = function(self, EnergyAmount, EnergyRate, index)
        WARN('setting production offset')
        self:SetProductionActive(true)
        self:SetProductionPerSecondEnergy(EnergyRate)
        WaitSeconds(EnergyAmount/EnergyRate)
        WARN('end offset')
        self:SetProductionPerSecondEnergy(0)
        self:SetProductionActive(false)
    end,

    InitiateActivationThread = function(self) 
        self.ActivationTime = CreateEconomyEvent(self, 0, 0, self.initTime, self.UpdateActivationProgress)
        WaitFor( self.ActivationTime )

        if self.ActivationTime then
            RemoveEconomyEvent(self, self.ActivationTime )
            self.ActivationTime = nil
        end    
        self:SetWorkProgress(0.0)
        self:SetImmobile(false)
        self:SetBusy(false)
        self:SetReclaimable(false)
        self:SetUnSelectable(false) 
        self:SetPaused(false) 
        self:SetProductionActive(true)
        self:SetBlockCommandQueue(false)      
        self:SetConsumptionActive(true)      
        self:SetMaintenanceConsumptionActive()
        self:SetActiveConsumptionActive()
        self:EnableUnitIntel('RadarStealth')
        self:EnableUnitIntel('RadarStealthField')
        self:EnableUnitIntel('SonarStealth')
        self:EnableUnitIntel('SonarStealthField')
        self:EnableUnitIntel('Sonar')
        self:EnableUnitIntel('Omni')
        self:EnableUnitIntel('Cloak')
        self:EnableUnitIntel('CloakField')
        self:EnableUnitIntel('Spoof')
        self:EnableUnitIntel('Jammer')
        self:EnableUnitIntel('Radar')
    end,

    UpdateActivationProgress = function(self, progress)
        --LOG(' UpdateActivationProgress ')
        self:SetWorkProgress(progress)
    end,

    AddAutoRecall = function(self)
        -- On killed: this function plays when the unit takes a mortal hit.  It plays all the default death effect
        -- it also spawns the wreckage based upon how much it was overkilled.
        self.OnKilled = function(self, instigator, type, overkillRatio)
            
            self.Dead = true
        
            self:OnKilledVO()
            self:DoUnitCallbacks( 'OnKilled' )
            self:DestroyTopSpeedEffects()

            if self.UnitBeingTeleported and not self.UnitBeingTeleported.Dead then
                self.UnitBeingTeleported:Destroy()
                self.UnitBeingTeleported = nil
            end

            -- Notify instigator that you killed me.
            if instigator and IsUnit(instigator) then
                instigator:OnKilledUnit(self)
            end


            local aiBrain = self:GetAIBrain()
            aiBrain:OnAutoRecall()
            self:PlayTeleportOutEffects()
            self:CleanupTeleportChargeEffects()
            self:StopUnitAmbientSound('TeleportLoop')
            self:PlayUnitSound('TeleportEnd')
            self:DisableShield()
            self:DisableUnitIntel()
            self:Destroy()
        end
    end,

    Recall  = function(self)
        local aiBrain = self:GetAIBrain()
        if ArmyIsOutOfGame(aiBrain:GetArmyIndex()) then
            return
        end
        self:CleanupTeleportChargeEffects()
        if self.RecallTime then
            RemoveEconomyEvent( self, self.RecallTime)
            self.RecallTime = nil
        end
        if self.RecallThread then
            self:SetImmobile(false)
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
            self:SetWorkProgress(0.0)
            KillThread(self.RecallThread)
            self.RecallThread = nil

        else
            self.RecallThread = self:ForkThread(self.InitiateRecallThread)
        end
    end,
    
    InitiateRecallThread = function(self)
        local aiBrain = self:GetAIBrain()
        local distance = utilities.XZDistanceTwoVectors(self:GetPosition(), aiBrain:GetStartVector3f())        
        local recall = 10 + math.pow(math.sqrt(distance), 1.7)
        self:SetImmobile(true)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        self:PlayUnitSound('TeleportStart')
        self:PlayUnitAmbientSound('TeleportLoop')
        self:PlayRecallChargeEffects()
        self.RecallTime = CreateEconomyEvent(self, 0, 0, recall, self.UpdateRecallProgress)
        WaitFor( self.RecallTime )

        if self.RecallTime then
            RemoveEconomyEvent(self, self.RecallTime )
            self.RecallTime = nil
        end

        self:PlayTeleportOutEffects()
        self:CleanupTeleportChargeEffects()
        
        WaitSeconds( 0.1 )
        if not self.Dead then
            self:SetWorkProgress(0.0)
            self:StopUnitAmbientSound('TeleportLoop')
            self:PlayUnitSound('TeleportEnd')
            aiBrain:OnRecall()
            self:Destroy()
        end
    end,

    PlayRecallChargeEffects = function(self)
        local army = self:GetArmy()
        local bp = self:GetBlueprint()
        local fx

        self.TeleportChargeBag = {}
        for k, v in EffectTemplate.GenericTeleportCharge01 do
            fx = CreateEmitterAtEntity(self,army,v):OffsetEmitter(0, (bp.Physics.MeshExtentsY or 1) / 2, 0)
            self.Trash:Add(fx)
            table.insert( self.TeleportChargeBag, fx)
        end
    end,

    UpdateRecallProgress = function(self, progress)
        --LOG(' UpdatingTeleportProgress ')
        self:SetWorkProgress(progress)
    end,
}