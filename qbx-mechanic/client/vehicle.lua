--- Lecture véhicule & diagnostic — implémentation étape 4
--- Utilise uniquement des natives FiveM réelles (pas de valeurs inventées)

Vehicle = {}

---@param vehicle number
---@return table
function Vehicle.GetHealthData(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return {}
    end

    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local tankHealth = GetVehiclePetrolTankHealth(vehicle)

    local tires = {}
    for i = 0, 3 do
        local burst = IsVehicleTyreBurst(vehicle, i, false)
        local health = burst and 0.0 or 100.0
        tires[i] = health
    end

    return {
        engine = Utils.Percent(engineHealth, 1000.0),
        body = Utils.Percent(bodyHealth, 1000.0),
        tank = Utils.Percent(tankHealth, 1000.0),
        engineRaw = engineHealth,
        bodyRaw = bodyHealth,
        tankRaw = tankHealth,
        tires = {
            fl = tires[0],
            fr = tires[1],
            rl = tires[2],
            rr = tires[3],
        },
        dirt = GetVehicleDirtLevel(vehicle),
    }
end

---@param vehicle number
---@return table
function Vehicle.GetSummary(vehicle)
    if not vehicle or vehicle == 0 then return {} end

    local health = Vehicle.GetHealthData(vehicle)
    local fuel = 0

    if Config.Integrations.fuel.enabled then
        local fuelResource = Config.Integrations.fuel.resource
        if Config.Integrations.fuel.getFuelExport and GetResourceState(fuelResource) == 'started' then
            local ok, value = pcall(function()
                return exports[fuelResource][Config.Integrations.fuel.getFuelExport](vehicle)
            end)
            if ok and type(value) == 'number' then
                fuel = value
            end
        elseif GetResourceState('ox_fuel') == 'started' then
            local state = Entity(vehicle).state
            fuel = state and state.fuel or GetVehicleFuelLevel(vehicle)
        else
            fuel = GetVehicleFuelLevel(vehicle)
        end
    else
        fuel = GetVehicleFuelLevel(vehicle)
    end

    return {
        name = ClientUtils.GetVehicleDisplayName(vehicle),
        plate = ClientUtils.GetVehiclePlate(vehicle),
        class = GetVehicleClass(vehicle),
        health = health,
        fuel = Utils.Clamp(fuel, 0, 100),
    }
end

return Vehicle
