do
    ---Restricts sending taunts from a different faction
    ---@param tauntIndex integer
    ---@return boolean
    local function canSendFactionTaunt(tauntIndex)
        local focus = GetFocusArmy()
        if focus == -1 then return false end
        ---@type ArmiesTable
        local armies = GetArmiesTable()
        ---@type ArmyInfo
        local army = armies.armiesTable[focus]
        if not army then return false end

        local faction = army.faction
        -- Nicely hardcoded, but since the taunts don't have any faction associated to them
        -- and they've changed only once in the history of FAF, it will do!
        if faction == 0 and tauntIndex >= 0 and tauntIndex <= 22 then
            return true
        elseif faction == 1 and tauntIndex >= 23 and tauntIndex <= 56 then
            return true
        elseif faction == 2 and tauntIndex >= 57 and tauntIndex <= 92 then
            return true
        elseif faction == 3 and tauntIndex >= 93 and tauntIndex <= 97 then
            return true
        end

        return false
    end

    local oldSendTaunt = SendTaunt
    function SendTaunt(tauntIndex, sender)
        if not canSendFactionTaunt(tauntIndex) then
            --LOG("Taunt blocked, wrong owner faction!")
            return
        end

        oldSendTaunt(tauntIndex, sender)
    end
end
