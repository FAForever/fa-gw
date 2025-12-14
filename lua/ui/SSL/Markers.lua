local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group

local LayoutFor = import('/lua/maui/layouthelpers.lua').LayoutFor

local preparationTimeSeconds = tonumber(SessionGetScenarioInfo().Options.PreparationTime) or 30

local Markers = {}
local Timer = nil
local Credits = nil
function CreateCredits()
    Credits = UIUtil.CreateText(GetFrame(0), 'Mod by 4z0t', 16, "Arial", true)
    Credits:SetColor('ffffffff')
    Credits:DisableHitTest()
    --Credits:SetNeedsFrameUpdate(true)
    LayoutHelpers.AtLeftTopIn(Credits, GetFrame(0), 100, 500)
    Credits.text = UIUtil.CreateText(Credits, 'Markers by Eternal-', 16, "Arial", true)
    Credits.text:SetColor('ffffffff')
    Credits.text:DisableHitTest()
    LayoutHelpers.Below(Credits.text, Credits, 4)
end

function UpdateMarkers(SyncMarkers)
    ---@type WorldView
    local worldView = import("/lua/ui/game/worldview.lua").viewLeft
    if not worldView.spawnOverlay then
        worldView.spawnOverlay = Group(worldView)
        LayoutFor(worldView.spawnOverlay)
            :Fill(worldView)
            :EnableHitTest(true)
        worldView.spawnOverlay.HandleEvent = function(self, event)
            if event.Type == "ButtonPress" and event.Modifiers.Left then
                local pos = GetMouseWorldPos()
                SimCallback {
                    Func = "SelectSpawnLocation",
                    Args = {
                        Army = GetFocusArmy(),
                        Position = Vector(pos[1], pos[2], pos[3])
                    }
                }
            end
            return false
        end

    end

    if not Timer then
        CreateTimer()
    end
    if not Credits then
        CreateCredits()
    end
    -- LOG(repr(GetArmiesTable()))
    for strArmy, pos in SyncMarkers do
        if IsDestroyed(Markers[strArmy]) then
            Markers[strArmy] = createPositionMarker(GetArmy(strArmy), pos)
        else
            Markers[strArmy].pos = { pos[1], pos[2], pos[3] }
        end
    end
end

function CreateTimer()
    Timer = UIUtil.CreateText(GetFrame(0), '', 16, "Arial Black", true)
    Timer:SetColor('ffffffff')
    Timer:DisableHitTest()
    Timer:SetNeedsFrameUpdate(true)
    LayoutHelpers.AtCenterIn(Timer, GetFrame(0), -400)
    Timer.OnFrame = function(self, delta)
        self:SetText('Choose your destiny: ' .. math.ceil((preparationTimeSeconds - GameTick() / 10)))
    end

end

function createPositionMarker(armyData, postable)
    local worldView = import('/lua/ui/game/worldview.lua').viewLeft

    local pos = { postable[1], postable[2], postable[3] - 10 }

    -- Bitmap of marker
    local posMarker = Bitmap(worldView)
    LayoutHelpers.AtCenterIn(posMarker, worldView)
    LayoutHelpers.SetDimensions(posMarker, 150, 25)
    posMarker.pos = pos
    posMarker.Depth:Set(10)
    posMarker:SetNeedsFrameUpdate(true)
    posMarker:DisableHitTest()

    -- Nickname
    posMarker.nickname = UIUtil.CreateText(posMarker, armyData.nickname, 12)

    posMarker.nickname:SetColor('ffffffff')

    posMarker.nickname:SetDropShadow(true)
    LayoutHelpers.AtCenterIn(posMarker.nickname, posMarker)
    posMarker.nickname:DisableHitTest()

    -- Army color line below the nickname
    posMarker.separator = Bitmap(posMarker)
    posMarker.separator:SetTexture('/mods/SSL/textures/clear.dds')
    posMarker.separator.Left:Set(posMarker.nickname.Left)
    posMarker.separator.Right:Set(posMarker.nickname.Right)

    posMarker.separator.Height:Set(1)

    LayoutHelpers.Below(posMarker.separator, posMarker.nickname, 1) --	  1	px
    posMarker.separator:SetSolidColor(armyData.color) --				    |line|
    posMarker.separator:DisableHitTest()

    -- Bitmap of faction icon
    posMarker.faction = Bitmap(posMarker)
    -- posMarker.faction:SetTexture('/mods/Reveal positions/textures/'..armyData.faction..'.tga')
    posMarker.faction:SetTexture(UIUtil.SkinnableFile(UIUtil.GetFactionIcon(armyData.faction)))

    LayoutHelpers.SetDimensions(posMarker.faction, 16, 16)

    LayoutHelpers.AtVerticalCenterIn(posMarker.faction, posMarker.nickname) --	 distance
    LayoutHelpers.LeftOf(posMarker.faction, posMarker.nickname, 4) --     |icon|   [4px]   |nickname|
    posMarker.faction:DisableHitTest()

    -- Fill the bitmap of faction icon by army color
    posMarker.color = Bitmap(posMarker.faction)
    LayoutHelpers.FillParent(posMarker.color, posMarker.faction)
    posMarker.color.Depth:Set(function()
        return posMarker.faction.Depth() - 1
    end)
    posMarker.color:SetSolidColor(armyData.color)
    posMarker.color:DisableHitTest()

    local LazyVar = import('/lua/lazyvar.lua').Create
    posMarker.PosX = LazyVar()
    posMarker.PosY = LazyVar()

    posMarker.Left:Set(function()
        return worldView.Left() + posMarker.PosX() - posMarker.Width() / 2
    end)
    posMarker.Top:Set(function()
        return worldView.Top() + posMarker.PosY() - posMarker.Height() / 2
    end)


    posMarker.OnFrame = function(self, delta)
        local pos = worldView:Project(self.pos)
        self.PosX:Set(pos.x)
        self.PosY:Set(pos.y)
    end

    return posMarker
end

function Delete()
    for _, Marker in Markers do
        Marker:Destroy()
    end
    Timer:Destroy()
    Credits:Destroy()

    ---@type WorldView
    local worldView = import("/lua/ui/game/worldview.lua").viewLeft
    if worldView.spawnOverlay then
        worldView.spawnOverlay:Destroy()
        worldView.spawnOverlay = nil
    end
    Markers = nil
    Timer = nil
    Credits = nil
end

function GetArmy(name)
    for _, Army in GetArmiesTable().armiesTable do
        if Army.name == name then
            return Army
        end
    end
end

function ArmyName(name)
    for _, Army in GetArmiesTable().armiesTable do
        if Army.name == name then
            return Army.nickname
        end
    end
    return "ERROR"
end
