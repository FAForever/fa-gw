local AbilityDefinition = import('/lua/abilitydefinition.lua').abilities

local oldAIBrain = AIBrain
local oldOnCreateHuman = AIBrain.OnCreateHuman

AIBrain = Class(oldAIBrain) {
    OnCreateHuman = function(self, planName)
        oldOnCreateHuman(self, planName)

        self.support = false
        self.SpecialAbilities = {}
        self.SpecialAbilityUnits = {}
    end,

    OnCreateAI = function(self, planName)
        self:CreateBrainShared(planName)

        self.SpecialAbilities = {} -- GW Addition
        self.SpecialAbilityUnits = {} -- GW Addition

        --LOG('*AI DEBUG: AI planName = ', repr(planName))
        --LOG('*AI DEBUG: SCENARIO AI PLAN LIST = ', repr(aiScenarioPlans))
        local civilian = false
        for name,data in ScenarioInfo.ArmySetup do
            if name == self.Name then
                civilian = data.Civilian
                if data.Support then -- GW Addition
                    self.support = data.Support
                end  
                break
            end
        end
        if not civilian and not self.support then -- GW Addition: and not self.support
            local per = ScenarioInfo.ArmySetup[self.Name].AIPersonality

            -- Flag this brain as a possible brain to have skirmish systems enabled on
            self.SkirmishSystems = true

            local cheatPos = string.find( per, 'cheat')
            if cheatPos then
                AIUtils.SetupCheat(self, true)
                ScenarioInfo.ArmySetup[self.Name].AIPersonality = string.sub( per, 1, cheatPos - 1 )
            end


            self.CurrentPlan = self.AIPlansList[self:GetFactionIndex()][1]

            --LOG('*AI DEBUG: AI PLAN LIST = ', repr(self.AIPlansList))
            --LOG('===== AI DEBUG: AI Brain Fork Theads =====')
            self.EvaluateThread = self:ForkThread(self.EvaluateAIThread)
            self.ExecuteThread = self:ForkThread(self.ExecuteAIThread)

            self.PlatoonNameCounter = {}
            self.PlatoonNameCounter['AttackForce'] = 0
            self.BaseTemplates = {}
            self.RepeatExecution = true
            self:InitializeEconomyState()
            self.IntelData = {
                ScoutCounter = 0,
            }

            ------changed this for Sorian AI
            --Flag enemy starting locations with threat?
            if ScenarioInfo.type == 'skirmish' and string.find(per, 'sorian') then
                --Gives the initial threat a type so initial land platoons will actually attack it.
                self:AddInitialEnemyThreatSorian(200, 0.005, 'Economy')
            elseif ScenarioInfo.type == 'skirmish' then
                self:AddInitialEnemyThreat(200, 0.005)
            end
        end
        self.UnitBuiltTriggerList = {}
        self.FactoryAssistList = {}
        self.BrainType = 'AI'
    end,
    --[[
    IsUnitTargeatable = function(self, blip, unit)
        if unit and not unit:IsDead() and IsUnit(unit) then
            -- if we've got a LOS, then we can fire.
            if blip:IsSeenNow(self:GetArmyIndex()) then
                return true
            else
                local UnitId = unit:GetEntityId()
                if not self.UnitIntelList[UnitId] then
                    return false
                else
                    -- if we have a least one type of blip...
                    if self.UnitIntelList[UnitId]["Radar"] or blip:IsOnSonar(self:GetArmyIndex()) or blip:IsOnOmni(self:GetArmyIndex()) then
                        return true
                    else
                        return false
                    end
                end             
            end
        end
    end,
    
    SetUnitIntelTable = function(self, unit, reconType, val)
        if unit and not unit:IsDead() and IsUnit(unit) then
            
            local UnitId = unit:GetEntityId()
            if not self.UnitIntelList[UnitId] and val then
                self.UnitIntelList[UnitId] = {}
                self.UnitIntelList[UnitId][reconType] = 1            
            else
                if not self.UnitIntelList[UnitId][reconType] then
                    if val then
                        self.UnitIntelList[UnitId][reconType] = 1
                    end
                else
                    if val then
                        self.UnitIntelList[UnitId][reconType] = self.UnitIntelList[UnitId][reconType] + 1
                    else
                        if self.UnitIntelList[UnitId][reconType] == 1 then
                            self.UnitIntelList[UnitId][reconType] = nil
                        else
                            self.UnitIntelList[UnitId][reconType] = self.UnitIntelList[UnitId][reconType] - 1
                        end
                    end
                end
            end
            
        else
            local UnitId = unit:GetEntityId()
            if self.UnitIntelList[UnitId] then
                self.UnitIntelList[UnitId] = nil
            end
        end        

    end,
    
    OnDefeat = function(self)
        ##For Sorian AI
        if self.BrainType == 'AI' then
            SUtils.AISendChat('enemies', ArmyBrains[self:GetArmyIndex()].Nickname, 'ilost')
        end
        local per = ScenarioInfo.ArmySetup[self.Name].AIPersonality
        if string.find(per, 'sorian') then
            SUtils.GiveAwayMyCrap(self)
        end
        ###end sorian AI bit
        
        # seems that FA send the OnDeath twice : one when losing, the other when disconnecting. But we only want it one time !
        if ArmyIsOutOfGame(self:GetArmyIndex()) then
            return
        end

        SetArmyOutOfGame(self:GetArmyIndex())


        if math.floor(self:GetArmyStat("Recall",0.0).Value) != 1 and math.floor(self:GetArmyStat("FAFWin",0.0).Value) == 0 then
        
            if math.floor(self:GetArmyStat("FAFLose",0.0).Value) != -1 then
                self:AddArmyStat("FAFLose", -1)
            end
            
            local result = string.format("%s %i", "defeat", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
            table.insert( Sync.GameResult, { self:GetArmyIndex(), result } )
            
            # Score change, we send the score of all other players, yes mam !
            for index, brain in ArmyBrains do
                if brain and not brain:IsDefeated() then
                    local result = string.format("%s %i", "score", math.floor(brain:GetArmyStat("FAFWin",0.0).Value + brain:GetArmyStat("FAFLose",0.0).Value) )
                    table.insert( Sync.GameResult, { index, result } )
                end
            end       
        end
        
        import('/lua/SimUtils.lua').UpdateUnitCap(self:GetArmyIndex())
        import('/lua/SimPing.lua').OnArmyDefeat(self:GetArmyIndex())
        
        local function KillArmy()
            local allies = {}
            local selfIndex = self:GetArmyIndex()
            WaitSeconds(20)
         
            ##this part determines who the allies are 
            for index, brain in ArmyBrains do
                brain.index = index
                brain.score = brain:CalculateScore()
                if IsAlly(selfIndex, brain:GetArmyIndex()) and selfIndex != brain:GetArmyIndex() and not brain:IsDefeated() then
                    table.insert(allies, brain)
                end
            end
            ##This part determines which ally has the highest score and transfers ownership of all units to him
            if table.getn(allies) > 0 then
                table.sort(allies, function(a,b) return a.score > b.score end)
                for k,v in allies do                
                    local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
                    if units and table.getn(units) > 0 then
                        TransferUnitsOwnership(units, v.index)
                    end
                end
            end            

            local killacu = self:GetListOfUnits(categories.COMMAND, false)
            if killacu and table.getn(killacu) > 0 then
                for index,unit in killacu do
                    unit:Recall()
                end
            end
        end
        ForkThread(KillArmy)
        ##For Sorian AI bit 2
        if self.BuilderManagers then
            self.ConditionsMonitor:Destroy()
            for k,v in self.BuilderManagers do
                v.EngineerManager:SetEnabled(false)
                v.FactoryManager:SetEnabled(false)
                v.PlatoonFormManager:SetEnabled(false)
                v.StrategyManager:SetEnabled(false)
                v.FactoryManager:Destroy()
                v.PlatoonFormManager:Destroy()
                v.EngineerManager:Destroy()
                v.StrategyManager:Destroy()
            end
        end
        if self.Trash then
            self.Trash:Destroy()
        end
        ###end Sorian AI bit 2
    end,
    
    OnVictory = function(self)
        self:AddArmyStat("FAFWin", 1) 
        local result = string.format("%s %i", "victory", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
        table.insert( Sync.GameResult, { self:GetArmyIndex(), result } )
        
        # Score change, we send the score of all other players, yes mam !
        for index, brain in ArmyBrains do
            if brain and not brain:IsDefeated() then
                local result = string.format("%s %i", "score", math.floor(brain:GetArmyStat("FAFWin",0.0).Value + brain:GetArmyStat("FAFLose",0.0).Value) )
                table.insert( Sync.GameResult, { index, result } )
            end
        end
        

    end,

    OnDraw = function(self)
        local result = string.format("%s %i", "draw", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
        table.insert(Sync.GameResult, { self:GetArmyIndex(), result })
    end,
    --]]
    IsSupport = function(self)
        return self.support
    end,

    AbandonedByPlayer = function(self)
        if not IsGameOver() then
            local killacu = self:GetListOfUnits(categories.COMMAND, false)
            if killacu and table.getn(killacu) > 0 then
                for index,unit in killacu do
                    unit:Recall()
                end
            end
        end
    end,

    OnRecall = function(self)
        local result = string.format("%s %i", "recall", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
        table.insert( Sync.GameResult, { self:GetArmyIndex(), result } )
        self:AddArmyStat("Recall", 1)
    end,

    OnAutoRecall = function(self)
        local result = string.format("%s %i", "autorecall", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
        table.insert( Sync.GameResult, { self:GetArmyIndex(), result } )
        self:AddArmyStat("Recall", 1)
    end,

    AddReinforcements = function(self, list)
        local army = self:GetArmyIndex()
        AddReinforcementList(army, list)
        StartAbilityCoolDown(army, 'CallReinforcement_' .. list.group)
    end,

    ReinforcementsCalled = function(self, group)
        DisableSpecialAbility(self:GetArmyIndex(), 'CallReinforcement_' .. group)
        table.insert(Sync.ReinforcementCalled, {self:GetArmyIndex(), group })
    end,

    AddSpecialAbilityUnit = function(self, unit, type, autoEnable)
        local unitId = unit:GetEntityId()
        if AbilityDefinition[type] then
            if not self.SpecialAbilityUnits[type] then
                self.SpecialAbilityUnits[type] = {}
            end

            table.insert(self.SpecialAbilityUnits[type], unitId)
            SetAbilityUnits(self:GetArmyIndex(), type, self:GetSpecialAbilityUnitIds(type))

            if autoEnable and table.getn(self.SpecialAbilityUnits[type]) == 1 then
                self:EnableSpecialAbility(type, true)
            end
        end
    end,

    RemoveSpecialAbilityUnit = function(self, unit, type, autoDisable)
        if self.SpecialAbilityUnits[type] then
            local unitId = unit:GetEntityId()
            table.removeByValue(self.SpecialAbilityUnits[type], unitId)
            SetAbilityUnits(self:GetArmyIndex(), type, self:GetSpecialAbilityUnitIds(type))

            if autoDisable and table.getn(self.SpecialAbilityUnits[type]) < 1 then
                self:EnableSpecialAbility(type, false)
            end
        end
    end,

    EnableSpecialAbility = function(self, type, enable)
        if AbilityDefinition[type].enabled == false then
            WARN('Ability "' .. repr(type) .. '" is disabled in abilitydefinition file')
            return false
        else
            if not self.SpecialAbilities[type] then
                self.SpecialAbilities[type] = {}

                if AbilityDefinition[type]['ExtraInfo'] then
                    for k, v in AbilityDefinition[type]['ExtraInfo'] do
                        self:SetSpecialAbilityParam(type, k, v)
                    end
                end
            end
            enable = enable and true

            if self:IsSpecialAbilityEnabled(type) == nil or self:IsSpecialAbilityEnabled(type) ~= enable then
                local army = self:GetArmyIndex()
                self.SpecialAbilities[type]['enabled'] = enable

                if enable then
                    AddSpecialAbility(army, type)
                else
                    RemoveSpecialAbility(army, type)
                end
            end
        end
    end,

    GetSpecialAbilityUnits = function(self, type)
        if self.SpecialAbilityUnits[type] then
            local units = {}
            local remove = {}

            -- compile list of units in this type of special ability
            for k, v in self.SpecialAbilityUnits[type] do
                local unit = GetEntityById(v)
                if unit and not unit:BeenDestroyed() then
                    table.insert(units, unit)
                else
                    table.insert(remove, v)
                end
            end

            -- remove bad entries from the table so we won't get them next time
            for k, v in remove do
                table.removeByValue(self.SpecialAbilityUnits[type], v)
            end

            return units
        end
    end,

    GetSpecialAbilityUnitIds = function(self, type)
        self:GetSpecialAbilityUnits(type)  -- only for cleaning up the table, not interested in the results of this call
        return self.SpecialAbilityUnits[type]
    end,

    IsSpecialAbilityEnabled = function(self, type)
        if self.SpecialAbilities[type] then
            return self.SpecialAbilities[type]['enabled']
        end
    end,

    SetSpecialAbilityParam = function(self, type, parameter, value)
        -- set and/or change a parameter for the special ability. Returns old value (could be nil if previously not set)
        if parameter ~= 'enabled' then
            local old
            if self.SpecialAbilities[type][parameter] then
                old = self.SpecialAbilities[type][parameter]
            end

            self.SpecialAbilities[type][parameter] = value
            return old
        else
            WARN('AIBrain: SetSpecialAbilityParam(): cant set parameter "' .. parameter .. '" this way!')
        end
    end,

    GetSpecialAbilityParam = function(self, type, param1, param2)
        local r
        if type and param1 and self.SpecialAbilities[type][param1] then
            if param2 and self.SpecialAbilities[type][param1][param2] then
                r = self.SpecialAbilities[type][param1][param2]
            else
                r = self.SpecialAbilities[type][param1]
            end
        end
        return r
    end,
}