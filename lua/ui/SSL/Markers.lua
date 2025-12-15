local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local LazyVar = import('/lua/lazyvar.lua').Create
local LayoutFor = import('/lua/maui/layouthelpers.lua').LayoutFor

local preparationTimeSeconds = tonumber(SessionGetScenarioInfo().Options.SSLPreparationTime) or 30

---@class SSL.Marker : Bitmap
---@field worldView WorldView
---@field _nickname Text
---@field _faction Bitmap
---@field _separator Bitmap
---@field _color Bitmap
---@field PosX LazyVar
---@field PosY LazyVar
---@field pos Vector
SSLMarker = Class(Bitmap)
{
    ---@param self SSL.Marker
    ---@param parent SSL.Overlay
    ---@param worldView WorldView
    __init = function(self, parent, worldView)
        Bitmap.__init(self, parent)

        self.worldView = worldView
        self.pos = Vector(0, 0, 0)

        self._nickname = UIUtil.CreateText(self, '', 12, "Arial", true)
        self._faction = Bitmap(self)
        self._separator = Bitmap(self)
        self._color = Bitmap(self)

        self.PosX = LazyVar()
        self.PosY = LazyVar()

        self.Left:Set(function()
            return math.floor(self.worldView.Left() + self.PosX() - self.Width() * 0.5)
        end)
        self.Top:Set(function()
            return math.floor(self.worldView.Top() + self.PosY() - self.Height() * 0.5)
        end)
    end,

    ---@param self SSL.Marker
    InitLayout = function(self)
        LayoutFor(self._nickname)
            :AtCenterIn(self)
            :Color('ffffffff')

        LayoutFor(self._separator)
            :Left(self._nickname.Left)
            :Right(self._nickname.Right)
            :AnchorToBottom(self._nickname)
            :Color('ffffffff')
            :Height(1)

        LayoutFor(self._faction)
            :Width(16)
            :Height(16)
            :AtVerticalCenterIn(self._nickname)
            :LeftOf(self._nickname, 4)

        LayoutFor(self._color)
            :Fill(self._faction)
            :Under(self._faction)
            :Color('ffffffff')

        LayoutFor(self)
            :Width(150)
            :Height(25)
            :NeedsFrameUpdate(true)
            :DisableHitTest(true)
    end,


    ---@param self SSL.Marker
    ---@param data ArmyInfo
    SetArmyData = function(self, data)
        self._nickname:SetText(data.nickname)
        self._separator:SetSolidColor(data.color)
        self._color:SetSolidColor(data.color)
        self._faction:SetTexture(
            UIUtil.SkinnableFile(
                UIUtil.GetFactionIcon(data.faction)
            )
        )
    end,

    ---@param self SSL.Marker
    ---@param delta number
    OnFrame = function(self, delta)
        local pos = self.worldView:Project(self.pos)
        self.PosX:Set(pos.x)
        self.PosY:Set(pos.y)
    end
}

---@class SSL.Timer : Group
---@field _text Text
SSLTimer = Class(Group)
{
    ---@param self SSL.Timer
    ---@param parent SSL.Overlay
    __init = function(self, parent)
        Group.__init(self, parent)

        self._text = UIUtil.CreateText(self, '', 16, "Arial Black", true)
    end,

    ---@param self SSL.Timer
    InitLayout = function(self)
        LayoutFor(self._text)
            :AtCenterIn(self)
            :Color('ffffffff')

        LayoutFor(self)
            :Width(100)
            :Height(25)
            :DisableHitTest(true)
            :NeedsFrameUpdate(true)
    end,

    ---@param self SSL.Timer
    ---@param delta number
    OnFrame = function(self, delta)
        local time = math.ceil((preparationTimeSeconds - GameTick() / 10))
        self._text:SetText('Choose your spawning location: ' .. time)
    end
}

---@param name string
---@return ArmyInfo
function GetArmy(name)
    for _, Army in GetArmiesTable().armiesTable do
        if Army.name == name then
            return Army
        end
    end
end

---@class SSL.Overlay : Group
---@field _timer SSL.Timer
---@field _markers table<string, SSL.Marker>
SSLOverlay = Class(Group)
{
    ---@param self SSL.Overlay
    ---@param parent WorldView
    __init = function(self, parent)
        Group.__init(self, parent)

        self._timer = SSLTimer(self)
        self._markers = {}
    end,

    ---@param self SSL.Overlay
    InitLayout = function(self)
        local parent = self:GetParent()

        self._timer:InitLayout()
        LayoutFor(self._timer)
            :AtTopIn(self, 200)
            :AtHorizontalCenterIn(self)

        LayoutFor(self)
            :Fill(parent)
            :EnableHitTest(true)
    end,

    ---@param self SSL.Overlay
    ---@param data table<string, Vector>
    UpdateMarkers = function(self, data)
        local markers = self._markers
        for strArmy, pos in data do
            if IsDestroyed(markers[strArmy]) then
                local marker = SSLMarker(self, self:GetParent())
                marker:InitLayout()
                marker:SetArmyData(GetArmy(strArmy))
                markers[strArmy] = marker
            else
                markers[strArmy].pos = { pos[1], pos[2], pos[3] }
            end
        end
    end,

    ---@param self SSL.Overlay
    ---@param event KeyEvent
    HandleEvent = function(self, event)
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
    end,
}

function UpdateMarkers(syncMarkers)
    ---@type WorldView
    local worldView = import("/lua/ui/game/worldview.lua").viewLeft
    local overlay = worldView.spawnOverlay --[[@as SSL.Overlay]]
    if IsDestroyed(overlay) then
        worldView.spawnOverlay = SSLOverlay(worldView)
        worldView.spawnOverlay:InitLayout()
        overlay = worldView.spawnOverlay
    end
    overlay:UpdateMarkers(syncMarkers)
end

function Delete()
    ---@type WorldView
    local worldView = import("/lua/ui/game/worldview.lua").viewLeft
    if not IsDestroyed(worldView.spawnOverlay--[[@as SSL.Overlay]] ) then
        worldView.spawnOverlay:Destroy()
    end
    worldView.spawnOverlay = nil
end
