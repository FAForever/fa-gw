local recallBtn = false

-- Add the recall button to the second position in the top bar
table.insert(tabs, 2, 
    {
        bitmap = 'objectives',
        disableForObserver = true,
        disableInCampaign = true,
        disableInReplay = true,
        tooltip = 'recall',
        recall = true
    }
)

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

local oldCommonLogic = CommonLogic
function CommonLogic()
    oldCommonLogic()
    for i, tab in controls.tabs do
        if tab.Data.recall then
            tab.OnCheck = function(self, checked)
                    SimCallback({Func = 'ToggleRecall', Args = { From=GetFocusArmy()}})

            end
            tab.OnClick = function(self, modifiers)
                --if self._checkState == "unchecked" then
                    self:ToggleCheck()
                --end
            end
        end
    end
end

