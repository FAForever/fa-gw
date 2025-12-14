do
    local _InitializeArmies = InitializeArmies
    function InitializeArmies()
        ScenarioInfo.IsSSL = ScenarioInfo.Options.SSLSpawnAreaType and ScenarioInfo.Options.SSLSpawnAreaType ~= "none"

        if not ScenarioInfo.IsSSL then
            return _InitializeArmies()
        end
        return import("/lua/sim/SelectSpawnLocation.lua").InitializeArmies()
    end
end
