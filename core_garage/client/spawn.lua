--[[--------------------------------------------------------------------------
    core_garage — spawn véhicule + application props
---------------------------------------------------------------------------]]

---@param vehicle number
---@param props table
local function setVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or type(props) ~= 'table' then return end

    -- ESX helper si dispo
    if ESX and ESX.Game and ESX.Game.SetVehicleProperties then
        ESX.Game.SetVehicleProperties(vehicle, props)
    else
        if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
        if props.color1 then
            local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
            SetVehicleColours(vehicle, props.color1, props.color2 or props.color1)
            SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor or wheelColor)
        end
        if props.mods then
            for modType, modIndex in pairs(props.mods) do
                SetVehicleMod(vehicle, tonumber(modType), modIndex, false)
            end
        end
        for i = 0, 49 do
            local key = 'mod' .. i
            if props[key] ~= nil then
                SetVehicleMod(vehicle, i, props[key], false)
            end
        end
        if props.modLivery or props.livery then
            SetVehicleLivery(vehicle, props.modLivery or props.livery)
        end
        if props.extras then
            for id, enabled in pairs(props.extras) do
                SetVehicleExtra(vehicle, tonumber(id), enabled and 0 or 1)
            end
        end
        if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end
        if props.neonEnabled then
            for i = 0, 3 do
                SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i + 1] == true)
            end
        end
        if props.neonColor then
            SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
        end
        if props.tyreSmokeColor then
            SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
        end
        if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
    end

    -- Santé / essence / saleté
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then
        SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
        -- Compat scripts essence
        Entity(vehicle).state:set('fuel', props.fuelLevel + 0.0, true)
    end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end

    -- Vitres
    if props.windows then
        for i, broken in pairs(props.windows) do
            if broken then SmashVehicleWindow(vehicle, tonumber(i)) end
        end
    end

    -- Portes
    if props.doors then
        for i, broken in pairs(props.doors) do
            if broken then SetVehicleDoorBroken(vehicle, tonumber(i), true) end
        end
    end

    -- Pneus
    if props.tyres then
        for i, burst in pairs(props.tyres) do
            if burst then SetVehicleTyreBurst(vehicle, tonumber(i), true, 1000.0) end
        end
    end

    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, false, true, false)
end

--- Capture props complets
function CoreGarage.GetVehicleProperties(vehicle)
    if ESX and ESX.Game and ESX.Game.GetVehicleProperties then
        local props = ESX.Game.GetVehicleProperties(vehicle)
        props.engineHealth = GetVehicleEngineHealth(vehicle)
        props.bodyHealth = GetVehicleBodyHealth(vehicle)
        props.tankHealth = GetVehiclePetrolTankHealth(vehicle)
        props.fuelLevel = GetVehicleFuelLevel(vehicle)
        props.dirtLevel = GetVehicleDirtLevel(vehicle)

        props.windows = {}
        for i = 0, 7 do
            props.windows[i] = not IsVehicleWindowIntact(vehicle, i)
        end
        props.doors = {}
        for i = 0, 5 do
            props.doors[i] = IsVehicleDoorDamaged(vehicle, i)
        end
        props.tyres = {}
        for i = 0, 7 do
            props.tyres[i] = IsVehicleTyreBurst(vehicle, i, false)
        end
        return props
    end

    -- Fallback minimal
    local props = {
        model = GetEntityModel(vehicle),
        plate = GarageUtils.NormalizePlate(GetVehicleNumberPlateText(vehicle)),
        engineHealth = GetVehicleEngineHealth(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        tankHealth = GetVehiclePetrolTankHealth(vehicle),
        fuelLevel = GetVehicleFuelLevel(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle),
        color1 = 0,
        color2 = 0,
        windows = {},
        doors = {},
        tyres = {},
        extras = {},
    }
    local c1, c2 = GetVehicleColours(vehicle)
    props.color1, props.color2 = c1, c2
    for i = 0, 7 do
        props.windows[i] = not IsVehicleWindowIntact(vehicle, i)
        props.tyres[i] = IsVehicleTyreBurst(vehicle, i, false)
    end
    for i = 0, 5 do
        props.doors[i] = IsVehicleDoorDamaged(vehicle, i)
    end
    for i = 0, 14 do
        if DoesExtraExist(vehicle, i) then
            props.extras[i] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end
    props.livery = GetVehicleLivery(vehicle)
    return props
end

local function progress(cfgKey, label)
    local cfg = Config.Progress[cfgKey] or {}
    local anim = cfg.anim
    return lib.progressCircle({
        duration = cfg.duration or 3000,
        label = label or cfg.label or '',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = cfg.disable or { move = true, car = true, combat = true },
        anim = anim and {
            dict = anim.dict,
            clip = anim.clip,
        } or nil,
    })
end

function CoreGarage.TakeOutVehicle(plate, isImpound)
    local garageName = CoreGarage.currentGarage
    if not garageName then return false end

    CoreGarage.CloseNui()

    -- Animation portail
    if Config.Gate.enabled then
        if not progress('gate', _('gate_opening')) then
            CoreGarage.Notify(_('cancelled'), 'inform')
            return false
        end
    end

    if not progress(isImpound and 'impound' or 'takeOut', _(isImpound and 'progress_impound' or 'progress_takeout')) then
        CoreGarage.Notify(_('cancelled'), 'inform')
        return false
    end

    local result
    if isImpound then
        result = lib.callback.await('core_garage:retrieveImpound', false, { plate = plate, garage = garageName })
    else
        result = lib.callback.await('core_garage:takeOut', false, { plate = plate, garage = garageName })
    end

    if not result or not result.ok then
        local err = result and result.error or 'error'
        if err == 'company_max_out' and result.errorArg then
            CoreGarage.Notify(_('company_max_out', result.errorArg), 'error')
        elseif err == 'impound_wait' and result.errorArg then
            CoreGarage.Notify(_('impound_wait', result.errorArg), 'error')
        else
            CoreGarage.Notify(_(err), 'error')
        end
        return false
    end

    local spawn = GarageUtils.ToVec4(result.spawn)
    if not spawn then
        TriggerServerEvent('core_garage:server:spawnFailed', result.plate)
        CoreGarage.Notify(_('error'), 'error')
        return false
    end

    local model = result.props.model
    if type(model) == 'string' then model = joaat(model) end

    if not IsModelInCdimage(model) then
        TriggerServerEvent('core_garage:server:spawnFailed', result.plate)
        CoreGarage.Notify(_('error'), 'error')
        return false
    end

    lib.requestModel(model, 5000)

    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w or result.heading or 0.0, true, true)
    if not vehicle or vehicle == 0 then
        TriggerServerEvent('core_garage:server:spawnFailed', result.plate)
        CoreGarage.Notify(_('error'), 'error')
        SetModelAsNoLongerNeeded(model)
        return false
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetModelAsNoLongerNeeded(model)

    setVehicleProperties(vehicle, result.props)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(netId, true)
    SetNetworkIdExistsOnAllMachines(netId, true)

    TriggerServerEvent('core_garage:server:spawned', result.plate, netId)

    if result.giveKeys then
        TriggerEvent(Config.General.keysEvent or 'core_garage:client:giveKeys', result.plate, vehicle)
    end

    CoreGarage.mileageCache[result.plate] = result.mileage or 0.0

    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

    if isImpound and result.fee then
        CoreGarage.Notify(_('impound_paid', result.fee), 'success')
    else
        CoreGarage.Notify(_('vehicle_out', result.plate), 'success')
    end

    return true
end

-- Application props via statebag (OneSync)
AddStateBagChangeHandler('garageProps', nil, function(bagName, _, value)
    if not value then return end
    local entity = GetEntityFromStateBagName(bagName)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        setVehicleProperties(entity, value)
    end
end)

-- Kilométrage
CreateThread(function()
    while true do
        local sleep = 2000
        if Config.General.mileageEnabled then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) == ped then
                    local plate = GarageUtils.NormalizePlate(GetVehicleNumberPlateText(veh))
                    if Entity(veh).state[Config.General.plateStatebag] or CoreGarage.mileageCache[plate] then
                        sleep = Config.General.mileageInterval or 5000
                        local speed = GetEntitySpeed(veh) * 3.6 -- km/h
                        local dt = (Config.General.mileageInterval or 5000) / 1000.0 / 3600.0
                        local add = speed * dt
                        local current = CoreGarage.mileageCache[plate] or 0.0
                        current = current + add
                        CoreGarage.mileageCache[plate] = current
                        if add > 0.001 then
                            TriggerServerEvent('core_garage:server:updateMileage', plate, current, GetEntityCoords(veh))
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Détection destruction
CreateThread(function()
    local tracked = {}
    while true do
        Wait(2000)
        if not Config.General.autoImpoundOnDestroy then goto continue end
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local plate = GarageUtils.NormalizePlate(GetVehicleNumberPlateText(veh))
            if Entity(veh).state[Config.General.plateStatebag] then
                tracked[plate] = { veh = veh, netId = NetworkGetNetworkIdFromEntity(veh) }
            end
        end

        for plate, data in pairs(tracked) do
            local exists = DoesEntityExist(data.veh)
            local destroyed = not exists
            if exists then
                local health = GetVehicleEngineHealth(data.veh)
                destroyed = health <= (Config.General.destroyHealthThreshold or 50.0)
            end
            if destroyed then
                TriggerServerEvent('core_garage:server:vehicleDestroyed', plate, data.netId)
                tracked[plate] = nil
                CoreGarage.mileageCache[plate] = nil
            end
        end
        ::continue::
    end
end)
