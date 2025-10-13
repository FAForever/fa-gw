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
