local resolvedSystem = Config.Fuel.system

local providers = {
    ox_fuel = function(vehicle)
        local stateFuel = Entity(vehicle).state.fuel
        if stateFuel then
            return stateFuel
        end
        return GetVehicleFuelLevel(vehicle)
    end,
    LegacyFuel = function(vehicle)
        if GetResourceState('LegacyFuel') ~= 'started' then
            return GetVehicleFuelLevel(vehicle)
        end
        return exports.LegacyFuel:GetFuel(vehicle)
    end,
    mnr_fuel = function(vehicle)
        if GetResourceState('mnr_fuel') ~= 'started' then
            return GetVehicleFuelLevel(vehicle)
        end
        return exports['mnr_fuel']:GetFuel(vehicle)
    end,
    native = function(vehicle)
        return GetVehicleFuelLevel(vehicle)
    end,
}

local function detectFuelSystem()
    if Config.Fuel.system ~= 'auto' then
        return Config.Fuel.system
    end
    if GetResourceState('ox_fuel') == 'started' then return 'ox_fuel' end
    if GetResourceState('LegacyFuel') == 'started' then return 'LegacyFuel' end
    if GetResourceState('mnr_fuel') == 'started' then return 'mnr_fuel' end
    return 'native'
end

CreateThread(function()
    Wait(500)
    resolvedSystem = detectFuelSystem()
end)

---@param vehicle number
---@return number
function GetVehicleFuel(vehicle)
    if not vehicle or vehicle == 0 then return 0 end

    local provider = providers[resolvedSystem] or providers.native
    local ok, value = pcall(provider, vehicle)

    if not ok or value == nil then
        value = GetVehicleFuelLevel(vehicle)
    end

    return math.max(0, math.min(100, value))
end

function GetVehicleFuelSystem()
    return resolvedSystem
end
