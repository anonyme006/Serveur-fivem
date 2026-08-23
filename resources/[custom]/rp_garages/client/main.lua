local openGarage

local function canUseGarage(g)
    if g.type == 'public' or g.type == 'impound' then return true end
    if g.type == 'job' then
        local pd = exports.qbx_core:GetPlayerData()
        return pd and pd.job and pd.job.name == g.job
    end
    return false
end

CreateThread(function()
    for _, g in ipairs(Config.Garages) do
        if g.blip then
            local blip = AddBlipForCoord(g.coords.x, g.coords.y, g.coords.z)
            SetBlipSprite(blip, g.blip.sprite)
            SetBlipColour(blip, g.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(g.label)
            EndTextCommandSetBlipName(blip)
        end
        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:addSphereZone({
                coords = g.coords,
                radius = 2.0,
                options = {
                    {
                        name = 'rp_garage_' .. g.id,
                        icon = 'fa-solid fa-warehouse',
                        label = g.label,
                        canInteract = function() return canUseGarage(g) end,
                        onSelect = function() openGarage(g) end,
                    }
                }
            })
        end
    end
end)

openGarage = function(g)
    local filter = g.type == 'impound' and 'impound' or nil
    local vehicles = lib.callback.await('rp_garages:getVehicles', false, g.id, filter) or {}
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        garage = { id = g.id, label = g.label, type = g.type },
        vehicles = vehicles,
    })
end

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb(1)
end)

RegisterNUICallback('spawn', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('rp_garages:server:spawn', data.garageId, data.vehicleId)
    cb(1)
end)

RegisterNUICallback('release', function(data, cb)
    TriggerServerEvent('rp_garages:server:impoundRelease', data.vehicleId)
    cb(1)
end)

RegisterNUICallback('store', function(data, cb)
    local veh = cache.vehicle
    if not veh then cb(0) return end
    local plate = GetVehicleNumberPlateText(veh)
    local props = lib.getVehicleProperties(veh)
    TriggerServerEvent('rp_garages:server:store', data.garageId, plate, props)
    TaskLeaveVehicle(cache.ped, veh, 0)
    Wait(1500)
    if DoesEntityExist(veh) then DeleteVehicle(veh) end
    SetNuiFocus(false, false)
    cb(1)
end)

RegisterNetEvent('rp_garages:client:spawn', function(garageId, row)
    local g
    for _, garage in ipairs(Config.Garages) do
        if garage.id == garageId then g = garage break end
    end
    if not g then return end
    local model = row.vehicle
    local hash = type(model) == 'string' and joaat(model) or model
    lib.requestModel(hash)
    local s = g.spawn
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w, true, false)
    SetVehicleNumberPlateText(veh, row.plate)
    SetVehicleFuelLevel(veh, row.fuel or 100.0)
    if row.mods then
        local mods = type(row.mods) == 'string' and json.decode(row.mods) or row.mods
        if mods then lib.setVehicleProperties(veh, mods) end
    end
    SetPedIntoVehicle(cache.ped, veh, -1)
    SetModelAsNoLongerNeeded(hash)
    if GetResourceState('qbx_vehiclekeys') == 'started' then
        TriggerEvent('qbx_vehiclekeys:client:addKeys', row.plate)
    end
    lib.notify({ description = L('taken'), type = 'success' })
end)
