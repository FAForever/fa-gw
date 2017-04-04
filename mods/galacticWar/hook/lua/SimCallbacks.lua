-- For galactic War.
Callbacks.ToggleRecall = import('/lua/recall.lua').ToggleRecall
Callbacks.Deploy = import('/lua/gwReinforcements.lua').Deploy

-- issue:#43
Callbacks.AddTarget = function(data, units)
	if type(data.target) == 'string' then
		local entity = GetEntityById(data.target)
		if entity and IsBlip(entity) and entity.GetSource then
			local blipentity = entity:GetSource()
			if blipentity then
				if IsUnit(blipentity) then
					for id, unit in units or {} do
						blipentity:addAttacker(unit)
						unit:addTarget(blipentity)
					end
				end
			end
		end
	end
end

Callbacks.ClearTargets = function(data, units)
	for id, unit in units or {} do	
		if unit then 
			unit:clearTarget()
		end
	end
end