KX = KX or {}

local trackedPlate = nil
local lastCoords = nil

local function applyPerformance(vehicle, performance)
    if not Config.EnablePerformance or type(performance) ~= 'table' then return end
    SetVehicleModKit(vehicle, 0)

    local engine = Config.PerformanceMods.engine
    for i = 1, #engine.levels do
        local level = engine.levels[i]
        if level.id == performance.engine then
            SetVehicleMod(vehicle, engine.modType, level.modIndex, false)
            break
        end
    end

    local brakes = Config.PerformanceMods.brakes
    for i = 1, #brakes.levels do
        local level = brakes.levels[i]
        if level.id == performance.brakes then
            SetVehicleMod(vehicle, brakes.modType, level.modIndex, false)
            break
        end
    end

    local transmission = Config.PerformanceMods.transmission
    for i = 1, #transmission.levels do
        local level = transmission.levels[i]
        if level.id == performance.transmission then
            SetVehicleMod(vehicle, transmission.modType, level.modIndex, false)
            break
        end
    end

    local suspension = Config.PerformanceMods.suspension
    for i = 1, #suspension.levels do
        local level = suspension.levels[i]
        if level.id == performance.suspension then
            SetVehicleMod(vehicle, suspension.modType, level.modIndex, false)
            break
        end
    end

    local armor = Config.PerformanceMods.armor
    for i = 1, #armor.levels do
        local level = armor.levels[i]
        if level.id == performance.armor then
            SetVehicleMod(vehicle, armor.modType, level.modIndex, false)
            break
        end
    end

    ToggleVehicleMod(vehicle, 18, performance.turbo == 'on')
end

local function applyCosmetics(vehicle, cosmetics)
    if type(cosmetics) ~= 'table' then return end
    if cosmetics.primary ~= nil then
        local _, secondary = GetVehicleColours(vehicle)
        ClearVehicleCustomPrimaryColour(vehicle)
        SetVehicleColours(vehicle, cosmetics.primary, cosmetics.secondary or secondary)
    end
    if cosmetics.secondary ~= nil then
        local primary = GetVehicleColours(vehicle)
        SetVehicleColours(vehicle, cosmetics.primary or primary, cosmetics.secondary)
    end
    if cosmetics.wheels ~= nil then
        SetVehicleWheelType(vehicle, cosmetics.wheels)
        SetVehicleMod(vehicle, 23, 0, false)
    end
end

local function applyTireHealth(vehicle, data)
    if not data then return end
    local mapping = {
        [0] = data.tire_fl,
        [1] = data.tire_fr,
        [4] = data.tire_rl,
        [5] = data.tire_rr,
    }

    for wheelIndex, health in pairs(mapping) do
        if health and health <= 15.0 then
            SetVehicleTyreBurst(vehicle, wheelIndex, true, 1000.0)
        end
    end
end

function KX.ApplyVehicleData(vehicle, data)
    if not vehicle or vehicle == 0 or not data then return end

    if data.engine_health then
        SetVehicleEngineHealth(vehicle, data.engine_health + 0.0)
    end
    if data.body_health then
        SetVehicleBodyHealth(vehicle, data.body_health + 0.0)
    end
    if data.fuel then
        SetVehicleFuelLevel(vehicle, data.fuel + 0.0)
    end
    if data.engine_temp then
        SetVehicleEngineTemperature(vehicle, data.engine_temp + 0.0)
    end

    applyPerformance(vehicle, data.performance)
    applyCosmetics(vehicle, data.cosmetics)
    applyTireHealth(vehicle, data)

    if data.brakes_health and data.brakes_health < 30.0 then
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', 0.4)
    end
end

function KX.RepairNative(vehicle, serviceId, options)
    options = options or {}
    if not vehicle or vehicle == 0 then return end

    if serviceId == 'repair_engine' then
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleEngineTemperature(vehicle, 90.0)
        SetVehicleUndriveable(vehicle, false)
    elseif serviceId == 'repair_body' or serviceId == 'repair_doors' or serviceId == 'repair_hood'
        or serviceId == 'repair_trunk' or serviceId == 'repair_bumpers' or serviceId == 'repair_windows'
        or serviceId == 'repair_lights' then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleBodyHealth(vehicle, 1000.0)
        if serviceId ~= 'repair_body' then
            -- keep engine state if only body parts
        end
    elseif serviceId == 'clean' then
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
    elseif serviceId == 'repair_tire' or serviceId == 'replace_tire' then
        local wheel = options.wheel or 'all'
        local map = { fl = 0, fr = 1, rl = 4, rr = 5 }
        if wheel == 'all' then
            for _, idx in pairs(map) do
                SetVehicleTyreFixed(vehicle, idx)
            end
        elseif map[wheel] then
            SetVehicleTyreFixed(vehicle, map[wheel])
        end
    elseif serviceId == 'tire_sport' or serviceId == 'tire_drift' or serviceId == 'tire_offroad' or serviceId == 'tire_race' then
        for _, idx in pairs({ 0, 1, 4, 5 }) do
            SetVehicleTyreFixed(vehicle, idx)
        end
    elseif serviceId == 'paint_primary' and options.color ~= nil then
        local _, secondary = GetVehicleColours(vehicle)
        SetVehicleColours(vehicle, options.color, secondary)
    elseif serviceId == 'paint_secondary' and options.color ~= nil then
        local primary = GetVehicleColours(vehicle)
        SetVehicleColours(vehicle, primary, options.color)
    elseif serviceId == 'wheels' and options.wheelType ~= nil then
        SetVehicleModKit(vehicle, 0)
        SetVehicleWheelType(vehicle, options.wheelType)
        SetVehicleMod(vehicle, 23, 0, false)
    end
end

function KX.LoadVehicleData(vehicle)
    local plate = KX.GetVehiclePlate(vehicle)
    if not plate then return nil end
    local native = KX.GetNativeSnapshot(vehicle)
    local data = lib.callback.await('kx_mechanic:server:getVehicleData', false, plate, native)
    if data then
        KX.ApplyVehicleData(vehicle, data)
    end
    return data
end

local function computeWear(vehicle, speed)
    local wear = Config.Wear.baseWear
    local aggressive = speed > 40.0 and (IsControlPressed(0, 71) or IsControlPressed(0, 72))
    local multiplier = aggressive and Config.Wear.aggressiveMultiplier or 1.0
    local temp = GetVehicleEngineTemperature(vehicle)
    if temp >= Config.Wear.overheatThreshold then
        multiplier = multiplier * Config.Wear.overheatWearBoost
    end

    return {
        oil_level = wear.oil * multiplier,
        battery_level = wear.battery * multiplier,
        radiator_level = wear.radiator * multiplier,
        spark_plugs = wear.spark_plugs * multiplier,
        brakes_health = wear.brakes * multiplier,
        transmission_health = wear.transmission * multiplier,
        suspension_health = wear.suspension * multiplier,
        clutch_health = wear.clutch * multiplier,
        tire_fl = wear.tires * multiplier,
        tire_fr = wear.tires * multiplier,
        tire_rl = wear.tires * multiplier,
        tire_rr = wear.tires * multiplier,
        mileage = Config.Wear.mileagePerTick * (speed / 20.0),
        engine_temp = temp,
    }
end

CreateThread(function()
    if not Config.EnableWearSimulation then return end

    while true do
        local sleep = Config.Wear.tickInterval
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(vehicle, -1) == ped then
                local plate = KX.GetVehiclePlate(vehicle)
                if plate then
                    if trackedPlate ~= plate then
                        trackedPlate = plate
                        lastCoords = GetEntityCoords(vehicle)
                        KX.LoadVehicleData(vehicle)
                    end

                    local coords = GetEntityCoords(vehicle)
                    local speed = GetEntitySpeed(vehicle)
                    if lastCoords and #(coords - lastCoords) > 2.0 then
                        local delta = computeWear(vehicle, speed)
                        TriggerServerEvent('kx_mechanic:server:updateWear', plate, delta)
                    end
                    lastCoords = coords
                end
            end
        else
            trackedPlate = nil
            lastCoords = nil
            sleep = Config.Wear.tickInterval * 2
        end
        Wait(sleep)
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkPlayerEnteredVehicle' then return end
    local vehicle = args[2]
    if vehicle and DoesEntityExist(vehicle) then
        CreateThread(function()
            Wait(500)
            if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                KX.LoadVehicleData(vehicle)
            end
        end)
    end
end)