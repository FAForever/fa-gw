OtherArmyResultStrings.recall = '<LOC usersync_0005>%s has fled the battle.'
OtherArmyResultStrings.autorecall = '<LOC usersync_0006>%s was recalled by his HQ.'

MyArmyResultStrings.recall = "<LOC GAMERESULT_0004>You have left the battle!"
MyArmyResultStrings.autorecall = "<LOC GAMERESULT_0005>You have been recalled by your HQ!"

function DoGameResult(armyIndex, result)

	LOG("GAMERESULT for " .. armyIndex .. " : " .. result)
    local condPos = string.find(result, " ")
	if condPos != 0 then
		result = string.sub(result, 1, condPos - 1)
	end

	if result != 'score' then
	
		if not announced[armyIndex] then
			if armyIndex == GetFocusArmy() then
				local armies = GetArmiesTable().armiesTable
				if result == 'defeat' or result == 'recall' or result == 'autorecall' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Loser=armies[armyIndex].nickname},} , true)
				elseif result == 'victory' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Winner=armies[armyIndex].nickname},} , true)
				elseif result == 'draw' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Draw=armies[armyIndex].nickname},} , true)
				end
			else
				local armies = GetArmiesTable().armiesTable
				if result == 'defeat' or result == 'recall' or result == 'autorecall' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Loser=armies[armyIndex].nickname},} , true)
				elseif result == 'victory' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Winner=armies[armyIndex].nickname},} , true)
				elseif result == 'draw' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Draw=armies[armyIndex].nickname},} , true)
				end
			end

			announced[armyIndex] = true
			if armyIndex == GetFocusArmy() then
				if SessionIsObservingAllowed() then
					SetFocusArmy(-1)
				end
				
				if result == 'victory' then
					PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Victory'}))
				else
					PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Fail'}))
				end
				
				local victory = true
				if result == 'defeat' or result == 'recall' or result == 'autorecall' then
					victory = false
				end
				
				import('/lua/ui/game/tabs.lua').OnGameOver()
				import('/lua/ui/game/tabs.lua').TabAnnouncement('main', LOC(MyArmyResultStrings[result]))
				import('/lua/ui/game/tabs.lua').AddModeText("<LOC _Score>", function() import('/lua/ui/dialogs/score.lua').CreateDialog(victory) end)
			else
				local armies = GetArmiesTable().armiesTable
				import('/lua/ui/game/score.lua').ArmyAnnounce(armyIndex, LOCF(OtherArmyResultStrings[result], armies[armyIndex].nickname))
			end
		end
	end
end