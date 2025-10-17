local AbilityDefinition = import('/lua/abilitydefinition.lua').abilities

---@type AIBrain
local oldAIBrain = AIBrain ---@diagnostic disable-line: undefined-global
local oldOnCreateHuman = oldAIBrain.OnCreateHuman

---@class GwAIBrain: AIBrain
---@field SpecialAbilities table GW Addition
---@field SpecialAbilityUnits table GW Addition
---@field Support boolean Is this a GW support army?
AIBrain = Class(oldAIBrain) {
    ---@param self GwAIBrain
    ---@param planName any
    OnCreateHuman = function(self, planName)
        oldOnCreateHuman(self, planName)

        self.Support = false
        self.SpecialAbilities = {}
        self.SpecialAbilityUnits = {}
    end,

    ---@param self GwAIBrain
    ---@param planName any
    OnCreateAI = function(self, planName)
        self:CreateBrainShared(planName)

        self.SpecialAbilities = {}
        self.SpecialAbilityUnits = {}

        --LOG('*AI DEBUG: AI planName = ', repr(planName))
        --LOG('*AI DEBUG: SCENARIO AI PLAN LIST = ', repr(aiScenarioPlans))
        local civilian = false
        for name,data in ScenarioInfo.ArmySetup do
            if name == self.Name then
                civilian = data.Civilian
                if data.Support then -- GW Addition
                    self.Support = data.Support
                end
                break
            end
        end
        if not civilian and not self.Support then -- GW Addition: and not self.Support
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

    ---@param self GwAIBrain
    ---@return boolean
    IsSupport = function(self)
        return self.Support
    end,

    ---@param self GwAIBrain
    AbandonedByPlayer = function(self)
        if not IsGameOver() then
            ---@type GwACUUnit[]
            local acus = self:GetListOfUnits(categories.COMMAND, false)
            for _, unit in pairs(acus) do
                unit:Recall()
            end
        end
    end,

    ---@param self GwAIBrain
    OnRecall = function(self)
        self:AddArmyStat("Recall", 1)
        self.Recalled = true
    end,

    ---@param self GwAIBrain
    OnAutoRecall = function(self)
        self:SetResult("autorecall")
        self:AddArmyStat("Recall", 1)

        -- Handle the rest as if the player died
        self:OnDefeat()
    end,

    ---@param self GwAIBrain
    ---@param group ReinforcementTransportGroup
    AddReinforcements = function(self, group)
        local army = self:GetArmyIndex()
        AddReinforcementList(army, group)
        StartAbilityCoolDown(army, 'CallReinforcement_' .. group.group)
    end,

    ---@param self GwAIBrain
    ---@param group integer
    ---@param groupId integer
    ReinforcementsCalled = function(self, group, groupId)
        DisableSpecialAbility(self:GetArmyIndex(), 'CallReinforcement_' .. group)
        table.insert(Sync.ReinforcementCalled, {self:GetArmyIndex(), groupId })
    end,

    ---@param self GwAIBrain
    ---@param unit Unit
    ---@param type string
    ---@param autoEnable boolean
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

    ---@param self GwAIBrain
    ---@param unit Unit
    ---@param type string
    ---@param autoDisable boolean
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

    ---@param self GwAIBrain
    ---@param type string
    ---@param enable boolean
    EnableSpecialAbility = function(self, type, enable)
        if AbilityDefinition[type].enabled == false then
            WARN('Ability "' .. repr(type) .. '" is disabled in abilitydefinition file')
            return
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

    ---@param self GwAIBrain
    ---@param type string
    ---@return Unit[]
    GetSpecialAbilityUnits = function(self, type)
        local units = {}
        if self.SpecialAbilityUnits[type] then
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
        end
        return units
    end,

    ---@param self GwAIBrain
    ---@param type any
    ---@return unknown
    GetSpecialAbilityUnitIds = function(self, type)
        self:GetSpecialAbilityUnits(type)  -- only for cleaning up the table, not interested in the results of this call
        return self.SpecialAbilityUnits[type]
    end,

    ---@param self GwAIBrain
    ---@param type any
    ---@return boolean
    IsSpecialAbilityEnabled = function(self, type)
        if self.SpecialAbilities[type] then
            return self.SpecialAbilities[type]['enabled']
        end
        return false
    end,

    ---@param self GwAIBrain
    ---@param type any
    ---@param parameter any
    ---@param value any
    ---@return unknown
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

    ---@param self GwAIBrain
    ---@param type any
    ---@param param1 any
    ---@param param2 any
    ---@return unknown
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

    ---@param self GwAIBrain
    ---@return table
    GetStartVector3f = function(self)
        local startX, startZ = self:GetArmyStartPos()
        return {startX, 0, startZ}
    end,
}