local CommandMode = import('/lua/ui/game/commandmode.lua')

local recallBtn = false

local tabs = {
    {
        bitmap = 'menu',
        content = 'main',
        closeSound = 'UI_Main_Window_Close',
        openSound = 'UI_Main_Window_Open',
        tooltip = 'exit_menu',
    },
    {
        bitmap = 'objectives',
        disableForObserver = true,
        disableInCampaign = true,
        disableInReplay = true,
        tooltip = 'recall',
        recall = true
    },
    {
        bitmap = 'diplomacy',
        content = 'diplomacy',
        disableInCampaign = true,
        disableInReplay = true,
        disableForObserver = true,
        closeSound = 'UI_Diplomacy_Close',
        openSound = 'UI_Diplomacy_Open',
        tooltip = 'diplomacy',
    },
    {
        pause = true,
        disableForObserver = true,
        tooltip = 'options_Pause',
    },
}
-- TODO: Dont hook the whole table, remove just the rehost feature instead
local menus = {
    main = {
        singlePlayer = {
            {
                action = 'Save',
                disableOnGameOver = true,
                label = '<LOC _Save_Game>Save Game',
                tooltip = 'esc_save',
            },
            {
                action = 'Load',
                label = '<LOC _Load_Game>Load Game',
                tooltip = 'esc_load',
            },
            {
                action = 'Options',
                label = '<LOC _Options>',
                tooltip = 'esc_options',
            },
            {
                action = 'RestartGame',
                label = '<LOC _Restart_Game>Restart Game',
                tooltip = 'esc_restart',
            },
            {
                action = 'EndSPGame',
                label = '<LOC _End_Game>',
                tooltip = 'esc_quit',
            },
            {
                action = 'ExitSPGame',
                label = '<LOC _Exit_to_Windows>',
                tooltip = 'esc_exit',
            },
            {
                action = 'Return',
                disableOnGameOver = true,
                label = '<LOC main_menu_9586>Close Menu',
                tooltip = 'esc_return',
            },
        },
        replay = {
            {
                action = 'LoadReplay',
                label = '<LOC _Load_Replay>Load Replay',
                tooltip = 'esc_load',
            },
            {
                action = 'Options',
                label = '<LOC _Options>',
                tooltip = 'esc_options',
            },
            {
                action = 'RestartReplay',
                label = '<LOC _Restart_Replay>Restart Replay',
                tooltip = 'esc_restart',
            },
            {
                action = 'EndMPGame',
                label = '<LOC _End_Replay>',
                tooltip = 'esc_quit',
            },
            {
                action = 'ExitMPGame',
                label = '<LOC _Exit_to_Windows>',
                tooltip = 'esc_exit',
            },
            {
                action = 'Return',
                disableOnGameOver = true,
                label = '<LOC main_menu_9586>Close Menu',
                tooltip = 'esc_return',
            },
        },
        lan = {
            {
                action = 'Options',
                label = '<LOC _Options>',
                tooltip = 'esc_options',
            },
            {
                action = 'EndMPGame',
                label = '<LOC _End_Game>',
                tooltip = 'esc_quit',
            },
            {
                action = 'ExitMPGame',
                label = '<LOC _Exit_to_Windows>',
                tooltip = 'esc_exit',
            },
            {
                action = 'Return',
                disableOnGameOver = true,
                label = '<LOC main_menu_9586>Close Menu',
                tooltip = 'esc_return',
            },
        },
        gpgnet = {
            {
                action = 'ShowGameInfo',
                label = 'Show Game Info',
                tooltip = 'Show the settings of this game',
            },
			{
                action = 'Options',
                label = '<LOC _Options>',
                tooltip = 'esc_options',
            },
            {
                action = 'ExitMPGame',
                label = 'Exit to FAF',
                tooltip = 'esc_exit',
            },
            {
                action = 'Return',
                disableOnGameOver = true,
                label = '<LOC main_menu_9586>Close Menu',
                tooltip = 'esc_return',
            },
        },
    },
}

local actions = {
    Save = function()
        local saveType
        if import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
            saveType = "CampaignSave"
        else
            saveType = "SaveGame"
        end
        import('/lua/ui/dialogs/saveload.lua').CreateSaveDialog(GetFrame(0), nil, saveType)
    end,
    Load = function()
        if import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
            saveType = "CampaignSave"
        else
            saveType = "SaveGame"
        end
        import('/lua/ui/dialogs/saveload.lua').CreateLoadDialog(GetFrame(0), nil, saveType)
    end,
    LoadReplay = function()
        import('/lua/ui/dialogs/replay.lua').CreateDialog(GetFrame(0), true)
    end,
    EndSPGame = function()
        UIUtil.QuickDialog(GetFrame(0), "<LOC EXITDLG_0001>Are you sure you'd like to quit?", 
            "<LOC _Yes>", EndGame,
            "<LOC _Save>", EndGameSaveWindow,
            "<LOC _No>", nil,
            true,
            {escapeButton = 3, enterButton = 1, worldCover = true})
    end,
    EndMPGame = function()
        UIUtil.QuickDialog(GetFrame(0), "<LOC EXITDLG_0001>Are you sure you'd like to quit?",
        "<LOC _Yes>", EndGame, 
        "<LOC _No>", nil,
            nil, nil,
            true,
            {escapeButton = 3, enterButton = 1, worldCover = true})
    end,
    RestartGame = function()
        UIUtil.QuickDialog(GetFrame(0), "<LOC EXITDLG_0002>Are you sure you'd like to restart?", 
            "<LOC _Yes>", function() RestartSession() end, 
            "<LOC _No>", nil,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = true})
    end,
    RestartReplay = function()
        local replayFilename = GetFrontEndData('replay_filename')
        UIUtil.QuickDialog(GetFrame(0), "<LOC EXITDLG_0002>Are you sure you'd like to restart?", 
            "<LOC _Yes>", function() LaunchReplaySession(replayFilename) end, 
            "<LOC _No>", nil)
    end,
    ExitSPGame = function()
        UIUtil.QuickDialog(GetFrame(0), "<LOC EXITDLG_0003>Are you sure you'd like to exit?", 
            "<LOC _Yes>", function()
                ExitApplication()
            end, 
            "<LOC _Save>", ExitGameSaveWindow,
            "<LOC _No>", nil,
            true,
            {escapeButton = 3, enterButton = 1, worldCover = true})
    end,
    ExitMPGame = function()
        UIUtil.QuickDialog(GetFrame(0), "<LOC EXITDLG_0003>Are you sure you'd like to exit?", 
            "<LOC _Yes>", function()
                ExitApplication()
            end, 
            "<LOC _No>", nil,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = true})
    end,
	ShowGameInfo = function()
        ToggleGameInfo()
    end,
    Return = function()
        CollapseWindow()
    end,
    Options = function()
        import('/lua/ui/dialogs/options.lua').CreateDialog(GetFrame(0))
    end,
}

controls = {
    parent = false,
    bgBottomGlow = false,
    bgTopGlow = false,
    bgStretch = false,
}

function Create(parent)
    savedParent = parent
    
    controls.parent = Group(savedParent)
    controls.parent.Depth:Set(100)
    
    controls.bgTop = CreateStretchBar(controls.parent, true)
    controls.bgBottom = CreateStretchBar(controls.parent)
    controls.bgBottom.Width:Set(controls.bgTop.Width)
    
    controls.collapseArrow = Checkbox(savedParent)
    Tooltip.AddCheckboxTooltip(controls.collapseArrow, 'menu_collapse')
    
    controls.tabContainer = Group(controls.bgTop)
    controls.tabContainer:DisableHitTest()
    
    local function CreateTab(data)
        local tab = Checkbox(controls.tabContainer)
        tab.Depth:Set(function() return controls.bgTop.Depth() + 10 end)
        tab.Data = data
        Tooltip.AddCheckboxTooltip(tab, data.tooltip)
        
        if data.pause then
            tab.Glow = Bitmap(tab)
            LayoutHelpers.AtCenterIn(tab.Glow, tab)
            tab.Glow:DisableHitTest()
            tab.Glow:SetAlpha(0)
        end
        
        return tab
    end
    
    controls.tabs = {}
    for i, data in tabs do
        local index = i
        controls.tabs[index] = CreateTab(data)
        if data.pause then
            pauseBtn = controls.tabs[index]
        end
        if data.recall then
            recallBtn = controls.tabs[index]
        end

    end
    
    SetLayout()
    CommonLogic()
end

function CommonLogic()
    for i, tab in controls.tabs do
        if tab.Data.disableInCampaign and import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
            tab:Disable()
        elseif tab.Data.disableInReplay and SessionIsReplay() then
            tab:Disable()
        elseif tab.Data.disableForObserver and GetFocusArmy() == -1 then
            tab:Disable()
        end
        if tab.Data.recall then
            tab.OnCheck = function(self, checked)
                    SimCallback({Func = 'ToggleRecall', Args = { From=GetFocusArmy()}})

            end
            tab.OnClick = function(self, modifiers)
--                if self._checkState == "unchecked" then
                    self:ToggleCheck()
--                end
            end   
        
        elseif tab.Data.pause then
            if not CanUserPause() then
                tab:Disable()
            end
            tab.Glow.Time = 0
            tab.Glow.OnFrame = function(self, delta)
                self.Time = self.Time + (delta * 10)
                local newAlpha = MATH_Lerp(math.sin(self.Time), -1, 1, 0, .5)
                self:SetAlpha(newAlpha)
                if self.LastCycle and newAlpha < .1 then
                    self:SetNeedsFrameUpdate(false)
                    self:SetAlpha(0)
                end
            end
            tab.OnCheck = function(self, checked)
                if checked then
                    if not CanUserPause() then
                        return
                    end
                    SessionRequestPause()
                    self:SetGlowState(checked)
                else
                    SessionResume()
                    self:SetGlowState(checked)
                end
            end
            tab.OnClick = function(self, modifiers)
                if self._checkState == "unchecked" then
                    if CanUserPause() then
                        self:ToggleCheck()
                    end
                else
                    self:ToggleCheck()
                    if not CanUserPause() then
                        self:Disable()
                    end
                end
            end
            tab.SetGlowState = function(self, state)
                if state then
                    self.Glow.LastCycle = false
                    self.Glow.Time = 0
                    self.Glow:SetNeedsFrameUpdate(true)
                else
                    self.Glow.LastCycle = true
                end
            end
        else
            tab.OnCheck = function(self, checked)
                for _, altTab in controls.tabs do
                    if altTab != self and not altTab.Data.pause and not altTab.Data.recall then
                        altTab:SetCheck(false, true)
                    end
                end
                if checked then
                    local sound = Sound({Cue = self.Data.openSound, Bank = "Interface",})
                    PlaySound(sound)
                    BuildContent(self.Data.content)
                else
                    local sound = Sound({Cue = self.Data.closeSound, Bank = "Interface",})
                    PlaySound(sound)
                    CollapseWindow()
                end
            end
            tab.OnClick = function(self, modifiers)
                if not animationLock then
                    self:ToggleCheck()
                end
            end
        end
    end
    controls.collapseArrow.OnCheck = function(self, checked)
        ToggleTabDisplay()
    end
end

function BuildContent(contentID)
    ToggleTabDisplay(true)
    controls.collapseArrow:SetCheck(false, true)
    if controls.contentGroup then
        CollapseWindow(function() BuildContent(contentID) end)
        return
    end
    import('/lua/ui/game/multifunction.lua').CloseMapDialog()
    import('/lua/ui/game/chat.lua').CloseChatConfig()
    activeTab = contentID
    for _, tab in controls.tabs do
        if tab.Data.content == contentID then
            tab:SetCheck(true, true)
        end
    end
    local contentGroup = false
    if menus[contentID] then
        contentGroup = Group(controls.parent)
        
        local function BuildButton(button)
            local btn = UIUtil.CreateButtonStd(contentGroup, '/game/medium-btn/medium', button.label, UIUtil.menuFontSize)
            btn.label:SetFont(UIUtil.factionFont, UIUtil.menuFontSize)
            if button.action and actions[button.action] then
                btn.OnClick = function() CollapseWindow(actions[button.action]) end
            end
            LayoutHelpers.AtVerticalCenterIn(btn.label, btn, 4)
            return btn
        end
        
        local tableID = 'singlePlayer'
        if HasCommandLineArg('/gpgnet') then
            tableID = 'gpgnet'
        elseif SessionIsMultiplayer() then
            tableID = 'lan'
        elseif GameMain.GetReplayState() then
            tableID = 'replay'
        end
        
        contentGroup.Buttons = {}
        
        for index, buttonData in menus[contentID][tableID] do
            local i = index
            contentGroup.Buttons[i] = BuildButton(buttonData)
            if gameOver and buttonData.disableOnGameOver then
                contentGroup.Buttons[i]:Disable()
            end
            if i == 1 then
                LayoutHelpers.AtTopIn(contentGroup.Buttons[i], contentGroup)
                LayoutHelpers.AtHorizontalCenterIn(contentGroup.Buttons[i], contentGroup)
            else
                LayoutHelpers.Below(contentGroup.Buttons[i], contentGroup.Buttons[i-1])
            end
        end
        
        controls.bgTop.widthOffset = 4
        contentGroup.Width:Set(contentGroup.Buttons[1].Width)
        contentGroup.Height:Set(function() return contentGroup.Buttons[1].Height() * table.getsize(contentGroup.Buttons) end)
    else
        controls.bgTop.widthOffset = 30
        contentGroup = import('/lua/ui/game/'..contentID..'.lua').CreateContent(controls.parent)
    end
    
    animationLock = true
    
    contentGroup.Top:Set(function() return controls.bgTop.Bottom() + 20 end)
    LayoutHelpers.AtHorizontalCenterIn(contentGroup, controls.bgTop)
    contentGroup:SetAlpha(0, true)
    contentGroup.OnFrame = function(self, delta)
        local newAlpha = self:GetAlpha() + (4 * delta)
        if newAlpha > 1 then
            newAlpha = 1
            self:SetNeedsFrameUpdate(false)
        end
        self:SetAlpha(newAlpha, true)
    end
    
    controls.contentGroup = contentGroup
    
    CreateStretchBG()
    controls.bgTop:SetNeedsFrameUpdate(true)
    controls.bgTop.Time = 0
    controls.bgTop.OnFrame = function(self, delta)
        self.Time = self.Time + delta
        local newWidth = self.Width() + (delta * 500)
        if newWidth > math.max(contentGroup.Width() + self.widthOffset, self.defWidth) or self.Time > .1 then
            newWidth = math.max(contentGroup.Width() + self.widthOffset, self.defWidth)
            self:SetNeedsFrameUpdate(false)
            controls.bgBottom:SetNeedsFrameUpdate(true)
        end
        self.Width:Set(newWidth)
    end
    controls.bgBottom.Time = 0
    controls.bgBottom.OnFrame = function(self, delta)
        self.Time = self.Time + delta
        local newTop = self.Top() + (delta * 1200)
        if newTop > controls.contentGroup.Bottom() or self.Time > .2 then
            newTop = controls.contentGroup.Bottom
            controls.contentGroup:SetNeedsFrameUpdate(true)
            self:SetNeedsFrameUpdate(false)
            animationLock = false
        end
        self.Top:Set(newTop)
    end
end

function OnPause(state, pausedBy, lTimeoutsRemaining, isOwner)
    pauseBtn:SetCheck(state, true)
    pauseBtn:SetGlowState(state)
    local text = '<LOC pause_0001>Game Resumed'
    local owner = false
    if state then
        CreateScreenGlow()
        text = '<LOC pause_0002>Game Paused'
    else
        HideScreenGlow()
    end
    if not isOwner and pausedBy then
        owner = LOCF('<LOC pause_0000>By %s', SessionGetCommandSourceNames()[pausedBy])
    end

    if lTimeoutsRemaining and isOwner then
        timeoutsRemaining = lTimeoutsRemaining
    end

    if state then
        Tooltip.SetTooltipText(pauseBtn, LOC('<LOC tooltipui0098>'))
        Tooltip.AddCheckboxTooltip(pauseBtn, 'options_Play')
    else
        Tooltip.SetTooltipText(pauseBtn, LOC('<LOC tooltipui0195>'))
        Tooltip.AddCheckboxTooltip(pauseBtn, 'options_Pause')
    end
    import('/lua/ui/game/announcement.lua').CreateAnnouncement(text, pauseBtn, owner)
end

function ToggleRecall()
    LOG("recall")
end