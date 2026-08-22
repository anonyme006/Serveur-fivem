if not Config.Persistence.enabled then return end

local function collectProps(veh)
    if not veh or veh == 0 then return nil end

    local props = {
        model = GetEntityModel(veh),
        plate = Core.NormalizePlate(GetVehicleNumberPlateText(veh)),
        plateIndex = GetVehicleNumberPlateTextIndex(veh),
        engineHealth = GetVehicleEngineHealth(veh),
        bodyHealth = GetVehicleBodyHealth(veh),
        tankHealth = GetVehiclePetrolTankHealth(veh),
        fuelLevel = Core.GetFuelLevel(veh),
        dirtLevel = GetVehicleDirtLevel(veh),
        color1 = 0,
        color2 = 0,
        pearlescentColor = 0,
        wheelColor = 0,
        windowTint = GetVehicleWindowTint(veh),
        coords = GetEntityCoords(veh),
        heading = GetEntityHeading(veh),
    }

    local c1, c2 = GetVehicleColours(veh)
    props.color1, props.color2 = c1, c2
    local pear, wheel = GetVehicleExtraColours(veh)
    props.pearlescentColor, props.wheelColor = pear, wheel

    props.doors = {}
    for i = 0, 5 do
        props.doors[tostring(i)] = IsVehicleDoorDamaged(veh, i) and true or false
    end

    props.windows = {}
    for i = 0, 7 do
        props.windows[tostring(i)] = not IsVehicleWindowIntact(veh, i)
    end

    props.tyres = {}
    for i = 0, 7 do
        props.tyres[tostring(i)] = IsVehicleTyreBurst(veh, i, false) and true or false
    end

    return props
end

local function saveVehicle(veh)
    local props = collectProps(veh)
    if not props or not props.plate or props.plate == '' then return end
    lib.callback.await('qbx_rp_core:saveVehicle', false, props.plate, props)
end

-- Sauvegarde périodique du véhicule conduit
CreateThread(function()
    while true do
        Wait(Config.Persistence.saveInterval or 60000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                saveVehicle(veh)
            end
        end
    end
end)

-- Sauvegarde à la sortie du véhicule
if Config.Persistence.saveOnExit then
    local lastVeh = 0
    CreateThread(function()
        while true do
            Wait(400)
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) == ped then
                    lastVeh = veh
                end
            elseif lastVeh ~= 0 and DoesEntityExist(lastVeh) then
                saveVehicle(lastVeh)
                lastVeh = 0
            else
                lastVeh = 0
            end
        end
    end)
end

RegisterNetEvent('qbx_rp_core:applyVehicleDamage', function(netId, props)
    if type(props) ~= 'table' then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end

    if props.engineHealth then SetVehicleEngineHealth(veh, props.engineHealth + 0.0) end
    if props.bodyHealth then SetVehicleBodyHealth(veh, props.bodyHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(veh, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(veh, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(veh, props.dirtLevel + 0.0) end

    if type(props.tyres) == 'table' then
        for k, burst in pairs(props.tyres) do
            if burst then
                SetVehicleTyreBurst(veh, tonumber(k), true, 1000.0)
            end
        end
    end

    if type(props.doors) == 'table' then
        for k, damaged in pairs(props.doors) do
            if damaged then
                SetVehicleDoorBroken(veh, tonumber(k), true)
            end
        end
    end
end)
