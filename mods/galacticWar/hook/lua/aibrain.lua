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

            local cheatPos = string.find(per, 'cheat')
            if cheatPos then
                AIUtils.SetupCheat(self, true)
                ScenarioInfo.ArmySetup[self.Name].AIPersonality = string.sub(per, 1, cheatPos - 1)
            end

            LOG('* OnCreateAI: AIPersonality: ('..per..')')
            if string.find(per, 'sorian') then
                self.Sorian = true
            end
            if string.find(per, 'uveso') then
                self.Uveso = true
            end
            if string.find(per, 'dilli') then
                self.Dilli = true
            end
            if DiskGetFileInfo('/lua/AI/altaiutilities.lua') then
                self.Duncan = true
            end

            self.CurrentPlan = self.AIPlansList[self:GetFactionIndex()][1]
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

            -- Flag enemy starting locations with threat?
            if ScenarioInfo.type == 'skirmish' then
                if self.Sorian then
                    -- Gives the initial threat a type so initial land platoons will actually attack it.
                    self:AddInitialEnemyThreatSorian(200, 0.005, 'Economy')
                else
                    self:AddInitialEnemyThreat(200, 0.005)
                end
            end
        end
        self.UnitBuiltTriggerList = {}
        self.FactoryAssistList = {}
        self.DelayEqualBuildPlattons = {}
        self.BrainType = 'AI'
    end,

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
        self:AddArmyStat("Recall", 1)
        self.Recalled = true
    end,

    OnAutoRecall = function(self)
        self:SetResult("autorecall")
        self:AddArmyStat("Recall", 1)

        -- Handle the rest as if the player died
        self:OnDefeat()
    end,

    AddReinforcements = function(self, list)
        local army = self:GetArmyIndex()
        AddReinforcementList(army, list)
        StartAbilityCoolDown(army, 'CallReinforcement_' .. list.group)
    end,

    ReinforcementsCalled = function(self, group, groupId)
        DisableSpecialAbility(self:GetArmyIndex(), 'CallReinforcement_' .. group)
        table.insert(Sync.ReinforcementCalled, {self:GetArmyIndex(), groupId })
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

    GetStartVector3f = function(self)
        local startX, startZ = self:GetArmyStartPos()
        return {startX, 0, startZ}
    end,
}