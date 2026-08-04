if not Config.Weather or not Config.Weather.enabled then return end

local weatherCfg = Config.Weather
local timeCfg = Config.Time or { enabled = false }

local currentWeather = weatherCfg.startWeather or 'CLEAR'
local blackout = weatherCfg.blackout and true or false
local hour = (timeCfg.hour or 12) % 24
local minute = (timeCfg.minute or 0) % 60
local freezeTime = timeCfg.freeze and true or false

local VALID = {
    CLEAR = true, EXTRASUNNY = true, CLOUDS = true, OVERCAST = true,
    RAIN = true, CLEARING = true, THUNDER = true, SMOG = true,
    FOGGY = true, XMAS = true, SNOW = true, SNOWLIGHT = true,
    BLIZZARD = true, HALLOWEEN = true, NEUTRAL = true,
}

local function isAdmin(src)
    local xPlayer = Core.GetPlayer(src)
    if not xPlayer or not xPlayer.getGroup then return false end
    local group = xPlayer.getGroup()
    return weatherCfg.adminGroups and weatherCfg.adminGroups[group] == true
end

local function buildPool()
    local pool = {}
    for weather, weight in pairs(weatherCfg.types or {}) do
        weight = tonumber(weight) or 0
        if weight > 0 and VALID[weather] then
            for _ = 1, weight do
                pool[#pool + 1] = weather
            end
        end
    end
    if #pool == 0 then pool[1] = 'CLEAR' end
    return pool
end

local weatherPool = buildPool()

local function pickWeather(exclude)
    if #weatherPool == 1 then return weatherPool[1] end
    for _ = 1, 12 do
        local w = weatherPool[math.random(1, #weatherPool)]
        if w ~= exclude then return w end
    end
    return weatherPool[math.random(1, #weatherPool)]
end

local function syncPayload()
    return {
        weather = currentWeather,
        blackout = blackout,
        transition = weatherCfg.transitionSeconds or 45.0,
        hour = hour,
        minute = minute,
        freeze = freezeTime,
        timeEnabled = timeCfg.enabled ~= false,
    }
end

local function broadcast(target)
    TriggerClientEvent('esx_core:weather:sync', target or -1, syncPayload())
end

local function setWeather(weather, silent)
    weather = type(weather) == 'string' and weather:upper() or weather
    if not VALID[weather] then return false end
    currentWeather = weather
    broadcast(-1)
    if not silent and weatherCfg.notifyPlayers then
        TriggerClientEvent('esx_core:notify', -1, Core.Locale('weather_changed', weather), 'inform')
    end
    return true
end

local function setBlackout(state)
    blackout = state and true or false
    broadcast(-1)
    return blackout
end

local function setTime(h, m, silent)
    hour = math.floor(tonumber(h) or hour) % 24
    minute = math.floor(tonumber(m) or minute) % 60
    broadcast(-1)
    if not silent and weatherCfg.notifyPlayers then
        TriggerClientEvent(
            'esx_core:notify',
            -1,
            Core.Locale('time_changed', ('%02d:%02d'):format(hour, minute)),
            'inform'
        )
    end
end

-- Départ
CreateThread(function()
    Wait(500)
    if not weatherCfg.startWeather or not VALID[weatherCfg.startWeather:upper()] then
        currentWeather = pickWeather(nil)
    else
        currentWeather = weatherCfg.startWeather:upper()
    end
    broadcast(-1)
    print(('^2[esx_core]^0 météo sync : %s | %02d:%02d'):format(currentWeather, hour, minute))
end)

-- Rotation dynamique
CreateThread(function()
    while true do
        local minutes = tonumber(weatherCfg.changeMinutes) or 20
        Wait(math.max(1, minutes) * 60 * 1000)
        if weatherCfg.dynamic then
            setWeather(pickWeather(currentWeather), false)
        end
    end
end)

-- Avance de l'heure in-game
CreateThread(function()
    if timeCfg.enabled == false then return end
    local step = tonumber(timeCfg.realSecondsPerGameMinute) or 2
    step = math.max(0.25, step)

    while true do
        Wait(math.floor(step * 1000))
        if not freezeTime then
            minute = minute + 1
            if minute >= 60 then
                minute = 0
                hour = (hour + 1) % 24
            end
        end
    end
end)

-- Resync périodique
CreateThread(function()
    local interval = (timeCfg.syncInterval or 30000)
    while true do
        Wait(interval)
        broadcast(-1)
    end
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    local src = type(playerId) == 'number' and playerId or source
    SetTimeout(1500, function()
        broadcast(src)
    end)
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(4000, function()
        if GetPlayerEndpoint(src) then
            broadcast(src)
        end
    end)
end)

lib.callback.register('esx_core:weather:get', function()
    return syncPayload()
end)

--- Exports
exports('GetWeather', function()
    return currentWeather, blackout
end)

exports('SetWeather', function(weather)
    return setWeather(weather, true)
end)

exports('SetBlackout', function(state)
    return setBlackout(state)
end)

exports('GetTime', function()
    return hour, minute, freezeTime
end)

exports('SetTime', function(h, m)
    setTime(h, m, true)
end)

exports('FreezeTime', function(state)
    freezeTime = state and true or false
    broadcast(-1)
    return freezeTime
end)

--- Commandes admin
RegisterCommand('weather', function(src, args)
    if src > 0 and not isAdmin(src) then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('weather_denied'), 'error')
        return
    end

    local w = args[1] and args[1]:upper() or nil
    if not w or not VALID[w] then
        local list = {}
        for name in pairs(VALID) do list[#list + 1] = name end
        table.sort(list)
        local msg = Core.Locale('weather_usage', table.concat(list, ', '))
        if src > 0 then
            TriggerClientEvent('esx_core:notify', src, msg, 'inform')
        else
            print(msg)
        end
        return
    end

    setWeather(w, true)
    local msg = Core.Locale('weather_set', w)
    if src > 0 then
        TriggerClientEvent('esx_core:notify', src, msg, 'success')
    else
        print(msg)
    end
end, false)

RegisterCommand('time', function(src, args)
    if src > 0 and not isAdmin(src) then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('weather_denied'), 'error')
        return
    end

    local h = tonumber(args[1])
    local m = tonumber(args[2]) or 0
    if h == nil then
        local msg = Core.Locale('time_usage')
        if src > 0 then
            TriggerClientEvent('esx_core:notify', src, msg, 'inform')
        else
            print(msg)
        end
        return
    end

    setTime(h, m, true)
    local msg = Core.Locale('time_set', ('%02d:%02d'):format(hour, minute))
    if src > 0 then
        TriggerClientEvent('esx_core:notify', src, msg, 'success')
    else
        print(msg)
    end
end, false)

RegisterCommand('blackout', function(src, args)
    if src > 0 and not isAdmin(src) then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('weather_denied'), 'error')
        return
    end

    local arg = args[1] and args[1]:lower() or nil
    local state
    if arg == 'on' or arg == '1' or arg == 'true' then
        state = true
    elseif arg == 'off' or arg == '0' or arg == 'false' then
        state = false
    else
        state = not blackout
    end

    setBlackout(state)
    local msg = Core.Locale(state and 'blackout_on' or 'blackout_off')
    if src > 0 then
        TriggerClientEvent('esx_core:notify', src, msg, 'success')
    else
        print(msg)
    end
end, false)

RegisterCommand('freezetime', function(src)
    if src > 0 and not isAdmin(src) then
        TriggerClientEvent('esx_core:notify', src, Core.Locale('weather_denied'), 'error')
        return
    end
    freezeTime = not freezeTime
    broadcast(-1)
    local msg = Core.Locale(freezeTime and 'time_frozen' or 'time_unfrozen')
    if src > 0 then
        TriggerClientEvent('esx_core:notify', src, msg, 'success')
    else
        print(msg)
    end
end, false)
