local runActive = false
local route = {}
local routeIndex = 1
local routeBlip
local runVehicle
local pickupZoneId
local points = {}

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
            name = 'vibe_g6_pickup_' .. stop.id,
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
                    TriggerServerEvent('vibe_gruppe6:server:pickup', stop.id)
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

RegisterNetEvent('vibe_gruppe6:client:begin', function(newRoute)
    runActive = true
    route = newRoute or {}
    routeIndex = 1
    spawnRunVehicle()
    goToStop(1)
    exports.vibe_api:Notify('Gruppe 6', ('Tournée lancée — %s arrêt(s).'):format(#route), 'inform')
end)

RegisterNetEvent('vibe_gruppe6:client:nextStop', function(index)
    goToStop(index)
end)

RegisterNetEvent('vibe_gruppe6:client:returnDepot', function()
    removePickupZone()
    setRouteBlip(Config.Depot.coords, Config.Depot.label)
    exports.vibe_api:Notify('Gruppe 6', 'Retourne au dépôt pour déposer les fonds.', 'inform')
end)

RegisterNetEvent('vibe_gruppe6:client:stop', function()
    runActive = false
    route = {}
    routeIndex = 1
    removePickupZone()
    clearBlip()
    deleteRunVehicle()
end)

RegisterNetEvent('vibe_gruppe6:client:refreshPoints', function(newPoints)
    points = newPoints or {}
end)

CreateThread(function()
    points = lib.callback.await('vibe_gruppe6:server:getPoints', false) or {}

    exports.ox_target:addSphereZone({
        coords = Config.Depot.coords,
        radius = Config.Depot.radius,
        options = {
            {
                name = 'vibe_g6_start',
                icon = 'fa-solid fa-truck-fast',
                label = 'Prendre une tournée convoi',
                canInteract = function()
                    return not runActive
                end,
                onSelect = function()
                    TriggerServerEvent('vibe_gruppe6:server:start')
                end,
            },
            {
                name = 'vibe_g6_deposit',
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
                        TriggerServerEvent('vibe_gruppe6:server:deposit')
                    end
                end,
            },
            {
                name = 'vibe_g6_cancel',
                icon = 'fa-solid fa-ban',
                label = 'Annuler la tournée',
                canInteract = function()
                    return runActive
                end,
                onSelect = function()
                    TriggerServerEvent('vibe_gruppe6:server:cancel')
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
