local spawnedVehicles = {} -- plate -> entity
local currentGarage = nil
local busy = false

local function notify(msg, nType)
    if lib and lib.notify then
        lib.notify({ title = 'Garage', description = msg, type = nType or 'inform' })
        return
    end
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    end
end

local function progress(label, duration, anim)
    if GetResourceState('esx_progressbar') ~= 'started' then
        Wait(duration)
        return true
    end

    return exports['esx_progressbar']:ProgressAwait({
        name = 'ox_garage',
        label = label,
        duration = duration,
        canCancel = true,
        animation = anim,
    })
end

local function trimPlate(plate)
    if not plate then return '' end
    return (string.gsub(string.upper(plate), '^%s*(.-)%s*$', '%1'))
end

local function getClosestVehicle(coords, maxDist)
    local vehicles = GetGamePool('CVehicle')
    local closest, closestDist = nil, maxDist or Config.StoreDistance

    for i = 1, #vehicles do
        local veh = vehicles[i]
        if DoesEntityExist(veh) then
            local dist = #(coords - GetEntityCoords(veh))
            if dist < closestDist then
                closest = veh
                closestDist = dist
            end
        end
    end

    return closest, closestDist
end

local function isSpawnClear(coords, radius)
    return not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, radius or 3.0)
end

local function deleteLocalVehicle(plate)
    plate = trimPlate(plate)
    local entity = spawnedVehicles[plate]
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteVehicle(entity)
    end
    spawnedVehicles[plate] = nil
end

local function applyProps(vehicle, props)
    if not props or not DoesEntityExist(vehicle) then return end
    if ESX and ESX.Game and ESX.Game.SetVehicleProperties then
        ESX.Game.SetVehicleProperties(vehicle, props)
        return
    end
    if lib and lib.setVehicleProperties then
        lib.setVehicleProperties(vehicle, props)
    end
end

local function getProps(vehicle)
    if ESX and ESX.Game and ESX.Game.GetVehicleProperties then
        return ESX.Game.GetVehicleProperties(vehicle)
    end
    if lib and lib.getVehicleProperties then
        return lib.getVehicleProperties(vehicle)
    end
    return { plate = trimPlate(GetVehicleNumberPlateText(vehicle)), model = GetEntityModel(vehicle) }
end

local function spawnVehicle(data, spawn)
    local model = data.model or (data.props and data.props.model)
    if type(model) == 'string' then model = joaat(model) end
    if not model or not IsModelInCdimage(model) then
        notify('Modèle de véhicule invalide', 'error')
        return nil
    end

    lib.requestModel(model, 5000)

    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w or 0.0, true, false)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(vehicle) then
        notify('Impossible de faire apparaître le véhicule', 'error')
        return nil
    end

    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')

    local plate = trimPlate(data.plate or (data.props and data.props.plate))
    if plate ~= '' then
        SetVehicleNumberPlateText(vehicle, plate)
    end

    applyProps(vehicle, data.props)
    SetVehicleEngineHealth(vehicle, data.engine or 1000.0)
    SetVehicleBodyHealth(vehicle, data.body or 1000.0)
    if data.fuel then
        SetVehicleFuelLevel(vehicle, data.fuel + 0.0)
    end

    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    spawnedVehicles[plate] = vehicle

    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    return vehicle
end

local function openVehicleMenu(garage, vehicles, isImpound)
    if not vehicles or #vehicles == 0 then
        notify(isImpound and 'Aucun véhicule en fourrière' or 'Aucun véhicule dans ce garage', 'inform')
        return
    end

    local options = {}
    for _, veh in ipairs(vehicles) do
        local title = veh.label or veh.model or veh.plate
        local desc = ('Plaque : %s'):format(veh.plate)
        if isImpound then
            desc = desc .. (' — Caution : $%s'):format(Config.Impound.price)
        end
        options[#options + 1] = {
            title = title,
            description = desc,
            icon = 'car',
            onSelect = function()
                if busy then return end
                busy = true

                local ok = progress(
                    Config.RetrieveLabel,
                    Config.Progress.retrieve,
                    {
                        animDict = 'anim@mp_player_intmenu@key_fob@',
                        anim = 'fob_click',
                        flags = 49,
                    }
                )

                if not ok then
                    busy = false
                    notify('Action annulée', 'error')
                    return
                end

                local spawn = garage.spawn
                if not isSpawnClear(spawn, 3.0) then
                    busy = false
                    notify('Point de sortie occupé', 'error')
                    return
                end

                local result = lib.callback.await('ox_garage:retrieve', false, {
                    garageId = garage.id,
                    plate = veh.plate,
                    impound = isImpound == true,
                })

                busy = false

                if not result or not result.ok then
                    notify((result and result.reason) or 'Impossible de sortir le véhicule', 'error')
                    return
                end

                spawnVehicle(result, spawn)
                notify(('Véhicule sorti : %s'):format(veh.plate), 'success')
            end,
        }
    end

    lib.registerContext({
        id = 'ox_garage_vehicles',
        title = garage.label,
        options = options,
    })
    lib.showContext('ox_garage_vehicles')
end

local function openGarage(garage)
    if busy then return end
    currentGarage = garage

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        -- Ranger le véhicule actuel
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(vehicle, -1) ~= ped then
            notify('Vous devez être conducteur', 'error')
            return
        end

        busy = true
        local props = getProps(vehicle)
        local plate = trimPlate(props.plate or GetVehicleNumberPlateText(vehicle))

        TaskLeaveVehicle(ped, vehicle, 16)
        local timeout = GetGameTimer() + 3000
        while IsPedInAnyVehicle(ped, false) and GetGameTimer() < timeout do
            Wait(50)
        end

        local ok = progress(
            Config.StoreLabel,
            Config.Progress.store,
            {
                animDict = 'mp_common',
                anim = 'givetake1_a',
                flags = 49,
            }
        )

        if not ok then
            busy = false
            notify('Rangement annulé', 'error')
            return
        end

        if not DoesEntityExist(vehicle) then
            busy = false
            notify('Véhicule introuvable', 'error')
            return
        end

        local result = lib.callback.await('ox_garage:store', false, {
            garageId = garage.id,
            plate = plate,
            props = props,
            engine = GetVehicleEngineHealth(vehicle),
            body = GetVehicleBodyHealth(vehicle),
            fuel = GetVehicleFuelLevel(vehicle),
        })

        if result and result.ok then
            deleteLocalVehicle(plate)
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)
            notify('Véhicule rangé', 'success')
        else
            notify((result and result.reason) or 'Impossible de ranger le véhicule', 'error')
        end

        busy = false
        return
    end

    -- Menu des véhicules stockés
    local vehicles = lib.callback.await('ox_garage:list', false, garage.id, false)
    openVehicleMenu(garage, vehicles, false)
end

local function openImpound()
    if busy then return end
    local vehicles = lib.callback.await('ox_garage:list', false, Config.Impound.id, true)
    openVehicleMenu(Config.Impound, vehicles, true)
end

local function storeNearbyVehicle(garage)
    if busy then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        openGarage(garage)
        return
    end

    local coords = GetEntityCoords(ped)
    local vehicle = getClosestVehicle(coords, Config.StoreDistance)
    if not vehicle then
        notify('Aucun véhicule à proximité', 'error')
        return
    end

    busy = true
    local props = getProps(vehicle)
    local plate = trimPlate(props.plate or GetVehicleNumberPlateText(vehicle))

    local ok = progress(
        Config.StoreLabel,
        Config.Progress.store,
        {
            animDict = 'mp_common',
            anim = 'givetake1_a',
            flags = 49,
        }
    )

    if not ok then
        busy = false
        notify('Rangement annulé', 'error')
        return
    end

    local result = lib.callback.await('ox_garage:store', false, {
        garageId = garage.id,
        plate = plate,
        props = props,
        engine = GetVehicleEngineHealth(vehicle),
        body = GetVehicleBodyHealth(vehicle),
        fuel = GetVehicleFuelLevel(vehicle),
    })

    if result and result.ok then
        deleteLocalVehicle(plate)
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        notify('Véhicule rangé', 'success')
    else
        notify((result and result.reason) or 'Impossible de ranger le véhicule', 'error')
    end

    busy = false
end

local function createBlips()
    for _, garage in ipairs(Config.Garages) do
        if garage.blip then
            local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
            SetBlipSprite(blip, garage.blip.sprite or 357)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, garage.blip.scale or 0.75)
            SetBlipColour(blip, garage.blip.color or 47)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(garage.label)
            EndTextCommandSetBlipName(blip)
        end
    end

    if Config.Impound and Config.Impound.blip then
        local imp = Config.Impound
        local blip = AddBlipForCoord(imp.coords.x, imp.coords.y, imp.coords.z)
        SetBlipSprite(blip, imp.blip.sprite or 67)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, imp.blip.scale or 0.75)
        SetBlipColour(blip, imp.blip.color or 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(imp.label)
        EndTextCommandSetBlipName(blip)
    end
end

local function setupTargets()
    if not Config.UseOxTarget or GetResourceState('ox_target') ~= 'started' then
        return false
    end

    for _, garage in ipairs(Config.Garages) do
        exports.ox_target:addSphereZone({
            coords = garage.coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = ('ox_garage_open_%s'):format(garage.id),
                    icon = 'fa-solid fa-warehouse',
                    label = ('Ouvrir %s'):format(garage.label),
                    onSelect = function()
                        openGarage(garage)
                    end,
                },
                {
                    name = ('ox_garage_store_%s'):format(garage.id),
                    icon = 'fa-solid fa-square-parking',
                    label = 'Ranger le véhicule',
                    onSelect = function()
                        storeNearbyVehicle(garage)
                    end,
                },
            },
        })
    end

    if Config.Impound then
        exports.ox_target:addSphereZone({
            coords = Config.Impound.coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'ox_garage_impound',
                    icon = 'fa-solid fa-car-burst',
                    label = Config.Impound.label,
                    onSelect = openImpound,
                },
            },
        })
    end

    return true
end

local function markerLoop()
    CreateThread(function()
        while true do
            local sleep = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for _, garage in ipairs(Config.Garages) do
                local dist = #(coords - garage.coords)
                if dist < Config.DrawDistance then
                    sleep = 0
                    local m = Config.Marker
                    DrawMarker(
                        m.type, garage.coords.x, garage.coords.y, garage.coords.z,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        m.size.x, m.size.y, m.size.z,
                        m.color.r, m.color.g, m.color.b, m.color.a,
                        m.bob, m.faceCamera, 2, false, nil, nil, false
                    )

                    if dist < Config.InteractDistance then
                        lib.showTextUI('[E] ' .. garage.label)
                        if IsControlJustReleased(0, 38) then
                            lib.hideTextUI()
                            if IsPedInAnyVehicle(ped, false) then
                                openGarage(garage)
                            else
                                local vehicles = lib.callback.await('ox_garage:list', false, garage.id, false)
                                openVehicleMenu(garage, vehicles, false)
                            end
                        end
                    end
                end
            end

            if Config.Impound then
                local dist = #(coords - Config.Impound.coords)
                if dist < Config.DrawDistance then
                    sleep = 0
                    local m = Config.Marker
                    DrawMarker(
                        m.type, Config.Impound.coords.x, Config.Impound.coords.y, Config.Impound.coords.z,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        m.size.x, m.size.y, m.size.z,
                        220, 60, 60, 160,
                        m.bob, m.faceCamera, 2, false, nil, nil, false
                    )
                    if dist < Config.InteractDistance then
                        lib.showTextUI('[E] ' .. Config.Impound.label)
                        if IsControlJustReleased(0, 38) then
                            lib.hideTextUI()
                            openImpound()
                        end
                    end
                end
            end

            if sleep ~= 0 then
                lib.hideTextUI()
            end

            Wait(sleep)
        end
    end)
end

CreateThread(function()
    while not ESX or not ESX.IsPlayerLoaded or not ESX.IsPlayerLoaded() do
        Wait(200)
    end

    createBlips()
    local hasTarget = setupTargets()
    if not hasTarget then
        markerLoop()
    end
end)

-- Nettoyage si un véhicule spawné est trop loin / détruit
CreateThread(function()
    while true do
        Wait(15000)
        for plate, entity in pairs(spawnedVehicles) do
            if not DoesEntityExist(entity) then
                spawnedVehicles[plate] = nil
            end
        end
    end
end)

exports('OpenGarage', openGarage)
exports('OpenImpound', openImpound)
