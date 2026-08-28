local speedMultiplier = Config.Speed.unit == 'MPH' and 2.23694 or 3.6
local speedUnitLabel = Config.Speed.unit == 'MPH' and 'MPH' or 'KM/H'

local inVehicle = false
local prevPayload = {}
local lastLocationUpdate = 0
local cachedLocation = nil

local directionLabels = {
    'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW',
}

local function getVehicleType(vehicle)
    local class = GetVehicleClass(vehicle)
    return Config.VehicleClassMap[class] or 'car'
end

local function getTypeFeatures(vehicle)
    local vType = getVehicleType(vehicle)
    return Config.VehicleTypes[vType] or Config.VehicleTypes.car, vType
end

local function getEnginePercent(vehicle)
    local health = GetVehicleEngineHealth(vehicle)
    return math.max(0, math.min(100, math.floor(health / 10)))
end

local function getEngineState(percent)
    for name, range in pairs(Config.Engine.states) do
        if percent >= range.min and percent <= range.max then
            return name
        end
    end
    return 'normal'
end

local function getGear(vehicle)
    if not Config.Gear.enabled then return nil end

    local speed = GetEntitySpeed(vehicle)
    local forward = GetEntitySpeedVector(vehicle, true)

    if speed <= Config.Gear.parkSpeed then
        if Config.Gear.usePark and GetVehicleHandbrake(vehicle) then
            return 'P'
        end
        return 'N'
    end

    if forward.y < -0.15 then
        return 'R'
    end

    local gear = GetVehicleCurrentGear(vehicle)
    if gear == 0 then
        return 'N'
    end

    return tostring(gear)
end

local function getIndicators(vehicle)
    if not Config.Indicators.enabled then return 'none' end

    local state = GetVehicleIndicatorLights(vehicle)
    if state == 1 then return 'left' end
    if state == 2 then return 'right' end
    if state == 3 then return 'warning' end
    return 'none'
end

local function getLights(vehicle)
    if not Config.Lights.enabled then return 'off' end

    local _, lightsOn, highBeams = GetVehicleLightsState(vehicle)
    if highBeams == 1 then return 'high' end
    if lightsOn == 1 then return 'low' end
    return 'off'
end

local function isBraking(vehicle)
    if not Config.Brake.enabled then return false end
    return IsControlPressed(0, 72) or IsControlPressed(0, 76)
end

local function getOpenDoors(vehicle)
    if not Config.Doors.enabled then return {} end

    local open = {}
    for door = 0, 5 do
        if GetVehicleDoorAngleRatio(vehicle, door) > 0.05 then
            open[#open + 1] = Config.Doors.labels[door] or ('door_' .. door)
        end
    end
    return open
end

local function getLocation()
    if not Config.Location.enabled then return nil end

    local now = GetGameTimer()
    if cachedLocation and (now - lastLocationUpdate) < Config.Refresh.location then
        return cachedLocation
    end

    local coords = GetEntityCoords(cache.ped)
    local data = {}

    if Config.Location.showStreet then
        local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash)
        if crossingHash ~= 0 then
            street = street .. ' · ' .. GetStreetNameFromHashKey(crossingHash)
        end
        data.street = street
    end

    if Config.Location.showZone then
        local zone = GetNameOfZone(coords.x, coords.y, coords.z)
        data.zone = GetLabelText(zone)
    end

    if Config.Location.showDirection then
        local heading = (360.0 - GetEntityHeading(cache.ped)) % 360.0
        local index = math.floor((heading + 22.5) / 45.0) % 8 + 1
        data.direction = directionLabels[index]
    end

    lastLocationUpdate = now
    cachedLocation = data
    return data
end

local function buildPayload(vehicle)
    local features = getTypeFeatures(vehicle)
    local speed = Config.Speed.enabled and math.floor(GetEntitySpeed(vehicle) * speedMultiplier) or 0
    local rpm = Config.RPM.enabled and GetVehicleCurrentRpm(vehicle) or 0
    local fuel = features.fuel and GetVehicleFuel(vehicle) or nil
    local engine = features.engine and getEnginePercent(vehicle) or nil

    local fuelRounded = fuel
    if fuel and not Config.Fuel.showDecimals then
        fuelRounded = math.floor(fuel + 0.5)
    end

    return {
        speed = speed,
        speedUnit = speedUnitLabel,
        rpm = rpm,
        fuel = fuelRounded,
        fuelRaw = fuel,
        fuelLow = fuel and fuel <= Config.Fuel.lowWarning or false,
        fuelCritical = fuel and fuel <= Config.Fuel.criticalWarning or false,
        engine = engine,
        engineState = engine and getEngineState(engine) or nil,
        engineWarning = engine and engine <= Config.Engine.warning or false,
        engineCritical = engine and engine <= Config.Engine.critical or false,
        gear = features.gear and getGear(vehicle) or nil,
        seatbelt = features.seatbelt and IsSeatbeltBuckled() or nil,
        indicators = features.indicators and getIndicators(vehicle) or 'none',
        lights = features.lights and getLights(vehicle) or 'off',
        braking = features.brake and isBraking(vehicle) or false,
        doors = features.doors and getOpenDoors(vehicle) or {},
        location = getLocation(),
        vehicleType = getVehicleType(vehicle),
        features = features,
        animations = Config.Animations.enabled,
        position = Config.Position,
    }
end

local function payloadsEqual(a, b)
    if not a or not b then return false end
    for key, value in pairs(a) do
        if key == 'features' then goto continue end
        if type(value) == 'table' then
            if not b[key] or #value ~= #b[key] then return false end
            for i = 1, #value do
                if value[i] ~= b[key][i] then return false end
            end
        else
            if b[key] ~= value then return false end
        end
        ::continue::
    end
    return true
end

local function sendVehicleUpdate(payload, force)
    if force or not payloadsEqual(payload, prevPayload) then
        prevPayload = payload
        SendNUIMessage({
            action = 'vehicle:update',
            data = payload,
        })
    end
end

local function showVehicleHud()
    inVehicle = true
    SendNUIMessage({
        action = 'vehicle:show',
        data = {
            animations = Config.Animations.enabled,
            position = Config.Position,
            speedUnit = speedUnitLabel,
            padDigits = Config.Speed.padDigits,
        },
    })
end

local function hideVehicleHud()
    inVehicle = false
    prevPayload = {}
    cachedLocation = nil
    SendNUIMessage({ action = 'vehicle:hide' })
end

local function vehicleLoop(vehicle)
    while inVehicle and cache.vehicle == vehicle do
        if LocalPlayer.state.isLoggedIn and Config.Enabled then
            if not IsPauseMenuActive() then
                sendVehicleUpdate(buildPayload(vehicle))
            end
            Wait(Config.Refresh.inVehicle)
        else
            Wait(500)
        end
    end
end

lib.onCache('vehicle', function(vehicle)
    if vehicle and vehicle ~= 0 and not IsThisModelABicycle(vehicle) then
        showVehicleHud()
        sendVehicleUpdate(buildPayload(vehicle), true)
        CreateThread(function()
            vehicleLoop(vehicle)
        end)
    else
        hideVehicleHud()
    end
end)

CreateThread(function()
    Wait(1000)
    if cache.vehicle and cache.vehicle ~= 0 and not IsThisModelABicycle(cache.vehicle) then
        showVehicleHud()
        sendVehicleUpdate(buildPayload(cache.vehicle), true)
        CreateThread(function()
            vehicleLoop(cache.vehicle)
        end)
    end
end)

exports('IsVehicleHudVisible', function()
    return inVehicle
end)

exports('GetVehicleHudData', function()
    if not cache.vehicle then return nil end
    return buildPayload(cache.vehicle)
end)
