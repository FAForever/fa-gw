do
    local _InitializeArmies = InitializeArmies
    function InitializeArmies()
        ScenarioInfo.IsSSL = ScenarioInfo.Options.AutoTeams
            and ScenarioInfo.Options.SpawnAreaType
            and ScenarioInfo.Options.SpawnAreaType ~= "none"

        if not ScenarioInfo.IsSSL then
            return _InitializeArmies()
        end
        return import("/lua/sim/SelectSpawnLocation.lua").InitializeArmies()
    end
end
