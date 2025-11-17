local utils = import("/lua/utilities.lua")

---GW: Use scenario reason to disable the multiplayer recall feature
---Not to confuse with GW recall, which has its own button and works differently
---@param data {From: number, Vote: boolean}
function SetRecallVote(data)
    local army = data.From
    if not OkayToMessWithArmy(army) then
        return
    end
    local focus = GetFocusArmy()
    if army == focus then
        SyncCannotRequestRecall("scenario")
    end
end

---Returns the duration of recall based on the distance from the starting position
---
---@see https://www.desmos.com/calculator/ydjvzrg8jl
---@param unit Unit
---@return number time
function CalculateRecallTime(unit)
    local minimumTime = 15
    local maxTime = 90

    local aiBrain = unit:GetAIBrain()
    local startX, startZ = aiBrain:GetArmyStartPos()
    local pos = unit:GetPosition()
    local distance = utils.GetDistanceBetweenTwoPoints2(startX, startZ, pos[1], pos[3])
    local time = math.min(minimumTime + math.pow(math.sqrt(distance), 1.45), maxTime)
    --LOG("Recall time: ", time, ", distance: ", distance)

    return time
end
