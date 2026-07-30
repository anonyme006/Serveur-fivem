Core = Core or {}

function Core.Locale(key, ...)
    local pack = Locales[Config.Locale] or Locales['fr'] or {}
    local str = pack[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

function Core.NormalizePlate(plate)
    return (plate or ''):gsub('%s+', ''):upper()
end

function Core.DecodeJson(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return {} end
    local ok, data = pcall(json.decode, raw)
    return (ok and type(data) == 'table' and data) or {}
end

function Core.Notify(msg, nType)
    if lib and lib.notify then
        lib.notify({
            title = Core.Locale('notify_title'),
            description = msg,
            type = nType or 'inform',
        })
        return
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

function Core.GetFuelLevel(vehicle)
    if not vehicle or vehicle == 0 then return 100.0 end

    local mode = Config.Alerts.fuel.resource or 'auto'
    local state = GetResourceState

    local function fromOx()
        local ok, val = pcall(function()
            return Entity(vehicle).state.fuel
        end)
        if ok and type(val) == 'number' then return val end
        return nil
    end

    local function fromLegacy()
        local ok, val = pcall(function()
            return exports['LegacyFuel']:GetFuel(vehicle)
        end)
        if ok and type(val) == 'number' then return val end
        return nil
    end

    if mode == 'ox_fuel' or (mode == 'auto' and state('ox_fuel') == 'started') then
        return fromOx() or GetVehicleFuelLevel(vehicle)
    end

    if mode == 'LegacyFuel' or (mode == 'auto' and state('LegacyFuel') == 'started') then
        return fromLegacy() or GetVehicleFuelLevel(vehicle)
    end

    return GetVehicleFuelLevel(vehicle)
end

function Core.Percent(value, max)
    max = max or 100.0
    value = tonumber(value) or max
    local pct = math.floor((value / max) * 100 + 0.5)
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end
    return pct
end
