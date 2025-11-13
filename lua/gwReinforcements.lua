local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioTriggers = import('/lua/scenariotriggers.lua')
local SimUtils = import('/lua/SimUtils.lua')
local Utilities = import('/lua/utilities.lua')
---@type ReinforcementList
local ReinforcementList =  import('/lua/gwReinforcementList.lua').gwReinforcements

local pairs, ipairs = pairs, ipairs
local GetArmyBrain = GetArmyBrain
local Random = Random
local WaitSeconds = WaitSeconds

-- {Number of Tech 3, 2, 1 units that can fit into the transport}
local TransportInfo = {
    {14, 6, 3, bpID = 'UEA0104'}, -- UEF
    {12, 6, 3, bpID = 'UAA0104'}, -- Aeon
    {10, 4, 2, bpID = 'URA0104'}, -- Cybran
    {16, 8, 4, bpID = 'XSA0104'}, -- Seraphim
}

local armySupport = {}
local armySupportIndex = {}

local factions = {1, 1}
local teams = {-1, -1}

---@class ReinforcementGroupBase
---@field playerId integer
---@field avatarName string
---@field delay integer Delay in second before this group can be used
---@field unitNames BlueprintId[] List of units this group contains

---@class ReinforcementInitialStructuresGroup: ReinforcementGroupBase

---@class ReinforcementInitialUnitsGroup: ReinforcementGroupBase

---@class ReinforcementPeriodicGroup: ReinforcementGroupBase
---@field period integer Period in second between respawning the group

---@class ReinforcementTransportGroup: ReinforcementGroupBase
---@field delay integer Delay in second before it can be called
---@field groupId integer Unique ID of a group
---@field called boolean Whenever this group was already used or not
---@field group integer Index of the group of player's group

---@class ReinforcementList
---@field initialStructure ReinforcementInitialStructuresGroup[]
---@field initialUnitWarp ReinforcementInitialUnitsGroup[]
---@field periodicUnitWarp ReinforcementPeriodicGroup[]
---@field passiveItems table
---@field transportedUnits ReinforcementTransportGroup[]


---@class GwBeaconUnit: StructureUnit
---@field ACU GwACUUnit
---@field Faction integer
---@field Team integer
---@field NearestOffMapLocation Vector

---@class GwACUUnit: ACUUnit
---@field ReinforcementsBeacon GwBeaconUnit?
---@field ReinforcementTransportGroups ReinforcementTransportGroup[]

---@alias ArmySetup table<string, ArmyInfo>

---@class ArmyInfo
---@field ArmyColor integer
---@field ArmyIndex integer
---@field ArmyName string
---@field Civilian boolean
---@field Faction integer
---@field Human boolean
---@field OwnerID string PeerId (faf_id or gw_player_id) as string
---@field PlayerColor integer
---@field PlayerName string
---@field Support boolean
---@field Team integer


---@param unit Unit
local function spawnOutEffect(unit)
    unit:PlayUnitSound('TeleportStart')
    unit:PlayUnitAmbientSound('TeleportLoop')
    WaitSeconds( 0.1 )
    unit:PlayTeleportInEffects()
    WaitSeconds( 0.1 )
    unit:StopUnitAmbientSound('TeleportLoop')
    unit:PlayUnitSound('TeleportEnd')

    local cargo = unit:GetCargo()
    for _, v in cargo do
        if not v.Dead then
            v:Destroy()
        end
    end

    unit:Destroy()
end

local DespawnDistanceTollerance = 10

---Returns a nearest position to the offmap area for given beacon
---@param beacon GwBeaconUnit
---@return Vector
local function calculateNearestOffMapLocation(beacon)
    local PlayableArea = ScenarioInfo.PlayableArea
    if not PlayableArea then
        WARN('scenarioinfo.playableArea not found')
    end
    local BeaconPosition = beacon:GetPosition()
    local NearestOffMapLocation = {}

    local corner1 = {ScenarioInfo.PlayableArea[1], ScenarioInfo.PlayableArea[2], 0}
    local corner2 = {ScenarioInfo.PlayableArea[3], ScenarioInfo.PlayableArea[2], 0}
    local corner3 = {ScenarioInfo.PlayableArea[3], ScenarioInfo.PlayableArea[4], 0}
    local corner4 = {ScenarioInfo.PlayableArea[1], ScenarioInfo.PlayableArea[4], 0}

    -- Are we closer to top or bottom?
    local vert = {}
    local hori = {}
    vert = {BeaconPosition[1] + Random(-20, 20), BeaconPosition[2], ScenarioInfo.PlayableArea[4]}
    if VDist3(corner1,BeaconPosition) < VDist3(corner4,BeaconPosition) then
        --we are closer to top
        vert = {BeaconPosition[1] + Random(-20, 20), BeaconPosition[2], ScenarioInfo.PlayableArea[2]}
    end

    -- Are we closer to left or right?
    hori = {ScenarioInfo.PlayableArea[3], BeaconPosition[2], BeaconPosition[3] + Random(-20, 20)}
    if VDist3(corner1,BeaconPosition) < VDist3(corner2,BeaconPosition) then
        --we are closer to left
        hori = {ScenarioInfo.PlayableArea[1], BeaconPosition[2], BeaconPosition[3] + Random(-20, 20)}
    end 

    -- what is the closer spawn location, horizontal or vertical?
    NearestOffMapLocation = hori
    if VDist3(vert,BeaconPosition) < VDist3(hori,BeaconPosition) then
        --we are closer to the computed vertical
        NearestOffMapLocation = vert
    end

    --WARN('calculated nearestoffmaplocation, it is ' .. repr(NearestOffMapLocation))
    return NearestOffMapLocation
end

---@param counter integer
---@param position Vector
---@return Vector
local function calculateBuildLocationByCounterAndPosition(counter, position)
    local xOffSet = 0
    local zOffSet = 0
    local AngleOfOffset = (counter * 30)
    local DistanceOfOffset = (counter)

    if DistanceOfOffset < 4 then 
        DistanceOfOffset = 4
    end

    xOffSet = (math.sin(counter) * DistanceOfOffset)
    zOffSet = (math.cos(counter) * DistanceOfOffset)

    --WARN('x and z offsets and angle and distance are ' .. repr(xOffSet) .. ' and ' .. repr(zOffSet) .. ' and ' .. repr(AngleOfOffset) .. ' and ' .. repr(DistanceOfOffset))

    return {(position[1] + xOffSet), (position[3] + zOffSet), 0}
end

local function callTransportToCarryMeAway(self, transportBPid)
    --WARN('starting carry me away function with transportID and name ' .. repr(transportBPid) .. ' and ' .. repr(self:GetAIBrain().Name))
    local NearestOffMapLocation = calculateNearestOffMapLocation(self)
    local transport = CreateUnitHPR(transportBPid, self:GetAIBrain().Name, NearestOffMapLocation[1], NearestOffMapLocation[2], NearestOffMapLocation[3], 0, 0, 0)
    transport.CanTakeDamage = false
    transport:SetUnSelectable(true)
    transport:SetDoNotTarget(true)

    IssueTransportLoad({self}, transport)
    IssueMove({transport}, NearestOffMapLocation)

    WaitSeconds(10)

    ScenarioTriggers.CreateUnitToPositionDistanceTrigger(spawnOutEffect, transport, NearestOffMapLocation, DespawnDistanceTollerance)
end

---@param engineer ConstructionUnit
---@param transportBpId BlueprintId
local function modEngineer(engineer, transportBpId)
    engineer.CanIBuild = true
    engineer.transportBPid = transportBpId
    engineer.OldOnStopBuild = engineer.OnStopBuild
    engineer.CallTransportToCarryMeAway = callTransportToCarryMeAway
    engineer.OnStopBuild = function(self, unitBeingBuilt)
        SimUtils.TransferUnitsOwnership({unitBeingBuilt}, self.TransferToArmyId --[[@as integer]])
        if not self.HaveCalledTransport then
            self.HaveCalledTransport = true
            self:ForkThread(self.CallTransportToCarryMeAway, self.transportBPid)
        end
        self.OldOnStopBuild(self,unitBeingBuilt)
    end
    engineer.OldOnStartBuild = engineer.OnStartBuild
    engineer.OnStartBuild = function(self, unitBeingBuilt, order)
        if not self.CanIBuild then 
            unitBeingBuilt:Destroy()
        end
        self.CanIBuild = false
        self.OldOnStartBuild(self, unitBeingBuilt, order)
    end
end

---@param EngineerBPid BlueprintId
---@param StructureBPid BlueprintId
---@param TransportBPid BlueprintId
---@param BuildLocation Vector
---@param beacon GwBeaconUnit
---@param group integer
---@param groupId integer
local function spawnEngineerAndTransportAndBuildTheStructure(EngineerBPid, StructureBPid, TransportBPid, BuildLocation, beacon, group, groupId)
    local position = calculateNearestOffMapLocation(beacon)
    local engineer = CreateUnitHPR(EngineerBPid, armySupport[beacon.Team], position[1], position[2], position[3],0,0,0) --[[@as ConstructionUnit]]
    engineer.ArmyName = armySupport[beacon.Team]
    engineer.TransferToArmyId = beacon.Army
    engineer:SetProductionActive(true)
    WaitSeconds(0.1)
    engineer:SetProductionPerSecondEnergy(10000)
    engineer:SetProductionPerSecondMass(500)
    WaitSeconds(0.1)

    local transport = CreateUnitHPR(TransportBPid, armySupport[beacon.Team], position[1], position[2], position[3],0,0,0)
    local aiBrain = engineer:GetAIBrain()
    local Transports = aiBrain:MakePlatoon('', '')
    aiBrain:AssignUnitsToPlatoon(Transports, {transport}, 'Support', 'None')
    ScenarioFramework.AttachUnitsToTransports({engineer}, {transport})

    local beaconPosition = beacon:GetPosition()
    beaconPosition.x = beaconPosition.x + Random(-10,10)
    beaconPosition.z = beaconPosition.z + Random(-10,10)

    cmd = Transports:MoveToLocation(beaconPosition, false)
    if cmd then
        beacon.AiBrain:ReinforcementsCalled(group, groupId)
        while Transports:IsCommandsActive(cmd) do
            WaitSeconds(1)
            if not aiBrain:PlatoonExists(Transports) then
                break
            end
        end
    end

    Transports:UnloadAllAtLocation(beaconPosition)
    transport:SetUnSelectable(true)
    engineer:SetUnSelectable(true)

    WaitSeconds(5)

    if not transport.Dead then
        Transports:MoveToLocation(position, false)
    end

    if not engineer.Dead then
        aiBrain:BuildStructure(engineer, StructureBPid, BuildLocation)
        modEngineer(engineer, TransportBPid)
    end

    ScenarioTriggers.CreateUnitToPositionDistanceTrigger(spawnOutEffect, transport, position, DespawnDistanceTollerance)
end

---@param transportBpId BlueprintId
---@param units Unit[]
---@param NearestOffMapLocation Vector
---@param beacon GwBeaconUnit
---@param group integer
---@param groupId integer
local function spawnTransportAndIssueDrop(transportBpId, units, NearestOffMapLocation, beacon, group, groupId)
    --WARN('spawning transport, bpid and army are ' .. repr(transportBPid) .. ' and ' .. repr(beacon.ArmyName))
    local transport = CreateUnitHPR(transportBpId, armySupport[beacon.Team], NearestOffMapLocation[1], NearestOffMapLocation[2], NearestOffMapLocation[3], 0, 0, 0)

    transport.OldOnTransportDetach = transport.OnTransportDetach

    transport.OnTransportDetach = function(self, attachBone, unit)
        SimUtils.TransferUnitsOwnership( {unit}, beacon.Army--[[@as integer]])
        self.OldOnTransportDetach(self, attachBone, unit)
    end 

    transport.OffMapExcempt = true
    transport:SetUnSelectable(true)
    transport:SetFireState(1)

    local aiBrain = transport:GetAIBrain()
    local Transports = aiBrain:MakePlatoon('', '')
    aiBrain:AssignUnitsToPlatoon(Transports, {transport}, 'Support', 'None')

    ScenarioFramework.AttachUnitsToTransports(units, {transport})
    local beaconPosition = beacon:GetPosition()

    beaconPosition.x = beaconPosition.x + Random(-10, 10)
    beaconPosition.z = beaconPosition.z + Random(-10, 10)

    cmd = Transports:MoveToLocation(beaconPosition, false)

    beacon.AiBrain:ReinforcementsCalled(group, groupId)
    if cmd then
        while Transports:IsCommandsActive(cmd) do
            WaitSeconds(1)
            if not aiBrain:PlatoonExists(Transports) then
                break
            end
        end
    end

    Transports:UnloadAllAtLocation(beaconPosition)

    WaitSeconds(5)
    if not transport.Dead then
        Transports:MoveToLocation(NearestOffMapLocation, false)
    end

    ScenarioTriggers.CreateUnitToPositionDistanceTrigger(spawnOutEffect, transport, NearestOffMapLocation, DespawnDistanceTollerance)
end

---@param beacon GwBeaconUnit
---@param bpIds BlueprintId[]
---@param group integer
---@param groupId integer
local function spawnTransportedReinforcements(beacon, bpIds, group, groupId)
    local NearestOffMapLocation = beacon.NearestOffMapLocation
    ---@type Unit[][]
    local UnitsToTransport = {
        {},
        {},
        {}
    }

    local NumberOfTransportsNeeded = 0

    --this spawns our units
    for _, bpId in ipairs(bpIds) do
        local newUnit = CreateUnitHPR(bpId, armySupport[beacon.Team], NearestOffMapLocation[1], NearestOffMapLocation[2], NearestOffMapLocation[3], 0, 0, 0)
        local TransportClass = newUnit:GetBlueprint().Transport.TransportClass
        table.insert(UnitsToTransport[TransportClass], newUnit)
    end

    --this should spawn transports and attach untis to them
    for techLevel = 1, 3 do
        local TransportCapacity = TransportInfo[beacon.Faction][techLevel]
        local counter = 0
        local LoadForThisTransport = {}
        for _, unit in ipairs(UnitsToTransport[techLevel]) do
            counter = counter + 1
            table.insert(LoadForThisTransport, unit)
            --if we reached max load for one transport, spawn it, load unit, set orders, start counting again 
            if counter == TransportCapacity then
                ForkThread(spawnTransportAndIssueDrop, TransportInfo[beacon.Faction].bpID, LoadForThisTransport, NearestOffMapLocation, beacon, group, groupId)
                counter = 0
                LoadForThisTransport = {}
            end
        end
        --this is to make sure we spawn a transport even if we don't have enough units to completely fill one up'
        if counter > 0 then
            ForkThread(spawnTransportAndIssueDrop, TransportInfo[beacon.Faction].bpID, LoadForThisTransport, NearestOffMapLocation, beacon, group, groupId)
        end
    end

    --this will calculate how many T2 transports we need based upon how many units we have
    --there doesn't appear to be a way to do this quickly, so we're just going to add 1 for every 2 class 3 units, 1 for every 6 class 2 units, and 1 for every 12 class 1 units
end

---@param beacon GwBeaconUnit
---@param bpIds BlueprintId[]
---@param group integer
---@param groupId integer
local function callEngineersToBeacon(beacon, bpIds, group, groupId)
    --bring in units + engineers + etc
    beacon.AiBrain = beacon:GetAIBrain()
    beacon.ArmyName = beacon.AiBrain.Name
    beacon.Team = ScenarioInfo.ArmySetup[beacon.ArmyName].Team

    beacon.NearestOffMapLocation = calculateNearestOffMapLocation(beacon)

    local EngineersToSpawnAndOrdersAndTransport = {}

    for _, sbpId in ipairs(bpIds) do
        if GetUnitBlueprintByName(sbpId).General.FactionName == 'Aeon' then
            table.insert(EngineersToSpawnAndOrdersAndTransport, {'UAL0309',sbpId, 'UAA0107'})
        elseif GetUnitBlueprintByName(sbpId).General.FactionName == 'UEF' then
            table.insert(EngineersToSpawnAndOrdersAndTransport, {'UEL0309',sbpId, 'UEA0107'})
        elseif GetUnitBlueprintByName(sbpId).General.FactionName == 'Cybran' then
            table.insert(EngineersToSpawnAndOrdersAndTransport, {'URL0309',sbpId, 'URA0107'})
        elseif GetUnitBlueprintByName(sbpId).General.FactionName == 'Seraphim' then
            table.insert(EngineersToSpawnAndOrdersAndTransport, {'XSL0309',sbpId, 'XSA0107'})
        end
    end

    for i, data in ipairs(EngineersToSpawnAndOrdersAndTransport) do
        local BuildLocation = calculateBuildLocationByCounterAndPosition(i, beacon:GetPosition())
        ForkThread(spawnEngineerAndTransportAndBuildTheStructure,data[1], data[2], data[3], BuildLocation, beacon, group, groupId)
    end
end

---@param beacon GwBeaconUnit
---@param bpIds BlueprintId[]
---@param group integer
---@param groupId integer
local function callReinforcementsToBeacon(beacon, bpIds, group, groupId)
    beacon.AiBrain = beacon:GetAIBrain()
    beacon.ArmyName = beacon.AiBrain.Name
    beacon.Team = ScenarioInfo.ArmySetup[beacon.ArmyName].Team
    --WARN('gwReinforcementList.TransportedUnits is ' .. repr(ScenarioInfo.gwReinforcementList.transportedUnits))

    beacon.UnitReinforcementsToCall = bpIds

    beacon.NearestOffMapLocation = calculateNearestOffMapLocation(beacon)
    --WARN('beacon.UnitReinforcementsToCall is ' .. repr(beacon.UnitReinforcementsToCall))
    if beacon.UnitReinforcementsToCall then
        spawnTransportedReinforcements(beacon, beacon.UnitReinforcementsToCall, group, groupId)
    end
end

---Deletes the reinforcement beacon if it exists
---@param ACU GwACUUnit
local function despawnBeacon(ACU)
    if ACU.ReinforcementsBeacon and not ACU.ReinforcementsBeacon.Dead then
        local BeaconPosition = ACU.ReinforcementsBeacon:GetPosition()
        local TeleportToPosition = {-1000, BeaconPosition[2], -1000}  --far off-map

        ACU.ReinforcementsBeacon:PlayTeleportOutEffects()
        Warp(ACU.ReinforcementsBeacon, TeleportToPosition, ACU.ReinforcementsBeacon:GetOrientation())
        ACU.ReinforcementsBeacon:Destroy()
    end

    ACU.ReinforcementsBeacon = nil
end

---@param ACU GwACUUnit
---@param beacon GwBeaconUnit
local function modBeacon(ACU, beacon)
    beacon.ACU = ACU
    if EntityCategoryContains(categories.UEF, ACU) then
        beacon.Faction = 1
    elseif EntityCategoryContains(categories.AEON, ACU) then
        beacon.Faction = 2
    elseif EntityCategoryContains(categories.CYBRAN, ACU) then
        beacon.Faction = 3
    elseif EntityCategoryContains(categories.SERAPHIM, ACU) then
        beacon.Faction = 4
    end

    ---@param self GwBeaconUnit
    ---@param index integer
    beacon.Deploy = function(self, index)
        LOG("deploying index " .. index)

        local toRemove = {}
        curTime = GetGameTimeSeconds()
        for i, group in pairs(self.ACU.ReinforcementTransportGroups) do
            if group.group == index and group.delay <= curTime then
                ---@type BlueprintId[]
                local mobileUnits = {}
                ---@type BlueprintId[]
                local structures = {}
                -- split between units & building
                for _, bpId in ipairs(group.unitNames) do
                    local bp = GetUnitBlueprintByName(bpId)
                    if bp.CategoriesHash then
                        if bp.CategoriesHash["STRUCTURE"] then
                            table.insert(structures, bpId)
                        else
                            table.insert(mobileUnits, bpId)
                        end
                    end
                end

                if table.getn(mobileUnits) > 0 then
                    callReinforcementsToBeacon(self, mobileUnits, group.group, group.groupId)
                end

                if table.getn(structures) > 0 then
                    callEngineersToBeacon(self, structures, group.group, group.groupId)
                end
                table.insert(toRemove, i)
            end
        end

        for _, idx in toRemove do
            table.remove(self.ACU.ReinforcementTransportGroups, idx)
        end
    end
end

---this function check all passive items.
---@param ACU CommandUnit
local function checkPassiveItems(ACU)
    local brain = ACU:GetAIBrain()
    local playerId
    for ArmyName, Army in ScenarioInfo.ArmySetup do
        if ArmyName == brain.Name then
            playerId = tonumber(Army.OwnerID)
            break
        end
    end
    for _, List in ScenarioInfo.gwReinforcementList.passiveItems do
        if List.playerId == playerId then
            if List.itemNames then
                for _, itemname in List.itemNames do
                    if itemname == "autorecall" then
                        ACU:AddAutoRecall()
                    end
                end
            end
        end
    end
end

---this function check all the units delay to spawn them.
---@param ACU GwACUUnit
local function checkUnitsDelay(ACU)
    ACU.ReinforcementTransportGroups = {}
    local brain = ACU:GetAIBrain() --[[@as GwAIBrain]]
    local playerId

    for ArmyName, Army in ScenarioInfo.ArmySetup do
        if ArmyName == brain.Name then
            playerId = tonumber(Army.OwnerID) or -1
            break
        end
    end

    for _, group in ipairs(ScenarioInfo.gwReinforcementList.transportedUnits) do
        if group.playerId == playerId then
            brain:AddReinforcements(group)
            table.insert(ACU.ReinforcementTransportGroups, group)
        end
    end
end

---@param ACU GwACUUnit
local function modHumanACU(ACU)
    ACU.OldOnStartBuild = ACU.OnStartBuild
    ACU.DespawnBeacon = despawnBeacon
    ACU.ModBeacon = modBeacon
    ACU.OnStartBuild = function(self, unitBeingBuilt, order)
        if EntityCategoryContains(categories.REINFORCEMENTSBEACON, unitBeingBuilt) then
            ACU:DespawnBeacon()
            ACU.ReinforcementsBeacon = unitBeingBuilt
            ACU:ModBeacon(ACU.ReinforcementsBeacon)
        end
        self.OldOnStartBuild(self, unitBeingBuilt, order)
    end
    checkUnitsDelay(ACU)
    checkPassiveItems(ACU)
end

---Spawn an initial reinforcement structure for army
---@param group ReinforcementInitialStructuresGroup
---@param armyInfo ArmyInfo
local function initialStructuresSpawnThread(group, armyInfo)
    local delay = group.delay
    local bpIds = group.unitNames

    local aiBrain = GetArmyBrain(armyInfo.ArmyIndex)
    local posX, posY = aiBrain:GetArmyStartPos()

    WaitSeconds(1)

    for _, bpId in ipairs(bpIds) do
        local unit = aiBrain:CreateUnitNearSpot(bpId, posX, posY) --[[@as StructureUnit]]
        if not unit then
            WARN(string.format("GW Reinforcements: Failed to create initial strucure: %s for army: %s", bpId, tostring(aiBrain.Army)))
            continue
        end
        unit:SetReclaimable(false)

        -- Set reclaim to 1 mass to avoid eco boosting
        local oldCreateWreckageProp = unit.CreateWreckageProp
        unit.CreateWreckageProp = function(self, overkillRatio)
            local prop = oldCreateWreckageProp(self, overkillRatio)
            prop:SetMaxReclaimValues(1, 1, 0)
        end

        if delay > 0 then
            unit:InitiateActivation(delay)
        end

        if unit ~= nil and unit:GetBlueprint().Physics.FlattenSkirt then
            unit:CreateTarmac(true, true, true)
        end
    end
end

---Spaws all initial reinforcement structures for all armies
---@param structureGroups ReinforcementInitialStructuresGroup[]
---@param armySetup ArmySetup
local function spawnInitialStructures(structureGroups, armySetup)
    for _, group in ipairs(structureGroups) do
        for _, armyInfo in pairs(armySetup) do
            if tonumber(armyInfo.OwnerID) == group.playerId then
                ForkThread(initialStructuresSpawnThread, group, armyInfo)
            end
        end
    end
end

---@param bpIds BlueprintId[]
---@param armyId Army
---@param position Vector
local function spawnUnitsWithTeleportInEffect(bpIds, armyId, position)
    for _, bpId in ipairs(bpIds) do
        local NewUnit = CreateUnitHPR(bpId, armyId, position[1], position[2], position[3], 0, 0, 0)
        NewUnit:PlayTeleportInEffects()
        NewUnit:CreateProjectile('/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
    end
end

---Spawn a reinforcement units periodically after their set delay
---@param group ReinforcementPeriodicGroup
---@param armyInfo ArmyInfo
local function periodicReinforcementsSpawnThread(group, armyInfo)
    local delay = group.delay
    if delay > 0 then
        WaitSeconds(delay)
    end

    local position = ScenarioUtils.MarkerToPosition(armyInfo.ArmyName)
    local period = group.period
    local bpIds = group.unitNames
    local armyIndex = armyInfo.ArmyIndex

    while not ArmyIsOutOfGame(armyIndex) do
        spawnUnitsWithTeleportInEffect(bpIds, armyIndex, position)

        WaitSeconds(period)
    end
end

---Starts spawning periodical reinforcment units for all armies with teleport in effect
---@param unitGroups ReinforcementPeriodicGroup[]
---@param armySetup ArmySetup
local function spawnPeriodicReinforcements(unitGroups, armySetup)
    local i = 1
    for _, group in ipairs(unitGroups) do
        for _, armyInfo in pairs(armySetup) do
            if tonumber(armyInfo.OwnerID) == group.playerId then
                ScenarioInfo.GwReinforcementSpawnThreads[i] = ForkThread(periodicReinforcementsSpawnThread, group, armyInfo)
                i = i + 1
            end
        end
    end
end

---Spawn an initial reinforcement units after their set delay
---@param group ReinforcementInitialUnitsGroup
---@param armyInfo ArmyInfo
local function initialReinforcementsSpawnThread(group, armyInfo)
    local delay = group.delay
    if delay > 0 then
        WaitSeconds(delay)
    end

    local position = ScenarioUtils.MarkerToPosition(armyInfo.ArmyName)
    spawnUnitsWithTeleportInEffect(group.unitNames, armyInfo.ArmyIndex, position)
end

---Spawn an initial reinforcment units for all armies with teleport in effect
---@param unitGroups ReinforcementInitialUnitsGroup[]
---@param armySetup ArmySetup
local function spawnInitialReinforcements(unitGroups, armySetup)
    for _, group in ipairs(unitGroups) do
        for _, armyInfo in pairs(armySetup) do
            if tonumber(armyInfo.OwnerID) == group.playerId then
                ForkThread(initialReinforcementsSpawnThread, group, armyInfo)
            end
        end
    end
end

---@param armyId Army
---@param factionIndex integer
local function setSupportArmyColor(armyId, factionIndex)
    if factionIndex == 1 then
        ScenarioFramework.SetUEFNeutralColor(armyId)
    elseif factionIndex == 2 then
        ScenarioFramework.SetAeonNeutralColor(armyId)
    elseif factionIndex == 3 then
        ScenarioFramework.SetCybranNeutralColor(armyId)
    elseif factionIndex == 4 then
        ScenarioFramework.SetNeutralColor(armyId)
    end
end

---Sets up the support armies entries, faction/team index for all player teams.
function AssignSupports()
    ---@type ArmySetup
    local armiesList = ScenarioInfo.ArmySetup

    for _, army in pairs(armiesList) do
        if army.ArmyIndex == 1 then
            factions[1] = army.Faction
            teams[1] = army.Team

        elseif army.ArmyIndex == 2 then
            factions[2] = army.Faction
            teams[2] = army.Team
        end
    end

    for _, army in pairs(armiesList) do
        if army.ArmyName == "SUPPORT_1" then
            army.Team = teams[1]
            army.Civilian = true
            army.ArmyColor = 1
            army.PlayerColor = 1
            army.Faction = factions[1]
            army.PlayerName = "gw_support_1"
            armySupport[army.Team] = army.ArmyName
            armySupportIndex[army.Team] = army.ArmyIndex
            army.Support = true
        elseif army.ArmyName == "SUPPORT_2" then
            army.Team = teams[2]
            army.ArmyColor = 2
            army.PlayerColor = 2
            army.Civilian = true
            army.Faction = factions[2]
            army.PlayerName = "gw_support_2" 
            armySupport[army.Team] = army.ArmyName
            armySupportIndex[army.Team] = army.ArmyIndex
            army.Support = true
        end
    end
end

---comment
function GwReinforcementsMainThread()
    setSupportArmyColor(armySupportIndex[teams[1]], factions[1])
    setSupportArmyColor(armySupportIndex[teams[2]], factions[2])

    WaitSeconds(1)

    ScenarioInfo.GwReinforcementSpawnThreads = {}
    ScenarioInfo.gwReinforcementList = ReinforcementList

    ---@type ArmySetup
    local armySetup = ScenarioInfo.ArmySetup
    --WARN('armieslist is ' .. repr (armySetup))

    for name, army in pairs(armySetup) do
        if army.Human then
            local brain = GetArmyBrain(army.ArmyIndex) --[[@as GwAIBrain]]
            ---@type ACUUnit[]
            local units = brain:GetListOfUnits(categories.COMMAND, false)
            for _, unit in pairs(units) do
                brain:AddSpecialAbilityUnit(unit, 'Recall', true)
                modHumanACU(unit--[[@as GwACUUnit]])
            end
        end
    end

    for _, armyId in pairs(armySupportIndex) do
        local brain = GetArmyBrain(armyId)
        brain:GiveStorage('MASS', 2000)
        brain:GiveStorage('ENERGY', 10000)
        brain:SetResourceSharing(false)
    end

    --LOG("GW Reinforcements list:", repr(ReinforcementList))

    spawnInitialStructures(ReinforcementList.initialStructure, armySetup)
    spawnInitialReinforcements(ReinforcementList.initialUnitWarp, armySetup)
    spawnPeriodicReinforcements(ReinforcementList.periodicUnitWarp, armySetup)
end
