--[[
    Pulse Phone — Server bootstrap
]]

Pulse = Pulse or {}
Pulse.Server = Pulse.Server or {}
Pulse.Cache = Pulse.Cache or {
    numbers = {}, -- citizenid -> number
    playersByNumber = {}, -- number -> source
}

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

---@param src number
---@return string|nil
function Pulse.Server.GetCitizenId(src)
    local player = getPlayer(src)
    if not player then return nil end
    return player.PlayerData.citizenid
end

---@param src number
---@return table|nil
function Pulse.Server.GetPlayer(src)
    return getPlayer(src)
end

lib.callback.register('pulse-phone:server:getBootstrap', function(source)
    local player = getPlayer(source)
    if not player then return nil end

    local citizenid = player.PlayerData.citizenid
    local user = Pulse.Database.EnsureUser(citizenid, player)
    if not user then return nil end

    Pulse.Cache.numbers[citizenid] = user.phone_number
    Pulse.Cache.playersByNumber[user.phone_number] = source

    local charinfo = player.PlayerData.charinfo or {}
    return {
        citizenid = citizenid,
        firstname = charinfo.firstname or 'Unknown',
        lastname = charinfo.lastname or '',
        phoneNumber = user.phone_number,
        wallpaper = user.wallpaper,
        theme = user.theme,
        battery = user.battery or 100,
        signal = 4,
        time = os.date('%H:%M'),
        date = os.date('%A %d %B'),
    }
end)

AddEventHandler('playerDropped', function()
    local src = source
    local citizenid = Pulse.Server.GetCitizenId(src)
    if not citizenid then return end
    local number = Pulse.Cache.numbers[citizenid]
    if number then
        Pulse.Cache.playersByNumber[number] = nil
    end
    Pulse.Cache.numbers[citizenid] = nil
    if Pulse.Calls and Pulse.Calls.OnPlayerDropped then
        Pulse.Calls.OnPlayerDropped(src, citizenid)
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Pulse.Database.Init()
    Pulse.Companies.SyncFromConfig()
    print('^2[pulse-phone]^7 started')
end)
