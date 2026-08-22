if not Config.Weather or not Config.Weather.enabled then return end

local currentWeather = 'CLEAR'
local blackout = false
local transition = 45.0
local hour, minute = 12, 0
local freeze = false
local timeEnabled = true
local baseServerMinute = nil
local lastSyncAt = GetGameTimer()

local function applyState(data, instant)
    if type(data) ~= 'table' then return end

    if data.weather then
        currentWeather = tostring(data.weather):upper()
    end
    if data.blackout ~= nil then blackout = data.blackout and true or false end
    if data.transition then transition = tonumber(data.transition) or transition end
    if data.hour ~= nil then hour = tonumber(data.hour) or hour end
    if data.minute ~= nil then minute = tonumber(data.minute) or minute end
    if data.freeze ~= nil then freeze = data.freeze and true or false end
    if data.timeEnabled ~= nil then timeEnabled = data.timeEnabled ~= false end

    lastSyncAt = GetGameTimer()
    baseServerMinute = hour * 60 + minute

    ClearOverrideWeather()
    ClearWeatherTypePersist()

    if instant then
        SetWeatherTypeNow(currentWeather)
        SetWeatherTypeNowPersist(currentWeather)
    else
        SetWeatherTypeOvertimePersist(currentWeather, transition + 0.0)
    end
    SetWeatherTypePersist(currentWeather)

    SetArtificialLightsState(blackout)
    SetArtificialLightsStateAffectsVehicles(blackout)

    if timeEnabled then
        NetworkOverrideClockTime(hour, minute, 0)
    end
end

RegisterNetEvent('qbx_rp_core:weather:sync', function(data)
    applyState(data, false)
end)

CreateThread(function()
    Wait(1500)
    local data = lib.callback.await('qbx_rp_core:weather:get', false)
    if data then
        applyState(data, true)
    end

    local step = tonumber((Config.Time and Config.Time.realSecondsPerGameMinute) or 2)
    step = math.max(0.25, step)

    while true do
        -- Verrouille la météo native du client
        SetWeatherTypePersist(currentWeather)
        SetWeatherTypeNow(currentWeather)
        SetArtificialLightsState(blackout)

        if timeEnabled then
            if not freeze and baseServerMinute then
                local elapsed = (GetGameTimer() - lastSyncAt) / 1000.0
                local advanced = math.floor(elapsed / step)
                local total = baseServerMinute + advanced
                NetworkOverrideClockTime(math.floor(total / 60) % 24, total % 60, 0)
            else
                NetworkOverrideClockTime(hour, minute, 0)
            end
        end

        Wait(0)
    end
end)
