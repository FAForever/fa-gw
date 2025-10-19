---@return string
function GetReplayId()
    local id = nil

    if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") and GetFrontEndData('syncreplayid') ~= nil and GetFrontEndData('syncreplayid') ~= 0 then
        id = GetFrontEndData('syncreplayid')
    elseif HasCommandLineArg("/savereplay") then
        local url = GetCommandLineArg("/savereplay", 1)[1] --[[@as string]]
        --GW replays are currently saved locally at %gamedata%/replays/gw/GAMEID_player_PLAYERID.SCFAReplay
        id = string.match(url, '.*/(%d+)_') -- gets the number between last "/" and "_"
    elseif HasCommandLineArg("/replayid") then
        id =  GetCommandLineArg("/replayid", 1)[1]
    end

    return id
end
