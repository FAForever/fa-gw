local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local SimUtils = import('/lua/SimUtils.lua')

-- {Number of Tech 3, 2, 1 units that can fit into the transport}
local TransportInfo = {
    {14, 6, 3, bpID = 'UEA0104'}, -- UEF
    {12, 6, 2, bpID = 'UAA0104'}, -- Aeon
    {10, 4, 2, bpID = 'URA0104'}, -- Cybran
    {16, 8, 4, bpID = 'XSA0104'}, -- Seraphim
}

local armySupport = {}
local armySupportIndex = {}

local factions = {1, 1}
local teams = {-1, -1}


function assignSupports()
    local ArmiesList = ScenarioInfo.ArmySetup

    for name,army in ScenarioInfo.ArmySetup do
        if army.ArmyIndex == 1 then
            factions[1] = army.Faction
            teams[1] = army.Team

        elseif army.ArmyIndex == 2 then
            factions[2] = army.Faction
            teams[2] = army.Team
        end
    end

    for name,army in ScenarioInfo.ArmySetup do
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

function gwSetAiColor(index, faction)
    if faction == 1 then
        ScenarioFramework.SetUEFNeutralColor(index)
    elseif faction == 2 then
        ScenarioFramework.SetAeonNeutralColor(index)
    elseif faction == 3 then
        ScenarioFramework.SetCybranNeutralColor(index)
    elseif faction == 4 then
        ScenarioFramework.SetNeutralColor(index)
    end
end

function gwReinforcementsMainThread()
    local gwReinforcementList =  import('/lua/gwReinforcementList.lua').gwReinforcements

    gwSetAiColor(armySupportIndex[teams[1]], factions[1])
    gwSetAiColor(armySupportIndex[teams[2]], factions[2])

    WaitTicks(10)

    ScenarioInfo.gwReinforcementSpawnThreads = {}
    ScenarioInfo.gwReinforcementList = gwReinforcementList
    
    local ArmiesList = ScenarioInfo.ArmySetup
    --WARN('armieslist is ' .. repr (ArmiesList))

    local HumanPlayerACUs = GetACUs(ScenarioInfo.ArmySetup)
    for index, HumanACU in HumanPlayerACUs do
        ModHumanACU(HumanACU)
    end 

    GetArmyBrain(armySupportIndex[teams[1]]):GiveStorage('MASS', 2000)
    GetArmyBrain(armySupportIndex[teams[1]]):GiveStorage('ENERGY', 10000)

    GetArmyBrain(armySupportIndex[teams[2]]):GiveStorage('MASS', 2000)
    GetArmyBrain(armySupportIndex[teams[2]]):GiveStorage('ENERGY', 10000)

    GetArmyBrain(armySupportIndex[teams[1]]):SetResourceSharing(false)
    GetArmyBrain(armySupportIndex[teams[2]]):SetResourceSharing(false)

    LOG("ScenarioInfo.gwReinforcementList")
    --LOG(repr(ScenarioInfo.gwReinforcementList))

    SpawnInitialStructures(ScenarioInfo.gwReinforcementList.initialStructure, ArmiesList)
    SpawnInitialReinforcements(ScenarioInfo.gwReinforcementList.initialUnitWarp, ArmiesList)
    SpawnPeriodicReinforcements(ScenarioInfo.gwReinforcementList.periodicUnitWarp, ArmiesList)
end

function SpawnInitialStructures(gwSpawnList, Armies)
    local counter = 1
    for _, List in gwSpawnList do
        for ArmyName, Army in Armies do
            if Army.PlayerName == List.playerName then
                ScenarioInfo.gwReinforcementSpawnThreads[counter] = ForkThread(InitialStructuresSpawnThread, List, Army)
                counter = counter + 1 
            end
        end
    end
end

function SpawnPeriodicReinforcements(gwSpawnList, Armies)
    local counter = 1
    for _, List in gwSpawnList do
        for ArmyName, Army in Armies do
            if Army.PlayerName == List.playerName then
                ScenarioInfo.gwReinforcementSpawnThreads[counter] = ForkThread(PeriodicReinforcementsSpawnThread, List, Army)
                counter = counter + 1 
            end
        end
    end
end

function SpawnInitialReinforcements(gwSpawnList, Armies)
    local counter = 1
    for _, List in gwSpawnList do
        for ArmyName, Army in Armies do
            if Army.PlayerName == List.playerName then
                ScenarioInfo.gwReinforcementSpawnThreads[counter] = ForkThread(InitialReinforcementsSpawnThread, List, Army)
                counter = counter + 1 
            end
        end
    end
end

function InitialStructuresSpawnThread(List, Army)
    local delay = List.delay
    local UnitsToSpawn = List.unitNames

    local aiBrain = GetArmyBrain(Army.ArmyIndex)
    local posX, posY = aiBrain:GetArmyStartPos()

    WaitSeconds(1)

    for _, v in UnitsToSpawn do
        local unit = aiBrain:CreateUnitNearSpot(v, posX, posY)
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
            unit:CreateTarmac(true, true, true, false, false)
        end
    end
end

function PeriodicReinforcementsSpawnThread(List, Army)
    local position = ScenarioUtils.MarkerToPosition(Army.ArmyName)
    local delay = List.delay
    local period = List.period
    local UnitsToSpawn = List.unitNames

    WaitSeconds(delay)

    while not ArmyIsOutOfGame(Army.ArmyIndex) do
        for _, unitName in UnitsToSpawn do
            local NewUnit = CreateUnitHPR(unitName, Army.ArmyIndex, position[1], position[2], (position[3]), 0, 0, 0)
            NewUnit:PlayTeleportInEffects()
            NewUnit:CreateProjectile('/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
        end
        WaitSeconds(period)
    end
end

function InitialReinforcementsSpawnThread(List, Army)
    local position = ScenarioUtils.MarkerToPosition(Army.ArmyName)
    local delay = List.delay
    --local period = List.period
    local UnitsToSpawn = List.unitNames

    WaitSeconds(delay)

    --while not ArmyIsOutOfGame(Army.ArmyIndex) do
        for _, unitName in UnitsToSpawn do
            local NewUnit = CreateUnitHPR(unitName, Army.ArmyIndex, position[1], position[2], (position[3]), 0, 0, 0)
            NewUnit:PlayTeleportInEffects()
            NewUnit:CreateProjectile( '/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
        end
    --   WaitSeconds(period)
    --end
end

function GetACUs(armies)
    local ACUs = {}

    for ArmyName, Army in armies do
        if Army.Human then 
            local brain = GetArmyBrain(Army.ArmyIndex)
            local units = brain:GetListOfUnits(categories.COMMAND, false)
            if units then
                for _, unit in units do
                    ACUs[unit:GetArmy()] = unit
                    brain:AddSpecialAbilityUnit( unit, 'Recall', true )
                    LOG('found an ACU near marker ' .. repr(ArmyName))
                end
            end
        end
    end
    return ACUs
end

function ModHumanACU(ACU)
    ACU.OldOnStartBuild = ACU.OnStartBuild 
    ACU.DespawnBeacon = DespawnBeacon
    ACU.ModBeacon = ModBeacon
    ACU.OnStartBuild = function(self, unitBeingBuilt, order)
        if EntityCategoryContains(categories.REINFORCEMENTSBEACON, unitBeingBuilt) then
            ACU:DespawnBeacon()
            ACU.ReinforcementsBeacon = unitBeingBuilt
            ACU:ModBeacon(ACU.ReinforcementsBeacon)
        end
        self.OldOnStartBuild(self, unitBeingBuilt, order)
    end
    CheckUnitsDelay(ACU)
    CheckPassiveItems(ACU)
end

function Deploy(data)
    if not OkayToMessWithArmy(data.From) then return end
    local aiBrain = GetArmyBrain(data.From)
    if aiBrain:IsDefeated() then return end

    local units = aiBrain:GetListOfUnits(categories.REINFORCEMENTSBEACON, false)
    local focusArmy = GetFocusArmy()

    if table.getn(units) == 0 and focusArmy == data.From then     
        PrintText(LOC('<LOC reinforcements0001>No beacon found for deployment!'), 20, nil, 15, 'center')
    end

    for _, unit in units do
        if unit.UnitBeingBuilt or unit:GetFractionComplete() ~= 1 then
            if focusArmy == data.From then
                PrintText(LOC('<LOC reinforcements0002>The beacon is not complete!'), 20, nil, 15, 'center')
            end
        else
            unit:Deploy(data.Index)
        end
    end

end


function ModBeacon(ACU, beacon)
    beacon.ArmyIndex  = ACU:GetArmy()
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

    beacon.Deploy = function(self, index)
        LOG("deploying index " .. index)

        local toRemove = {}
        curTime = GetGameTimeSeconds()
        for idx, List in self.ACU.unitsDelays do
            if List.group == index and List.delay <= curTime then
                Units = {}
                Buildings = {}
                -- split between units & building
                for index, unitBPid in List.unitNames do
                    bp = GetUnitBlueprintByName(unitBPid)
                    if bp.Categories then
                        local cats = {} 
                        for k,cat in pairs(bp.Categories) do
                            cats[cat] = true
                        end                         
                        if cats.STRUCTURE then
                            table.insert(Buildings, unitBPid)
                        else
                            table.insert(Units, unitBPid)
                        end
                    end
                end

                if table.getn(Units) > 0 then
                    CallReinforcementsToBeacon(self, Units, List.group)
                end

                if table.getn(Buildings) > 0 then
                    CallEngineersToBeacon(self, Buildings, List.group)
                end
                table.insert(toRemove, idx)
            end
        end

        for _, idx in toRemove do
            table.remove(self.ACU.unitsDelays, idx)
        end
    end
end

-- this function check all passive items.
function CheckPassiveItems(ACU)
    local brain = ACU:GetAIBrain()
    for _, List in ScenarioInfo.gwReinforcementList.passiveItems do
        if List.playerName == brain.Nickname then
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

--this function check all the units delay to spawn them.
function CheckUnitsDelay(ACU)
    ACU.unitsDelays = {}
    local brain = ACU:GetAIBrain()
    for _, List in ScenarioInfo.gwReinforcementList.transportedUnits do
        if List.playerName == brain.Nickname then
            brain:AddReinforcements(List)
            table.insert(ACU.unitsDelays, List)
        end 
    end
end

function DespawnBeacon(ACU)
    --WARN("despawning beacon, beacon is " .. repr(ACU.ReinforcementsBeacon))
    if ACU.ReinforcementsBeacon and not ACU.ReinforcementsBeacon:IsDead() then
        if ACU.ReinforcementsBeacon.EvacTruck and not ACU.ReinforcementsBeacon.EvacTruck:IsDead() then 
            ACU.ReinforcementsBeacon.EvacTruck:SetUnSelectable(false)
        end

        local BeaconPosition = ACU.ReinforcementsBeacon:GetPosition()
        local TeleportToPosition = {-1000 ,BeaconPosition[2] ,-1000}  --far off-map

        ACU.ReinforcementsBeacon:PlayTeleportOutEffects()
        Warp(ACU.ReinforcementsBeacon, TeleportToPosition, ACU.ReinforcementsBeacon:GetOrientation())
        ACU.ReinforcementsBeacon:Destroy()
    end

    ACU.ReinforcementsBeacon = nil
end

function CallEngineersToBeacon(beacon, List, group)
    --bring in units + engineers + etc
    --[[
    beacon.Army = nil
    for _, Army in ListArmies() do
       if beacon.ArmyIndex == Army.ArmyIndex then
           beacon.Army = Army
           WARN("found army for our beacon!")
       end
    end
    --]]
    beacon.AiBrain = beacon:GetAIBrain()
    beacon.Nickname = beacon.AiBrain.Nickname
    beacon.ArmyName = beacon.AiBrain.Name
    beacon.Team = ScenarioInfo.ArmySetup[beacon.ArmyName].Team

    beacon.StructureReinforcementsToCall = List

    beacon.NearestOffMapLocation = CalculateNearestOffMapLocation(beacon)

    WARN('beacon.StructureReinforcementsToCall is ' .. repr(beacon.StructureReinforcementsToCall))
    if beacon.StructureReinforcementsToCall then
        SpawnBuildByEngineerReinforcements(beacon, beacon.StructureReinforcementsToCall, group)
    end
end

function CallReinforcementsToBeacon(beacon, List, group)
    --bring in units + engineers + etc
    --[[
    beacon.Army = nil
    for _, Army in ListArmies() do
       if beacon.ArmyIndex == Army.ArmyIndex then
           beacon.Army = Army
           WARN("found army for our beacon!")
       end
    end
    --]]
    beacon.AiBrain = beacon:GetAIBrain()
    beacon.Nickname = beacon.AiBrain.Nickname
    beacon.ArmyName = beacon.AiBrain.Name
    beacon.Team = ScenarioInfo.ArmySetup[beacon.ArmyName].Team
    --WARN('gwReinforcementList.TransportedUnits is ' .. repr(ScenarioInfo.gwReinforcementList.transportedUnits))

    beacon.UnitReinforcementsToCall = List

    beacon.NearestOffMapLocation = CalculateNearestOffMapLocation(beacon)
    --WARN('beacon.UnitReinforcementsToCall is ' .. repr(beacon.UnitReinforcementsToCall))
    if beacon.UnitReinforcementsToCall then
        SpawnTransportedReinforcements(beacon, beacon.UnitReinforcementsToCall, group)
    end
end

function CalculateNearestOffMapLocation(beacon)
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

function SpawnTransportedReinforcements(beacon, unitsToSpawn, group)
    WARN('Spawningtransported Reinforcements')
    local NearestOffMapLocation = beacon.NearestOffMapLocation 
    local UnitsToTransport = {}
    UnitsToTransport[1] = {}
    UnitsToTransport[2] = {}
    UnitsToTransport[3] = {}
    local NumberOfTransportsNeeded = 0

    --this spawns our units
    for _, unitBPid in unitsToSpawn do
        --WARN('spawning reinforcement unit bpid is ' .. repr(unitBPid))
        --WARN('spawning beacon.ArmyName unit bpid is ' .. repr(beacon.ArmyIndex))
        
        --get the right support AI for this player

        local newUnit = CreateUnitHPR(unitBPid, armySupport[beacon.Team], NearestOffMapLocation[1], NearestOffMapLocation[2], NearestOffMapLocation[3], 0, 0, 0)
        local TransportClass = newUnit:GetBlueprint().Transport.TransportClass
        table.insert(UnitsToTransport[TransportClass], newUnit)
    end

    --this should spawn transports and attach untis to them
    for TechLevel = 1, 3, 1 do
        local TransportCapacity = TransportInfo[beacon.Faction][TechLevel]
        local counter = 0
        local LoadForThisTransport = {}
        for index, unit in UnitsToTransport[TechLevel] do
            counter = counter + 1
            table.insert(LoadForThisTransport, unit)
            --if we reached max load for one transport, spawn it, load unit, set orders, start counting again 
            if counter == TransportCapacity then
                ForkThread(SpawnTransportAndIssueDrop, TransportInfo[beacon.Faction].bpID, LoadForThisTransport, NearestOffMapLocation, beacon, group)
                counter = 0
                LoadForThisTransport = {}
            end 
        end
        --this is to make sure we spawn a transport even if we don't have enough units to completely fill one up'
        if counter > 0 then
            ForkThread(SpawnTransportAndIssueDrop, TransportInfo[beacon.Faction].bpID, LoadForThisTransport, NearestOffMapLocation, beacon, group)
        end
    end

    --this will calculate how many T2 transports we need based upon how many units we have
    --there doesn't appear to be a way to do this quickly, so we're just going to add 1 for every 2 class 3 units, 1 for every 6 class 2 units, and 1 for every 12 class 1 units
end

function SpawnTransportAndIssueDrop(transportBPid, units, NearestOffMapLocation, beacon, group)
    --WARN('spawning transport, bpid and army are ' .. repr(transportBPid) .. ' and ' .. repr(beacon.ArmyName))
    local transport = CreateUnitHPR(transportBPid, armySupport[beacon.Team], NearestOffMapLocation[1], NearestOffMapLocation[2], NearestOffMapLocation[3], 0, 0, 0)

    transport.OldOnTransportDetach = transport.OnTransportDetach

    transport.OnTransportDetach = function(self, attachBone, unit)
        SimUtils.TransferUnitsOwnership( {unit}, beacon.ArmyIndex)
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

    beacon.AiBrain:ReinforcementsCalled(group)
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
    if not transport:IsDead() then
        Transports:MoveToLocation(NearestOffMapLocation, false)
    end

    while not transport:IsDead() and not IsUnitCloseToPoint(transport,NearestOffMapLocation) do
        WaitSeconds(2)
    end
    
    if transport:IsDead() then
        return
    else
        spawnOutEffect(transport)
    end
end

function IsUnitCloseToPoint(unit, point)
    local position = unit:GetPosition()
    if VDist2(position[1], position[3], point[1], point[3]) < 5 then
        return true
    else
        return false
    end 
end

function spawnOutEffect(unit) 
    unit:PlayUnitSound('TeleportStart')
    unit:PlayUnitAmbientSound('TeleportLoop')
    WaitSeconds( 0.1 )
    unit:PlayTeleportInEffects()
    WaitSeconds( 0.1 )
    unit:StopUnitAmbientSound('TeleportLoop')
    unit:PlayUnitSound('TeleportEnd')

    local cargo = unit:GetCargo()
    for _, v in cargo do
        if not v:IsDead() then
            v:Destroy()
        end
    end   
    unit:Destroy()
end 

function SpawnBuildByEngineerReinforcements(beacon, StructuresToBuild, group)
    local EngineersToSpawnAndOrdersAndTransport = {}
    local NearestOffMapLocation = beacon.NearestOffMapLocation 
    local counter = 0

    for index, structureName in StructuresToBuild do
        if GetUnitBlueprintByName(structureName).General.FactionName == 'Aeon' then
            table.insert(EngineersToSpawnAndOrdersAndTransport, {'UAL0309',structureName, 'UAA0107'})
        elseif GetUnitBlueprintByName(structureName).General.FactionName == 'UEF' then
            table.insert(EngineersToSpawnAndOrdersAndTransport, {'UEL0309',structureName, 'UEA0107'})
        elseif GetUnitBlueprintByName(structureName).General.FactionName == 'Cybran' then
            table.insert(EngineersToSpawnAndOrdersAndTransport, {'URL0309',structureName, 'URA0107'})
        elseif GetUnitBlueprintByName(structureName).General.FactionName == 'Seraphim' then
            table.insert(EngineersToSpawnAndOrdersAndTransport, {'XSL0309',structureName, 'XSA0107'})
        end
    end

    for _, EngineerStructureTransportSet in EngineersToSpawnAndOrdersAndTransport do
        counter = counter + 1
        local BuildLocation = CalculateBuildLocationByCounterAndPosition(counter, beacon:GetPosition())
        ForkThread(SpawnEngineerAndTransportAndBuildTheStructure,EngineerStructureTransportSet[1], EngineerStructureTransportSet[2], EngineerStructureTransportSet[3], BuildLocation, beacon, group)    
    end
end

function CalculateBuildLocationByCounterAndPosition(counter, position)
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

    local BuildLocation = {(position[1] + xOffSet), (position[3] + zOffSet), 0}

    return BuildLocation
end

function SpawnEngineerAndTransportAndBuildTheStructure(EngineerBPid, StructureBPid, TransportBPid, BuildLocation, beacon, group)
    local NearestOffMapLocation = CalculateNearestOffMapLocation(beacon)
    local engineer = CreateUnitHPR(EngineerBPid, armySupport[beacon.Team], NearestOffMapLocation[1], NearestOffMapLocation[2], NearestOffMapLocation[3],0,0,0)
    engineer.ArmyName = armySupport[beacon.Team]
    engineer.PlayerArmyName = beacon.ArmyIndex
    engineer:SetProductionActive(true)
    WaitSeconds(0.1)
    engineer:SetProductionPerSecondEnergy(10000)
    engineer:SetProductionPerSecondMass(500)
    WaitSeconds(0.1)

    local transport = CreateUnitHPR(TransportBPid, armySupport[beacon.Team], NearestOffMapLocation[1], NearestOffMapLocation[2], NearestOffMapLocation[3],0,0,0)
    local aiBrain = engineer:GetAIBrain()
    local Transports = aiBrain:MakePlatoon('', '')
    aiBrain:AssignUnitsToPlatoon(Transports, {transport}, 'Support', 'None')
    ScenarioFramework.AttachUnitsToTransports({engineer}, {transport})

    local beaconPosition = beacon:GetPosition()
    beaconPosition.x = beaconPosition.x + Random(-10,10)
    beaconPosition.z = beaconPosition.z + Random(-10,10)

    cmd = Transports:MoveToLocation(beaconPosition, false)
    if cmd then
        beacon.AiBrain:ReinforcementsCalled(group)
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

    if not transport:IsDead() then
        Transports:MoveToLocation(NearestOffMapLocation, false)
    end

    if not engineer:IsDead() then
        aiBrain:BuildStructure(engineer, StructureBPid, BuildLocation)
        ModEngineer(engineer, TransportBPid, beacon)
    end

    while not transport:IsDead() and not IsUnitCloseToPoint(transport, NearestOffMapLocation) do
        WaitSeconds(2)
    end

    if transport:IsDead() then
        return
    else
        spawnOutEffect(transport)
    end
end

function ModEngineer(engineer, transportBPid, beacon)
    engineer.CanIBuild = true
    engineer.transportBPid = transportBPid
    engineer.OldOnStopBuild = engineer.OnStopBuild
    engineer.CallTransportToCarryMeAway = CallTransportToCarryMeAway
    engineer.spawnOutEffect = spawnOutEffect
    engineer.RemindMyTransportToPickMeUp = RemindMyTransportToPickMeUp
    engineer.OnStopBuild = function(self, unitBeingBuilt)
        SimUtils.TransferUnitsOwnership({unitBeingBuilt}, self.PlayerArmyName)
        if not self.HaveCalledTransport then
            self.HaveCalledTransport = true
            self:ForkThread(self.CallTransportToCarryMeAway, self.transportBPid)
        else
            --self:ForkThread(self.RemindMyTransportToPickMeUp, self.myTransport)
        end
        self.OldOnStopBuild(self,unitBeingBuilt)
    end
    engineer.OldOnStartBuild = engineer.OnStartBuild
    engineer.OnStartBuild = function(self, unitBeingBuilt, order)
        if not self.CanIBuild then 
            unitBeingBuilt:Destroy()
            --IssueClearCommands(self)
            --self:OnStopBuild(unitBeingBuilt)
            --self.spawnOutThread = self:ForkThread(self.spawnOutEffect)
            --self:ForkThread(self.RemindMyTransportToPickMeUp,self.myTransport)
        --   return
        end
        self.CanIBuild = false
        --unitBeingBuilt:SetUnSelectable(true)
        self.OldOnStartBuild(self, unitBeingBuilt, order)
        --engineer:SetActiveConsumptionInactive()
    end
end

CallTransportToCarryMeAway = function(self, transportBPid)
    --WARN('starting carry me away function with transportID and name ' .. repr(transportBPid) .. ' and ' .. repr(self:GetAIBrain().Name))
    local NearestOffMapLocation = CalculateNearestOffMapLocation(self)
    local transport = CreateUnitHPR(transportBPid, self:GetAIBrain().Name, NearestOffMapLocation[1], NearestOffMapLocation[2], NearestOffMapLocation[3], 0, 0, 0)
    transport:SetCanTakeDamage(false)
    transport:SetUnSelectable(true)
    
    transport:SetDoNotTarget(true)
    self.myTransport = transport
    
    IssueTransportLoad({self}, transport)
    
    IssueMove({transport}, NearestOffMapLocation)
    
    WaitSeconds(10)
    
    while not transport:IsDead() and not IsUnitCloseToPoint(transport, NearestOffMapLocation) do
        WaitSeconds(2)
    end
    
    if transport:IsDead() then
        return
    else
        spawnOutEffect(transport)
    end
end

RemindMyTransportToPickMeUp = function(self, transport)
    IssueClearCommands(self)
    IssueTransportLoad({self},transport)
    
    local NearestOffMapLocation = CalculateNearestOffMapLocation(self)
    
    IssueMove({self}, NearestOffMapLocation)
    WaitSeconds(2)
    
    IssueMove({transport}, NearestOffMapLocation)
    
    WaitSeconds(10)
    
    while not transport:IsDead() and not IsUnitCloseToPoint(transport,NearestOffMapLocation) do
        WaitSeconds(2)
    end
    
    if transport:IsDead() then
        return
    else
        spawnOutEffect(transport)
    end
end