local runActive = false
local route = {}
local routeIndex = 1
local routeBlip
local runVehicle
local pickupZoneId

local function notify(title, msg, nType)
    if lib and lib.notify then
        lib.notify({ title = title or 'Gruppe 6', description = msg, type = nType or 'inform' })
    elseif ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    end
end

RegisterNetEvent('esx_gruppe6:notify', function(title, msg, nType)
    notify(title, msg, nType)
end)

local function removePickupZone()
    if pickupZoneId then
        exports.ox_target:removeZone(pickupZoneId)
        pickupZoneId = nil
    end
end

local function clearBlip()
    if routeBlip then
        RemoveBlip(routeBlip)
        routeBlip = nil
    end
end

local function deleteRunVehicle()
    if runVehicle and DoesEntityExist(runVehicle) then
        SetEntityAsMissionEntity(runVehicle, true, true)
        DeleteVehicle(runVehicle)
    end
    runVehicle = nil
end

local function setRouteBlip(coords, label)
    clearBlip()
    routeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(routeBlip, 500)
    SetBlipColour(routeBlip, 2)
    SetBlipScale(routeBlip, 0.85)
    SetBlipRoute(routeBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or 'Arrêt Gruppe 6')
    EndTextCommandSetBlipName(routeBlip)
end

local function getCurrentStop()
    return route[routeIndex]
end

local function setupPickupZone(stop)
    removePickupZone()
    if not stop then return end

    pickupZoneId = exports.ox_target:addSphereZone({
        coords = stop.coords,
        radius = Config.Pickup.radius,
        options = {{
            name = 'esx_g6_pickup_' .. stop.id,
            icon = 'fa-solid fa-sack-dollar',
            label = Config.Pickup.label .. ' — ' .. stop.label,
            canInteract = function()
                if not runActive or routeIndex > #route then return false end
                local current = getCurrentStop()
                return current and current.id == stop.id
            end,
            onSelect = function()
                if lib.progressCircle({
                    duration = Config.Pickup.duration,
                    label = Config.Pickup.label,
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = { dict = 'anim@heists@box_carry@', clip = 'idle' },
                }) then
                    TriggerServerEvent('esx_gruppe6:server:pickup', stop.id)
                end
            end,
        }},
    })
end

local function goToStop(index)
    routeIndex = index
    local stop = getCurrentStop()
    if not stop then return end
    setRouteBlip(stop.coords, stop.label)
    setupPickupZone(stop)
end

local function spawnRunVehicle()
    deleteRunVehicle()
    local s = Config.Spawn
    local hash = joaat(Config.Vehicle)
    lib.requestModel(hash)
    runVehicle = CreateVehicle(hash, s.x, s.y, s.z, s.w, true, false)
    SetVehicleNumberPlateText(runVehicle, 'GRUPPE6')
    SetPedIntoVehicle(cache.ped, runVehicle, -1)
    SetModelAsNoLongerNeeded(hash)
end

RegisterNetEvent('esx_gruppe6:client:begin', function(newRoute)
    runActive = true
    route = newRoute or {}
    routeIndex = 1
    spawnRunVehicle()
    goToStop(1)
    notify('Gruppe 6', L('run_started', #route), 'inform')
end)

RegisterNetEvent('esx_gruppe6:client:nextStop', function(index)
    goToStop(index)
end)

RegisterNetEvent('esx_gruppe6:client:returnDepot', function()
    removePickupZone()
    setRouteBlip(Config.Depot.coords, Config.Depot.label)
    notify('Gruppe 6', L('return_depot'), 'inform')
end)

RegisterNetEvent('esx_gruppe6:client:stop', function()
    runActive = false
    route = {}
    routeIndex = 1
    removePickupZone()
    clearBlip()
    deleteRunVehicle()
end)

RegisterNetEvent('esx_gruppe6:client:refreshPoints', function()
    -- sync côté client si besoin futur (markers, debug)
end)

CreateThread(function()
    local blip = Config.Depot.blip
    if blip then
        local b = AddBlipForCoord(Config.Depot.coords.x, Config.Depot.coords.y, Config.Depot.coords.z)
        SetBlipSprite(b, blip.sprite or 477)
        SetBlipColour(b, blip.color or 2)
        SetBlipScale(b, blip.scale or 0.85)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Gruppe 6')
        EndTextCommandSetBlipName(b)
    end

    exports.ox_target:addSphereZone({
        coords = Config.Depot.coords,
        radius = Config.Depot.radius,
        options = {
            {
                name = 'esx_g6_start',
                icon = 'fa-solid fa-truck-fast',
                label = 'Prendre une tournée convoi',
                canInteract = function()
                    return not runActive
                end,
                onSelect = function()
                    TriggerServerEvent('esx_gruppe6:server:start')
                end,
            },
            {
                name = 'esx_g6_deposit',
                icon = 'fa-solid fa-vault',
                label = Config.Deposit.label,
                canInteract = function()
                    return runActive and routeIndex > #route
                end,
                onSelect = function()
                    if lib.progressCircle({
                        duration = Config.Deposit.duration,
                        label = Config.Deposit.label,
                        position = 'bottom',
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab' },
                    }) then
                        TriggerServerEvent('esx_gruppe6:server:deposit')
                    end
                end,
            },
            {
                name = 'esx_g6_cancel',
                icon = 'fa-solid fa-ban',
                label = 'Annuler la tournée',
                canInteract = function()
                    return runActive
                end,
                onSelect = function()
                    TriggerServerEvent('esx_gruppe6:server:cancel')
                end,
            },
        },
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    removePickupZone()
    clearBlip()
    deleteRunVehicle()
end)
