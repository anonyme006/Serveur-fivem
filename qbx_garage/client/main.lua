local currentGarage = nil
local showingTextUI = false

local function notify(msg, nType)
    lib.notify({
        title = Translate('menu_title'),
        description = msg,
        type = nType or 'inform',
    })
end

local function formatMoney(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local left, num, right = string.match(s, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function getGarageByName(name)
    for i = 1, #Config.Garages do
        if Config.Garages[i].name == name then
            return Config.Garages[i]
        end
    end
    return nil
end

local function isSpawnClear(coords, radius)
    radius = radius or Config.SpawnCheckRadius or 3.0
    return not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, radius)
end

local function findFreeSpawn(garage)
    local spawns = garage.spawns or {}
    for i = 1, #spawns do
        local s = spawns[i]
        if isSpawnClear(s) then
            return s, i
        end
    end
    return spawns[1], 1
end

local function applyVehicleProps(vehicle, data)
    if not vehicle or vehicle == 0 then return end

    if data.mods and next(data.mods) and lib.setVehicleProperties then
        lib.setVehicleProperties(vehicle, data.mods)
    end

    if data.plate then
        SetVehicleNumberPlateText(vehicle, data.plate)
    end

    local fuel = tonumber(data.fuel) or 100
    if GetResourceState('ox_fuel') == 'started' then
        Entity(vehicle).state.fuel = fuel
    elseif GetResourceState('LegacyFuel') == 'started' then
        pcall(function() exports['LegacyFuel']:SetFuel(vehicle, fuel) end)
    elseif GetResourceState('cdn-fuel') == 'started' then
        pcall(function() exports['cdn-fuel']:SetFuel(vehicle, fuel) end)
    else
        SetVehicleFuelLevel(vehicle, fuel + 0.0)
    end

    if data.engine then
        SetVehicleEngineHealth(vehicle, data.engine + 0.0)
    end
    if data.body then
        SetVehicleBodyHealth(vehicle, data.body + 0.0)
    end
end

local function getCurrentVehicleProps(vehicle)
    if lib.getVehicleProperties then
        return lib.getVehicleProperties(vehicle)
    end

    return {
        model = GetEntityModel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        fuelLevel = GetVehicleFuelLevel(vehicle),
        engineHealth = GetVehicleEngineHealth(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
    }
end

local function spawnVehicle(data)
    local model = data.model
    local hash = data.hash or joaat(model)
    if not IsModelInCdimage(hash) then
        notify(Translate('error'), 'error')
        return
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(hash) then
        notify(Translate('error'), 'error')
        return
    end

    local s = data.spawn
    if not isSpawnClear(s) then
        notify(Translate('spawn_blocked'), 'error')
        SetModelAsNoLongerNeeded(hash)
        return
    end

    local vehicle = CreateVehicle(hash, s.x + 0.0, s.y + 0.0, s.z + 0.0, s.w or 0.0, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleEngineOn(vehicle, false, true, false)
    SetVehicleDoorsLocked(vehicle, 1)
    applyVehicleProps(vehicle, data)
    SetModelAsNoLongerNeeded(hash)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(netId, true)
    TriggerServerEvent('qbx_garage:server:setOutNetId', data.plate, netId)

    notify(Translate('taken_out'), 'success')
end

local function openGarageMenu(garage)
    currentGarage = garage

    local result = lib.callback.await('qbx_garage:server:getVehicles', false, garage.name)
    if not result or not result.ok then
        notify(Translate(result and result.message or 'error'), 'error')
        return
    end

    local vehicles = result.vehicles or {}
    local options = {}

    if #vehicles == 0 then
        options[#options + 1] = {
            title = Translate('no_vehicles'),
            icon = 'circle-xmark',
            disabled = true,
        }
    else
        for i = 1, #vehicles do
            local v = vehicles[i]
            local isImpound = garage.type == 'impound'
            local price = isImpound and (v.depotprice > 0 and v.depotprice or (garage.impoundPrice or 0)) or 0
            local desc = ('Plaque: %s | Moteur: %.0f | Carrosserie: %.0f'):format(v.plate, v.engine or 1000, v.body or 1000)
            if isImpound and price > 0 then
                desc = desc .. (' | $%s'):format(formatMoney(price))
            end

            options[#options + 1] = {
                title = v.model,
                description = desc,
                icon = isImpound and 'warehouse' or 'car',
                metadata = {
                    { label = 'Plaque', value = v.plate },
                    { label = 'Carburant', value = tostring(v.fuel) .. '%' },
                },
                onSelect = function()
                    local spawn = select(1, findFreeSpawn(garage))
                    if not spawn then
                        notify(Translate('spawn_blocked'), 'error')
                        return
                    end

                    if not isSpawnClear(spawn) then
                        notify(Translate('spawn_blocked'), 'error')
                        openGarageMenu(garage)
                        return
                    end

                    local take = lib.callback.await('qbx_garage:server:takeOut', false, garage.name, v.id, 1)
                    if not take or not take.ok then
                        notify(Translate(take and take.message or 'error'), 'error')
                        openGarageMenu(garage)
                        return
                    end

                    spawnVehicle(take.vehicle)
                end,
            }
        end
    end

    options[#options + 1] = {
        title = Translate('close'),
        icon = 'xmark',
        onSelect = function() end,
    }

    lib.registerContext({
        id = 'qbx_garage_menu',
        title = garage.type == 'impound' and Translate('impound_title') or garage.label,
        options = options,
    })
    lib.showContext('qbx_garage_menu')
end

local function tryStoreVehicle(garage)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        openGarageMenu(garage)
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        notify(Translate('must_be_driver'), 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local props = getCurrentVehicleProps(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    local result = lib.callback.await('qbx_garage:server:storeVehicle', false, garage.name, plate, props, netId)
    if not result or not result.ok then
        notify(Translate(result and result.message or 'error'), 'error')
        return
    end

    TaskLeaveVehicle(ped, vehicle, 0)
    Wait(1200)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end
    notify(Translate('stored'), 'success')
end

RegisterNetEvent('qbx_garage:client:deleteVehicle', function(netId)
    if not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteVehicle(entity)
    end
end)

RegisterNetEvent('qbx_garage:client:giveKeys', function(netId, plate)
    local vehicle = netId and NetworkGetEntityFromNetworkId(netId) or 0
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        pcall(function()
            exports.qbx_vehiclekeys:GiveKeys(vehicle)
        end)
    end
    TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
end)

-- Blips
CreateThread(function()
    for i = 1, #Config.Garages do
        local g = Config.Garages[i]
        if g.blip and g.blip.enabled then
            local blip = AddBlipForCoord(g.menu.x, g.menu.y, g.menu.z)
            SetBlipSprite(blip, g.blip.sprite or 357)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, g.blip.scale or 0.75)
            SetBlipColour(blip, g.blip.colour or 3)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(g.label or Translate('blip_label'))
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Markers / interaction
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local near = false
        local nearGarage = nil
        local inVehicle = IsPedInAnyVehicle(ped, false)

        for i = 1, #Config.Garages do
            local g = Config.Garages[i]
            local dist = #(coords - g.menu)
            if dist < (g.drawDistance or 30.0) then
                sleep = 0
                local m = g.marker
                if m then
                    DrawMarker(
                        m.type or 36,
                        g.menu.x, g.menu.y, g.menu.z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        (m.size and m.size.x) or 0.6,
                        (m.size and m.size.y) or 0.6,
                        (m.size and m.size.z) or 0.6,
                        m.color.r, m.color.g, m.color.b, m.color.a,
                        false, true, 2, false, nil, nil, false
                    )
                end

                if dist < (g.interactDistance or 2.5) then
                    near = true
                    nearGarage = g
                end
            end
        end

        if near and nearGarage then
            local label = (inVehicle and nearGarage.type ~= 'impound')
                and Translate('press_store')
                or Translate('press_open')

            if not showingTextUI then
                lib.showTextUI(label, { position = 'right-center', icon = 'warehouse' })
                showingTextUI = true
            end

            if IsControlJustReleased(0, 38) then
                lib.hideTextUI()
                showingTextUI = false
                if inVehicle and nearGarage.type ~= 'impound' then
                    tryStoreVehicle(nearGarage)
                else
                    openGarageMenu(nearGarage)
                end
            end
        elseif showingTextUI then
            lib.hideTextUI()
            showingTextUI = false
        end

        Wait(sleep)
    end
end)

RegisterCommand('garage', function(_, args)
    local name = args[1] or Config.DefaultGarage or 'pillbox'
    local garage = getGarageByName(name)
    if garage then
        openGarageMenu(garage)
    else
        notify(Translate('error'), 'error')
    end
end, false)

exports('OpenGarage', function(name)
    local garage = getGarageByName(name or Config.DefaultGarage)
    if garage then openGarageMenu(garage) end
end)
