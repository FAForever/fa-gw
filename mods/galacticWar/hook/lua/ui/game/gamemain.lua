do
    local oldCreateUI = CreateUI
    function CreateUI(isReplay)
        oldCreateUI(isReplay)
        import('/lua/ui/ability_panel/abilities.lua').SetupOrdersControl(gameParent)
    end
end
