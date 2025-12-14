local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local DrawLine = DrawLine

local lineGroundOffset = 10

local maxShapeRatio = 1 / 3
local minShapeRatio = 4 / 25

---@class ArmySetupEntry
---@field ArmyIndex integer
---@field ArmyName string
---@field Civilian boolean
---@field Faction Faction
---@field Human boolean
---@field PlayerName string
---@field StartSpot integer
---@field Team integer



---@class SpawnArea
---@field color Color
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number
local SpawnArea = Class()
{
    ---@param self SpawnArea
    ---@param color Color
    ---@param x1 number
    ---@param y1 number
    ---@param x2 number
    ---@param y2 number
    __init = function(self, color, x1, y1, x2, y2)
        self.color = color
        self[1] = math.min(x1, x2)
        self[2] = math.min(y1, y2)
        self[3] = math.max(x1, x2)
        self[4] = math.max(y1, y2)
    end,

    ---@param self SpawnArea
    ---@return number
    GetArea = function(self)
        return self:Width() * self:Height()
    end,

    ---@param self SpawnArea
    ---@param xMin number
    ---@param yMin number
    ---@param xMax number
    ---@param yMax number
    ClampToSize = function(self, xMin, yMin, xMax, yMax)
        self[1] = math.clamp(self[1], xMin, xMax)
        self[2] = math.clamp(self[2], yMin, yMax)
        self[3] = math.clamp(self[3], xMin, xMax)
        self[4] = math.clamp(self[4], yMin, yMax)
    end,

    ---@param self SpawnArea
    ---@return number
    Width = function(self)
        return math.abs(self[3] - self[1])
    end,

    ---@param self SpawnArea
    ---@return number
    Height = function(self)
        return math.abs(self[4] - self[2])
    end,

    ---@param self SpawnArea
    ---@param ratio number
    ScaleArea = function(self, ratio)
        local width = self:Width()
        local height = self:Height()

        local center = self:GetCenter()

        width = width * math.sqrt(ratio)
        height = height * math.sqrt(ratio)

        self[1] = center[1] - width / 2
        self[2] = center[3] - height / 2
        self[3] = center[1] + width / 2
        self[4] = center[3] + height / 2
    end,

    ---@param self SpawnArea
    Render = function(self)
        local box = {
            { self[1], GetSurfaceHeight(self[1], self[2]) + lineGroundOffset, self[2] },
            { self[1], GetSurfaceHeight(self[1], self[4]) + lineGroundOffset, self[4] },
            { self[3], GetSurfaceHeight(self[3], self[4]) + lineGroundOffset, self[4] },
            { self[3], GetSurfaceHeight(self[3], self[2]) + lineGroundOffset, self[2] },
        }

        DrawLine(box[1], box[2], self.color)
        DrawLine(box[2], box[3], self.color)
        DrawLine(box[3], box[4], self.color)
        DrawLine(box[1], box[4], self.color)
    end,

    ---@param self SpawnArea
    ---@param pos Vector
    IsInArea = function(self, pos)
        return pos[1] > self[1] and pos[1] < self[3] and pos[3] > self[2] and pos[3] < self[4]
    end,

    ---@param self SpawnArea
    ---@return Vector
    GetCenter = function(self)
        local mx, my = (self[1] + self[3]) * 0.5, (self[2] + self[4]) * 0.5
        return Vector(mx, GetTerrainHeight(mx, my), my)
    end
}


---@param data { Position : Vector, Army : number }
function SelectSpawnLocation(data)
    if not ScenarioInfo.IsSpawnPhase then
        return
    end

    if not data or not data.Position or not OkayToMessWithArmy(data.Army) then
        return
    end

    local armyId = data.Army

    local teamId = ScenarioInfo.ArmyToTeam[armyId]
    ---@type SpawnArea
    local area = ScenarioInfo.SpawnAreas[teamId]
    if not area then return end

    if not area:IsInArea(data.Position) then
        if GetCurrentCommandSource() == GetFocusArmy() then
            print("Invalid spawn position")
        end
        return
    end

    ScenarioInfo.SpawnLocations[armyId] = data.Position
end

function GetColorsAndTeams(teams)
    local function GetFocusArmyTeam()
        local fa = GetFocusArmy()
        return ScenarioInfo.ArmyToTeam[fa]
    end

    local t1, t2
    for team in teams do
        if not t1 then
            t1 = team
        elseif not t2 then
            t2 = team
        end
    end

    local faTeam = GetFocusArmyTeam()

    local c1
    local c2
    if faTeam == t1 then
        c1 = "ff00ff00"
        c2 = "ffff0000"
    else
        c1 = "ffff0000"
        c2 = "ff00ff00"
    end
    return t1, t2, c1, c2
end

local function GetMapRect()
    if ScenarioInfo.MapData.PlayableRect then
        return unpack(ScenarioInfo.MapData.PlayableRect)
    end
    return 0, 0, GetMapSize()
end

function ComputeSpawnAreas(t1, t2, c1, c2)
    local armySetup = ScenarioInfo.ArmySetup
    local armies = ScenarioInfo.Configurations.standard.teams[1].armies -- all available armies

    ---@type table<string, Vector>
    local armyPositions = {}
    for _, armyName in armies do
        ---@type Marker
        local marker = import("/lua/sim/ScenarioUtilities.lua").GetMarker(armyName)
        if marker then
            armyPositions[armyName] = marker.position
        end
    end

    local v1 = Vector(0, 0, 0)
    local v2 = Vector(0, 0, 0)

    local x1Max, y1Max, x1Min, y1Min = 0, 0, 100000, 100000
    local x2Max, y2Max, x2Min, y2Min = 0, 0, 100000, 100000

    local n1, n2 = 0, 0
    -- We assume that team 1 is odd positions and team 2 is even positions

    for i, armyName in armies do
        local pos = armyPositions[armyName]
        if pos then
            if math.mod(i, 2) == 1 then
                x1Max = math.max(x1Max, pos[1])
                y1Max = math.max(y1Max, pos[3])
                x1Min = math.min(x1Min, pos[1])
                y1Min = math.min(y1Min, pos[3])

                v1 = VAdd(v1, pos)

                n1 = n1 + 1
            else
                x2Max = math.max(x2Max, pos[1])
                y2Max = math.max(y2Max, pos[3])
                x2Min = math.min(x2Min, pos[1])
                y2Min = math.min(y2Min, pos[3])

                v2 = VAdd(v2, pos)

                n2 = n2 + 1
            end
        end
    end

    v1 = Vector(v1[1] / n1, v1[2] / n1, v1[3] / n1)
    v2 = Vector(v2[1] / n2, v2[2] / n2, v2[3] / n2)

    local x1, y1, x2, y2 = GetMapRect()
    local msizeX, msizeY = x2 - x1, y2 - y1

    ---@param c Color
    ---@param xMax number
    ---@param yMax number
    ---@param xMin number
    ---@param yMin number
    ---@param center Vector
    ---@return SpawnArea
    local function ComputeShape(c, xMax, yMax, xMin, yMin, center)
        local width = math.max(xMax - xMin, 10)
        local height = math.max(yMax - yMin, 10)

        local xRatio = width / msizeX
        local yRatio = height / msizeY

        local areaRatio = math.clamp(xRatio * yRatio, minShapeRatio, maxShapeRatio)

        local a = SpawnArea(c,
            center[1] - width / 2, center[3] - height / 2,
            center[1] + width / 2, center[3] + height / 2)

        a:ScaleArea(areaRatio / (xRatio * yRatio))
        a:ClampToSize(x1, y1, x2, y2)
        return a
    end

    return {
        [t1] = ComputeShape(c1, x1Max, y1Max, x1Min, y1Min, v1),
        [t2] = ComputeShape(c2, x2Max, y2Max, x2Min, y2Min, v2),
    }
end

local symmetryToAreaShape = {
    ["auto"] = ComputeSpawnAreas,
    ["rvsl"] = function(t1, t2, c1, c2)
        local x1, y1, x2, y2 = GetMapRect()
        local msizeX, msizeY = x2 - x1, y2 - y1
        local msizeX13, msizeY13 = msizeX / 3, msizeY / 3
        return {
            [t1] = SpawnArea(c1, x1, y1, x1 + msizeX13, y2),
            [t2] = SpawnArea(c2, x2 - msizeX13, y1, x2, y2),
        }
    end,
    ["tvsb"] = function(t1, t2, c1, c2)
        local x1, y1, x2, y2 = GetMapRect()
        local msizeX, msizeY = x2 - x1, y2 - y1
        local msizeX13, msizeY13 = msizeX / 3, msizeY / 3
        return {
            [t1] = SpawnArea(c1, x1, y1, x2, y1 + msizeY13),
            [t2] = SpawnArea(c2, x1, y2 - msizeY13, x2, y2),
        }
    end,
    ["tlvsbr"] = function(t1, t2, c1, c2)
        local x1, y1, x2, y2 = GetMapRect()
        local msizeX, msizeY = x2 - x1, y2 - y1
        local msizeX25, msizeY25 = 2 * msizeX / 5, 2 * msizeY / 5
        return {
            [t1] = SpawnArea(c1, x1, y1, x1 + msizeX25, y1 + msizeY25),
            [t2] = SpawnArea(c2, x2 - msizeX25, y2 - msizeY25, x2, y2),
        }
    end,
    ["trvsbl"] = function(t1, t2, c1, c2)
        local x1, y1, x2, y2 = GetMapRect()
        local msizeX, msizeY = x2 - x1, y2 - y1
        local msizeX25, msizeY25 = 2 * msizeX / 5, 2 * msizeY / 5
        return {
            [t1] = SpawnArea(c1, x2 - msizeX25, y1, x2, y1 + msizeY25),
            [t2] = SpawnArea(c2, x1, y2 - msizeY25, x1 + msizeX25, y2),
        }
    end,
    ["whole"] = function(t1, t2, c1, c2)
        local x1, y1, x2, y2 = GetMapRect()
        return {
            [t1] = SpawnArea(c1, x1, y1, x2, y2),
            [t2] = SpawnArea(c2, x1, y1, x2, y2),
        }
    end,
}

function CreateSpawnAreas(teams)
    if table.getsize(teams) ~= 2 then
        print("Too many teams to spawn, defaulting to whole map")
        local x1, y1, x2, y2 = GetMapRect()
        local area = SpawnArea("ff00ff00", x1, y1, x2, y2)
        local areas = {}
        for team in teams do
            areas[team] = area
        end
        return areas
    end

    local terrainSymmetry = ScenarioInfo.Options.SSLSpawnAreaType

    local t1, t2, c1, c2 = GetColorsAndTeams(teams)

    local f = symmetryToAreaShape[terrainSymmetry]
    if f then
        return f(t1, t2, c1, c2)
    end
    -- Default to auto
    return symmetryToAreaShape["auto"](t1, t2, c1, c2)
end

function RenderLines()
    for teamId, area in ScenarioInfo.SpawnAreas do
        area:Render()
    end
end

function RenderMarkers()

    local tblArmy = ListArmies()
    local focusArmy = GetFocusArmy()

    Sync.Markers = {}
    for iArmy, strArmy in pairs(tblArmy) do
        local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian

        if armyIsCiv then continue end
        local markerpos = ScenarioInfo.SpawnLocations[iArmy]

        if focusArmy == -1 or IsAlly(iArmy, focusArmy) or (iArmy == focusArmy) then
            Sync.Markers[strArmy] = markerpos
        end

    end

end

function RenderThread()
    LOG("MAIN THREAD")
    while true do
        RenderLines()
        RenderMarkers()
        WaitTicks(1)
    end
end

function SpawnACUs(tblGroups)
    local tblArmy = ListArmies()
    local civOpt = ScenarioInfo.Options.CivilianAlliance
    local bCreateInitial = ShouldCreateInitialArmyUnits()

    for iArmy, strArmy in pairs(tblArmy) do
        local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian
        if (not armyIsCiv and bCreateInitial) or (armyIsCiv and civOpt ~= 'removed') then
            local commander = (not ScenarioInfo.ArmySetup[strArmy].Civilian)
            local cdrUnit
            tblGroups[strArmy], cdrUnit = ScenarioUtils.CreateInitialArmyGroup(strArmy, commander)
            if commander and cdrUnit and ArmyBrains[iArmy].Nickname then
                cdrUnit:SetCustomName(ArmyBrains[iArmy].Nickname)
                cdrUnit:SetPosition(ScenarioInfo.SpawnLocations[iArmy], true)
            end
        end
    end
end

function DefaultSpawnLocations(areas, armyToTeam)
    local positions = {}
    for _, army in ScenarioInfo.ArmySetup do
        if army.Civilian then
            continue
        end
        local team = armyToTeam[army.ArmyIndex]
        local area = areas[team]
        positions[army.ArmyIndex] = area:GetCenter()
    end
    return positions
end

-- armyId -> teamId
function SplitPlayersByTeams()
    local armyToTeam = {}
    local teams = {}
    ---@param army ArmySetupEntry
    for _, army in ScenarioInfo.ArmySetup do
        if army.Civilian then
            continue
        end
        armyToTeam[army.ArmyIndex] = army.Team
        teams[army.Team] = teams[army.Team] or {}
        table.insert(teams[army.Team], army.ArmyIndex)
    end
    return armyToTeam, teams
end

function PreparationPhase(tblGroups)
    ScenarioInfo.IsSpawnPhase = true
    LOG("render started")
    local armyToTeam, teams = SplitPlayersByTeams()
    ScenarioInfo.ArmyToTeam = armyToTeam
    local areas = CreateSpawnAreas(teams)
    ScenarioInfo.SpawnAreas = areas
    ScenarioInfo.SpawnLocations = DefaultSpawnLocations(areas, armyToTeam)
    local mainThread = ForkThread(RenderThread)
    WaitTicks((tonumber(ScenarioInfo.Options.SSLPreparationTime) or 30) * 10)

    for iArmy, pos in ScenarioInfo.SpawnLocations do
        ArmyBrains[iArmy].StartPos = Vector2(pos[1], pos[3])
    end

    SpawnACUs(tblGroups)
    LOG("COMS SPAWNED")
    KillThread(mainThread)

    Sync.DeleteMarkers          = true
    ScenarioInfo.IsSpawnPhase   = false
    ScenarioInfo.SpawnAreas     = nil
    ScenarioInfo.ArmyToTeam     = nil
    ScenarioInfo.SpawnLocations = nil
end

function InitializeArmies()
    LOG("DYNAMICSPAWN")
    local tblGroups = {}
    local tblArmy = ListArmies()

    local civOpt = ScenarioInfo.Options.CivilianAlliance

    for iArmy, strArmy in pairs(tblArmy) do
        local tblData = Scenario.Armies[strArmy]

        tblGroups[strArmy] = {}

        if not tblData then continue end

        SetArmyEconomy(strArmy, tblData.Economy.mass, tblData.Economy.energy)

        local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian

        if armyIsCiv and civOpt ~= 'neutral' and strArmy ~= 'NEUTRAL_CIVILIAN' then -- give enemy civilians darker color
            SetArmyColor(strArmy, 255, 48, 48) -- non-player red color for enemy civs
        end

        local wreckageGroup = ScenarioUtils.FindUnitGroup('WRECKAGE', Scenario.Armies[strArmy].Units)
        if wreckageGroup then
            local platoonList, tblResult, treeResult = ScenarioUtils.CreatePlatoons(strArmy, wreckageGroup)
            for num, unit in tblResult do
                ScenarioUtils.CreateWreckageUnit(unit)
            end
        end

        for iEnemy, strEnemy in tblArmy do
            local enemyIsCiv = ScenarioInfo.ArmySetup[strEnemy].Civilian
            local a, e = iArmy, iEnemy
            local state = 'Enemy'

            if a == e then continue end

            if armyIsCiv or enemyIsCiv then
                if civOpt == 'neutral' or strArmy == 'NEUTRAL_CIVILIAN' or strEnemy == 'NEUTRAL_CIVILIAN' then
                    state = 'Neutral'
                end

                if ScenarioInfo.Options['RevealCivilians'] == 'Yes' and ScenarioInfo.ArmySetup[strEnemy].Human then
                    ForkThread(function()
                        WaitSeconds(.1)
                        local real_state = IsAlly(a, e) and 'Ally' or IsEnemy(a, e) and 'Enemy' or 'Neutral'

                        GetArmyBrain(e):SetupArmyIntelTrigger(
                            {
                                Category = categories.ALLUNITS,
                                Type = 'LOSNow',
                                Value = true,
                                OnceOnly = true,
                                TargetAIBrain = GetArmyBrain(a),
                                CallbackFunction = function()
                                    SetAlliance(a, e, real_state)
                                end
                            })
                        SetAlliance(a, e, 'Ally')
                    end)
                end
            end

            if state then
                SetAlliance(a, e, state)
            end
        end


    end
    ForkThread(PreparationPhase, tblGroups)
    return tblGroups
end
