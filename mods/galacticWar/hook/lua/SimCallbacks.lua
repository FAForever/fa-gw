-- For galactic War.
do
	--- List of callbacks that is being populated throughout this file
	---@type table<string, fun(data: table, units?: Unit[])>
	local Callbacks = Callbacks

	Callbacks.ToggleRecall = import('/lua/recall.lua').ToggleRecall
	Callbacks.Deploy = function(data)
		if not OkayToMessWithArmy(data.From) then return end

		local aiBrain = GetArmyBrain(data.From)
		if aiBrain:IsDefeated() then return end

		local units = aiBrain:GetListOfUnits(categories.REINFORCEMENTSBEACON, false)
		local focusArmy = GetFocusArmy()

		if table.getn(units) == 0 and focusArmy == data.From then
			PrintText(LOC('<LOC reinforcements0001>No beacon found for deployment!'), 20, nil, 15, 'center')
		end

		for _, unit in units do
			if unit.UnitBeingBuilt or unit:GetFractionComplete() ~= 1 then
				if focusArmy == data.From then
					PrintText(LOC('<LOC reinforcements0002>The beacon is not complete!'), 20, nil, 15, 'center')
				end
			else
				unit:Deploy(data.Index)
			end
		end
	end
end