do
    -- Add faction and rank to the allowed cmd arguments
    ---@type UIAutolobbyArgumentsComponent
    local AAC          = AutolobbyArgumentsComponent
    local ArgumentKeys = AAC.ArgumentKeys

    -- Ladder uses "/uef" while GW sets "/faction 0"
    ArgumentKeys["/faction"] = true
    ArgumentKeys["/rank"]    = true
    ArgumentKeys["/ssl"]     = true
end
